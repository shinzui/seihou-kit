---
name: seihou-prune-orphan-modules
description: Diagnose and clear stale orphan module records from a project's .seihou/manifest.json that pollute `seihou status` — phantom applied modules and spurious "Pending migration" lines left by modules that own no files, no checkout links, and no seeds. Use on old repos that show modules you no longer recognize, pending migrations that neither `seihou update` nor `seihou migrate` can resolve, or leftovers from superseded modules.
allowed-tools: AskUserQuestion, Read, Write, Edit, Glob, Bash
---

# Seihou Prune Orphan Modules

Old Seihou projects accumulate **orphan module records**: entries in the manifest's
top-level `modules[]` array that are no longer backed by anything on disk or by any
application. They typically come from early applications of an infrastructure module
(e.g. a skill-link module) that was later superseded, re-applied under a different
owner, or whose linking responsibility moved to another module.

These records own nothing, but they still appear in `seihou status`, and if the module's
source version is bumped they surface as a **"Pending migration: X -> Y"** line that:

- `seihou update` ignores ("Already up to date", because it resolves the recorded remote
  origin, not your local edit), and
- `seihou migrate` refuses ("no version recorded in the manifest"), and
- `seihou remove` refuses ("has no removal spec").

There is no CLI command that cleanly retires a no-version orphan, so this skill verifies
the record truly owns nothing and then surgically removes it from `modules[]`, with a
backup. It must **never** touch a module that owns files, checkout links, or seeds, or
that is a live application instance — those are resolved with the CLI, not by hand.

## When to Use

Activate when the user says things like:

- "`seihou status` shows a module I don't recognize / don't use anymore"
- "There's a pending migration I can't get rid of"
- "`seihou update` says up to date but status still shows a migration"
- "This old repo has phantom / leftover / stale modules in its manifest"
- "Clean up the manifest" / "stop polluting my status"
- "Many old repos have this problem — fix them the same way"
- "/seihou-prune-orphan-modules"

## Key Concepts

### The manifest shape (schema 10)

`.seihou/manifest.json` is a single-line JSON document. The fields that matter here:

| Field                | Meaning                                                               |
|----------------------|-----------------------------------------------------------------------|
| `version`            | Manifest **schema** version (e.g. `10`) — never change it.            |
| `applications[]`     | Each has an `applicationId`, a `target`, and an `instances[]` list.   |
| `modules[]`          | Flat list of applied-module records (`name`, maybe `version`, `parentVars`, `origin`, `appliedAt`). This is where orphans live. |
| `files{}`            | Map of generated file path → `{ module, applications, baseline, hash, … }`. `module` is the owner. |
| `checkoutOutputs{}`  | Map of link path → `{ owners: { <applicationId>: [<module>…] }, spec }`. |
| `seeds{}`            | Seed ownership records.                                               |

### What makes a record an *orphan* (safe to hand-remove)

A `modules[]` entry for module `M` is an orphan **only if ALL of these hold**:

1. **Owns no files** — no entry in `files{}` has `module == M`.
2. **Owns no checkout links** — no entry in `checkoutOutputs{}` lists `M` in any
   `owners[*]` array.
3. **Owns no seeds** — no entry in `seeds{}` is owned by `M`.
4. **Is not a live application instance** — `M` does not appear in any
   `applications[*].instances[*].name`.

If any one of these fails, the record is **not** an orphan. Stop and route it to the CLI
(see Phase 4). Removing a non-orphan by hand would corrupt ownership and can orphan or
delete real files/links.

### Why not just use the CLI

- `seihou update` resolves the recorded **remote** origin, so it won't act on a stale
  record whose remote version is unchanged.
- `seihou migrate` requires a recorded version on the instance.
- `seihou remove` requires a removal spec and treats the instance as owning managed
  effects.

None of these retire a nothing-owning, possibly version-less record. Surgical removal of
exactly that record is the correct fix, and it is safe precisely because the record owns
nothing.

## Workflow Overview

1. **Locate the project** — find `.seihou/manifest.json`.
2. **Read status** — run `seihou status`; note phantom modules and pending migrations.
3. **Classify** — for each suspect module, prove orphan-vs-live from the manifest.
4. **Decide per module** — orphan → prune; live-but-outdated → CLI; keep otherwise.
5. **Confirm** — show the user exactly which records will be dropped.
6. **Prune safely** — back up, remove only orphan `modules[]` entries, reparse.
7. **Verify** — re-run `seihou status`; confirm it is clean.
8. **Summarize** — report, including the `repair-origins` hint if relevant.

