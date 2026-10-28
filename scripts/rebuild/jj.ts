import { $ } from "zx";
import type { Backend, Mode } from "./snapshot.ts";

async function revision(revset: string): Promise<string> {
  const result =
    await $`jj --ignore-working-copy log --no-graph -r ${revset} -T commit_id`.quiet();
  return result.stdout.trim();
}

async function publishingSettings() {
  const bookmark = (
    await $`jj config get nixos.publish-bookmark`.quiet()
  ).stdout.trim();
  const remote = (
    await $`jj config get nixos.publish-remote`.quiet()
  ).stdout.trim();
  if (
    !/^[A-Za-z0-9._/-]+$/.test(bookmark) ||
    !/^[A-Za-z0-9._-]+$/.test(remote)
  ) {
    throw new Error(
      "Publishing bookmark and remote must be simple, explicit names.",
    );
  }

  await revision(bookmark);
  await revision(`${bookmark}@${remote}`);
  await $`git remote get-url ${remote}`.quiet();
  return { bookmark, remote };
}

export async function jjBackend(mode: Mode): Promise<Backend> {
  const publication =
    mode === "switch" ? await publishingSettings() : undefined;

  return {
    name: "jj",

    async capture(description) {
      await $`jj status`;
      if (await revision("@ & conflicts()")) {
        throw new Error("Resolve JJ conflicts before rebuilding.");
      }
      if (publication) {
        if (await revision("@ & empty()")) {
          throw new Error(
            "@ is empty; select the intended change before switching.",
          );
        }
        const { bookmark, remote } = publication;
        if (
          await revision(`(${bookmark} | ${bookmark}@${remote}) ~ ancestors(@)`)
        ) {
          throw new Error(
            "Local or remote publishing bookmark is not an ancestor of @; review history first.",
          );
        }
        await $`pre-commit run --all-files`;
        await $`jj describe -m ${description}`;
      }

      const commit = await revision("@");
      const subject =
        await $`jj --ignore-working-copy log --no-graph -r ${commit} -T ${"description.first_line()"}`.quiet();
      return { revision: commit, description: subject.stdout.trim() };
    },

    async publish(commit) {
      if (!publication) {
        throw new Error("Publishing is only supported for switch.");
      }
      const { bookmark, remote } = publication;
      await $`jj --ignore-working-copy bookmark set -r ${commit} -- ${bookmark}`;
      await $`jj --ignore-working-copy git push --remote ${remote} --bookmark ${`exact:${bookmark}`}`;
      // The subsequent build still uses commit, not this new empty child.
      await $`jj new ${commit}`;
    },
  };
}
