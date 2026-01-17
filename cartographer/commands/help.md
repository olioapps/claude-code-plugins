---
allowed-tools: Read
description: Display Cartographer usage guide and workflow documentation
---

## Cartographer Help

Print the following help documentation:

```markdown
# Cartographer Plugin

Generate AI-optimized codebase navigation (`/atlas` skills) plus spec-driven development workflows.

## Quick Start

1. **Generate atlas:** `/cartographer:chart`
2. **Use atlas:** `/atlas` (auto-invoked when asking "where is X?")
3. **Keep fresh:** `/cartographer:calibrate` → `/cartographer:rechart`

## Commands

| Command | Description |
|---------|-------------|
| `/cartographer:chart` | Generate complete atlas |
| `/cartographer:rechart` | Update atlas incrementally |
| `/cartographer:calibrate` | Detect drift |
| `/cartographer:explore <domain>` | Enrich domain docs |
| `/cartographer:where <query>` | Quick path lookup |
| `/navigator:plan <task>` | Create spec with atlas context |
| `/navigator:build <spec>` | Execute spec with patterns |
| `/navigator:review <spec>` | Review against spec/patterns |
| `/cartographer:orient` | Set up CLAUDE.md |
| `/cartographer:embed` | Export for plugin-free use |

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Atlas not found | `/cartographer:chart` |
| Atlas stale | `/cartographer:calibrate` then `/cartographer:rechart` |
| Wrong project type | Re-run `/cartographer:chart` with context |
| Navigator blocked | Ensure atlas exists |

## More Info

- Reference docs: `cartographer/references/`
- Templates: `cartographer/assets/atlas-templates/`
```