## Instructions for Claude

### Phase 1: Locate the Project

If the user gave a path, use it. Otherwise assume the current directory. Resolve
`PROJECT_ROOT` as the nearest ancestor containing `.seihou/manifest.json`.

```bash
ls .seihou/manifest.json
```

If none exists, tell the user this directory is not a Seihou-managed project and stop.

For a batch request ("fix all my old repos"), ask for the list or a parent directory to
scan, and process each project through Phases 2–7 independently. Never assume a fix in
one repo transfers to another — classify each manifest on its own.

### Phase 2: Read Status

```bash
seihou status
```

Record:

- **Applied modules** and any **"Pending migration"** lines.
- Any **"Artifacts that differ…"** / `repair-origins` warning (handled in Phase 8).

The candidates to investigate are modules that the user does not recognize, modules
showing a pending migration that the CLI won't resolve, and modules the user named
explicitly.

### Phase 3: Classify Each Candidate

Run this analyzer. It reports, per `modules[]` record, whether it is an orphan under the
four-part test, with the evidence. **Read, do not modify, in this phase.**

```bash
python3 - "$PROJECT_ROOT/.seihou/manifest.json" <<'PY'
import json, sys
m = json.load(open(sys.argv[1]))
print("manifest schema version:", m.get("version"))

file_owners = {}
for meta in m.get("files", {}).values():
    file_owners[meta.get("module")] = file_owners.get(meta.get("module"), 0) + 1

link_owners = {}
for spec in m.get("checkoutOutputs", {}).values():
    for owners in spec.get("owners", {}).values():
        for mod in owners:
            link_owners[mod] = link_owners.get(mod, 0) + 1

seed_owners = {}
for spec in m.get("seeds", {}).values():
    # seeds schema stores owning instances; count any mention per module name
    for v in json.dumps(spec).split('"'):
        pass
seed_blob = json.dumps(m.get("seeds", {}))

instance_names = set()
for app in m.get("applications", []):
    for inst in app.get("instances", []):
        instance_names.add(inst.get("name"))

print("\n--- modules[] records ---")
for rec in m.get("modules", []):
    name = rec.get("name")
    owns_files = file_owners.get(name, 0)
    owns_links = link_owners.get(name, 0)
    owns_seed  = (('"%s"' % name) in seed_blob)
    is_instance = name in instance_names
    orphan = (owns_files == 0 and owns_links == 0 and not owns_seed and not is_instance)
    print(f"  {name!r} version={rec.get('version')} appliedAt={rec.get('appliedAt')}")
    print(f"      files={owns_files} links={owns_links} seed={owns_seed} app-instance={is_instance}  => {'ORPHAN (prunable)' if orphan else 'LIVE (use CLI)'}")
PY
```

Trust the analyzer's verdict:

- **ORPHAN (prunable)** — candidate for Phase 6.
- **LIVE (use CLI)** — go to Phase 4; do not hand-edit.

### Phase 4: Live-but-Outdated Modules (CLI, not surgery)

For a record flagged **LIVE** that the user wants updated or removed:

- **Outdated, newer version published** → `seihou update` (or `seihou update --dry-run`
  first). If the newer version is only a local edit that is not committed/pushed, the
  recorded remote won't have it; tell the user to publish it first, or point `update` at
  the right origin.
- **Deliberate layout migration** → `seihou migrate <module> --dry-run` then
  `seihou migrate <module>`.
- **Intentional removal of a module that owns files/links** → `seihou remove <module>
  --dry-run`; it needs a removal spec in the module's `module.dhall`.

Do not remove a LIVE record from the manifest by hand. Explain why (it owns real
files/links) and stop that record here.

### Phase 5: Confirm the Prune Set

List the exact orphan records to drop and ask once:

```
Question: "Drop these orphan records from .seihou/manifest.json? They own no files, links, or seeds."
Header: "Prune"
Options:
- Yes, drop them (a backup is written first) (Recommended)
- Show me each record's JSON first
- No, leave the manifest unchanged
```

If the user wants to see them, print the full JSON of each orphan record before asking
again.

### Phase 6: Prune Safely

