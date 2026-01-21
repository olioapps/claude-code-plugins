---
model: sonnet
allowed-tools: Read, Write, Glob, Bash(test:*), Bash(mkdir:*), AskUserQuestion
argument-hint: [--cartographer | --navigator | --agents | --all] [--output <dir>]
description: Export commands for plugin-free operation
---

## Context

Arguments: `/cartographer:embed [OPTIONS]`
- **--cartographer** - Export cartographer commands only
- **--navigator** - Export navigator commands only
- **--agents** - Include agent definitions (required for chart/review to work standalone)
- **--all** - Export everything (cartographer + navigator + agents)
- **--output <dir>** - Custom output directory (default: `.claude/commands/`)
- **(empty)** - Same as --all

Current directory: !`pwd`

## Command Mapping

| Plugin Command | Embedded Name | Model |
|----------------|---------------|-------|
| `/cartographer:chart` | `/chart` | sonnet |
| `/cartographer:rechart` | `/rechart` | sonnet |
| `/cartographer:calibrate` | `/calibrate` | sonnet |
| `/cartographer:calibrate-parallel` | `/calibrate-parallel` | sonnet |
| `/cartographer:explore` | `/explore` | sonnet |
| `/cartographer:where` | `/where` | haiku |
| `/cartographer:validate` | `/validate` | sonnet |
| `/cartographer:capture` | `/capture` | haiku |
| `/cartographer:review` | `/atlas-review` | sonnet |
| `/navigator:plan` | `/spec-plan` | sonnet |
| `/navigator:build` | `/spec-build` | sonnet |
| `/navigator:review` | `/spec-review` | sonnet |
| `/navigator:iterate` | `/spec-iterate` | sonnet |

## Workflow

### 1. Discover Plugin Templates

Locate the cartographer plugin's embed templates. Search in order:

```
~/.claude/plugins/*/cartographer/assets/embed-templates/
~/.claude/plugins/marketplaces/*/cartographer/assets/embed-templates/
.claude/plugins/*/cartographer/assets/embed-templates/
```

Use Glob to find `*.template.md` files. Store path as `{template_dir}`.

**Required templates:**

Cartographer:
- `cartographer-chart.template.md`
- `cartographer-rechart.template.md`
- `cartographer-calibrate.template.md`
- `cartographer-calibrate-parallel.template.md`
- `cartographer-explore.template.md`
- `cartographer-where.template.md`
- `cartographer-validate.template.md`
- `cartographer-capture.template.md`
- `cartographer-review.template.md`

Navigator:
- `navigator-plan.template.md`
- `navigator-build.template.md`
- `navigator-review.template.md`
- `navigator-iterate.template.md`

Agents (if --agents or --all):
- `agent-surveyor.template.md`
- `agent-auditor.template.md`
- `agent-import-analyzer.template.md`
- `agent-pattern-enforcer.template.md`
- `agent-architecture-auditor.template.md`
- `agent-anti-pattern-detector.template.md`
- `agent-convention-checker.template.md`
- `agent-atlas-validator.template.md`

**If not found:**
```
❌ Could not locate cartographer plugin templates.

Searched:
- ~/.claude/plugins/*/cartographer/
- ~/.claude/plugins/marketplaces/*/cartographer/
- .claude/plugins/*/cartographer/

Ensure the cartographer plugin is installed.
```

### 2. Check Output Directory

```bash
test -d "{output_dir}" && echo "EXISTS" || echo "NOT_FOUND"
```

**If exists with conflicts, use AskUserQuestion:**
- Overwrite all
- Skip existing
- Choose different directory
- Abort

### 3. Create Output Directory

```bash
mkdir -p {output_dir}
```

### 4. Export Commands

For each command to export:
1. Read template from `{template_dir}`
2. Write to output directory with embedded name

**File naming:**
- `cartographer-{name}.template.md` → `{name}.md`
- `navigator-{name}.template.md` → `spec-{name}.md`
- `agent-{name}.template.md` → `agents/{name}.md`

### 5. Export Agents (if --agents or --all)

Create agents directory and export agent definitions:

```bash
mkdir -p {output_dir}/agents
```

**Agent file mapping:**

| Template | Output |
|----------|--------|
| `agent-surveyor.template.md` | `agents/surveyor.md` |
| `agent-auditor.template.md` | `agents/auditor.md` |
| `agent-import-analyzer.template.md` | `agents/import-analyzer.md` |
| `agent-pattern-enforcer.template.md` | `agents/pattern-enforcer.md` |
| `agent-architecture-auditor.template.md` | `agents/architecture-auditor.md` |
| `agent-anti-pattern-detector.template.md` | `agents/anti-pattern-detector.md` |
| `agent-convention-checker.template.md` | `agents/convention-checker.md` |
| `agent-atlas-validator.template.md` | `agents/atlas-validator.md` |

**Commands reference agents via relative paths:**

| Command | Required Agents |
|---------|-----------------|
| `chart.md` | `agents/surveyor.md`, `agents/import-analyzer.md` |
| `calibrate.md` | `agents/auditor.md` |
| `validate.md` | `agents/atlas-validator.md` |
| `spec-review.md` | `agents/pattern-enforcer.md`, `agents/architecture-auditor.md`, `agents/anti-pattern-detector.md`, `agents/convention-checker.md` |

Commands use Task tool to invoke agents from the `agents/` directory. Agent definitions stay separate from command logic.

### 6. Report Results

```markdown
## Commands Embedded

**Output:** `{output_dir}`

### Cartographer Commands (daily use)
- `/where` - Quick path lookup
- `/explore` - Deep domain analysis
- `/calibrate` - Check atlas drift
- `/capture` - Capture new patterns
- `/validate` - Validate atlas structure
- `/atlas-review` - Review atlas quality

### Cartographer Commands (plugin-only)
- `/chart` - Generate atlas (initial)
- `/rechart` - Update atlas (regeneration)
- `/calibrate-parallel` - Parallel drift check (advanced)

### Navigator Commands
- `/spec-plan` - Create implementation spec
- `/spec-build` - Execute spec
- `/spec-review` - Review implementation
- `/spec-iterate` - Iterative UI improvement

{IF agents exported:}
### Agent Definitions
Exported to `{output_dir}/agents/`:
- `surveyor.md` - Codebase analysis
- `auditor.md` - Drift detection
- `import-analyzer.md` - Import pattern analysis
- `atlas-validator.md` - Atlas structure validation
- `pattern-enforcer.md` - Pattern compliance
- `architecture-auditor.md` - Layer boundaries
- `anti-pattern-detector.md` - Anti-pattern detection
- `convention-checker.md` - Naming conventions

**Next steps:**
- Commands are ready to use without the plugin
- Re-run `/cartographer:embed` to update from plugin
```

## Error Handling

| Error | Action |
|-------|--------|
| Templates not found | Report search paths, suggest reinstall |
| Permission denied | Report error, suggest different path |
| Partial export | Report what succeeded |
