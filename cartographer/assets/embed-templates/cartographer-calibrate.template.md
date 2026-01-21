<!--
Embedded Cartographer Command: calibrate
Source: cartographer/commands/cartographer/calibrate.md
Standalone version for plugin-free operation
-->
---
model: sonnet
allowed-tools: Task, Glob, Grep, Read, Bash(test:*), Bash(find:*), Bash(wc:*), Bash(git log:*), AskUserQuestion
argument-hint: [--verbose]
description: Detect drift between atlas and actual codebase state
---

## Context

Arguments: `/calibrate [OPTIONS]`
- **--verbose** - Show detailed per-domain validation
- **(empty)** - Show summary with issues only

Current directory: !`pwd`

## Workflow

### 1. Pre-flight Checks

**Verify atlas exists:**
```bash
test -f ".claude/skills/atlas/references/schema.yaml" && echo "EXISTS" || echo "NOT_FOUND"
```

If not found → Error: "No atlas found. Run `/chart` first."

### 2. Invoke Auditor Agent

```
Use the auditor agent to audit the atlas.

Current atlas location: .claude/skills/atlas/
Schema path: .claude/skills/atlas/references/schema.yaml

The agent will return structured audit in ---AUDIT--- format.
```

**Parse auditor output:**
- Extract summary, issues by severity, domain/pattern status
- Validate response format

### 3. Present Results

**Format based on verbosity:**

#### Summary Mode (default)

```markdown
## Atlas Calibration Report

**Status:** {🟢 Healthy | 🟡 Warning | 🔴 Critical}
**Last Updated:** {date} ({days} days ago)
**Staleness Score:** {score}/1.0

### Issues Found

{if critical_issues}
#### 🔴 Critical Issues ({count})
{list each with type and message}
{/if}

{if high_issues}
#### 🟠 High Priority ({count})
{list each with type and message}
{/if}

{if medium_issues}
#### 🟡 Medium Priority ({count})
{list each with type and message}
{/if}

### Quick Stats
- Domains: {valid}/{total} valid
- Patterns: {valid}/{total} valid
- References: {valid}/{total} valid

### Recommendations
{list prioritized recommendations}
```

#### Verbose Mode (--verbose)

```markdown
## Atlas Calibration Report (Verbose)

**Status:** {status}
**Last Updated:** {date}

### Domain Status

| Domain | Path | Documented | Actual | Drift | Status |
|--------|------|------------|--------|-------|--------|
{for each domain}
| {name} | {path} | {documented} | {actual} | {drift%} | {✅|⚠️|❌} |
{/for}

### Pattern Status

| Pattern | Documented | Actual | Drift | Status |
|---------|------------|--------|-------|--------|
{for each pattern}
| {name} | {documented} | {actual} | {drift%} | {✅|⚠️|❌} |
{/for}

### Reference Files

| Reference | Exists | Links Valid | Issues |
|-----------|--------|-------------|--------|
{for each reference}
| {path} | {yes/no} | {yes/no} | {issues} |
{/for}

### All Issues

#### Critical
{detailed list}

#### High
{detailed list}

#### Medium
{detailed list}

#### Low
{detailed list}

### Recommendations
{detailed recommendations with commands}
```

### 4. Offer Quick Actions

**If critical issues found:**
```
Use AskUserQuestion:

Critical drift detected. How to proceed?

Options:
1. Run /rechart now to fix all issues
2. Run /rechart --domain {most_affected} to fix worst domain
3. Show detailed report for manual review
4. Dismiss (acknowledge drift, continue using atlas)
```

**If warning status:**
```
Use AskUserQuestion:

Atlas has moderate drift. Recommended action?

Options:
1. Run /rechart to update
2. Run /explore {domain} to investigate specific area
3. Dismiss for now
```

### 5. Log Calibration

**Create calibration log (optional):**
- Timestamp
- Status
- Issues found
- Actions taken

This allows tracking drift over time.

---

## Status Thresholds

| Status | Criteria |
|--------|----------|
| 🟢 Healthy | No critical/high issues, staleness < 0.3 |
| 🟡 Warning | No critical issues, has high OR staleness 0.3-0.6 |
| 🔴 Critical | Has critical issues OR staleness > 0.6 OR >50% invalid |

---

## Issue Types

| Type | Severity | Description |
|------|----------|-------------|
| `missing_path` | CRITICAL | Documented path no longer exists |
| `invalid_reference` | CRITICAL | Reference file link broken |
| `count_drift_high` | HIGH | File count differs >50% |
| `count_drift_medium` | MEDIUM | File count differs >20% |
| `orphan_directory` | MEDIUM | Directory not covered by atlas |
| `stale_atlas` | MEDIUM | Atlas >30 days old |
| `count_drift_low` | LOW | File count differs <20% |
| `minor_issue` | LOW | Cosmetic or informational |

---

## Error Handling

| Error | Action | Recovery |
|-------|--------|----------|
| No atlas found | Error message | Run /chart |
| Auditor fails | Report error | Manual inspection |
| Parse error | Report parse issue | Check atlas format |

## Responsibilities

**YOU (handler):**
- Verify atlas exists
- Invoke auditor agent
- Format and present results
- Offer quick actions based on severity

**Auditor agent:**
- Validate all documented elements
- Detect orphan directories
- Calculate staleness
- Return structured audit

**You present results. The auditor does the validation work.**
