---
allowed-tools: Task, Glob, Grep, Read, Write, Edit, Bash, AskUserQuestion
argument-hint: <spec file>
description: Execute spec with atlas pattern guidance (auto-creates implementation branch)
---

## Context

Arguments: `/navigator:build <SPEC_FILE>`
- **<spec_file>** - Path to spec file (e.g., `specs/add-user-profile.md`)

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

If not found → Error: "Spec file not found: {spec_file}"

### 2. Load Context

**Read spec file:**
- Parse all sections
- Extract prerequisites, steps, validation commands
- Identify domains and patterns referenced
- Extract composition ID if present in spec

**Load atlas files:**
- `.claude/skills/atlas/SKILL.md`
- `.claude/skills/atlas/references/schema.yaml`
- `.claude/skills/atlas/references/conventions.yaml` - Pattern conventions
- Relevant domain references (from spec "Atlas Context" section)
- Relevant pattern guides (from spec "Pattern Guides" section)

**Extract from conventions.yaml for each pattern in spec:**
- File conventions (where to create files)
- Test conventions (where to create tests)
- Registration steps (where to wire up new code)
- Validation commands (how to verify each pattern)

### 3. Verify Prerequisites

**Check prerequisite files:**
```bash
test -f "{prerequisite_file}" && echo "✅ EXISTS" || echo "❌ MISSING"
```

**If any missing:**
```
❌ Prerequisites not met

Missing files:
- {file1}
- {file2}

Cannot proceed until prerequisites are resolved.
Options:
1. Complete prerequisite tasks first
2. Skip prerequisites (risky)
3. Abort
```

### 4. Setup Implementation Branch

**Extract branch info from spec:**
- `{target_branch}` - Implementation Branch from spec
- `{base_branch}` - Base Branch from spec

**Check if target branch exists:**
```bash
git rev-parse --verify {target_branch} 2>/dev/null && echo "EXISTS" || echo "NOT_FOUND"
```

**If target branch does NOT exist:**
1. Verify base branch exists:
   ```bash
   git rev-parse --verify {base_branch} 2>/dev/null && echo "EXISTS" || echo "NOT_FOUND"
   ```
   If base branch not found → Error: "Base branch '{base_branch}' does not exist"

2. Create target branch from base branch:
   ```bash
   git checkout -b {target_branch} {base_branch}
   ```

**If target branch EXISTS:**
```bash
git checkout {target_branch}
```

**Verify on correct branch:**
```bash
git branch --show-current
```
Must match `{target_branch}` before proceeding.

**Report branch status:**
```
✅ On branch: {target_branch}
   Based on: {base_branch}
```

### 5. Load Pattern Guidance

**For each pattern in spec, load from conventions.yaml:**
```yaml
{pattern_id}:
  file_convention: "{where to create file}"
  test_convention: "{where to create test}"
  registration:
    - file: "{registration file}"
      action: "{what to do}"
  validation_commands:
    - "{command 1}"
    - "{command 2}"
  example_files:
    - "{reference implementation to study}"
```

**For each pattern guide referenced in spec:**
- Read full pattern guide from `patterns/{pattern_id}.md`
- Extract codebase-specific template
- Extract implementation checklist

**Build guidance context:**
```
When implementing {pattern_name}:

File Conventions (from conventions.yaml):
- Create file at: {file_convention}
- Create test at: {test_convention}

Registration Steps:
- {action} in {file}

Reference Implementation:
- Study: {example_file}

Checklist (from pattern guide):
- [ ] {checklist item 1}
- [ ] {checklist item 2}
```

### 6. Execute Steps

**For each step in spec:**

1. **Announce step:**
   ```
   ### Step {N}: {Step Title}
   ```

2. **Load relevant context:**
   - Read files mentioned in step
   - Apply pattern guidance from conventions.yaml
   - Study example_files if implementing new pattern

3. **Implement changes:**
   - Follow spec instructions precisely
   - Use file_convention from conventions.yaml for new files
   - Use test_convention for test files
   - Adhere to pattern conventions from pattern guide
   - Write clean, documented code

4. **Complete registration steps:**
   - For each registration in conventions.yaml for this pattern
   - Perform {action} in {file}

5. **Verify step completion:**
   - Check expected outcome
   - Run pattern-specific validation_commands from conventions.yaml
   - Fix any issues before proceeding

6. **Report progress:**
   ```
   ✅ Step {N} complete: {brief summary}
   - Files created: {list}
   - Registration: {completed steps}
   - Validation: {pass/fail}
   ```

**If step fails:**
- Report specific error
- Attempt recovery if possible
- Ask user how to proceed if blocked

### 7. Run Validation

**Execute validation commands from spec:**

```bash
{type_check_command}
```
- If fails → Report errors, attempt fixes, re-run

```bash
{test_command}
```
- If fails → Report failing tests, attempt fixes, re-run

```bash
{lint_command}
```
- If fails → Apply lint fixes, re-run

```bash
{build_command}
```
- If fails → Report build errors, attempt fixes

**Validation loop:**
- Max 3 attempts per validation step
- Report each attempt result
- If still failing after 3 attempts, ask user

### 8. Final Verification

**Check success criteria from spec:**
- [ ] Criterion 1 - verified how
- [ ] Criterion 2 - verified how
- [ ] Criterion 3 - verified how

**Review pattern adherence:**
- Did implementation follow documented patterns?
- Any deviations? (document if intentional)

### 9. Report Results

```markdown
## Build Complete

**Spec:** `{spec_file}`
**Branch:** `{current_branch}`

### Steps Completed
{list each step with status}

### Files Modified
{list files created/modified}

### Validation Results
- Type check: ✅ Pass
- Tests: ✅ Pass ({count} tests)
- Lint: ✅ Pass
- Build: ✅ Pass

### Success Criteria
{list each criterion with ✅/❌}

### Pattern Adherence
{note any deviations from patterns}

### Next Steps
1. Run `/navigator:review {spec_file}` for quality review
2. Commit changes: `/git-actions:commit`
3. Create PR: `/git-actions:pr-write`
```

---

## Step Execution Protocol

For each implementation step:

1. **Read before write** - Always read existing files first
2. **Follow patterns** - Check pattern guide before writing
3. **Small changes** - Make incremental changes, not massive edits
4. **Verify as you go** - Don't wait until end to find issues
5. **Document deviations** - If you must deviate from pattern, note why

---

## Handling Blockers

| Blocker | Action |
|---------|--------|
| File not found | Check path, ask user if truly missing |
| Pattern unclear | Read pattern guide, ask for clarification |
| Test failure | Analyze error, fix, re-run |
| Build failure | Check error, fix dependencies/types |
| Conflicting instructions | Ask user which to prioritize |

---

## Error Handling

| Error | Action | Recovery |
|-------|--------|----------|
| No atlas | Block with message | Run /cartographer:chart |
| No spec | Error with path | User provides correct path |
| Prerequisites missing | Block with list | User resolves or overrides |
| Step failure | Report, attempt fix | Ask user if stuck |
| Validation failure | Fix and retry | Ask user after 3 attempts |

## Responsibilities

**YOU (handler):**
- Load all context (spec, atlas, patterns)
- Verify prerequisites
- Execute steps with pattern guidance
- Run validations and fix issues
- Report comprehensive results

**You are the implementer. Follow the spec precisely while adhering to atlas patterns.**
