---
name: seihou-module-readme
description: Generate or refresh a human-readable README.md for a Seihou module, documenting its version, variables, prompts, dependencies, exports, generated files, and usage — so readers understand the module without reading module.dhall or the template code. Use when authoring or updating documentation for a module.
allowed-tools: AskUserQuestion, Read, Write, Edit, Glob, Bash
---

# Seihou Module README

This skill produces a `README.md` next to a module's `module.dhall`, synthesizing the
module's public interface into human-readable documentation. The goal is that a reader
can understand what the module does, what inputs it takes, what it produces, and how to
use it, **without** opening `module.dhall` or any file under `files/`.

It works by:

1. Locating the module directory (the one containing `module.dhall`).
2. Reading `module.dhall` to extract metadata (name, version, description, vars,
   prompts, steps, dependencies, exports, commands, removal).
3. Running `seihou vars <module>` and `seihou validate-module <path>` for a consistency
   check against the resolved module.
4. Rendering a structured README with fixed section ordering.
5. Writing or updating `README.md` in the module directory.

## When to Use

Activate when the user says things like:

- "Add a README to this module"
- "Document this seihou module"
- "Generate module docs"
- "Write a README for my module"
- "Refresh the module README"
- "Document the variables and dependencies for this module"
- "/seihou-module-readme"

## Key Concepts

### Module directory

A Seihou module lives in a directory containing:

- `module.dhall` — the module definition
- `files/` — template sources referenced by steps

The README this skill produces lives alongside `module.dhall` (same directory), not
inside `files/`. It documents the module itself, not the project it generates.

### Public interface vs. implementation

The README should describe the module's **public interface** — things that affect how a
user calls it and what they get back. That means:

- Module identity: `name`, `version`, `description`
- Inputs: `vars` (with type, default, required, description, validation), `prompts`
- Outputs: `steps` (as a list of generated paths, not the template contents), `exports`,
  `commands`, `removal` availability
- Composition: `dependencies` and any variable bindings they pass

Template bodies, Dhall-level plumbing (`S.Module::{...}`, schema imports), and internal
step details beyond destination and strategy stay out of the README.

### Authoritative sources

- `module.dhall` — the source of truth for everything documented
- `seihou vars <module>` — confirms variable names and defaults as Seihou resolves them
- `seihou validate-module <path>` — sanity check that the module loads cleanly before
  documenting it

## Workflow Overview

1. **Locate the module** — resolve the target module directory.
2. **Validate and read** — run `seihou validate-module`; read `module.dhall`.
3. **Extract metadata** — parse name, version, description, vars, prompts, steps,
   dependencies, exports, commands, removal.
4. **Cross-check variables** — run `seihou vars <module>` and reconcile.
5. **Decide on existing README** — preserve hand-written sections if present.
6. **Render README.md** — fill in the template in the fixed order below.
7. **Write the file and summarize** — report what was written and next steps.

## Instructions for Claude

### Phase 1: Locate the Module

If the user already named a module or pointed at a path in their request, use that. Do
not re-ask. Otherwise:

```
Question: "Which module should I document?"
Header: "Module"
Options:
- Current directory (contains module.dhall)
- Let me provide a path
- Pick from modules listed by `seihou list`
```

Resolve to an absolute path `MODULE_DIR` such that `MODULE_DIR/module.dhall` exists.

If the user only gave a module **name** (not a path), run:

```bash
seihou list
```

to find it, then ask the user to confirm the directory if ambiguous. Installed modules
under `.seihou/` are not a good documentation target — prefer the source repo where
`module.dhall` was authored.

Fail fast with a clear message if `MODULE_DIR/module.dhall` does not exist.

### Phase 2: Validate and Read

Run a validation check first — if the module is broken, the README may encode wrong
information:

```bash
seihou validate-module <MODULE_DIR>
```

If validation fails, surface the error to the user and stop. Do not proceed to write
documentation for a broken module.

Then read `module.dhall`:

```bash
# via Read tool
<MODULE_DIR>/module.dhall
```

### Phase 3: Extract Metadata

From `module.dhall`, extract the following. Leave a field out of the README entirely if
the module does not define it (rather than writing "N/A" placeholders).

| Field          | Dhall location                             | README section       |
|----------------|--------------------------------------------|----------------------|
| `name`         | top-level `name`                           | Title                |
| `version`      | top-level `version` (`Optional Text`)      | Version line         |
| `description`  | top-level `description` (`Optional Text`)  | Lead paragraph       |
| `vars`         | top-level `vars`                           | Variables table      |
| `prompts`      | top-level `prompts`                        | Prompts section      |
| `steps`        | top-level `steps`                          | Generated Files      |
| `dependencies` | top-level `dependencies`                   | Dependencies section |
| `exports`      | top-level `exports`                        | Exports section      |
| `commands`     | top-level `commands`                       | Commands section     |
| `removal`      | top-level `removal` (`Optional Removal.Type`) | Removal section   |

Notes on extraction:

- Variable defaults are `Optional Text`. Render `Some "foo"` as `foo`, and `None Text`
  as an em dash (`—`) in the Default column.
- `required = True/False` becomes a yes/no column.
- `validation = Some "<regex>"` becomes a Validation column (code-fenced regex).
- For `steps`, document `dest`, `strategy`, `when` (if set), and `patch` (if set). Do
  not document `src` paths or any template content — those are implementation.
- For `dependencies`, list the `module` name and any `vars` bindings (each as
  `name = value`).
- For `exports`, list the `var` name and `alias` if present.

### Phase 4: Cross-Check Variables

Run:

```bash
seihou vars <module-name>
```

