"""Launch candidate GNOME with disposable state and isolated D-Bus connections."""

import argparse
import ast
import ctypes
import json
import os
from pathlib import Path
import pwd
import re
import shutil
import signal
import stat
import subprocess
import sys
import tempfile
import time
from xml.sax.saxutils import escape


def window_size(value):
    match = re.fullmatch(r"([1-9][0-9]{2,3})x([1-9][0-9]{2,3})", value)
    if match is None:
        raise argparse.ArgumentTypeError("size must be WIDTHxHEIGHT, e.g. 1280x800")

    width, height = map(int, match.groups())
    if not (320 <= width <= 7680 and 240 <= height <= 4320):
        raise argparse.ArgumentTypeError("size must be within 320x240 and 7680x4320")
    return value


def outer_wayland_socket():
    if os.environ.get("XDG_SESSION_TYPE") != "wayland":
        raise RuntimeError("Run this command from a Wayland desktop session.")

    display = os.environ.get("WAYLAND_DISPLAY")
    runtime = os.environ.get("XDG_RUNTIME_DIR")
    if not display or not runtime:
        raise RuntimeError("WAYLAND_DISPLAY and XDG_RUNTIME_DIR must be set.")

    path = Path(display)
    if not path.is_absolute():
        path = Path(runtime) / path
    path = path.resolve(strict=True)
    if not stat.S_ISSOCK(path.stat().st_mode):
        raise RuntimeError(f"Not a Wayland socket: {path}")
    return str(path)


def candidate_profile(manifest):
    lines = Path(manifest["profile"]).read_text().splitlines()
    databases = []
    for line in lines:
        if not line or line.startswith("#") or line == "user-db:user":
            continue
        if not line.startswith("file-db:/nix/store/"):
            raise RuntimeError(f"Unsupported candidate dconf profile entry: {line!r}")
        if not Path(line.removeprefix("file-db:")).is_file():
            raise RuntimeError(f"Missing candidate dconf database: {line}")
        databases.append(line)

    if not databases:
        raise RuntimeError("The candidate profile has no system databases.")
    return "\n".join(["user-db:user", *databases, ""])


def private_environment(root, manifest, wayland):
    # Do not inherit session addresses, user search paths, or application state.
    environment = {}
    rendering_variables = {
        "LANG", "TZ", "DRI_PRIME", "GBM_BACKEND", "LIBGL_DRIVERS_PATH",
        "__GLX_VENDOR_LIBRARY_NAME", "__EGL_VENDOR_LIBRARY_FILENAMES",
    }
    for key, value in os.environ.items():
        if key in rendering_variables or key.startswith("LC_"):
            environment[key] = value

    directories = {
        "HOME": "home",
        "XDG_CONFIG_HOME": "config",
        "XDG_DATA_HOME": "data",
        "XDG_CACHE_HOME": "cache",
        "XDG_STATE_HOME": "state",
        "XDG_RUNTIME_DIR": "runtime",
        "TMPDIR": "tmp",
    }
    for variable, name in directories.items():
        path = root / name
        path.mkdir(mode=0o700)
        environment[variable] = str(path)

    user = pwd.getpwuid(os.getuid()).pw_name
    environment.update({
        "USER": user,
        "LOGNAME": user,
        "PATH": manifest["path"],
        "WAYLAND_DISPLAY": wayland,
        "GDK_BACKEND": "wayland",
        "XDG_SESSION_TYPE": "wayland",
        "XDG_CURRENT_DESKTOP": "GNOME",
        "XDG_DATA_DIRS": ":".join(manifest["dataDirectories"]),
        "XDG_CONFIG_DIRS": str(root / "config"),
        "DCONF_PROFILE": str(root / "dconf-profile"),
        "GSETTINGS_BACKEND": "dconf",
        "GSETTINGS_SCHEMA_DIR": manifest["schemaDirectory"],
        "GIO_EXTRA_MODULES": manifest["gioModules"],
        "PIPEWIRE_RUNTIME_DIR": str(root / "runtime"),
        "PIPEWIRE_CONFIG_DIR": manifest["pipewireConfigDirectory"],
        "PULSE_RUNTIME_PATH": str(root / "runtime" / "pulse"),
        "NO_AT_BRIDGE": "1",
        "GTK_A11Y": "none",
        "DBUS_SYSTEM_BUS_ADDRESS": f"unix:path={root}/runtime/system-bus",
    })
    return environment


def write_bus_config(root, manifest):
    # No standard service directories or systemd activation: only private dconf.
    config = f"""<busconfig>
  <type>session</type>
  <listen>unix:tmpdir={escape(str(root / 'runtime'))}</listen>
  <auth>EXTERNAL</auth>
  <servicedir>{escape(manifest['dconfServices'])}</servicedir>
  <policy context="default">
    <allow send_destination="*"/>
    <allow receive_sender="*"/>
    <allow own="*"/>
  </policy>
</busconfig>
"""
    path = root / "bus.conf"
    path.write_text(config)
    return path


