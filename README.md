# seihou-kit

Claude Code skills and subagents for seihou end-users.

## Installation

```bash
seihou kit install <skill-name>   # install a skill
seihou kit list                   # see all available content
seihou kit status                 # see what's installed
seihou kit update                 # pull latest versions
```

## Structure

```
seihou-kit/
├── kit.json          # Machine-readable manifest
├── skills/           # Claude Code skill directories
│   └── <name>/
│       └── SKILL.md
└── agents/           # Claude Code subagent files
    └── <name>.md
```

## Adding content

1. Create a skill directory under `skills/` or an agent file under `agents/`.
2. Add the entry to `kit.json`.
3. Commit and push.

Users get the new content on their next `seihou kit update`.