Only orphan records confirmed in Phase 5. The script backs up, removes **only** the named
orphan records (matched by `name`, and by `appliedAt` when disambiguating duplicates),
preserves the compact one-line JSON format and the schema `version`, and reparses to
prove validity.

```bash
BACKUP="$PROJECT_ROOT/.seihou/manifest.json.bak.$(date +%Y%m%d%H%M%S)"
cp "$PROJECT_ROOT/.seihou/manifest.json" "$BACKUP"
echo "backup: $BACKUP"

# ORPHANS: the module name(s) confirmed in Phase 5.
python3 - "$PROJECT_ROOT/.seihou/manifest.json" "claude-skill-link" <<'PY'
import json, sys
path = sys.argv[1]
orphans = set(sys.argv[2:])
m = json.load(open(path))
before = len(m.get("modules", []))
# Safety: refuse to drop a name that owns anything or is an app instance.
file_owners = {meta.get("module") for meta in m.get("files", {}).values()}
link_owners = set()
for spec in m.get("checkoutOutputs", {}).values():
    for owners in spec.get("owners", {}).values():
        link_owners.update(owners)
seed_blob = json.dumps(m.get("seeds", {}))
instance_names = {i.get("name") for a in m.get("applications", []) for i in a.get("instances", [])}
for name in list(orphans):
    if name in file_owners or name in link_owners or ('"%s"' % name) in seed_blob or name in instance_names:
        sys.exit(f"REFUSING: {name!r} owns files/links/seeds or is an app instance — not an orphan.")
m["modules"] = [r for r in m.get("modules", []) if r.get("name") not in orphans]
after = len(m["modules"])
json.dump(m, open(path, "w"), separators=(",", ":"), ensure_ascii=False)
json.load(open(path))  # reparse to validate
print(f"modules[] {before} -> {after}; schema version preserved: {m.get('version')}")
PY
```

Replace `"claude-skill-link"` with the actual confirmed orphan name(s), space-separated.
The embedded safety check re-verifies ownership and aborts if any name is not truly an
orphan, so a mistake cannot delete a live record. If it aborts, restore from the backup
and re-classify.

### Phase 7: Verify

```bash
seihou status
```

Confirm the pruned modules and their pending-migration lines are gone and nothing else
changed (same tracked files, same checkout outputs, same live applications).

### Phase 8: Summarize

```
## Manifest Pruned: <PROJECT_ROOT>

### Removed orphan records (owned nothing)
- <module> (appliedAt <date>, version <ver|none>)

### Left in place
- <module> — LIVE, owns <N files / N links>; use `seihou update`/`migrate`/`remove`

### Backup
- <BACKUP path>  (manifest is git-tracked: `git checkout .seihou/manifest.json` also reverts)

### Also noticed
- Origin recorded as a local path → run `seihou manifest repair-origins` (or `--dry-run`)

### Next Steps
1. Review `git diff .seihou/manifest.json`.
2. Commit: `git add .seihou/manifest.json && git commit -m "chore(seihou): prune orphan manifest records"`
```

Fill "Also noticed" only if `seihou status` showed the origin-mismatch warning.

## Important Notes

- **Four-part orphan test is mandatory.** Never prune a record that owns files, checkout
  links, or seeds, or that is an application instance. The Phase 6 script re-checks and
  aborts otherwise — do not weaken it.
- **Prefer the CLI.** `seihou update`, `migrate`, and `remove` are the correct tools for
  live modules. Hand-editing the manifest is only for nothing-owning orphans the CLI
  cannot retire.
- **Always back up first**, and tell the user the manifest is git-tracked so a revert is
  trivial.
- **Preserve the schema `version` and the compact JSON format.** Do not reformat the
  whole file or touch `version` (that is a job for `seihou manifest upgrade`).
- **Confirm before deleting.** Show the user the exact records.
- **A version bump on the module source can *cause* the "Pending migration" line** for an
  orphan (status compares the local source version to the recorded instance). That line
  is a symptom of the orphan, not a real migration — pruning the orphan clears it.
- **Batch repos independently.** Classify each project's manifest on its own; never carry
  a verdict from one repo to another.
- **Out of scope:** upgrading a module's `module.dhall`, repairing origins (hand off to
  `seihou manifest repair-origins`), and manifest schema upgrades (`seihou manifest
  upgrade`). Mention them; don't do them under this skill.
