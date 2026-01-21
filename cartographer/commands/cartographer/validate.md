---
model: sonnet
allowed-tools: Task, Glob, Grep, Read, Write, Edit, Bash(test:*), Bash(mkdir:*), AskUserQuestion
argument-hint: [--strict] [--fix]
description: Validate atlas document structure, format, and reference integrity
---

## Context

Arguments: `/cartographer:validate [OPTIONS]`
- **--strict** - Fail on warnings, not just errors
- **--fix** - Auto-fix simple issues (missing timestamps, broken links)

Current directory: !`pwd`

## Purpose

Validates the atlas documents themselves for:
- Schema compliance (structure and required fields)
- Reference integrity (all links resolve)
- Pattern completeness (required fields present)
- Anti-pattern quality (codebase-specific, 2-4 per pattern)

**Relationship to other commands:**

| Command | Purpose |
|---------|---------|
| `/cartographer:calibrate` | Detects drift (staleness, file counts, missing paths) |
| `/cartographer:validate` | Validates format/structure/completeness (this command) |

Both should pass for a healthy atlas.

## Workflow

### 1. Pre-flight Checks

**Verify atlas exists:**
```bash
test -d ".claude/skills/atlas" && echo "EXISTS" || echo "NOT_FOUND"
```

**If atlas not found:**
```
❌ No atlas found to validate.

Run `/cartographer:chart` to generate an atlas first.
```
**STOP** - Cannot validate non-existent atlas.

### 2. Launch Atlas Validator Agent

**Invoke atlas-validator agent:**

Using Task tool with `agents/review/atlas-validator.md`:

```
Atlas location: .claude/skills/atlas/
Validation mode: {standard|strict based on --strict flag}
```

### 3. Process Validation Results

**Parse agent output for:**
- Errors (blocking issues)
- Warnings (recommendations)
- Auto-fixable issues

### 4. Handle Auto-Fix (if --fix provided)

**For each auto-fixable issue:**

| Issue Type | Auto-Fix Action |
|------------|-----------------|
| Missing timestamp | Add `generated: {current_timestamp}` |
| Missing atlas_version | Add `atlas_version: '3.0'` |
| Broken relative link | Attempt path correction |
| Missing observations.md | Create from template |

**Apply fixes and report:**
```
🔧 Auto-fixed {count} issues:
- Added missing timestamp to schema.yaml
- Corrected link path in SKILL.md
```

### 5. Generate Report

**For standard validation:**

```markdown
## Atlas Validation Results

**Atlas:** `.claude/skills/atlas/`
**Mode:** Standard

---

### Summary

| Check | Status | Details |
|-------|--------|---------|
| Structure | ✅/❌ | {details} |
| SKILL.md | ✅/❌ | {details} |
| schema.yaml | ✅/❌ | {details} |
| Reference Integrity | ✅/❌ | {X}/{Y} links valid |
| Completeness | ✅/❌ | {details} |

---

### Errors (must fix)

{list errors if any}

### Warnings (should fix)

{list warnings if any}

---

### Overall Status

{✅ Atlas is valid | ⚠️ Atlas has warnings | ❌ Atlas has errors}
```

**For strict validation, add:**

```markdown
### Strict Mode Checks

| Check | Status |
|-------|--------|
| All patterns have anti-patterns | ✅/❌ |
| All patterns have examples | ✅/❌ |
| All patterns have test conventions | ✅/❌ |
| All domains have documentation | ✅/❌ |
| observations.md exists | ✅/❌ |
| Updated within 30 days | ✅/❌ |
```

### 6. Provide Recommendations

**Based on validation results:**

```markdown
### Recommendations

1. **{priority}**: {description}
   - File: `{file}`
   - Action: {what to do}

2. **{priority}**: {description}
   - File: `{file}`
   - Action: {what to do}
```

**Common recommendations:**
- Add anti-patterns to patterns with fewer than 2
- Add example_files to patterns without them
- Create domain reference files for undocumented domains
- Update timestamp if atlas is stale

### 7. Exit Status

**Standard mode:**
- ✅ Valid: No errors
- ⚠️ Warnings: Errors = 0, Warnings > 0
- ❌ Invalid: Errors > 0

**Strict mode:**
- ✅ Valid: No errors AND no warnings
- ❌ Invalid: Errors > 0 OR Warnings > 0

