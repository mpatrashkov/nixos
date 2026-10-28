import type { Mode, Snapshot } from "./snapshot.ts";

export function generationLabel(
  mode: Mode,
  snapshot: Snapshot,
  systemName: string,
): string {
  if (!/^(?:[0-9a-f]{40}|[0-9a-f]{64})$/.test(snapshot.revision)) {
    throw new Error("Expected a full hexadecimal Git commit ID.");
  }
  if (!/^[A-Za-z0-9._-]+$/.test(systemName)) {
    throw new Error(
      "System name must use ASCII letters, digits, '.', '_' or '-'.",
    );
  }

  // Nix's 211-byte store-name limit includes the hostname and .drv suffix.
  const namePrefix = `nixos-system-${systemName}-`;
  const limit = Math.min(80, 211 - 4 - namePrefix.length);
  const prefix = mode === "test" ? "test-" : "";
  const suffix = `-${snapshot.revision.slice(0, 12)}`;
  const descriptionBudget = limit - prefix.length - suffix.length;
  if (descriptionBudget < 1) {
    throw new Error(
      "System name leaves insufficient space for a generation label.",
    );
  }

  // Colons are allowed by the NixOS option but rejected by Nix store names.
  const subject = snapshot.description.split("\n", 1)[0];
  const sanitized = subject
    .replace(/[^A-Za-z0-9._-]+/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "");
  const description = (sanitized || "configuration")
    .slice(0, descriptionBudget)
    .replace(/-$/, "");

  return `${prefix}${description || "x"}${suffix}`;
}
