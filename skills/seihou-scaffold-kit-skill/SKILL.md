---
name: seihou-scaffold-kit-skill
description: Scaffold new Claude Code skills and agents for Seihou, following established conventions. Use when creating a new skill or agent definition for seihou-kit.
allowed-tools: AskUserQuestion, Read, Write, Edit, Glob, Bash
---

# Seihou Scaffold

This skill scaffolds new Claude Code skills and agents for the seihou-kit repository. It
examines existing skills and agents in this repo as structural reference, uses the seihou
CLI help system and seihou repo for domain context, gathers requirements interactively,
generates files following established conventions, and registers them in `kit.json`.

## When to Use

Activate when the user says things like:
- "Create a new skill"
- "Scaffold an agent"
- "Add a skill for..."
- "I need a new agent that..."
- "Generate a skill definition"
- "Create a guide agent for..."
- "/seihou-scaffold-kit-skill"

## Reference Sources

### Structural reference (this repo)

Existing skills and agents in seihou-kit are the source of truth for format and conventions:

- **Skills** in `skills/*/SKILL.md`
- **Agents** in `agents/*.md`

Always read 1-2 existing examples from this repo before generating, so the output matches
established conventions. If the kit is still empty, fall back to the templates in Phase 5.

### Domain context (seihou CLI and seihou repo)

When the generated skill or agent needs to reference seihou commands, entity types, or
concepts:

- **`seihou --help`** and **`seihou <command> --help`** — authoritative, always-current
  command reference for syntax, flags, and subcommands
- **Seihou repo** at `/Users/shinzui/Keikaku/bokuno/seihou-project/seihou`:
  - `docs/user/` — user-facing guides (getting started, config, module authoring,
    registries)
  - `docs/cli/` and `docs/dev/` — deeper CLI and developer references
  - Use for understanding domain concepts, not for structural skill/agent format

## Workflow Overview

1. **Choose artifact type** — Skill or Agent
2. **Study references** — Read existing examples from this repo; check seihou CLI for domain context
3. **Gather metadata** — Name, description, tools, domain focus
4. **Gather content** — Workflow phases (skills) or domain knowledge (agents)
5. **Generate the file** — Write to the correct location in seihou-kit
6. **Register in kit.json** — Add the manifest entry
7. **Summary** — Show what was created and next steps

## Instructions for Claude

### Phase 1: Choose Artifact Type

If the user hasn't already specified, ask:

```
Question: "What would you like to scaffold?"
Header: "Type"
Options:
- Skill: A workflow that guides users through a task (e.g., bootstrapping a module, summarizing a registry)
- Agent: A domain expert or guide that answers questions and provides advice (e.g., module author guide, registry expert)
```

If the user provided enough context in their request (e.g., "create a skill for..."), skip
this question and proceed directly.

### Phase 2: Study References

Before gathering details, read existing examples from **this repo** to calibrate your
output. Then check the seihou CLI for domain context if the artifact will reference seihou
commands.

**Step 2a: Read structural references from seihou-kit**

```bash
# List existing skills in this repo
ls skills/
```

Read 1-2 existing skill files to understand the format. If none exist yet, use the skill
template in Phase 5 as the canonical format.

For agents, check what exists:
```bash
ls agents/
```

Read any existing agent files. If none exist yet, use the agent template in Phase 5 as the
canonical format.

**Step 2b: Check seihou CLI for domain context (if needed)**

If the skill or agent will reference seihou commands or concepts, explore the CLI help:

```bash
# Top-level commands
seihou --help

# Specific command help
seihou <command> --help
seihou <command> <subcommand> --help
```

For deeper domain context, consult the seihou repo docs:
```bash
# User-facing docs
ls /Users/shinzui/Keikaku/bokuno/seihou-project/seihou/docs/user/

# Getting started and key concepts
cat /Users/shinzui/Keikaku/bokuno/seihou-project/seihou/docs/user/getting-started.md
```

Use the seihou repo **only for domain understanding** — do not copy its skill/agent format.

### Phase 3: Gather Metadata

#### For Skills

Ask about the skill's identity:

```
Question: "What should this skill be named? (Use kebab-case, e.g., seihou-bootstrap-module)"
Header: "Name"
Options:
- Let me type the name
```

**Naming conventions:**
- Prefix with `seihou-` for Seihou-specific skills
- Use action verbs: `seihou-bootstrap-X`, `seihou-review-X`, `seihou-summarize-X`, `seihou-update-X`
- Keep it short and descriptive

Then ask about purpose:

```
Question: "In one sentence, what does this skill do?"
Header: "Purpose"
Options:
- Let me describe it
```

Then ask about the tools needed:

```
Question: "What kind of work does this skill do?"
Header: "Tools"
Options:
- Interactive workflow (asks questions, runs CLI commands) — AskUserQuestion, Bash, Read
- File generation (creates or modifies files) — AskUserQuestion, Read, Write, Edit, Glob, Bash
- Read-only analysis (searches and reads code) — Read, Grep, Glob
- CLI orchestration (runs seihou commands based on user input) — AskUserQuestion, Bash, Read
```

#### For Agents

Ask about the agent's identity:

```
Question: "What should this agent be named? (Use kebab-case, e.g., seihou-module-expert)"
Header: "Name"
Options:
- Let me type the name
```

**Naming conventions:**
- Prefix with `seihou-`
- Suffix with `-expert` for domain knowledge agents
- Suffix with `-guide` for conversational coaching agents
- Examples: `seihou-module-expert`, `seihou-registry-guide`

Then ask about purpose:

```
Question: "In one sentence, what is this agent an expert on?"
Header: "Expertise"
Options:
- Let me describe it
```

Then determine the agent type:

```
Question: "What kind of agent is this?"
Header: "Style"
Options:
- Domain expert: Answers technical questions about a specific area, includes quick-reference tables and file locations (Recommended)
- Guide: Helps users accomplish tasks conversationally, includes examples and troubleshooting
- Pattern expert: Specializes in a cross-cutting concern (e.g., testing, code style, schema authoring)
```

Then ask about tools:

```
Question: "What tools should this agent have access to?"
Header: "Tools"
Options:
- Read-only (Read, Grep, Glob) — for research and analysis (Recommended)
- Read + Bash (Read, Bash) — can also run commands to inspect state
- Read + Bash + Grep + Glob — full read-only exploration
```

### Phase 4: Gather Content

#### For Skills

Ask about the workflow:

```
Question: "Describe the main steps of this skill's workflow. What should happen from start to finish?"
Header: "Workflow"
Options:
- Let me describe the workflow
```

Follow up to understand:
- How many phases are there?
- What questions should be asked at each phase?
- What commands or file operations happen?
- What does success look like?

If the skill involves `seihou` CLI commands, ask:

```
Question: "Which seihou commands does this skill use? (e.g., seihou module init, seihou registry list)"
Header: "Commands"
Options:
- Let me list them
- I'm not sure — help me figure it out
```

If the user is unsure, explore the seihou CLI help:
```bash
# Browse available top-level commands
seihou --help

# Get details on a specific command
seihou <command> --help
```

For more detailed documentation:
```bash
ls /Users/shinzui/Keikaku/bokuno/seihou-project/seihou/docs/user/
```

#### For Agents

Ask about the domain knowledge:

```
Question: "What key concepts, rules, or patterns should this agent know about?"
Header: "Knowledge"
Options:
- Let me describe the domain
- Point me to relevant files/docs to read
```

If the user points to files, read them and extract:
- Core concepts and terminology
- Key business rules or constraints
- Important file locations
- Common patterns and idioms
- Cross-module interactions

If the agent relates to a seihou module or subsystem, check for existing documentation and
CLI help:
```bash
# Developer documentation in the seihou repo (for domain context)
ls /Users/shinzui/Keikaku/bokuno/seihou-project/seihou/docs/dev/

# CLI help for the relevant command
seihou <command> --help
```

### Phase 5: Generate the File

#### Generating a Skill

Create `skills/<name>/SKILL.md` following this structure:

```markdown
---
name: <name>
description: <description from Phase 3>
allowed-tools: <tools from Phase 3>
---

# <Title (human-readable form of the name)>

<One paragraph describing what this skill does and when to use it.>

## When to Use

Activate when the user says things like:
- "<phrase 1>"
- "<phrase 2>"
- "<phrase 3>"
- "<phrase 4>"

## Key Concepts

<If the skill involves domain concepts, define them here. Otherwise omit this section.>

### <Concept 1>

<Brief explanation.>

## Workflow Overview

1. **<Phase 1 name>** - <what happens>
2. **<Phase 2 name>** - <what happens>
...

## Instructions for Claude

### Phase 1: <Name>

<Detailed instructions including AskUserQuestion prompts, CLI commands, and decision logic.>

Use AskUserQuestion for interactive steps:

\```
Question: "<question text>"
Header: "<short label>"
Options:
- <option 1>
- <option 2>
\```

<CLI commands to run:>

\```bash
seihou <command>
\```

### Phase 2: <Name>

<Continue for each phase.>

## Output Format

After completing the workflow, provide a summary:

\```
## <Result Title>

- **<Field 1>**: [value]
- **<Field 2>**: [value]

### Next Steps

1. <step 1>
2. <step 2>
\```

## Important Notes

- <Notes specific to this skill>
```

**Important conventions to follow:**
- Use `AskUserQuestion` blocks exactly as shown (Question, Header, Options format)
- Show CLI commands in fenced bash code blocks
- Keep the workflow actionable — tell Claude exactly what to do, don't just describe
- Add "(Recommended)" suffix to the best default option in AskUserQuestion prompts
- If the user provided enough info upfront, note that questions can be skipped