def bus_call(manifest, method, *arguments):
    return subprocess.check_output([
        manifest["gdbus"], "call", "--session",
        "--dest", "org.freedesktop.DBus", "--object-path", "/org/freedesktop/DBus",
        "--method", f"org.freedesktop.DBus.{method}", *arguments,
    ], text=True, timeout=5).strip()


def verify_private_session(root, manifest):
    outer = json.loads((root / "outer-session.json").read_text())
    address = os.environ.get("DBUS_SESSION_BUS_ADDRESS", "")
    if not address or address == outer["bus"]:
        raise RuntimeError("The preview did not acquire a private D-Bus session.")
    if f"unix:path={root}/runtime/" not in address:
        raise RuntimeError(f"D-Bus socket is outside the private runtime directory: {address}")

    for variable in ("HOME", "XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_RUNTIME_DIR"):
        if not Path(os.environ[variable]).is_relative_to(root):
            raise RuntimeError(f"{variable} escaped the preview workspace.")
    if os.environ["XDG_RUNTIME_DIR"] == outer["runtime"]:
        raise RuntimeError("The preview is using the outer runtime directory.")
    if os.environ.get("DCONF_PROFILE") != str(root / "dconf-profile"):
        raise RuntimeError("The preview is not using its private dconf profile.")
    if os.environ.get("DBUS_SYSTEM_BUS_ADDRESS") != f"unix:path={root}/runtime/system-bus":
        raise RuntimeError("The preview is not using its filtered system-bus proxy.")

    activatable = bus_call(manifest, "ListActivatableNames")
    names = set(re.findall(r"'([^']+)'", activatable))
    if not names <= {"org.freedesktop.DBus", "ca.desrt.dconf"}:
        raise RuntimeError(f"Unexpected private-bus service activation: {activatable}")
    if "ca.desrt.dconf" not in names:
        raise RuntimeError("Private dconf service activation is unavailable.")
    print(f"Private session bus: {address}", flush=True)
    enabled = subprocess.check_output([
        manifest["gsettings"], "get", "org.gnome.shell", "enabled-extensions",
    ], text=True, timeout=5).strip()
    enabled_uuids = ast.literal_eval(enabled.removeprefix("@as "))
    available = {extension["uuid"] for extension in manifest["extensions"]}
    for uuid in enabled_uuids:
        if uuid not in available:
            print(f"Warning: configured extension is unavailable in the candidate: {uuid}",
                  file=sys.stderr)
    print(f"Candidate enabled extensions: {enabled}", flush=True)


def terminate(process):
    if process is None or process.poll() is not None:
        return
    process.terminate()
    try:
        process.wait(timeout=5)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait()


def run_inside_session(root, manifest, size):
    verify_private_session(root, manifest)
    command = [manifest["shell"], "--wayland", "--devkit", "--no-x11",
               f"--virtual-monitor={size}"]
    pipewire = None
    shell = None
    try:
        # Devkit streams the private compositor through PipeWire. Its socket is
        # private too; do not connect to or start the host's audio services.
        pipewire = subprocess.Popen([
            manifest["pipewire"], "--config", manifest["pipewireConfig"],
        ])
        deadline = time.monotonic() + 10
        pipewire_socket = root / "runtime" / "pipewire-0"
        while not pipewire_socket.exists():
            if pipewire.poll() is not None or time.monotonic() > deadline:
                raise RuntimeError("The private PipeWire helper did not start.")
            time.sleep(0.1)

        print("Starting disposable GNOME Shell; close Devkit or press Ctrl-C to exit.", flush=True)
        shell = subprocess.Popen(command)
        return shell.wait()
    finally:
        terminate(shell)
        terminate(pipewire)


