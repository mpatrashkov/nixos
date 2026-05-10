---
name: capture-gnome-settings
description: Captures live GNOME dconf changes via `dconf watch` and writes them into `nixos-modules/services/gnome/default.nix`, then triggers the NixOS Action workflow. Bypasses Planning Mode — this skill is the workflow.
---

# Skill: Capture GNOME Settings

This skill records GNOME settings the user changes through the GNOME UI and converts them into the existing `programs.dconf.profiles.user.databases` block in `nixos-modules/services/gnome/default.nix`.

## Constants

- **Target file:** `/home/miro/flake/nixos-modules/services/gnome/default.nix`
- **Watch log:** `/home/miro/flake/.sync-gnome.log` (must be gitignored)
- **Path scope:** only keys under `/org/gnome/` are captured — silently drop everything else.

## Workflow

When the user invokes `/capture-gnome-settings`, follow these steps in order. Do NOT invoke Planning Mode — this skill replaces it.

### 1. Prepare the log and gitignore

- Ensure `.sync-gnome.log` is listed in `/home/miro/flake/.gitignore`. If not, append it.
- Truncate the log: `: > /home/miro/flake/.sync-gnome.log`

### 2. Run the watcher in the foreground

Run this Bash command in the foreground (NOT `run_in_background`) so the user can Ctrl-C when finished:

```
dconf watch / | tee /home/miro/flake/.sync-gnome.log
```

Tell the user, in one sentence, to go change GNOME settings and press Ctrl-C in the terminal when done. The Bash tool will return when the user interrupts.

### 3. Parse the log

`dconf watch` output format is:

```
/org/gnome/path/to/key
  <gvariant-value>

/org/gnome/another/path
  <gvariant-value>
```

Each entry is a path line followed by an indented value line followed by a blank line. A **reset** has an empty value line (the key was unset).

Parse the log into a list of `(path, key, value-or-RESET)` tuples:

