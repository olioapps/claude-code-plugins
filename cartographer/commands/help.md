---
model: haiku
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

### Atlas Generation
| Command | Description |
|---------|-------------|
| `/cartographer:chart` | Generate complete atlas (initial) |
| `/cartographer:rechart` | Update atlas incrementally |
| `/cartographer:orient` | Add atlas reference to CLAUDE.md |
| `/cartographer:embed` | Export for plugin-free use |

### Atlas Health
| Command | Description |
|---------|-------------|
| `/cartographer:validate` | Check atlas structure/format |
| `/cartographer:calibrate` | Check drift from codebase |
| `/cartographer:review` | Check atlas quality/content |

### Atlas Usage
| Command | Description |
|---------|-------------|
| `/cartographer:where <query>` | Quick path lookup |
| `/cartographer:explore <domain>` | Enrich domain docs |
| `/cartographer:capture` | Add patterns/anti-patterns |

### Navigator (Spec-Driven Development)
| Command | Description |
|---------|-------------|
| `/navigator:plan <task>` | Create spec with atlas context |
| `/navigator:build <spec>` | Execute spec with patterns |
| `/navigator:review <spec>` | Review with agents (default) |
| `/navigator:iterate <element>` | Iterative UI improvement |

## Atlas Health Checks

Run all three for a healthy atlas:
1. `/cartographer:validate` - Structure OK?
2. `/cartographer:calibrate` - Matches codebase?
3. `/cartographer:review` - Quality sufficient?

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Atlas not found | `/cartographer:chart` |
| Atlas stale | `/cartographer:calibrate` then `/cartographer:rechart` |
| Wrong project type | Re-run `/cartographer:chart` with context |
| Navigator blocked | Ensure atlas exists |
| Generic anti-patterns | `/cartographer:review --fix` |
| Incomplete patterns | `/cartographer:explore --pattern <id>` |

## More Info

- Reference docs: `cartographer/references/`
- Templates: `cartographer/assets/atlas-templates/`
```
