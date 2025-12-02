---
allowed-tools: [Read, Glob, Grep, Write, AskUserQuestion]
argument-hint: [--verbose] [--auto-fix] [--domain <name>] [--interactive] [--threshold <level>]
description: Detect documentation drift between schema and actual codebase
---

# Documentation Audit Command

Compare `.claude/docs/codebase-schema.yaml` against actual filesystem to detect drift.

## Context

Arguments: `/codebase-documentation:audit-docs [FLAGS]`
- **--verbose** - Include detailed file-by-file analysis
- **--auto-fix** - Automatically apply TRIVIAL fixes
- **--interactive** - Prompt for action on each drift item
- **--domain \<name\>** - Audit specific domain only
- **--threshold \<level\>** - Only report drift at or above level (trivial|minor|significant)

## Instructions

### 1. Load Baseline

Read `.claude/docs/codebase-schema.yaml` to establish expected state.

**If schema not found:**
- Error: "Schema file not found at `.claude/docs/codebase-schema.yaml`"
- Suggestion: "Run `/codebase-documentation:document-codebase` to generate documentation first"

**If `--domain <name>` provided:**
- Validate domain exists in schema
- If not found: Error "Domain '{name}' not found in schema" + list available domains

### 2. Scan Filesystem

For each domain in the schema (or single domain if `--domain` flag):

**File Count Verification:**
1. Navigate to `domain.location` path
2. Use Glob to count files matching documented patterns
3. Compare actual count vs documented count
4. Calculate drift percentage: `abs(found - expected) / expected * 100`

**Structure Verification:**
1. Check if documented `key_files` still exist
2. Check for new subdirectories (use Glob for `{location}/**/`)
3. Verify patterns still match (sample 5-10 files)

**Pattern Verification:**
For each `file_patterns` entry:
1. Verify pattern still matches files (Glob test)
2. Check count accuracy (within tolerance)
3. Verify example file still exists

### 3. Classify Drift

For each domain, classify deviation using BOTH absolute and percentage thresholds (use whichever is MORE permissive):

**TRIVIAL** (Auto-fixable with `--auto-fix`):
- File count differs by ≤5 files OR ≤10%
- Example file moved but pattern still valid
- Metadata outdated (last_updated timestamp)
- **Auto-fix Action**: Update counts, timestamps, examples

**MINOR** (Review recommended):
- File count differs by 6-20 files OR 10-25%
- New subdirectories following existing patterns
- New pattern variations detected
- Key files moved but still present
- **Action**: Note in report, suggest manual review

**SIGNIFICANT** (Investigation required):
- File count differs by >20 files OR >25%
- Key files missing or moved outside domain
- New directories with different conventions
- Pattern violations (files not matching documented patterns)
- Entire undocumented directories discovered
- Domain location no longer exists
- **Action**: Flag for manual investigation

### 4. Generate Report

Present report in this format:

```markdown
# Documentation Audit Report
Generated: {ISO 8601 timestamp}
Schema Last Updated: {from metadata.documentation.generated_at if exists}

## Summary
- ✅ {X} domains up-to-date (no drift)
- ⚠️ {X} domains with trivial drift (auto-fixable)
- 🔍 {X} domains with minor drift (review recommended)
- ❌ {X} domains with significant drift (investigation required)

## Drift Details

### ✅ Up-to-Date Domains
| Domain | Location | Status |
|--------|----------|--------|
| {name} | `{path}` | No drift detected |

### ⚠️ Trivial Drift (Auto-fixable)

#### {domain_name}
- **Location**: `{path}`
- **Expected**: {X} files
- **Found**: {Y} files ({+/- Z} difference, {N}%)
- **Classification**: File count drift within tolerance
- **Auto-fix Action**: Update count to {Y}, update timestamp

---

### 🔍 Minor Drift (Review Recommended)

#### {domain_name}
- **Location**: `{path}`
- **Drift Type**: {New subdirectory detected | File count increase | Pattern variation}
- **Details**:
  - {Specific details about what changed}
- **Recommendation**:
  - Review if change warrants documentation update
  - Run: `/codebase-documentation:map-domain {domain_name}` for detailed analysis

---

### ❌ Significant Drift (Investigation Required)

#### {domain_name}
- **Location**: `{path}`
- **Drift Type**: {Major structural change | Domain missing | Key files missing}
- **Details**:
  - Expected: {X} files, Found: {Y} files ({+/- Z} difference, {N}%)
  - Missing key files: `{file1}`, `{file2}` (if applicable)
  - New undocumented directory: `{path}` (if applicable)
- **Impact**: High - {explanation}
- **Recommended Actions**:
  1. Run: `/codebase-documentation:map-domain {domain_name} --compare` for detailed analysis
  2. Consider re-running `/codebase-documentation:update-docs` to refresh documentation

---

## File Pattern Drift

| Pattern | Expected | Found | Drift | Status |
|---------|----------|-------|-------|--------|
| {name} | {X} | {Y} | {+/- Z} ({N}%) | {TRIVIAL|MINOR|SIGNIFICANT} |

---

## Recommended Actions

### Immediate (Auto-fixable)
{List TRIVIAL items that can be auto-fixed}

### Review Needed
{List MINOR items requiring manual review}

### Investigation Required
{List SIGNIFICANT items needing investigation}

---

{If --auto-fix was used:}
## Auto-Fix Summary

**Changes Applied:**
- Updated {X} domain file counts
- Updated {Y} pattern counts
- Updated schema timestamp to {date}

**Changes NOT Applied (require manual review):**
- {List of MINOR/SIGNIFICANT drift items}
```

