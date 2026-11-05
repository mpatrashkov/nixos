#!/usr/bin/env python3
"""Exercise the configured JJ launcher and full Neovim in disposable repositories.

Run: python3 scripts/tests/jj-review.py
Optionally put a compatible Zig/ZLS toolchain on PATH for native LSP checks.
Requires the repository's nvim and jujutsu Stow packages to be linked.
"""
import hashlib
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile

REPO = Path(__file__).resolve().parents[2]


def run(args, cwd, env=None):
    return subprocess.run(args, cwd=cwd, env=env, check=True, text=True, capture_output=True).stdout.strip()


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else None


def main():
    with tempfile.TemporaryDirectory(prefix="jj review ' regression ") as temporary:
        base = Path(temporary)
        root = base / "project"
        root.mkdir()
        run(["jj", "git", "init", "--colocate"], root)
        source = root / "src/main.zig"
        source.parent.mkdir()
        source.write_text("pub fn value() u32 { return 1; }\npub fn main() void { _ = value(); }\n")
        (root / "deleted.txt").write_text("deleted passage\n")
        (root / "old-name.txt").write_text("rename passage\n")
        run(["jj", "describe", "-m", "base"], root)
        run(["jj", "new", "-m", "selected"], root)
        source.write_text(source.read_text().replace("return 1", "return 2"))
        (root / "deleted.txt").unlink()
        (root / "old-name.txt").rename(root / "renamed.txt")
        (root / "added ' λ.txt").write_text("added passage\n")
        (root / "crlf.txt").write_bytes(b"\xef\xbb\xbfCRLF passage\r\n")
        (root / "binary.bin").write_bytes(b"binary\x00content")
        selected = run(["jj", "log", "--no-graph", "-r", "@", "-T", "commit_id"], root)

        shim = base / "bin"
        shim.mkdir()
        nvim = shutil.which("nvim")
        (shim / "nvim").write_text(
            "#!/bin/sh\nexec " + shlex.quote(nvim) + ' --headless "$@" -c '
            + shlex.quote("luafile " + str(REPO / "scripts/tests/jj-review.lua")) + "\n"
        )
        (shim / "nvim").chmod(0o755)
        env = os.environ.copy()
        env["PATH"] = str(shim) + os.pathsep + env["PATH"]
        # Keep test annotations and locks out of the user's persistent state.
        env["XDG_STATE_HOME"] = str(base / "state")
        index = root / ".git/index"
        original_source = digest(source)

        for mode in ("live", "historical", "legacy"):
            if mode == "historical":
                run(["jj", "new", "-m", "later working copy"], root)
            original_index = digest(index)
            result = base / (mode + ".result")
            env["JJ_REVIEW_TEST_RESULT"] = str(result)
            if mode == "live":
                command = "jj review"
            elif mode == "legacy":
                command = "jj review-legacy -r " + selected
            else:
                command = "jj review -r " + selected
            # script supplies the controlling terminal required by JJ's TUI tool.
            process = subprocess.run(
                ["script", "-q", "-e", "-c", command, "/dev/null"],
                cwd=source.parent, env=env, capture_output=True, timeout=60,
            )
            report = result.read_text() if result.exists() else process.stdout.decode(errors="replace")
            assert process.returncode == 0 and report.strip() == "PASS " + mode, report
            assert digest(source) == original_source, "Review modified working file on disk"
            assert digest(index) == original_index, "Review modified Git index"
            print(report.strip())

        failure = subprocess.run(["jj", "review", "-r", "root()"], cwd=root, env=env, capture_output=True)
        assert failure.returncode != 0 and b"legacy" in failure.stderr
        print("PASS unsupported revision rejection")

        parent = run(["jj", "log", "--no-graph", "-r", selected + "-", "-T", "commit_id"], root)
        run(["jj", "new", parent, "-m", "sibling"], root)
        (root / "sibling.txt").write_text("independent branch\n")
        sibling = run(["jj", "log", "--no-graph", "-r", "@", "-T", "commit_id"], root)
        run(["jj", "new", selected, sibling, "-m", "merge"], root)
        failure = subprocess.run(["jj", "review"], cwd=root, env=env, capture_output=True)
        assert failure.returncode != 0 and b"merge" in failure.stderr, failure.stderr
        print("PASS merge rejection (no first-parent substitution)")

        failure = subprocess.run(["jj", "review", "-r", "all()"], cwd=root, env=env, capture_output=True)
        assert failure.returncode != 0 and b"exactly one" in failure.stderr
        print("PASS ambiguous revision rejection")


if __name__ == "__main__":
    main()
