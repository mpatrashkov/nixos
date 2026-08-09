#!/usr/bin/env zx

import { $, glob, fs } from "zx";

interface PackageDef {
  file: string;
  owner: string;
  repo: string;
  rawRev: string; // as written in source, e.g. "v${version}" or "523dc9b7..."
  revType: "rev" | "tag";
  rawHash: string; // as written in source, e.g. "sha256-abc..."
  hashType: "hash" | "sha256";
  resolvedRev: string; // fully evaluated by nix, e.g. "v1.15.4"
}

interface UpdateDescriptor {
  owner: string;
  repo: string;
  file: string;
  currentRev: string; // resolved by nix eval
  latestRev: string; // latest available on GitHub
  currentHash: string; // raw hash string in the .nix file
  hashType: "hash" | "sha256";
  newHash: string; // calculated by nix-prefetch-github
}

/** Phase 1: regex scan — finds file paths and raw replacement strings */
async function scanNixFiles(): Promise<Omit<PackageDef, "resolvedRev">[]> {
  const files = await glob("nixos-modules/**/*.nix");
  const found: Omit<PackageDef, "resolvedRev">[] = [];

  for (const file of files) {
    const content = await fs.readFile(file, "utf8");
    if (!content.includes("fetchFromGitHub")) continue;

    const blockRegex = /fetchFromGitHub\s*\{[\s\S]*?\};/g;
    let m;
    while ((m = blockRegex.exec(content)) !== null) {
      const block = m[0];
      const owner = block.match(/owner\s*=\s*"([^"]+)"/)?.[1];
      const repo = block.match(/repo\s*=\s*"([^"]+)"/)?.[1];
      if (!owner || !repo) continue;

      const revM = block.match(/rev\s*=\s*"([^"]+)"/);
      const tagM = block.match(/tag\s*=\s*"([^"]+)"/);
      const hashM = block.match(/hash\s*=\s*"([^"]+)"/);
      const sha2M = block.match(/sha256\s*=\s*"([^"]+)"/);
      if ((!revM && !tagM) || (!hashM && !sha2M)) continue;

      found.push({
        file,
        owner,
        repo,
        rawRev: (revM ?? tagM)![1],
        revType: revM ? "rev" : "tag",
        rawHash: (hashM ?? sha2M)![1],
        hashType: hashM ? "hash" : "sha256",
      });
    }
  }

  return found;
}

/** Phase 2: nix eval — resolves actual rev/tag values (handles ${version} etc.) */
async function nixEvalPackages(): Promise<Map<string, string>> {
  const apply = `pkgs: map (p: {
    owner = (p.src or {}).owner or null;
    repo  = (p.src or {}).repo  or null;
    rev   = (p.src or {}).rev   or null;
    tag   = (p.src or {}).tag   or null;
  }) (builtins.filter (p: (p.src or {}).owner or null != null) pkgs)`;

  const { stdout } =
    await $`nix eval --json .#nixosConfigurations.nixos.config.environment.systemPackages --apply ${apply}`.quiet();

  const entries: Array<{
    owner: string;
    repo: string;
    rev: string | null;
    tag: string | null;
  }> = JSON.parse(stdout);
  const map = new Map<string, string>();
  for (const e of entries) {
    if (e.owner && e.repo) {
      // prefer tag; strip refs/tags/ prefix used by some nixpkgs fetchgit calls
      const raw = (e.tag ?? e.rev ?? "").replace(/^refs\/tags\//, "");
      map.set(`${e.owner}/${e.repo}`, raw);
    }
  }
  return map;
}

/** Merge both phases into a single list with resolved revs */
async function findGitHubPackages(): Promise<PackageDef[]> {
  const [scanned, resolved] = await Promise.all([
    scanNixFiles(),
    nixEvalPackages(),
  ]);
  return scanned.map((pkg) => ({
    ...pkg,
    resolvedRev: resolved.get(`${pkg.owner}/${pkg.repo}`) ?? pkg.rawRev,
  }));
}

async function getLatestReleaseOrCommit(
  owner: string,
  repo: string,
  currentRev: string,
): Promise<string | null> {
  const isCommitHash = /^[0-9a-f]{40}$/i.test(currentRev);

  if (isCommitHash) {
    let currentCommitDate = 0;
    try {
      const { stdout } =
        await $`gh api repos/${owner}/${repo}/commits/${currentRev}`.quiet();
      currentCommitDate = new Date(
        JSON.parse(stdout).commit.committer.date,
      ).getTime();
    } catch {}

    try {
      const { stdout } =
        await $`gh api repos/${owner}/${repo}/releases/latest`.quiet();
      const rel = JSON.parse(stdout);
      if (new Date(rel.published_at).getTime() > currentCommitDate)
        return rel.tag_name;
    } catch {}

    try {
      const { stdout: rs } = await $`gh api repos/${owner}/${repo}`.quiet();
      const branch = JSON.parse(rs).default_branch;
      const { stdout: bs } =
        await $`gh api repos/${owner}/${repo}/branches/${branch}`.quiet();
      return JSON.parse(bs).commit.sha;
    } catch {
      return null;
    }
  } else {
    try {
      const { stdout } =
        await $`gh api repos/${owner}/${repo}/releases/latest`.quiet();
      return JSON.parse(stdout).tag_name;
    } catch {}

    try {
      const { stdout } = await $`gh api repos/${owner}/${repo}/tags`.quiet();
      const tags = JSON.parse(stdout);
      if (tags.length > 0) return tags[0].name;
    } catch {}

    return null;
  }
}

async function main() {
  const packages = await findGitHubPackages();

  const results = await Promise.all(
    packages.map(async (pkg): Promise<UpdateDescriptor | null> => {
      const latest = await getLatestReleaseOrCommit(
        pkg.owner,
        pkg.repo,
        pkg.resolvedRev,
      );
      if (!latest || latest === pkg.resolvedRev) return null;

      console.error(
        `[${pkg.owner}/${pkg.repo}] ${pkg.resolvedRev} → ${latest}, fetching new hash...`,
      );
      const { stdout } =
        await $`nix-prefetch-github ${pkg.owner} ${pkg.repo} --rev ${latest}`.quiet();
      const newHash = JSON.parse(stdout).hash;

      return {
        owner: pkg.owner,
        repo: pkg.repo,
        file: pkg.file,
        currentRev: pkg.resolvedRev,
        latestRev: latest,
        currentHash: pkg.rawHash,
        hashType: pkg.hashType,
        newHash,
      };
    }),
  );

  const updates = results.filter((u): u is UpdateDescriptor => u !== null);

  console.log(JSON.stringify(updates, null, 2));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
