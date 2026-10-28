#!/usr/bin/env zx

import { existsSync } from "node:fs";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { $, cd } from "zx";
import { gitBackend } from "./rebuild/git.ts";
import { jjBackend } from "./rebuild/jj.ts";
import { exportSnapshot } from "./rebuild/snapshot.ts";
import type { Mode } from "./rebuild/snapshot.ts";

function options(args: string[]): {
  mode: Mode;
  update: boolean;
  description: string;
} {
  const [mode, update, ...messages] = args;
  if (mode !== "test" && mode !== "switch") {
    throw new Error("Expected rebuild mode: test or switch.");
  }
  if (update !== "true" && update !== "false") {
    throw new Error("Expected input-update setting: true or false.");
  }
  if (mode === "switch" && (messages.length !== 1 || !messages[0].trim())) {
    throw new Error("usage: nix-[update-]switch <description>");
  }
  if (mode === "test" && messages.length !== 0) {
    throw new Error("usage: nix-[update-]test");
  }
  return { mode, update: update === "true", description: messages[0] ?? "" };
}

async function main() {
  // zx keeps [node, zx-cli, script, ...arguments] in process.argv.
  const { mode, update, description } = options(process.argv.slice(3));
  const root = fileURLToPath(new URL("../", import.meta.url));
  cd(root);
  $.verbose = true;

  const trackedMetadata =
    await $`git ls-files -- .nixos-generation.json`.quiet();
  if (trackedMetadata.stdout.trim()) {
    throw new Error(
      ".nixos-generation.json is reserved build metadata and must not be tracked.",
    );
  }
  const backend = existsSync(".jj") ? await jjBackend(mode) : gitBackend(mode);
  if (update) {
    // Resolve inputs before capturing source; never let nh -u change it later.
    await $`nix flake update --flake ${root}`;
  }

  const workDir = await mkdtemp(join(tmpdir(), "nixos-rebuild-"));
  try {
    const snapshot = await backend.capture(description, workDir);
    console.log(`Source: ${snapshot.revision} (${backend.name})`);
    const sourceDir = await exportSnapshot(mode, snapshot, workDir);
    if (mode === "switch") {
      await backend.publish(snapshot.revision);
    }
    // Stream output directly, with an explicit host and frozen lockfile.
    await $`sudo nh os ${mode} --bypass-root-check --hostname nixos ${`path:${sourceDir}`} -- --no-update-lock-file`;
  } finally {
    await rm(workDir, { recursive: true, force: true });
  }
}

try {
  await main();
} catch (error) {
  console.error(
    "Rebuild stopped:",
    error instanceof Error ? error.message : error,
  );
  process.exitCode = 1;
}
