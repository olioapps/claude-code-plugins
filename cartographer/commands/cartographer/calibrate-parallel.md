---
model: sonnet
allowed-tools: Task, Glob, Grep, Read, Write, Bash(test:*), Bash(find:*), Bash(wc:*), AskUserQuestion
argument-hint: [--domains=<list>]
description: Parallel drift detection across all domains using multiple auditor agents
---

## Context

Arguments: `/cartographer:calibrate-parallel [OPTIONS]`
- **--domains=<list>** - Comma-separated list of domains to audit (default: all)

Current directory: !`pwd`

## Purpose

Enhanced calibration that parallelizes drift detection by spawning one auditor agent per domain. Significantly faster for large codebases with many domains.

**Comparison:**

| Command | Execution | Best For |
|---------|-----------|----------|
| `/cartographer:calibrate` | Sequential | Small codebases, quick checks |
| `/cartographer:calibrate-parallel` | Parallel | Large codebases, comprehensive audits |

## Workflow

### 1. Pre-flight Checks

**Verify atlas exists:**
```bash
test -f ".claude/skills/atlas/references/schema.yaml" && echo "EXISTS" || echo "NOT_FOUND"
```

**If atlas not found:**
```
❌ No atlas found to calibrate.

Run `/cartographer:chart` to generate an atlas first.
```
**STOP** - Cannot calibrate non-existent atlas.

### 2. Load Domain List

**Read schema.yaml:**
```yaml
domains:
  {domain_1}:
    location: {path}
  {domain_2}:
    location: {path}
  # ...
```

**Extract domains to audit:**
- If `--domains` provided: Use specified domains
- Otherwise: Use all domains from schema.yaml

**Report domain count:**
```
📊 Preparing parallel calibration for {N} domains:
- {domain_1}
- {domain_2}
- ...
```

### 3. Spawn Parallel Auditor Agents

**For each domain, spawn auditor agent (using Task tool with model: haiku):**

All agents launched simultaneously using parallel Task calls:

```
Agent 1: Audit domain "{domain_1}"
Agent 2: Audit domain "{domain_2}"
Agent 3: Audit domain "{domain_3}"
...
```

**Each agent receives:**
- Domain name
- Expected path from schema.yaml
- Expected file count from schema.yaml
- Expected key_files from schema.yaml

**Each agent performs:**
1. Verify domain path exists
2. Count actual files
3. Calculate drift percentage
4. Check key_files exist
5. Detect orphan subdirectories

### 4. Collect Agent Results

**As agents complete, collect:**
```yaml
{domain_name}:
  status: {healthy|warning|critical}
  path_exists: {yes|no}
  documented_count: {number}
  actual_count: {number}
  drift_percent: {percent}
  key_files_valid: {count}/{total}
  orphan_dirs: [{paths}]
  issues: [{issues}]
```

### 5. Aggregate Results

**Combine all domain audits:**

```markdown
## Parallel Calibration Results

**Domains audited:** {N}
**Execution:** Parallel ({N} agents)

---

### Summary by Status

| Status | Count | Domains |
|--------|-------|---------|
| 🟢 Healthy | {count} | {list} |
| 🟡 Warning | {count} | {list} |
| 🔴 Critical | {count} | {list} |

---

### Domain Details

{For each domain, sorted by severity:}

#### {domain_name} ({status_emoji})

| Metric | Documented | Actual | Drift |
|--------|------------|--------|-------|
| File Count | {doc} | {actual} | {percent}% |
| Key Files | {total} | {valid} | {missing} missing |

{If issues:}
**Issues:**
- {issue_1}
- {issue_2}

{If orphan_dirs:}
**Orphan directories:**
- {dir_1} ({count} files)
```

### 6. Calculate Overall Health

**Health score:**
```
healthy_domains / total_domains = health_percentage
```

**Status determination:**

| Health % | Status | Message |
|----------|--------|---------|
| 90-100% | 🟢 Healthy | Atlas accurately reflects codebase |
| 70-89% | 🟡 Warning | Some drift detected, consider rechart |
| <70% | 🔴 Critical | Significant drift, rechart recommended |

### 7. Generate Recommendations

**Prioritized by severity:**

```markdown
### Recommendations

1. **CRITICAL**: {domain} - Path missing
   - Action: Run `/cartographer:rechart` or remove domain

2. **HIGH**: {domain} - 75% file count drift
   - Action: Run `/cartographer:rechart --focus={domain}`

3. **MEDIUM**: {domain} - Orphan directories detected
   - Action: Add to domains or .atlas-ignore

4. **LOW**: {domain} - Minor count drift (15%)
   - Action: Accept or run `/cartographer:rechart`
```

---

## Parallel Execution Details

**Agent configuration:**
- Model: haiku (cost-efficient for validation tasks)
- Timeout: 60 seconds per domain
- Max concurrent: 10 agents

**Performance comparison:**

| Domains | Sequential | Parallel | Speedup |
|---------|------------|----------|---------|
| 5 | ~25s | ~10s | 2.5x |
| 10 | ~50s | ~15s | 3.3x |
| 20 | ~100s | ~20s | 5x |

---

## Error Handling

| Error | Action | Recovery |
|-------|--------|----------|
| No atlas | Block with message | Run /cartographer:chart |
| Agent timeout | Report partial, continue | Retry domain individually |
| Agent failure | Log error, continue | Report in summary |
| All agents fail | Error with details | Check system resources |

## Responsibilities

**YOU (handler):**
- Load domain list from schema.yaml
- Spawn auditor agents in parallel
- Collect and aggregate results
- Generate prioritized recommendations
- Report overall atlas health

**You coordinate parallel execution. Let the agents do the detailed work.**