### 5. Interactive Mode (if `--interactive` flag)

For each MINOR or SIGNIFICANT drift item, use AskUserQuestion:

**Question**: "Drift detected in '{domain_name}': {brief description}. How should we proceed?"
**Options**:
- **Auto-fix now** (only for TRIVIAL items)
- **Mark for review** (add to recommendations)
- **Investigate now** (suggest running `/codebase-documentation:map-domain {domain_name}`)
- **Ignore this time** (skip)

After all prompts, generate final report with applied changes.

### 6. Auto-Fix Mode (if `--auto-fix` flag)

**Without `--interactive`:**
- Automatically apply all TRIVIAL fixes
- Report changes made
- Do NOT touch MINOR or SIGNIFICANT drift

**With `--interactive`:**
- Apply TRIVIAL fixes immediately
- Prompt for MINOR/SIGNIFICANT drift

**Auto-fix Actions:**
1. Read current schema YAML
2. For each TRIVIAL drift:
   - Update domain file counts
   - Update pattern counts
   - Update example file paths (if moved but pattern valid)
3. Update `metadata.documentation.generated_at` timestamp (if field exists)
4. Write updated schema
5. Report all changes in summary

### 7. Threshold Filtering (if `--threshold <level>` provided)

Only include drift items at or above the specified level:
- `--threshold trivial` - Show all drift (default)
- `--threshold minor` - Hide TRIVIAL, show MINOR and SIGNIFICANT
- `--threshold significant` - Only show SIGNIFICANT drift

### 8. Verbose Mode (if `--verbose` flag)

Include additional details:
- Full file listings for each domain (not just counts)
- File-by-file pattern matching results
- Subdirectory breakdown with file counts
- Detailed change log

## Error Handling

### Schema Not Found
- **Error**: "Schema file not found at `.claude/docs/codebase-schema.yaml`"
- **Suggestion**: "Run `/codebase-documentation:document-codebase` to generate documentation first"

### Domain Not Found (with `--domain` flag)
- **Error**: "Domain '{name}' not found in schema"
- **List**: "Available domains: {comma-separated list from schema}"

### Domain Path Doesn't Exist
- **Classification**: SIGNIFICANT drift
- **Report**: "Domain location `{path}` no longer exists"
- **Recommendation**: "Run `/codebase-documentation:update-docs` to regenerate documentation"

### Permission Denied
- **Error**: "Cannot read directory: {path} (permission denied)"
- **Action**: Skip that domain, note in report, continue with others

### Schema Parse Error
- **Error**: "Cannot parse schema: {YAML error details}"
- **Suggestion**: "Check `.claude/docs/codebase-schema.yaml` for syntax errors"

## Drift Calculation Details

### Percentage Calculation
```
drift_percentage = abs(found - expected) / expected * 100
```

If expected is 0 and found > 0, classify as SIGNIFICANT (new undocumented content).

### Tolerance Thresholds
| Classification | Absolute Threshold | Percentage Threshold |
|----------------|-------------------|---------------------|
| TRIVIAL | ≤5 files | ≤10% |
| MINOR | 6-20 files | 10-25% |
| SIGNIFICANT | >20 files | >25% |

Use whichever threshold is MORE permissive (benefits the doubt).

### File Counting Strategy
1. Use Glob to list all files in domain location
2. Exclude common non-source directories (node_modules, dist, etc.) if present
3. Count only files (not directories)
4. For patterns, use Glob with specific pattern

## Examples

```bash
# Basic audit - check all domains
/codebase-documentation:audit-docs

# Verbose output with file details
/codebase-documentation:audit-docs --verbose

# Auto-fix trivial drift
/codebase-documentation:audit-docs --auto-fix

# Interactive mode - prompt for each item
/codebase-documentation:audit-docs --interactive

# Audit specific domain
/codebase-documentation:audit-docs --domain components

# Only show significant issues
/codebase-documentation:audit-docs --threshold significant

# Combined: verbose audit with auto-fix
/codebase-documentation:audit-docs --verbose --auto-fix

# Interactive audit of specific domain
/codebase-documentation:audit-docs --domain services --interactive
```

## Success Criteria

A successful audit should:
1. ✅ Detect all drift between schema and filesystem
2. ✅ Correctly classify drift severity
3. ✅ Generate clear, scannable report
4. ✅ Provide actionable next steps
5. ✅ Auto-fix safely (TRIVIAL only)
6. ✅ Handle missing directories gracefully
7. ✅ Work for any codebase structure (not assume specific architecture)