---

## Validation Checklist

### Structure
- [ ] SKILL.md exists
- [ ] references/schema.yaml exists
- [ ] references/ directory exists

### SKILL.md
- [ ] Frontmatter has `name: atlas`
- [ ] Frontmatter has non-empty `description`
- [ ] Domain Router section exists
- [ ] Pattern Router section exists
- [ ] File Location Conventions section exists
- [ ] Key Technologies section exists
- [ ] Validation Commands section exists

### schema.yaml
- [ ] metadata section complete
- [ ] At least 2 domains defined
- [ ] All domain paths are valid
- [ ] File counts > 0
- [ ] At least 2 file patterns defined
- [ ] testing section exists
- [ ] validation section exists
- [ ] patterns section exists (if patterns documented)

### Reference Integrity
- [ ] All SKILL.md links resolve
- [ ] All schema.yaml paths exist
- [ ] All documentation references exist
- [ ] All example_files exist

### Completeness (strict)
- [ ] Each pattern has 2-4 anti-patterns
- [ ] Each pattern has example_files
- [ ] Each pattern has test_convention
- [ ] Each domain has documentation
- [ ] observations.md exists

---

## Error Handling

| Error | Action | Recovery |
|-------|--------|----------|
| No atlas | Block with message | Run /cartographer:chart |
| Invalid YAML | Report syntax error | User fixes manually |
| Missing required | List all missing | User adds manually |
| Broken links | List all broken | User fixes or --fix |

## Responsibilities

**YOU (handler):**
- Launch atlas-validator agent
- Process validation results
- Apply auto-fixes if requested
- Generate comprehensive report
- Provide actionable recommendations

**You validate atlas structure, not codebase accuracy. Use /cartographer:calibrate for accuracy checks.**

---

## Output Parsing Protocol

### Atlas Validator Agent Output

**Delimiters:** `---ATLAS-VALIDATION---` and `---END---`

**Required fields to extract:**

```yaml
summary:
  status: string           # Required: valid|warnings|errors
  files_checked: number    # Required
  errors: number           # Required
  warnings: number         # Required
  mode: string             # Required: standard|strict

structure:
  skill_md: string         # Required: exists|missing
  schema_yaml: string      # Required: exists|missing
  references_dir: string   # Required: exists|missing
  pattern_guides: number   # Optional
  domain_references: number  # Optional

errors: []                 # Required (may be empty)
  - type: string           # missing_required_file|invalid_frontmatter|missing_required_section|broken_link|schema_violation
    file: string
    message: string

warnings: []               # Required (may be empty)
  - type: string           # missing_recommended|incomplete_pattern|weak_anti_patterns|generic_anti_pattern|stale_atlas
    file: string|pattern
    message: string

reference_integrity:
  total_links: number
  valid_links: number
  broken_links: number
  broken: [{source, link, line}]

completeness:
  domains_with_docs: string     # "X/Y"
  patterns_with_anti_patterns: string
  patterns_with_examples: string
  patterns_with_tests: string

auto_fixable: []           # Issues that can be auto-fixed
  - type: string
    file: string
    action: string

recommendations: []
  - priority: string       # high|medium|low
    type: string           # add_content|fix_link|improve_quality
    description: string
```

**Parsing steps:**
1. Find `---ATLAS-VALIDATION---` marker
2. Parse YAML content until `---END---`
3. Extract `summary.status` for overall result
4. Collect errors (blocking) and warnings (advisory)
5. Extract auto-fixable items if `--fix` requested
6. Build recommendations list

**Status determination:**

| Parsed Status | Mode | Final Status |
|---------------|------|--------------|
| `valid` | standard | ✅ Atlas is valid |
| `warnings` | standard | ⚠️ Atlas has warnings |
| `warnings` | strict | ❌ Atlas has errors (strict fails on warnings) |
| `errors` | any | ❌ Atlas has errors |

**If parsing fails:**
```
❌ Failed to parse atlas-validator output

Error: {specific parsing error}

Possible causes:
- Atlas files are severely malformed
- Validator agent encountered unexpected structure
- Agent output was truncated

Manual inspection required:
- Check .claude/skills/atlas/SKILL.md syntax
- Check .claude/skills/atlas/references/schema.yaml is valid YAML
```
