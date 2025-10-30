---
allowed-tools: Task
argument-hint: [all|staged]
description: Create commits with AI-generated messages (/commit:all or /commit:staged)
---

## Context

Create git commit using `commit-writer` agent.

Arguments: `/commit:$ARGUMENTS`
- **all** - stage all changes, create commit
- **staged** - commit staged changes only
- **(empty)** - default: staged if any exist, else all

Current status: !`git status --short`

## Task

Invoke `commit-writer` agent based on argument:

### all
```
Mode: stage-all
Action: stage all files (git add -A), create commit
Analyze: git diff HEAD
```

### staged
```
Mode: staged-only
Action: create commit (no staging)
Analyze: git diff --staged
```

### (empty)
```bash
# Check staged status
git diff --staged --quiet
# Exit 0 = nothing staged → use "all"
# Exit 1 = has staged → use "staged"
```

## Agent Invocation

**For /commit:all:**
```
Use commit-writer agent.
- stage-all mode
- include untracked files
- analyze: git diff HEAD
```

**For /commit:staged:**
```
Use commit-writer agent.
- staged-only mode
- analyze: git diff --staged
```

## Workflow

### Step 1: Gather File Information

First, gather staged file information to present to the user:

```bash
# Count staged files
git diff --cached --name-only | wc -l

# Get staged files list
git diff --cached --name-only
```

**File Presentation Rules:**
- If ≤10 files: List all files individually
- If >10 files: Summarize by category/directory (e.g., "15 files in src/", "3 config files", etc.)

### Step 2: Generate Commit Message

Invoke `commit-writer` agent to **GENERATE ONLY** (do NOT execute commit):

**For /commit:all:**
```
Use commit-writer agent.
- stage-all mode
- include untracked files
- analyze: git diff HEAD
- GENERATE MESSAGE ONLY - DO NOT EXECUTE GIT COMMIT
- Return the commit message for user review
```

**For /commit:staged:**
```
Use commit-writer agent.
- staged-only mode
- analyze: git diff --staged
- GENERATE MESSAGE ONLY - DO NOT EXECUTE GIT COMMIT
- Return the commit message for user review
```

### Step 3: Present for Verification

Present the generated commit message to the user along with:
1. The commit message (subject + body if any)
2. Staged files list (or summary if >10)
3. File change statistics (+X -Y lines)

Use AskUserQuestion tool with options:
- "Approve and commit" - Execute the commit as-is
- "Edit message" - Allow user to modify the message
- "Cancel" - Abort the commit

### Step 4: Execute or Cancel

**If approved:**
- Execute git commit with the generated message
- Return commit SHA and confirmation

**If edit requested:**
- Prompt user for modified message
- Execute git commit with user's message
- Return commit SHA and confirmation

**If cancelled:**
- Do nothing, inform user commit was cancelled

## Rules

1. **ALWAYS require user verification** - Never auto-commit without approval
2. Use Task tool to invoke commit-writer agent for message generation
3. Agent must generate message only, NOT execute commit
4. Present file list intelligently (full list if ≤10, summary if >10)
5. Use AskUserQuestion for verification
6. Execute commit only after user approval

## Examples

```bash
/commit:all      # Stage all + commit
/commit:staged   # Commit staged only
/commit          # Auto-detect
```

## Error Handling

**Agent fails:** report error, suggest fixes (resolve conflicts, check config), no retry

**No changes:** inform user, skip agent invocation
