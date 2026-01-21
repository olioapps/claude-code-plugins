<!--
Embedded Cartographer Command: calibrate-parallel
Source: cartographer/commands/cartographer/calibrate-parallel.md
Standalone version for plugin-free operation
-->
---
model: sonnet
allowed-tools: Task, Glob, Grep, Read, Write, Bash(test:*), Bash(find:*), Bash(wc:*), Bash(git log:*), AskUserQuestion
argument-hint: [--verbose]
description: Run parallel auditors for faster atlas validation on large codebases
---

## Context

Arguments: `/calibrate-parallel [OPTIONS]`
- **--verbose** - Show detailed output from each auditor
- **(empty)** - Show aggregated summary

Current directory: !`pwd`

## Purpose

Faster alternative to `/calibrate` for large codebases. Spawns multiple auditor agents in parallel, each validating a subset of the atlas.

**When to use:**
- Codebase has >10 domains
- Standard calibrate takes >30 seconds
- Need faster feedback during development

**When NOT to use:**
- Small codebases (<10 domains)
- Need detailed sequential output
- Debugging atlas issues

## Workflow

### 1. Pre-flight Checks

**Verify atlas exists:**
```bash
test -f ".claude/skills/atlas/references/schema.yaml" && echo "EXISTS" || echo "NOT_FOUND"
```

If not found → Error: "No atlas found. Run `/chart` first."

**Load schema:**
- Read `.claude/skills/atlas/references/schema.yaml`
- Count domains and patterns
- Determine parallelization strategy

### 2. Plan Parallel Execution

**Partition work:**
- Group domains into batches (3-5 domains per batch)
- Assign patterns to domain groups based on location

**Example partitioning for 12 domains:**
```
Batch 1: domains[0:4]   → Auditor 1
Batch 2: domains[4:8]   → Auditor 2
Batch 3: domains[8:12]  → Auditor 3
```

**Also assign:**
- Reference link validation → Auditor 1
- Staleness check → Auditor 2
- Orphan detection → Auditor 3

### 3. Launch Parallel Auditors

**Using Task tool, spawn auditors in parallel:**

```
Launch 3 Task agents in parallel:

Agent 1:
  subagent_type: auditor
  prompt: "Validate domains: {batch1_domains}. Check paths exist, counts accurate."

Agent 2:
  subagent_type: auditor
  prompt: "Validate domains: {batch2_domains}. Also check staleness."

Agent 3:
  subagent_type: auditor
  prompt: "Validate domains: {batch3_domains}. Also detect orphan directories."
```

**Wait for all agents to complete.**

### 4. Aggregate Results

**Collect from each auditor:**
- Domain validation results
- Issues found (by severity)
- Recommendations

**Merge into unified report:**
```yaml
aggregated:
  total_domains: {sum}
  valid_domains: {sum}
  issues:
    critical: {merged list}
    high: {merged list}
    medium: {merged list}
    low: {merged list}
  staleness_score: {from designated auditor}
  orphan_directories: {from designated auditor}
```

**Deduplicate issues:**
- Remove duplicate findings
- Merge overlapping recommendations

### 5. Present Aggregated Results

```markdown
## Atlas Calibration Report (Parallel)

**Status:** {🟢 Healthy | 🟡 Warning | 🔴 Critical}
**Auditors used:** {count}
**Total time:** {elapsed}

### Summary

| Metric | Result |
|--------|--------|
| Domains validated | {valid}/{total} |
| Patterns validated | {valid}/{total} |
| Issues found | {count} |
| Staleness score | {score} |

{if verbose}
### Per-Auditor Results

#### Auditor 1: {batch1_domains}
{detailed results}

#### Auditor 2: {batch2_domains}
{detailed results}

#### Auditor 3: {batch3_domains}
{detailed results}
{/if}

### Issues Found

{aggregated issues by severity}

### Recommendations

{merged recommendations}
```

### 6. Offer Quick Actions

Same as standard `/calibrate`:
- Run `/rechart` if critical issues
- Run `/explore` for specific domains
- Dismiss if acceptable

---

## Parallelization Strategy

| Codebase Size | Domains | Batches | Auditors |
|---------------|---------|---------|----------|
| Small | <10 | 1 | 1 (use /calibrate instead) |
| Medium | 10-20 | 3-4 | 3 |
| Large | 20-50 | 5-8 | 5 |
| Very Large | 50+ | 10+ | 8 (max) |

**Max auditors:** 8 (diminishing returns beyond this)

---

## Error Handling

| Error | Action | Recovery |
|-------|--------|----------|
| No atlas found | Error message | Run /chart |
| Auditor fails | Continue with others, note failure | Report partial results |
| All auditors fail | Report failure | Fall back to /calibrate |
| Timeout | Report partial results | Suggest /calibrate |

## Responsibilities

**YOU (handler):**
- Load atlas and plan partitioning
- Launch parallel auditor agents
- Wait for completion
- Aggregate and deduplicate results
- Present unified report

**Auditor agents (parallel):**
- Each validates assigned domains
- Returns partial audit results

**You orchestrate. The auditors work in parallel.**
