# Embedding Philosophy

## Core Principle: Complete Fidelity

**Embedded commands MUST maintain 100% feature parity with plugin commands.**

The `/cartographer:embed` command exports commands for plugin-free operation. These embedded versions should work identically to their plugin counterparts.

## What Gets Templated

Only these elements are templated (replaced during embed):

| Template Variable | Purpose | Example |
|-------------------|---------|---------|
| Command invocation paths | Shorter names without namespace | `/cartographer:chart` → `/chart` |
| Plugin-relative paths | Resolve to embedded locations | `agents/surveyor.md` → inline or adjacent |
| Project-specific mappings | Injected from atlas schema | Pattern keyword mappings |

## What Does NOT Get Templated

Everything else is copied verbatim:

- Workflow steps
- Validation logic
- Error handling
- Output formats
- Tool permissions
- Agent definitions

## Template Structure

### Command Templates

Command templates are nearly identical to source commands:

```markdown
<!--
Embedded Cartographer Command: {command_name}
Source: cartographer/commands/{path}/{command}.md
Standalone version for plugin-free operation
-->
{EXACT CONTENT FROM SOURCE COMMAND}
```

The only changes:
1. Header comment noting source
2. Command invocation paths updated (e.g., `/cartographer:chart` → `/chart`)
3. References to other commands updated to embedded names

### Agent Templates

Agent templates are identical to source agents:

```markdown
<!--
Embedded Agent: {agent_name}
Source: cartographer/agents/{agent}.md
-->
{EXACT CONTENT FROM SOURCE AGENT}
```

No changes except the header comment.

## Embedding Modes

### Standalone Embedding (Default)

Commands are self-contained files that work without the plugin:

```
.claude/commands/
├── chart.md
├── rechart.md
├── calibrate.md
├── explore.md
├── where.md
├── validate.md
├── capture.md
├── spec-plan.md
├── spec-build.md
├── spec-review.md
└── spec-iterate.md
```

### With Agents Inlined (`--agents`)

Agent definitions are appended to commands that use them:

```markdown
{command content}

---

## Embedded Agent: Surveyor

{full surveyor.md content}
```

This makes commands fully self-contained without needing separate agent files.

## Why Full Fidelity Matters

1. **Reliability**: Embedded commands behave exactly like plugin commands
2. **Maintainability**: One source of truth - update source, regenerate templates
3. **Debugging**: Issues in embedded mode reproduce in plugin mode
4. **Trust**: Users know what they're getting

## Template Generation

Templates should be generated from source files, not manually maintained:

```bash
# Future: automated template generation
/cartographer:generate-templates
```

Until automation exists, templates must be manually kept in sync with sources.

## Validation

When updating commands or agents:

1. Update the source file
2. Update or regenerate the corresponding embed template
3. Verify template matches source (except allowed templating)

## Command Mapping

| Plugin Command | Embedded Command |
|----------------|------------------|
| `/cartographer:chart` | `/chart` |
| `/cartographer:rechart` | `/rechart` |
| `/cartographer:calibrate` | `/calibrate` |
| `/cartographer:calibrate-parallel` | `/calibrate-parallel` |
| `/cartographer:explore` | `/explore` |
| `/cartographer:where` | `/where` |
| `/cartographer:validate` | `/validate` |
| `/cartographer:capture` | `/capture` |
| `/navigator:plan` | `/spec-plan` |
| `/navigator:build` | `/spec-build` |
| `/navigator:review` | `/spec-review` |
| `/navigator:iterate` | `/spec-iterate` |
