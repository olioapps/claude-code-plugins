<!--
Embedded Navigator Command: plan
Standalone version for plugin-free operation
-->
---
allowed-tools: Task, Glob, Grep, Read, Write, Bash(git branch:*), Bash(git status:*), Bash(test:*), Bash(mkdir:*), AskUserQuestion
argument-hint: <task description>
description: Create implementation spec with atlas context
---

## Context

Arguments: `/spec-plan <TASK_DESCRIPTION>`
- **<task>** - Description of the feature, chore, or bug fix

Current directory: !`pwd`
Current branch: !`git branch --show-current`

## Workflow

### 1. Pre-flight

**Verify atlas exists:**
```bash
test -f ".claude/skills/atlas/references/schema.yaml" && echo "EXISTS" || echo "NOT_FOUND"
```

**If not found:**
```
❌ Atlas required.

Run `/chart` to generate an atlas first.
```
**STOP**

**Create specs directory:**
```bash
mkdir -p specs
```

### 2. Load Atlas Context

Read:
- `.claude/skills/atlas/SKILL.md`
- `.claude/skills/atlas/references/schema.yaml`

Extract domains, patterns, validation commands.

### 3. Analyze Task

**Identify:**
- Task type: feature / chore / bugfix / refactor
- Affected domains (match to atlas)
- Required patterns

**Research:**
- Read relevant domain references
- Find similar implementations
- Check for conflicts

### 4. Capture Git Context

```bash
git branch --show-current  # base branch
```

Generate branch: `{type}/{description}`

### 5. Generate Spec

**Create:** `specs/{task-slug}.md`

```markdown
# {Type}: {Title}

## Prerequisites

{dependencies or "None"}

---

## Branch Information

**Implementation Branch**: `{target_branch}`
**Base Branch**: `{base_branch}`

---

## Task Description

**What**: {what to accomplish}
**Why**: {business value}
**Context**: {background}

**Success Criteria**:
- [ ] {criterion 1}
- [ ] {criterion 2}

---

## Atlas Context

### Relevant Domains
{domains from atlas}

### Pattern Guides
{patterns with conventions}

---

## Relevant Files

### Existing Files
{files to modify}

### New Files
{files to create}

---

## Step-by-Step Tasks

### 1. {Step}
{actions}

### N. Run Validation
Execute validation commands.

---

## Validation Commands

```bash
{commands from schema}
```

---

## Notes

{additional context}
```

### 6. Report

```markdown
## Spec Created

**File:** `specs/{filename}.md`

**Summary:**
- Domains: {list}
- Patterns: {list}
- Steps: {count}

**Next:** `/spec-build specs/{filename}.md`
```