Create `skills/<name>/SKILL.md` using the Write tool.

#### Generating an Agent

Create `agents/<name>.md` following this structure:

```markdown
---
name: <name>
description: <description from Phase 3, include "Use for..." guidance>
tools: <tools from Phase 3>
model: sonnet
---

# <Title (human-readable form of the name)>

You are an expert on <domain>. <Brief description of role and scope.>

<If there are reference docs:>
**Full documentation:** `<path>` - Always read this first for complete domain details.

## Quick Reference

### Core Concepts

- **<Concept 1>**: <Brief description>
- **<Concept 2>**: <Brief description>

### Key Business Rules

1. <Rule 1>
2. <Rule 2>

<For domain experts, add:>

### File Locations

\```
<path>/
├── <dir>/          # <purpose>
├── <dir>/          # <purpose>
└── <file>          # <purpose>
\```

## Key Patterns

1. **<Pattern 1>**: <Description>
2. **<Pattern 2>**: <Description>

<For guides, replace Key Patterns with:>

## Conversation Flow

When helping users:

1. **<Step 1>**: <what to do>
2. **<Step 2>**: <what to do>

## Example Interactions

**User**: "<example question>"

**Response**: <example answer>

## Output Format

When helping with <domain>:

\```
## <Domain> Analysis: <Topic>

### Current Behavior
(Read the docs and relevant code first)

### Recommendation
Clear recommendation for the change.

### Implementation
Code changes with context.

### Testing
- Tests to add/modify
\```

## Before Answering

1. Read <primary documentation path> for full domain context
2. Check relevant source files in <source path>
3. Reference existing patterns in the codebase
```

**Important conventions to follow:**
- Always include `model: sonnet` in frontmatter
- Agents are read-only — never include Write or Edit in tools
- Domain experts should point to full docs rather than duplicating them
- Include file location trees so the agent knows where to look
- Guides should include example interactions
- Use tables for quick-reference data (states, rules, flags)

Write the file using the Write tool.

### Phase 6: Register in kit.json

Use the Read tool to read `kit.json` and understand the current structure.

**For skills**, add an entry to the `skills` array:

```json
{
  "name": "<name>",
  "description": "<description>",
  "path": "skills/<name>",
  "files": ["SKILL.md"]
}
```

**For agents**, add an entry to the `agents` array:

```json
{
  "name": "<name>",
  "description": "<description>",
  "path": "agents",
  "files": ["<name>.md"]
}
```

Use the Edit tool to insert the new entry into the appropriate array in `kit.json`. Ensure
the resulting JSON is valid.

### Phase 7: Summary

After creating the file and updating kit.json, show a summary.

**For skills:**

```
## Skill Scaffolded: <name>

### Files Created
- `skills/<name>/SKILL.md`

### Files Modified
- `kit.json` (added skill entry)

### Skill Summary
- **Name**: <name>
- **Description**: <description>
- **Allowed Tools**: <tools>
- **Workflow Phases**: <count> phases

### Next Steps
1. Review the generated SKILL.md and refine the workflow details
2. Test the skill by invoking `/<name>`
3. Commit when satisfied: `git add skills/<name>/ kit.json`
```

**For agents:**

```
## Agent Scaffolded: <name>

### Files Created
- `agents/<name>.md`

### Files Modified
- `kit.json` (added agent entry)

### Agent Summary
- **Name**: <name>
- **Description**: <description>
- **Tools**: <tools>
- **Model**: sonnet
- **Type**: <expert / guide / pattern expert>

### Next Steps
1. Review the generated agent file and refine the domain knowledge
2. Add more quick-reference data as you learn the domain
3. Commit when satisfied: `git add agents/<name>.md kit.json`
```

## Important Notes

- **Reference before generating**: Always read 1-2 existing examples from this repo
  (seihou-kit) before writing. If the kit is empty, use the templates in Phase 5. Use the
  seihou CLI help (`seihou <command> --help`) for domain context, not for structural
  format.
- **Don't over-specify**: Generate a solid skeleton that the user can refine. Don't invent
  domain details you're unsure about — mark those spots with `<TODO: ...>` placeholders.
- **Respect the separation**: All generated files go in seihou-kit, never in the seihou
  repo.
- **Naming matters**: Follow the `seihou-` prefix convention. Use `-expert` or `-guide`
  suffix for agents.
- **kit.json must stay valid**: After editing, the JSON must parse correctly. Read before
  editing to understand the current structure.
- **Skill content should be actionable**: Skills tell Claude exactly what to do — specific
  questions to ask, specific commands to run. Don't write vague instructions.
- **Agent content should be reference-oriented**: Agents provide quick-lookup knowledge.
  Point to full docs, don't duplicate them.
- **If the user provides all details upfront**, skip the interactive questions and generate
  directly. Mention which questions were skipped in the summary.
