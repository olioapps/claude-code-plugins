---
allowed-tools: Task, Glob, Grep, Read, Write, Bash(git branch:*), Bash(git status:*), Bash(test:*), Bash(mkdir:*), AskUserQuestion
argument-hint: <task description> [--base-branch <branch>]
description: Create implementation spec with atlas context
---

## Context

Arguments: `/navigator:plan <TASK_DESCRIPTION> [OPTIONS]`
- **<task>** - Description of the feature, chore, or bug fix to plan
- **--base-branch <branch>** - Branch to base implementation on (default: current branch)

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

Navigator commands use the atlas for:
- Identifying relevant files and patterns
- Ensuring adherence to codebase conventions
- Mapping task requirements to existing code

Run `/cartographer:chart` to generate an atlas first.
```
**STOP** - Do not proceed without atlas.

**Check atlas freshness:**
- Read schema.yaml "Last Updated" timestamp
- If >30 days old, warn: "⚠️ Atlas may be outdated. Consider `/cartographer:calibrate`"

**Create specs directory:**
```bash
mkdir -p specs
```

### 2. Load Atlas Context

**Read atlas files:**
- `.claude/skills/atlas/SKILL.md` - Domain and pattern routers
- `.claude/skills/atlas/references/schema.yaml` - Full structure
- `.claude/skills/atlas/references/conventions.yaml` - Pattern conventions and keywords
- `.claude/skills/atlas/references/compositions.yaml` - Multi-pattern sequences

**Extract from schema.yaml:**
- Domain list with purposes
- File patterns
- Task mappings
- Validation commands

**Extract from conventions.yaml:**
- `keyword_index` - Maps task keywords to pattern IDs
- Pattern-specific file conventions
- Pattern-specific validation commands
- Registration steps per pattern

**Extract from compositions.yaml:**
- Multi-pattern task sequences (e.g., `add_api_endpoint`)
- Pattern ordering and conditions
- Validation sequences

### 3. Analyze Task

**Parse task description to identify:**
- Task type: feature / chore / bugfix / refactor
- Affected domains (match keywords to atlas)
- Required patterns (match task to pattern router)
- Complexity estimate: small / medium / large

**Use conventions.yaml keyword_index:**
- Extract keywords from task description
- Look up each keyword in `keyword_index` to find pattern IDs
- Example: "add user endpoint" → keywords ["endpoint", "user"] → patterns ["controllers", "providers"]

**Use compositions.yaml for multi-pattern tasks:**
- Check if matched patterns suggest a composition
- Example: patterns ["controllers", "providers", "data_access"] → composition "add_api_endpoint"
- Extract ordered pattern sequence with conditions

**Use atlas domain router:**
- Match task keywords to domains
- Identify primary and secondary domains

**Use atlas pattern router:**
- Match task type to relevant patterns
- Load pattern references for conventions

### 4. Research Codebase

**For each identified domain:**
- Read domain reference file
- Identify key files relevant to task
- Note existing patterns and conventions

**Look for similar implementations:**
- Search for related features
- Identify code to reference or extend

**Check for potential conflicts:**
- Files that might be affected
- Dependencies to consider

### 5. Capture Git Context

**Determine base branch:**
- If `--base-branch` argument provided → use that value
- Otherwise → use current branch:
  ```bash
  git branch --show-current  # base_branch
  ```

**Verify base branch exists:**
```bash
git rev-parse --verify {base_branch} 2>/dev/null && echo "EXISTS" || echo "NOT_FOUND"
```
If not found → Error: "Base branch '{base_branch}' does not exist"

**Generate target branch name:**
- Format: `{type}/{concise-description}`
- Types: `feature/`, `chore/`, `fix/`, `refactor/`
- Example: `feature/add-user-profile-page`

### 6. Generate Spec

**Create spec file:** `specs/{task-slug}.md`

```markdown
# {Task Type}: {Clear, Concise Title}

## Prerequisites

{IF prerequisites exist:}
**⚠️ This task has dependencies that must be completed first.**

### Required Files
{List files that MUST exist before implementation}

### Prerequisite Tasks
{List other specs/tasks that must be completed first}

{IF no prerequisites:}
**None** - This task has no dependencies and can be implemented immediately.

---

**⛔ DO NOT proceed until all prerequisites are verified.**

