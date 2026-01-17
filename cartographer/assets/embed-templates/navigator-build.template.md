<!--
Embedded Navigator Command: build
Standalone version for plugin-free operation
-->
---
allowed-tools: Task, Glob, Grep, Read, Write, Edit, Bash, AskUserQuestion
argument-hint: <spec file>
description: Execute spec with atlas pattern guidance
---

## Context

Arguments: `/spec-build <SPEC_FILE>`
- **<spec_file>** - Path to spec file

Current directory: !`pwd`
Current branch: !`git branch --show-current`

## Workflow

### 1. Pre-flight

**Verify atlas:**
```bash
test -f ".claude/skills/atlas/references/schema.yaml" && echo "EXISTS" || echo "NOT_FOUND"
```

**Verify spec:**
```bash
test -f "{spec_file}" && echo "EXISTS" || echo "NOT_FOUND"
```

### 2. Load Context

**Read spec:**
- Parse prerequisites, steps, validation
- Get domains and patterns referenced

**Load atlas:**
- SKILL.md and schema.yaml
- Relevant domain references
- Relevant pattern guides

### 3. Verify Prerequisites

Check all prerequisite files exist.

If missing → Block or ask to skip.

Check branch matches expected.

### 4. Load Pattern Guidance

For each pattern guide:
- Read conventions
- Note anti-patterns

Build guidance context for implementation.

### 5. Execute Steps

For each step:

1. **Announce:** "### Step N: {Title}"
2. **Load context:** Read relevant files
3. **Implement:** Follow spec + patterns
4. **Verify:** Check outcome
5. **Report:** "✅ Step N complete"

If step fails: Report error, attempt recovery, ask if blocked.

### 6. Run Validation

Execute validation commands:
```bash
{type_check}
{tests}
{lint}
{build}
```

**Loop:** Max 3 attempts per validation. Fix and retry.

### 7. Final Verification

Check success criteria from spec.
Review pattern adherence.

### 8. Report

```markdown
## Build Complete

**Spec:** `{spec_file}`

### Steps Completed
{list}

### Files Modified
{list}

### Validation
- Type check: ✅
- Tests: ✅
- Lint: ✅
- Build: ✅

### Success Criteria
{list with status}

### Next Steps
1. `/spec-review {spec_file}`
2. Commit changes
3. Create PR
```
