---
model: sonnet
allowed-tools: Task, Glob, Grep, Read, Write, Bash(test:*), AskUserQuestion
argument-hint: [--strict] [--fix]
description: Review atlas document quality (not just structure)
---

## Context

Arguments: `/cartographer:review [OPTIONS]`
- **--strict** - Fail on warnings, not just errors
- **--fix** - Attempt to auto-fix issues where possible

Current directory: !`pwd`

## Purpose

Reviews the **quality and content** of atlas documents, not just structure/format.

**Relationship to other commands:**

| Command | What It Checks |
|---------|----------------|
| `/cartographer:validate` | Structure/format (links valid, required fields present) |
| `/cartographer:calibrate` | Drift (paths exist, file counts match reality) |
| `/cartographer:review` | **Quality/content** (this command) |

All three should pass for a healthy, useful atlas.

## What This Reviews

| Aspect | Question Answered |
|--------|-------------------|
| Anti-pattern quality | Are they codebase-specific or generic? |
| Pattern completeness | Do patterns have examples, tests, registration? |
| Convention actionability | Can someone follow these conventions? |
| Domain coverage | Are major code areas documented? |
| Example validity | Do example files actually exist and demonstrate the pattern? |
| Keyword coverage | Can common tasks be routed to patterns? |

## Workflow

### 1. Pre-flight Checks

**Verify atlas exists:**
```bash
test -d ".claude/skills/atlas" && echo "EXISTS" || echo "NOT_FOUND"
```

**If atlas not found:**
```
❌ No atlas found to review.

Run `/cartographer:chart` to generate an atlas first.
```
**STOP** - Cannot review non-existent atlas.

### 2. Load Atlas Documents

**Read all atlas files:**
- `.claude/skills/atlas/SKILL.md`
- `.claude/skills/atlas/references/schema.yaml`
- `.claude/skills/atlas/references/observations.md` (if exists)
- `.claude/skills/atlas/references/patterns/*.md` (all pattern guides)

### 3. Review Anti-Pattern Quality

**For each pattern in schema.yaml `patterns` section:**

Check `anti_patterns_summary` entries:

**Quality criteria:**
1. Starts with "Don't" ✓
2. Is codebase-specific (not generic) ✓
3. Has implied fix (what to do instead) ✓
4. References specific codebase elements ✓

**Generic anti-patterns to flag (Claude already knows these):**
- "Don't use any types"
- "Don't skip error handling"
- "Don't use magic numbers"
- "Don't leave unused variables"
- "Don't forget to add tests"

**Good codebase-specific examples:**
- "Don't import DAOs directly in controllers - use providers layer"
- "Don't define types inline - import from src/types/"
- "Don't call Stripe API outside of src/integrations/stripe/"

**Scoring:**
```
anti_pattern_score = (codebase_specific_count / total_count) * 100
```

**Flag if:**
- Pattern has < 2 anti-patterns → `warning: incomplete`
- Pattern has > 4 anti-patterns → `info: consider consolidating`
- > 30% are generic → `warning: too generic`
- Any anti-pattern doesn't start with "Don't" → `error: malformed`

### 4. Review Pattern Completeness

**For each pattern in schema.yaml:**

| Field | Required | Quality Check |
|-------|----------|---------------|
| `keywords` | Yes | At least 2, relevant to pattern |
| `file_convention` | Yes | Contains path template with placeholder |
| `test_convention` | Recommended | Exists and is consistent with file_convention |
| `example_files` | Recommended | At least 2, files actually exist |
| `validation_commands` | Yes | At least 1, command is runnable |
| `registration` | If applicable | Steps are specific with file paths |
| `anti_patterns_summary` | Recommended | 2-4 codebase-specific items |

**Verify example files exist:**
```bash
test -f "{example_file}" && echo "EXISTS" || echo "MISSING"
```

**Flag if:**
- Missing required fields → `error`
- Missing recommended fields → `warning`
- Example files don't exist → `error: stale examples`
- File convention has no placeholder → `warning: not templated`

### 5. Review Convention Actionability

**For each pattern, check if someone could follow it:**

1. **File convention is clear:**
   - Has path structure (e.g., `src/controllers/`)
   - Has naming template (e.g., `{Name}Controller.ts`)
   - Not ambiguous

2. **Registration steps are specific:**
   - Names exact files to modify
   - Describes what to add
   - Not vague ("update config")

3. **Pattern guide exists and is complete:**
   - Has Implementation Checklist
   - Has Template section with actual code
   - Has Reference Implementations table

**Flag if:**
- Convention is vague → `warning: unclear convention`
- Registration references non-existent files → `error: invalid registration`
- Pattern guide has TODO placeholders → `warning: incomplete guide`

### 6. Review Domain Coverage

**Get all source directories:**
```bash
find . -type d -name "src" -o -name "lib" -o -name "app" | head -20
```

**Compare against documented domains:**
- List directories with >10 files not covered by any domain
- Check if major framework directories are documented (controllers, models, etc.)

**Flag if:**
- Directory with >20 files not in any domain → `warning: undocumented area`
- Standard framework directory missing (e.g., `controllers/` exists but no controller pattern) → `warning: missing pattern`

