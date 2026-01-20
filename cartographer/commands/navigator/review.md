---
allowed-tools: Task, Glob, Grep, Read, Bash(git diff:*), Bash(git log:*), Bash(git status:*), AskUserQuestion
argument-hint: <spec file>
description: Review implementation against spec and patterns
---

## Context

Arguments: `/navigator:review <SPEC_FILE>`
- **<spec_file>** - Path to spec file that was implemented

Current directory: !`pwd`
Current branch: !`git branch --show-current`

## Workflow

### 1. Pre-flight Checks

**Verify atlas exists:**
```bash
test -f ".claude/skills/atlas/references/schema.yaml" && echo "EXISTS" || echo "NOT_FOUND"
```

**If atlas not found:**
```
❌ Atlas required for navigator commands.

Run `/cartographer:chart` to generate an atlas first.
```
**STOP** - Do not proceed without atlas.

**Verify spec file exists:**
```bash
test -f "{spec_file}" && echo "EXISTS" || echo "NOT_FOUND"
```

### 2. Load Context

**Read spec file:**
- Extract success criteria
- Extract pattern guides referenced
- Extract expected files (new and modified)
- Extract composition ID if present

**Load atlas files:**
- `.claude/skills/atlas/references/schema.yaml`
- `.claude/skills/atlas/references/conventions.yaml` - Pattern conventions
- Relevant pattern guides from spec

**Extract from conventions.yaml for each pattern in spec:**
- File conventions (verify files created at correct locations)
- Test conventions (verify tests created)
- Registration steps (verify registration completed)
- Validation commands (run pattern-specific checks)

**Get implementation changes:**
```bash
git diff {base_branch}...HEAD --name-only
git diff {base_branch}...HEAD --stat
```

### 3. Review Against Spec

**Check success criteria:**

For each criterion in spec:
- Verify implementation meets criterion
- Document how it's verified
- Flag any gaps

```markdown
### Success Criteria Review

| Criterion | Status | Evidence |
|-----------|--------|----------|
| {criterion 1} | ✅/❌ | {how verified} |
| {criterion 2} | ✅/❌ | {how verified} |
```

**Check expected files:**

For each file in spec "New Files" / "Existing Files":
- Verify file was created/modified
- Check file follows expected patterns

```markdown
### File Coverage

| Expected | Status | Notes |
|----------|--------|-------|
| {file1} | ✅ Created | Follows pattern |
| {file2} | ✅ Modified | Changes appropriate |
| {file3} | ❌ Missing | Not implemented |
```

### 4. Review Against Patterns

**For each pattern in spec, check against conventions.yaml:**

1. **File Convention Check:**
   - Expected location: `{file_convention from conventions.yaml}`
   - Actual file created: {path} → ✅/❌

2. **Test Convention Check:**
   - Expected test location: `{test_convention}`
   - Test file exists: ✅/❌

3. **Registration Check:**
   - For each registration step in conventions.yaml:
   - {action} in `{file}` → ✅/❌

4. **Pattern Guide Adherence:**
   - Read pattern guide from `patterns/{pattern_id}.md`
   - Check implementation against checklist items
   - Check against codebase template

```markdown
### Pattern Adherence: {pattern_name}

**Conventions checked (from conventions.yaml):**
- [ ] File at correct location (`{file_convention}`) - ✅/❌
- [ ] Test at correct location (`{test_convention}`) - ✅/❌
- [ ] Registration completed in `{registration_file}` - ✅/❌

**Checklist items (from pattern guide):**
- [ ] {Checklist item 1} - ✅/❌
- [ ] {Checklist item 2} - ✅/❌

**Reference implementation comparison:**
- Compared against: `{example_file from conventions.yaml}`
- Follows established patterns: ✅/❌

**Areas for improvement:**
- `{file}:{line}` - {suggestion}
```

### 5. Code Quality Review

**Check implementation quality:**

- **Readability**: Is the code clear and self-documenting?
- **Consistency**: Does it match existing codebase style?
- **Completeness**: Are edge cases handled?
- **Testing**: Are new paths tested?

**Read changed files:**
- Identify potential issues
- Note positive patterns

### 6. Check for Regressions

**Run validation commands from spec:**
```bash
{type_check_command}
{test_command}
{lint_command}
{build_command}
```

**Report results:**
```markdown
### Validation Status

| Check | Status | Details |
|-------|--------|---------|
| Type check | ✅/❌ | {errors if any} |
| Tests | ✅/❌ | {failing tests if any} |
| Lint | ✅/❌ | {violations if any} |
| Build | ✅/❌ | {errors if any} |
```

### 7. Generate Review Report

```markdown
## Navigator Review: {spec_name}

**Spec:** `{spec_file}`
**Branch:** `{current_branch}`
**Base:** `{base_branch}`

---

### Summary

| Category | Score | Details |
|----------|-------|---------|
| Spec Compliance | {A/B/C/F} | {X}/{Y} criteria met |
| Pattern Adherence | {A/B/C/F} | {X}/{Y} conventions followed |
| Code Quality | {A/B/C/F} | {notes} |
| Validation | {A/B/C/F} | {pass/fail counts} |

**Overall Status:** {✅ Ready for PR | ⚠️ Needs attention | ❌ Significant issues}

---

### Detailed Findings

#### ✅ Successes
{list things done well}

#### ⚠️ Suggestions
{list improvement suggestions}

#### ❌ Issues
{list problems that should be fixed}

---

### Success Criteria Status

{table from step 3}

---

### Pattern Adherence Details

{sections from step 4}

---

### Files Changed

```
{git diff stat output}
```

---

### Validation Results

{table from step 6}

---

### Recommendations

{if ready for PR}
**Ready for PR.** No blocking issues found.

Suggested commit message:
```
{suggested commit message based on spec}
```

{if needs attention}
**Address before PR:**
1. {issue 1}
2. {issue 2}

{if significant issues}
**Significant issues found. Please address:**
1. {critical issue 1}
2. {critical issue 2}

Consider running `/navigator:build {spec_file}` again after fixes.
```

---

## Scoring Criteria

### Spec Compliance
- **A**: All success criteria met, all expected files present
- **B**: 80%+ criteria met, most files present
- **C**: 60%+ criteria met, some gaps
- **F**: <60% criteria met or major gaps

### Pattern Adherence
- **A**: All conventions followed, no anti-patterns
- **B**: Most conventions followed, minor deviations
- **C**: Some conventions followed, notable deviations
- **F**: Patterns largely ignored

### Code Quality
- **A**: Clean, readable, well-organized
- **B**: Good quality with minor issues
- **C**: Acceptable but needs improvement
- **F**: Significant quality concerns

### Validation
- **A**: All checks pass
- **B**: Minor warnings only
- **C**: Some failures, non-critical
- **F**: Critical failures

---

## Error Handling

| Error | Action | Recovery |
|-------|--------|----------|
| No atlas | Block with message | Run /cartographer:chart |
| No spec | Error with path | User provides correct path |
| No changes | Note implementation may be missing | Check if on correct branch |
| Validation fails | Report failures | User fixes or accepts |

## Responsibilities

**YOU (reviewer):**
- Load spec and atlas context
- Review implementation against spec criteria
- Check pattern adherence
- Run validations
- Generate comprehensive review report
- Provide clear recommendations

**You are an objective reviewer. Be thorough but constructive.**
