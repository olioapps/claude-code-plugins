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

## Rules

1. Use Task tool to invoke agent (no direct git commands)
2. Pass mode in agent context
3. Agent executes:
   - analyze changes
   - reference commit-best-practices skill
   - create commit message
   - execute git commit
   - return SHA + summary
4. Wait for agent response

## Examples

```bash
/commit:all      # Stage all + commit
/commit:staged   # Commit staged only
/commit          # Auto-detect
```

## Error Handling

**Agent fails:** report error, suggest fixes (resolve conflicts, check config), no retry

**No changes:** inform user, skip agent invocation