---

## Branch Information

**Implementation Branch**: `{target_branch_name}`

**Base Branch**: `{base_branch_name}`
Compare implementation branch against this branch when reviewing changes.

---

## Task Description

**What**: {What needs to be accomplished}

**Why**: {Business value or technical reason}

**Context**: {Relevant background information}

**Success Criteria**:
- [ ] {Criterion 1}
- [ ] {Criterion 2}
- [ ] {Criterion 3}

---

## Atlas Context

### Relevant Domains
{List domains from atlas with paths}

### Pattern Sequence
{IF composition matched from compositions.yaml:}
**Composition:** `{composition_id}` - {composition_description}

| Order | Pattern | Condition | File Convention |
|-------|---------|-----------|-----------------|
| 1 | {pattern_id} | {condition} | `{file_convention from conventions.yaml}` |
| 2 | {pattern_id} | {condition} | `{file_convention from conventions.yaml}` |
| ... | ... | ... | ... |

{IF no composition matched:}
**Patterns involved:** {list of matched patterns}

### File Conventions (from conventions.yaml)
{For each pattern involved:}
**{pattern_id}:**
- File: `{file_convention}`
- Test: `{test_convention}`

### Registration Steps (from conventions.yaml)
{For each pattern with registration:}
- [ ] {action} in `{file}`

### Pattern Guides
Review these pattern guides before implementing:
{List relevant patterns with links to patterns/*.md}

---

## Relevant Files

### Existing Files
{List files with brief explanation of relevance}

### New Files (derived from file conventions)
{List files that will be created based on conventions.yaml file_convention}

---

## Step-by-Step Tasks

**⚠️ Execute steps in order from top to bottom.**

### 1. {First Major Step}
- {Specific action item}
- {Another specific action}
- {Details about implementation}

### 2. {Second Major Step}
- {Specific action item}
- {Expected outcome}

{Continue with numbered steps}

### N. Run Validation
- Execute all commands in "Validation Commands" section
- Verify zero errors and regressions

---

## Validation Commands

**Execute ALL commands to confirm completion with zero regressions.**

### Global Validation (from schema.yaml)
```bash
{working_dir_command}
{type_check_command}
{lint_command}
{build_command}
```

### Pattern-Specific Validation (from conventions.yaml)
{For each pattern involved, list its validation_commands:}
**{pattern_id}:**
```bash
{validation_command_1}
{validation_command_2}
```

{IF composition matched, include validation_sequence:}
### Composition Validation Sequence
```bash
{validation_sequence from compositions.yaml}
```

**Expected Result**: All commands complete successfully with no errors.

---

## Notes

{Optional: Additional context, gotchas, helpful tips}
```

### 7. Report Results

```markdown
## Spec Created

**File:** `specs/{filename}.md`

**Summary:**
- Task type: {type}
- Domains involved: {list}
- Composition matched: {composition_id or "None"}
- Pattern sequence: {ordered list of patterns}
- Pattern guides referenced: {list}
- Implementation steps: {count}
- Estimated files to modify: {count}

**Branch information:**
- Base: `{base_branch}`
- Implementation: `{target_branch}`

**Next steps:**
1. Review spec for accuracy
2. Run `/navigator:build specs/{filename}.md` to execute
   - Build will automatically create and checkout the implementation branch
```

---

## Spec Quality Checklist

Before finalizing spec:
- [ ] Prerequisites section is complete (or marked "None")
- [ ] All relevant domains from atlas are listed
- [ ] Pattern guides are referenced with specific conventions
- [ ] Steps are specific and actionable
- [ ] Validation commands are from atlas schema
- [ ] Success criteria are measurable

---

## Error Handling

| Error | Action | Recovery |
|-------|--------|----------|
| No atlas | Block with message | Run /cartographer:chart |
| Atlas stale | Warn, continue | Suggest /cartographer:calibrate |
| No domains match | Ask for clarification | User provides more context |
| Spec exists | Prompt for action | Overwrite / rename / view existing |

## Responsibilities

**YOU (handler):**
- Verify atlas exists
- Load atlas context
- Analyze task against atlas
- Research codebase for relevant files
- Generate comprehensive spec
- Report results with next steps

**You use the atlas as your primary navigation aid. Do not explore without it.**
