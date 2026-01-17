---
allowed-tools: Task, Glob, Grep, Read, Write, Edit, Bash, AskUserQuestion
argument-hint: <spec file>
description: Execute spec with atlas pattern guidance
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

**Load atlas files:**
- `.claude/skills/atlas/SKILL.md`
- `.claude/skills/atlas/references/schema.yaml`
- Relevant domain references (from spec "Atlas Context" section)
- Relevant pattern guides (from spec "Pattern Guides" section)

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

**Check branch:**
```bash
git branch --show-current
```

If not on expected branch:
```
⚠️ Expected branch: {target_branch}
   Current branch: {current_branch}

Options:
1. Create/switch to expected branch
2. Continue on current branch
3. Abort
```

### 4. Load Pattern Guidance

**For each pattern guide referenced in spec:**
- Read full pattern guide
- Extract conventions to follow
- Note anti-patterns to avoid

**Build guidance context:**
```
When implementing, follow these patterns:

{pattern_name}:
- Convention: {convention}
- Example: {example}
- Anti-pattern: {avoid}
```

### 5. Execute Steps

**For each step in spec:**

1. **Announce step:**
   ```
   ### Step {N}: {Step Title}
   ```

2. **Load relevant context:**
   - Read files mentioned in step
   - Apply pattern guidance

3. **Implement changes:**
   - Follow spec instructions precisely
   - Adhere to pattern conventions
   - Write clean, documented code

4. **Verify step completion:**
   - Check expected outcome
   - Run quick validation if applicable

5. **Report progress:**
   ```
   ✅ Step {N} complete: {brief summary}
   ```

**If step fails:**
- Report specific error
- Attempt recovery if possible
- Ask user how to proceed if blocked

### 6. Run Validation

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

### 7. Final Verification

**Check success criteria from spec:**
- [ ] Criterion 1 - verified how
- [ ] Criterion 2 - verified how
- [ ] Criterion 3 - verified how

**Review pattern adherence:**
- Did implementation follow documented patterns?
- Any deviations? (document if intentional)

### 8. Report Results

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