### 7. Review Keyword Coverage

**Check keyword_index completeness:**

Common task keywords that should be mapped:
- `endpoint`, `api`, `route`, `controller`
- `model`, `entity`, `schema`, `database`
- `service`, `provider`, `business logic`
- `test`, `spec`, `unit test`
- `component`, `ui`, `view`

**Flag if:**
- Common keyword not in index → `info: consider adding`
- Keyword maps to non-existent pattern → `error: broken mapping`

### 8. Review SKILL.md Quality

**Check routing tables:**

1. **Domain Router:**
   - All domains in schema.yaml have router entry
   - Keywords are relevant and distinct
   - References resolve to existing files

2. **Pattern Router:**
   - All patterns in schema.yaml have router entry
   - Task descriptions are actionable
   - Guide links resolve

**Flag if:**
- Domain missing from router → `warning: incomplete router`
- Broken reference link → `error: broken link`

### 9. Generate Review Report

```markdown
## Atlas Quality Review

**Atlas:** `.claude/skills/atlas/`
**Mode:** {Standard | Strict}

---

### Summary

| Aspect | Score | Status |
|--------|-------|--------|
| Anti-Pattern Quality | {X}% codebase-specific | ✅/⚠️/❌ |
| Pattern Completeness | {X}/{Y} complete | ✅/⚠️/❌ |
| Convention Actionability | {X}/{Y} actionable | ✅/⚠️/❌ |
| Domain Coverage | {X}% covered | ✅/⚠️/❌ |
| Keyword Coverage | {X}/{Y} mapped | ✅/⚠️/❌ |
| SKILL.md Quality | {status} | ✅/⚠️/❌ |

**Overall:** {✅ High Quality | ⚠️ Needs Improvement | ❌ Significant Issues}

---

### Anti-Pattern Quality

**Patterns with quality issues:**

| Pattern | Anti-Patterns | Issues |
|---------|---------------|--------|
| {pattern_id} | {count} | {issues} |

**Generic anti-patterns detected:**
{list of generic anti-patterns that should be made specific}

**Recommendations:**
- Replace "{generic}" with codebase-specific rule
- Add anti-patterns to {patterns with < 2}

---

### Pattern Completeness

**Incomplete patterns:**

| Pattern | Missing |
|---------|---------|
| {pattern_id} | {missing_fields} |

**Stale examples (files don't exist):**
- `{pattern_id}`: `{missing_example_file}`

---

### Convention Actionability

**Unclear conventions:**

| Pattern | Issue | Suggestion |
|---------|-------|------------|
| {pattern_id} | {issue} | {suggestion} |

**Incomplete pattern guides:**
- `{pattern_id}`: Has TODO placeholders

---

### Domain Coverage

**Undocumented areas (>20 files):**

| Directory | File Count | Suggestion |
|-----------|------------|------------|
| {path} | {count} | Add as domain or extend existing |

---

### Keyword Coverage

**Unmapped common keywords:**
- `{keyword}` → Consider mapping to `{suggested_pattern}`

---

### Issues Summary

**Errors (must fix):**
{list errors}

**Warnings (should fix):**
{list warnings}

**Info (consider):**
{list info items}

---

### Recommended Actions

1. **High Priority:** {action}
2. **Medium Priority:** {action}
3. **Low Priority:** {action}

Run `/cartographer:capture` to add missing patterns or anti-patterns.
Run `/cartographer:explore --pattern {id}` to complete pattern guides.
```

### 10. Auto-Fix (if --fix)

**Auto-fixable issues:**

| Issue | Fix Action |
|-------|------------|
| Generic anti-pattern | Prompt for codebase-specific replacement |
| Missing example files | Remove from list or find alternatives |
| TODO in pattern guide | Prompt to complete or remove |
| Broken keyword mapping | Remove from index |

**Cannot auto-fix:**
- Missing patterns (requires codebase analysis)
- Unclear conventions (requires human judgment)
- Domain coverage gaps (requires codebase analysis)

---

## Scoring Thresholds

| Aspect | ✅ Good | ⚠️ Warning | ❌ Error |
|--------|---------|------------|----------|
| Anti-pattern quality | >80% specific | 50-80% specific | <50% specific |
| Pattern completeness | All required + recommended | All required | Missing required |
| Convention actionability | All clear | Most clear | Vague/broken |
| Domain coverage | >90% covered | 70-90% covered | <70% covered |
| Keyword coverage | Common keywords mapped | Most mapped | Key keywords missing |

---

## Error Handling

| Error | Action | Recovery |
|-------|--------|----------|
| No atlas | Block with message | Run /cartographer:chart |
| Malformed YAML | Report syntax error | Manual fix |
| Missing files | List missing | Run /cartographer:rechart |

## Responsibilities

**YOU (reviewer):**
- Load all atlas documents
- Analyze quality of each section
- Score against quality criteria
- Generate actionable report
- Apply auto-fixes if requested

**You review atlas quality, not structure. Use /cartographer:validate for structure, /cartographer:calibrate for drift.**
