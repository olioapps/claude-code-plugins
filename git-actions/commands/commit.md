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

**YOU (the command handler) orchestrate the entire commit workflow. The commit-writer agent ONLY generates messages, it does NOT execute commits.**

Determine mode based on argument:
- `all` → Stage all files, then generate message
- `staged` → Use already-staged files, generate message
- `(empty)` → Auto-detect (check if files are staged, use appropriate mode)

Then follow the workflow below step-by-step.

## Workflow - FOLLOW EXACTLY

### Step 1: Stage Files (if mode is "all")

**If /commit:all:**
```bash
git add -A
```

**If /commit:staged:**
Skip staging - use what's already staged

**If /commit (no args):**
Check if files are staged, then decide

### Step 2: Gather File Information

**YOU gather this information using Bash tool:**

```bash
# Get list of staged files
git diff --cached --name-only

# Get change stats
git diff --cached --stat
```

**Prepare file summary:**
- If ≤10 files: List all individually
- If >10 files: Summarize by category (e.g., "12 files in git-actions/", "3 config files")

### Step 3: Generate Commit Message (Agent)

**YOU invoke the commit-writer agent with EXPLICIT instructions:**

```
CRITICAL: GENERATE MESSAGE ONLY - DO NOT EXECUTE GIT COMMIT

Mode: [staged-only or stage-all based on Step 1]
Action: Analyze changes and generate commit message
Analyze: git diff --staged

YOU MUST ONLY:
1. Run git status and git diff --staged
2. Review recent commits (git log --oneline -10)
3. Generate a commit message following best practices
4. Return ONLY the message in this format:

## Generated Commit Message

Subject: [subject line]

Body:
[body paragraphs if needed]

Footer:
[footer if needed]

DO NOT run git add
DO NOT run git commit
DO NOT execute any git commands that modify the repository
ONLY return the generated message
```

### Step 4: Present for User Approval

**YOU present the message to the user:**

Display:
```markdown
## Proposed Commit

**Subject:** [subject line from agent]

**Body:**
[body if any]

**Files to be committed:**
[list or summary from Step 2]

**Change stats:** +X -Y lines
```

**YOU use AskUserQuestion tool:**
```
Options:
- "Approve and commit" → Proceed with commit
- "Request changes" → Ask user for feedback, re-invoke agent
- "Cancel" → Abort
```

### Step 5: Execute Based on User Decision

**If "Approve and commit":**
```bash
# YOU execute the commit using Bash tool
git commit -m "$(cat <<'EOF'
[subject line from agent]

[body from agent if any]

[footer from agent if any]
EOF
)"

# Get the SHA
git log -1 --format=%H

# Inform user of success with SHA
```

**If "Request changes":**
```
1. YOU ask user: "What changes would you like to the commit message?"
2. YOU re-invoke commit-writer agent with:
   - Same change analysis
   - User's feedback included
   - GENERATE MESSAGE ONLY (still no execution)
3. Return to Step 4 (present new message for approval)
```

**If "Cancel":**
```
YOU inform user: "Commit cancelled. No changes were committed."
```

## Critical Rules - Separation of Responsibilities

### Command Handler (YOU) Responsibilities:
1. ✅ Stage files (if /commit:all)
2. ✅ Gather file information and stats
3. ✅ Invoke commit-writer agent with "GENERATE ONLY" instructions
4. ✅ Present message to user for approval
5. ✅ Use AskUserQuestion for verification
6. ✅ Execute `git commit` ONLY after user approves
7. ✅ Handle change requests by re-invoking agent
8. ✅ Report final commit SHA

### Commit-Writer Agent Responsibilities:
1. ✅ Analyze git changes (status, diff, log)
2. ✅ Generate commit message following best practices
3. ✅ Return ONLY the message (no execution)
4. ❌ NEVER stage files
5. ❌ NEVER execute git commit
6. ❌ NEVER modify the repository

### CRITICAL: Two-Phase Workflow
**Phase 1 - Generation:** Agent generates → returns message
**Phase 2 - Approval:** User approves → Command executes

**NEVER allow the agent to execute commits directly.**

## Examples

```bash
/commit:all      # Stage all + commit
/commit:staged   # Commit staged only
/commit          # Auto-detect
```

## Error Handling

**Agent fails:** report error, suggest fixes (resolve conflicts, check config), no retry

**No changes:** inform user, skip agent invocation
