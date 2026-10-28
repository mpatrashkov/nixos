import { mkdir, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { $ } from "zx";
import { generationLabel } from "./label.ts";

export type Mode = "test" | "switch";

export interface Snapshot {
  revision: string;
  description: string;
}

export interface Backend {
  name: "git" | "jj";
  capture(description: string, workDir: string): Promise<Snapshot>;
  publish(revision: string): Promise<void>;
}

export async function exportSnapshot(
  mode: Mode,
  snapshot: Snapshot,
  workDir: string,
): Promise<string> {
  const sourceDir = join(workDir, "source");
  const archive = join(workDir, "source.tar");
  await mkdir(sourceDir);
  await $`git archive --format=tar --output ${archive} ${snapshot.revision}`;
  await $`tar -xf ${archive} -C ${sourceDir}`;

  const installable = `path:${sourceDir}#nixosConfigurations.nixos.config.system.name`;
  const systemName = (
    await $`nix eval --raw ${installable} --no-update-lock-file`.quiet()
  ).stdout.trim();
  const label = generationLabel(mode, snapshot, systemName);
  const metadata = JSON.stringify({ label, revision: snapshot.revision });
  await writeFile(join(sourceDir, ".nixos-generation.json"), `${metadata}\n`);
  console.log(`Generation label: ${label}`);

  return sourceDir;
}
