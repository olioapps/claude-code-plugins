<!--
Embedded Cartographer Command: calibrate
Standalone version for plugin-free operation
-->
---
allowed-tools: Glob, Grep, Read, Bash(test:*), Bash(find:*), Bash(wc:*), Bash(git log:*), AskUserQuestion
argument-hint: [--verbose]
description: Detect drift between atlas and actual codebase
---

## Context

Arguments: `/calibrate [OPTIONS]`
- **--verbose** - Show detailed per-domain validation
- **(empty)** - Show summary with issues only

Current directory: !`pwd`

## Workflow

### 1. Pre-flight

**Verify atlas exists:**
```bash
test -f ".claude/skills/atlas/references/schema.yaml" && echo "EXISTS" || echo "NOT_FOUND"
```

### 2. Load Atlas

Read and parse:
- `.claude/skills/atlas/references/schema.yaml`
- `.claude/skills/atlas/SKILL.md`

Extract:
- Domains with paths and counts
- File patterns with counts
- Last updated timestamp

### 3. Validate Domains

For each domain:
```bash
test -d "{path}" && echo "EXISTS" || echo "MISSING"
find "{path}" -type f | wc -l
```

Calculate drift percentage.

### 4. Validate Patterns

For each pattern:
```bash
find . -path "{pattern}" -type f | wc -l
```

Compare to documented counts.

### 5. Detect Orphans

Find source directories not covered by atlas.

### 6. Check References

Validate all links in SKILL.md point to existing files.

### 7. Calculate Staleness

- Days since last update
- Git commits since last update

### 8. Report

**Determine status:**
- 🟢 Healthy: No critical/high issues, staleness < 0.3
- 🟡 Warning: No critical, has high OR staleness 0.3-0.6
- 🔴 Critical: Has critical OR staleness > 0.6

```markdown
## Atlas Calibration Report

**Status:** {🟢|🟡|🔴} {status}
**Last Updated:** {date} ({days} days ago)

### Issues Found

{list by severity}

### Domain Status

| Domain | Path | Documented | Actual | Status |
|--------|------|------------|--------|--------|
{domain rows}

### Recommendations

{prioritized actions}
```

### 9. Offer Actions

If critical issues:
```
Options:
1. Run /rechart to fix
2. Show detailed report
3. Dismiss
```
