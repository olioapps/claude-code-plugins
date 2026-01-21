<!--
Embedded Cartographer Command: validate
Source: cartographer/commands/cartographer/validate.md
Standalone version for plugin-free operation
-->
---
model: sonnet
allowed-tools: Task, Glob, Grep, Read, Write, Edit, Bash(test:*), AskUserQuestion
argument-hint: [--strict] [--fix]
description: Validate atlas document structure, format, and reference integrity
---

## Context

Arguments: `/validate [OPTIONS]`
- **--strict** - Enable strict validation (all recommended fields required)
- **--fix** - Attempt to auto-fix common issues
- **(empty)** - Standard validation

Current directory: !`pwd`

## Purpose

Validates the **structural integrity** of the atlas documents themselves - not the accuracy against the codebase (that's `/calibrate`).

| Command | Purpose |
|---------|---------|
| `/validate` | Check atlas document format and links |
| `/calibrate` | Check atlas accuracy against codebase |

## Workflow

### 1. Pre-flight Checks

**Verify atlas exists:**
```bash
test -d ".claude/skills/atlas" && echo "EXISTS" || echo "NOT_FOUND"
```

If not found → Error: "No atlas found. Run `/chart` first."

### 2. Invoke Atlas Validator Agent

```
Use the atlas-validator agent to validate the atlas.

Atlas location: .claude/skills/atlas/
Mode: {standard | strict}
Fix mode: {enabled | disabled}

The agent will return structured validation in ---ATLAS-VALIDATION--- format.
```

### 3. Parse and Present Results

**Format results based on validation output:**

```markdown
## Atlas Validation Report

**Status:** {✅ Valid | ⚠️ Warnings | ❌ Errors}
**Mode:** {Standard | Strict}

### Structure Check

| File | Status | Issues |
|------|--------|--------|
| SKILL.md | {✅|❌} | {issues} |
| schema.yaml | {✅|❌} | {issues} |
| references/ | {✅|❌} | {issues} |

### Reference Integrity

- Total links: {count}
- Valid links: {count}
- Broken links: {count}

{if broken links}
**Broken links:**
{list with source file and target}
{/if}

### Completeness

| Metric | Status |
|--------|--------|
| Domains with docs | {X}/{Y} |
| Patterns with anti-patterns | {X}/{Y} |
| Patterns with examples | {X}/{Y} |

### Issues Found

{if errors}
#### ❌ Errors
{list errors with file and line}
{/if}

{if warnings}
#### ⚠️ Warnings
{list warnings}
{/if}

{if fix mode and auto_fixable}
### Auto-Fixed

{list what was fixed}
{/if}

### Recommendations

{prioritized recommendations}
```

### 4. Handle --fix Mode

If `--fix` flag provided and issues are auto-fixable:

**Auto-fixable issues:**
- Missing `generated` timestamp → Add current timestamp
- Missing `atlas_version` → Add current version
- Empty required arrays → Initialize as `[]`
- Broken relative links → Attempt path correction
- Missing observations.md → Create from template

**Non-auto-fixable:**
- Missing SKILL.md or schema.yaml
- Invalid YAML syntax
- Missing required sections
- Incorrect pattern structures

**Report fixes:**
```markdown
## Auto-Fix Applied

**Fixed:**
- {issue}: {fix applied}

**Could not fix:**
- {issue}: {reason}

Re-run `/validate` to verify fixes.
```

### 5. Offer Quick Actions

**If errors found:**
```
Use AskUserQuestion:

Atlas has validation errors. How to proceed?

Options:
1. Run /validate --fix to attempt auto-repair
2. Run /rechart to regenerate atlas
3. Show detailed error report for manual fix
4. Dismiss
```

---

## Validation Levels

| Level | Checks |
|-------|--------|
| **Standard** | Required files exist, required fields present, links resolve, basic structure valid |
| **Strict** | All standard + recommended fields present, quality thresholds met, anti-patterns complete, recent timestamp |

---

## Error Types

| Error Type | Severity | Description |
|------------|----------|-------------|
| `missing_required_file` | ERROR | SKILL.md or schema.yaml missing |
| `invalid_frontmatter` | ERROR | YAML frontmatter malformed |
| `missing_required_section` | ERROR | Required section not in file |
| `broken_link` | ERROR | Link target doesn't exist |
| `schema_violation` | ERROR | YAML structure invalid |
| `missing_recommended` | WARNING | Recommended field not present |
| `incomplete_pattern` | WARNING | Pattern missing recommended fields |
| `weak_anti_patterns` | WARNING | Pattern has <2 anti-patterns |
| `generic_anti_pattern` | WARNING | Anti-pattern appears generic |
| `stale_atlas` | WARNING | Atlas >30 days old |

---

## Error Handling

| Error | Action | Recovery |
|-------|--------|----------|
| No atlas found | Error message | Run /chart |
| Validator fails | Report error | Manual inspection |
| Parse error | Report issue | Check file syntax |

## Responsibilities

**YOU (handler):**
- Verify atlas exists
- Invoke atlas-validator agent
- Format and present results
- Handle --fix mode
- Offer quick actions

**Atlas-validator agent:**
- Check file structure
- Validate YAML schemas
- Check link integrity
- Assess completeness
- Return structured validation

**You present results. The validator does the checking work.**