Compare the variable names reported against those in `module.dhall`. If the module is
not discoverable by name (e.g., not installed or not on a search path), skip this step
and note it in the commit/summary — `module.dhall` alone is still sufficient.

### Phase 5: Decide on Existing README

If `MODULE_DIR/README.md` already exists:

```
Question: "A README already exists. How should I update it?"
Header: "README"
Options:
- Regenerate fully (overwrite) (Recommended)
- Preserve hand-written sections between <!-- keep:begin --> and <!-- keep:end --> markers
- Show me a diff first, don't write yet
```

If the user picks the preserve option, any block wrapped in
`<!-- keep:begin name="..." -->` / `<!-- keep:end -->` markers in the existing README
should be re-inserted verbatim at the bottom under a `## Notes` heading (or at the
location matching `name=` if the new README has a section with that id).

### Phase 6: Render README.md

Use this **exact** top-level structure. Omit any section whose source field is absent in
`module.dhall`. Keep prose terse — readers came here for a reference, not a tutorial.

```markdown
# <name>

> <description — one or two sentences>

**Version:** `<version>`

## Overview

<1–3 sentences expanding on the description: what this module produces, and who it is
for. Derive from description + steps + dependencies. If the description already says
this, drop the section.>

## Variables

| Name | Type | Default | Required | Validation | Description |
|------|------|---------|----------|------------|-------------|
| `mp.skill.name` | `text` | `master-plan` | yes | `[a-z][a-z0-9-]*` | Name of the skill directory |
| ... | ... | ... | ... | ... | ... |

## Prompts

The following values are asked interactively (unless supplied via `--var`):

- **`<var>`** — <prompt text>
  - Shown when: `<when expression>` *(if set)*
  - Choices: `opt1`, `opt2` *(if set)*

## Dependencies

This module pulls in:

- **`<dep-module>`**
  - Variable bindings:
    - `<name>` = `<value>`
  *(omit "Variable bindings" subsection if `vars` is empty)*

## Exports

Variables this module exposes to parent modules:

- `<var>` *(aliased as `<alias>` if set)*

## Generated Files

When run, this module writes:

- `<dest>` — strategy: `<strategy>`
  - Applied when: `<when expression>` *(if set)*
  - Patch mode: `<patch>` *(if set)*

`dest` may contain `{{var}}` placeholders; they are resolved at run time.

## Commands

After file generation, this module runs:

- `<run>` *(in `<workDir>` if set; when `<when>` if set)*

## Removal

<If `removal` is `Some`:>
This module supports removal via:

```bash
seihou remove <name>
```

Removal steps:

- `<action>` on `<path>` *(with content summary if relevant)*

<If `removal` is `None`:>
This module is **not removable** — `seihou remove <name>` will refuse. File additions
made by this module will have to be reverted manually.

## Usage

Apply the module:

```bash
seihou run <name>
```

With variable overrides:

```bash
seihou run <name> --var <var>=<value>
```

Preview without writing files:

```bash
seihou run <name> --dry-run
```

## See Also

- `module.dhall` — full module definition and authoritative source
- `files/` — template sources
```

Rendering rules:

- Wrap every variable name, module name, default value, regex, dest path, and command in
  backticks.
- Leave tables compact — one row per entry.
- For `when` expressions, quote them verbatim (e.g. `Eq intentions.enabled true`).
- Do not invent prose beyond what the module declares. If a `description` field is
  missing from a variable, render the Description column as an em dash `—`.
- If a list-valued field (`vars`, `prompts`, `steps`, `dependencies`, `exports`,
  `commands`) is empty, omit its entire section — do not print "None".

### Phase 7: Write and Summarize

Write the rendered README to `<MODULE_DIR>/README.md` using the Write tool (Edit if
preserving hand-written sections).

Then re-run the validator as a sanity check (the README itself doesn't affect
validation, but this confirms nothing else moved):

```bash
seihou validate-module <MODULE_DIR>
```

Finally, report:

```
## README Generated: <module name>

### File
- `<MODULE_DIR>/README.md` (<created | updated>)

### Module Summary
- **Version**: <version or "unversioned">
- **Variables**: <count> (<required-count> required)
- **Prompts**: <count>
- **Dependencies**: <count>
- **Exports**: <count>
- **Generated files**: <count>
- **Removable**: <yes | no>

### Next Steps
1. Review the generated README and tighten any prose that reads as generic.
2. If the module gains new variables or steps, re-run `/seihou-module-readme` to
   refresh.
3. Commit when satisfied:
   ```bash
   git add <MODULE_DIR>/README.md
   git commit -m "docs(<module name>): add module README"
   ```
```

## Output Format

Use the summary template above verbatim. Keep it terse — the README itself is the main
deliverable.

## Important Notes

- **The README lives next to `module.dhall`**, not inside `files/`. Never place it in a
  location that would get templated into a generated project.
- **Do not read template file contents** when synthesizing the README. The whole point
  of this skill is that the README is inferrable from the module's public interface.
  Reading step sources wastes context and tempts the model into documenting
  implementation details.
- **Omit, don't stub.** Sections with no corresponding data are dropped entirely — a
  reader seeing `## Prompts` followed by "None" learns nothing useful.
- **Preserve the author's voice where present.** If the existing README has explanatory
  prose in `<!-- keep:begin -->` blocks, carry those across on regeneration.
- **Never edit `module.dhall` from this skill.** Documentation is strictly downstream.
  If the user wants to fix metadata (e.g., add a missing description), tell them to edit
  `module.dhall` and re-run.
- **Run `seihou validate-module` before and after.** Documenting a module that fails to
  load would hard-code the wrong interface.
