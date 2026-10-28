import { join } from "node:path";
import { $ } from "zx";
import type { Backend, Mode } from "./snapshot.ts";

export function gitBackend(mode: Mode): Backend {
  return {
    name: "git",

    async capture(description, workDir) {
      if (mode === "switch") {
        await $`git symbolic-ref --quiet HEAD`.quiet();
        await $`git add -A`;
        await $`git commit -m ${description}`;
        const revision = (await $`git rev-parse HEAD`.quiet()).stdout.trim();
        const subject = (
          await $`git show -s --format=%s ${revision}`.quiet()
        ).stdout.trim();
        return { revision, description: subject };
      }

      // A separate index includes new files without changing the real index/branch.
      const git = $({
        env: { ...process.env, GIT_INDEX_FILE: join(workDir, "index") },
      });
      await git`git read-tree HEAD`;
      await git`git add -A`;
      const tree = (await git`git write-tree`.quiet()).stdout.trim();
      const commit =
        await git`git commit-tree ${tree} -p HEAD -m ${"NixOS test snapshot"}`.quiet();
      return { revision: commit.stdout.trim(), description: "configuration" };
    },

    async publish(_revision) {
      await $`git push`;
    },
  };
}