- Split the path: everything up to the last `/` is the **dconf path** (becomes the Nix attrset name as `"org/gnome/.../..."`); the final segment is the **key** (becomes the inner attribute name, kept verbatim — keys with hyphens stay quoted-free since Nix accepts hyphens in attr names without quoting only when they don't start with a digit; quote with `"key-name"` to be safe when in doubt — but the existing file uses bare hyphenated names like `dock-position`, so match that style).
- Drop any entry whose path does not start with `/org/gnome/`.
- Apply **last-write-wins**: if the same `(path, key)` appears multiple times, keep only the final occurrence.
- Split results into two lists:
  - **changes** — entries with a value
  - **resets** — entries with an empty value line

### 4. Confirm resets explicitly

If `resets` is non-empty, list them to the user (path + key) and ask via the user interaction tool (`header: "Confirm Reset"`) which to remove from `gnome.nix`. Use a multi-select-style prompt or, if the option count is large, ask once "Remove all listed resets?" with Yes / No / Pick individually. Only the confirmed resets get deleted from the Nix file. Unconfirmed resets are dropped silently.

### 5. Convert GVariant values to `lib.gvariant.mk*` calls

Use the conversion table in the **GVariant Conversion Reference** section below. If you encounter a textual form not covered there, **STOP** and ask the user via the user interaction tool (`header: "Unknown GVariant"`) — show the raw value and ask how to encode it. Do not guess.

### 6. Edit `gnome.nix`

Open the target file and locate the `programs.dconf.profiles.user.databases` block, specifically the `settings = { ... };` attrset inside it.

For each parsed change:

- The outer attribute name is the dconf path with leading `/` stripped (e.g. `"org/gnome/shell/extensions/dash-to-dock"`).
- If that outer attribute already exists, merge the new key into its inner attrset.
- If it does not exist, create a new outer attribute.

For each confirmed reset: remove the matching inner key. If removing the last key from an outer attrset, remove the whole outer attribute too.

**Ordering:** outer attributes are grouped by subsystem (the segment after `org/gnome/` — e.g. `desktop`, `mutter`, `shell`, `settings-daemon`) and sorted alphabetically by subsystem, then alphabetically by full path within each subsystem. Inner keys are sorted alphabetically. Re-sort the entire `settings` attrset after edits so ordering stays consistent — do NOT preserve hand-ordering.

**Preserve** any existing comments inside the `settings` block (like the `# TODO: not sure about this one` line) by attaching them to the key they precede; if that key is removed by a reset, ask the user (`header: "Comment Drop"`) before discarding the comment.

Do NOT touch the `programs.dconf.profiles.gdm.databases` block or anything else in the file.

### 7. Show the diff

After editing, run `git diff --no-color nixos-modules/services/gnome/default.nix` and show it to the user.

### 8. Trigger NixOS Action workflow

Ask the user via the user interaction tool (`header: "NixOS Action"`) to choose:

- **Apply (switch)** — prompt for commit message (`header: "Git Commit"`), then run `./scripts/nix-switch "<msg>"` with no output redirection.
- **Verify (test)** — run `./scripts/nix-test` with no output redirection.
- **Do nothing**

Both scripts run autonomously via Bash. Stream raw output back.

---

## GVariant Conversion Reference

`dconf watch` prints values in GVariant textual form. The mapping to `lib.gvariant.mk*` (always written as `lib.gvariant.mkX ARG`):

| dconf textual form | Nix expression |
|---|---|
| `'foo'` or `"foo"` | `lib.gvariant.mkString "foo"` |
| `true` / `false` | `lib.gvariant.mkBoolean true` / `false` |
| `42` (bare integer) | `lib.gvariant.mkInt32 42` (default int) |
| `int16 42` | `lib.gvariant.mkInt16 42` |
| `int64 42` | `lib.gvariant.mkInt64 42` |
| `byte 0x2a` or `byte 42` | `lib.gvariant.mkUchar 42` |
| `uint16 42` | `lib.gvariant.mkUint16 42` |
| `uint32 42` | `lib.gvariant.mkUint32 42` |
| `uint64 42` | `lib.gvariant.mkUint64 42` |
| `3.14` | `lib.gvariant.mkDouble 3.14` |
| `objectpath '/some/path'` | `lib.gvariant.mkObjectpath "/some/path"` |
| `['a','b']` | `lib.gvariant.mkArray [ "a" "b" ]` (elements converted recursively) |
| `@as []` | `lib.gvariant.mkEmptyArray (lib.gvariant.type.string)` — match the type tag in `@..` (`as` → string, `ai` → int32, `au` → uint32, `ab` → boolean, `ad` → double, `ay` → uchar, `ao` → objectpath, etc.) |
| `('a', 'b')` | `lib.gvariant.mkTuple [ "a" "b" ]` (elements converted recursively) |
| `(uint32 1, 'foo')` | `lib.gvariant.mkTuple [ (lib.gvariant.mkUint32 1) "foo" ]` |
| `nothing` (typed maybe, empty) | `lib.gvariant.mkNothing lib.gvariant.type.string` (substitute correct element type) |
| `just 'foo'` or `@ms 'foo'` | `lib.gvariant.mkJust "foo"` |
| `<'foo'>` (variant wrapper) | `lib.gvariant.mkVariant "foo"` |
| `{'k': 'v'}` (dict) | `lib.gvariant.mkArray [ (lib.gvariant.mkDictionaryEntry [ "k" "v" ]) ]` |

**Type-tag table for `lib.gvariant.type.*`:**

| GVariant tag | Nix |
|---|---|
| `s` (string) | `lib.gvariant.type.string` |
| `b` (boolean) | `lib.gvariant.type.boolean` |
| `n` (int16) | `lib.gvariant.type.int16` |
| `i` (int32) | `lib.gvariant.type.int32` |
| `x` (int64) | `lib.gvariant.type.int64` |
| `q` (uint16) | `lib.gvariant.type.uint16` |
| `u` (uint32) | `lib.gvariant.type.uint32` |
| `t` (uint64) | `lib.gvariant.type.uint64` |
| `d` (double) | `lib.gvariant.type.double` |
| `y` (uchar/byte) | `lib.gvariant.type.uchar` |
| `o` (objectpath) | `lib.gvariant.type.objectpath` |
| `a<X>` (array of X) | `lib.gvariant.type.arrayOf <X>` |
| `m<X>` (maybe X) | (use `mkMaybe` / `mkJust` / `mkNothing`) |

**Inference rules when no explicit prefix is present:**

- A bare integer with no `int16`/`uint32`/etc. prefix → `mkInt32`. `dconf` only emits an explicit prefix when the schema declares a non-default type, so trust it: if the prefix is there, use it; if not, it's `int32` (or `boolean` / `string` / `double` / array — those are unambiguous).
- An array's element type is whatever the elements parse as (e.g. all bare strings → array of strings).
- For `mkEmptyArray`, the type tag in `@as` / `@ai` / etc. tells you which `lib.gvariant.type.*` to pass.

**Anything outside this table → stop and ask the user.** Do NOT silently fall back to `mkString`.

---

## Style Conventions (match the existing file)

- Two-space indentation.
- Outer attribute names are quoted: `"org/gnome/shell" = { ... };`.
- Inner attribute names are bare when they're valid Nix identifiers with hyphens (e.g. `dock-position`, `switch-windows`); quote them only if they contain characters Nix won't accept bare.
- Each inner attribute on its own line, terminated with `;`.
- Tuples inside arrays use the multi-line form when they contain multiple elements (see the `org/gnome/desktop/input-sources` block as the reference).