class ChildSupervisor:
    """Adopt detached descendants and signal only our direct, unreaped children."""

    def __init__(self):
        if not hasattr(os, "pidfd_open") or not hasattr(signal, "pidfd_send_signal"):
            raise RuntimeError("Linux pidfd support is required for safe preview cleanup.")
        libc = ctypes.CDLL(None, use_errno=True)
        # PR_SET_CHILD_SUBREAPER: orphaned grandchildren become our children,
        # including Devkit, which calls setsid() and escapes process groups.
        if libc.prctl(36, 1, 0, 0, 0) != 0:
            raise OSError(ctypes.get_errno(), "Cannot enable child-subreaper supervision")

    def children(self):
        path = Path(f"/proc/self/task/{os.getpid()}/children")
        return [int(value) for value in path.read_text().split()]

    def cleanup(self):
        descriptors = {}
        handlers = {sig: signal.signal(sig, signal.SIG_IGN)
                    for sig in (signal.SIGINT, signal.SIGTERM)}
        start = time.monotonic()
        try:
            while True:
                while True:
                    try:
                        pid, _ = os.waitpid(-1, os.WNOHANG)
                    except ChildProcessError:
                        pid = 0
                    if pid == 0:
                        break
                    descriptor = descriptors.pop(pid, None)
                    if descriptor is not None:
                        os.close(descriptor)

                children = self.children()
                if not children:
                    return
                elapsed = time.monotonic() - start
                if elapsed > 12:
                    raise RuntimeError(
                        "Preview descendants did not exit; preserving temporary state."
                    )
                for pid in children:
                    if pid not in descriptors:
                        # An unreaped direct child cannot have its PID reused.
                        descriptors[pid] = os.pidfd_open(pid)
                        try:
                            signal.pidfd_send_signal(descriptors[pid], signal.SIGTERM)
                        except ProcessLookupError:
                            pass
                    if elapsed > 5:
                        try:
                            signal.pidfd_send_signal(descriptors[pid], signal.SIGKILL)
                        except ProcessLookupError:
                            pass
                time.sleep(0.05)
        finally:
            for descriptor in descriptors.values():
                os.close(descriptor)
            for sig, handler in handlers.items():
                signal.signal(sig, handler)


def interrupt(signum, frame):
    raise KeyboardInterrupt


def run_preview(root, manifest_path, manifest, args, wayland):
    profile = candidate_profile(manifest)
    environment = private_environment(root, manifest, wayland)
    (root / "dconf-profile").write_text(profile)
    bus_config = write_bus_config(root, manifest)
    (root / "outer-session.json").write_text(json.dumps({
        "bus": os.environ.get("DBUS_SESSION_BUS_ADDRESS", ""),
        "runtime": os.environ.get("XDG_RUNTIME_DIR", ""),
    }))

    print(f"Candidate GNOME Shell: {manifest['shellVersion']} ({manifest['shell']})")
    print(f"Candidate extensions: {manifest['extensionDirectory']}")
    for extension in manifest["extensions"]:
        print(f"  {extension['uuid']} v{extension['version']}: {extension['path']}")
    print(f"Disposable workspace: {root}")
    print(f"Outer Wayland socket (viewer only): {wayland}")
    print(f"Preview size: {args.size}\nCandidate dconf profile:\n{profile}")

    print(f"System-bus policy: deny host services; rules={manifest['systemBusRules']}")
    if args.dry_run:
        print("Private environment:\n" + json.dumps(environment, indent=2, sort_keys=True))
        print("Private D-Bus configuration:\n" + bus_config.read_text())
        print("Dry run: no Shell, bus, or PipeWire process started.")
        return 0

    upstream = os.environ.get("DBUS_SYSTEM_BUS_ADDRESS", "unix:path=/run/dbus/system_bus_socket")
    proxy_socket = root / "runtime" / "system-bus"
    proxy = subprocess.Popen([
        manifest["systemBusProxy"], upstream, str(proxy_socket), "--filter", "--log",
        *manifest["systemBusRules"],
    ], env=environment, cwd=root)
    deadline = time.monotonic() + 5
    while not proxy_socket.exists():
        if proxy.poll() is not None or time.monotonic() > deadline:
            raise RuntimeError("The filtered system-bus proxy did not start.")
        time.sleep(0.05)

    command = [
        manifest["dbusRunSession"], f"--config-file={bus_config}", "--",
        sys.executable, str(Path(__file__).resolve()), str(manifest_path),
        "--inside-session", str(root), "--size", args.size,
    ]
    sys.stdout.flush()
    process = subprocess.Popen(command, env=environment, cwd=root, start_new_session=True)
    return process.wait()


def main():
    parser = argparse.ArgumentParser(prog="gnome-preview", description=__doc__)
    parser.add_argument("manifest", type=Path, help=argparse.SUPPRESS)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--size", type=window_size, default="1280x800")
    parser.add_argument("--inside-session", type=Path, help=argparse.SUPPRESS)
    args = parser.parse_args()
    manifest = json.loads(args.manifest.read_text())
    os.umask(0o077)
    signal.signal(signal.SIGTERM, interrupt)

    try:
        if args.inside_session is not None:
            return run_inside_session(args.inside_session, manifest, args.size)
        wayland = outer_wayland_socket()
        supervisor = ChildSupervisor()
        root = Path(tempfile.mkdtemp(prefix="gnome-preview-", dir="/tmp"))
        try:
            return run_preview(root, args.manifest, manifest, args, wayland)
        finally:
            supervisor.cleanup()
            shutil.rmtree(root)
    except KeyboardInterrupt:
        if args.inside_session is not None:
            print("\nPrivate GNOME session stopped.", file=sys.stderr)
        else:
            print("\nGNOME preview stopped; disposable state removed.", file=sys.stderr)
        return 130
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        print(f"gnome-preview: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
