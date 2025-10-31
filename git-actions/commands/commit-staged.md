---
allowed-tools: Task, Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(git rev-list:*)
argument-hint: [additional context]
description: Create a commit with AI-generated message for staged changes only
---

## Context

Create git commit using **only staged changes** and generating an AI-powered commit message using the `commit-writer` agent.

Arguments: `/git-actions:commit-staged $ARGUMENTS`
- **[additional context]** - optional text for custom instructions (e.g., "use conventional commits format", "keep it under 40 chars")

**Examples:**
- `/git-actions:commit-staged` - Standard commit with staged changes
- `/git-actions:commit-staged use conventional commits format` - Override style
- `/git-actions:commit-staged emphasize performance improvements` - Focus guidance

Current status: !`git status --short`

## Additional Context Handling

**If additional context is provided:**
1. Parse it as custom instructions from the user
2. Pass it to the commit-writer agent with HIGHEST PRIORITY
3. Agent must follow these instructions even if they conflict with defaults
4. Example: User says "no body" → agent must not include body, even for complex changes

## Task

**YOU (the command handler) orchestrate the entire commit workflow. The commit-writer agent ONLY generates messages, it does NOT execute commits.**

This command will:
1. Verify staged changes exist
2. Generate a commit message via the agent
3. Present for user approval
4. Execute the commit if approved

## Workflow - FOLLOW EXACTLY

### Step 1: Verify Staged Changes

**YOU check for staged changes using the Bash tool:**

```bash
# Check if any files are staged
git diff --cached --name-only
```

**Error Handling:**
- If no staged changes exist, inform user: "No staged changes to commit. Use `/git-actions:commit-all` to stage and commit all changes, or stage files manually first."
- If check fails, report the error and exit

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

**YOU invoke the commit-writer agent:**

```
Use commit-writer agent.

Context:
- mode: staged-only
- action: generate commit message

[IF ADDITIONAL CONTEXT WAS PROVIDED:]
ADDITIONAL CONTEXT (HIGHEST PRIORITY - OVERRIDES ALL DEFAULTS):
[insert additional context here]

The commit-writer agent will:
- Gather all necessary git context
- Analyze changes for atomicity and purpose
- Match repository commit style conventions
- Generate concise, information-dense commit message
- Return structured message (subject, body, footer)

YOU (command handler) do NOT need to know how the agent formats commits.
The agent owns all message generation logic.
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
YOU inform user: "Commit cancelled. Staged changes remain staged."
```

## Critical Rules - Separation of Responsibilities

### Command Handler (YOU) Responsibilities:
1. ✅ Verify staged changes exist
2. ✅ Gather file information and stats
3. ✅ Invoke commit-writer agent with context
4. ✅ Present message to user for approval
5. ✅ Use AskUserQuestion for verification
6. ✅ Execute `git commit` ONLY after user approves
7. ✅ Handle change requests by re-invoking agent
8. ✅ Report final commit SHA

### Commit-Writer Agent Responsibilities:
1. ✅ All message generation (subject, body, footer, formatting)
2. ✅ Commit style matching and best practices application
3. ✅ Atomicity analysis and recommendations
4. ✅ Return structured message output

**The agent has ZERO orchestration responsibilities. You have ZERO message formatting knowledge.**

### Two-Phase Workflow
**Phase 1 - Generation:** Agent analyzes and generates → returns message
**Phase 2 - Approval:** User approves → Command executes `git commit`

## Error Handling

**Agent fails:** report error, suggest fixes (resolve conflicts, check config), no retry

**No staged changes:** inform user with suggestion to use `/git-actions:commit-all` or stage files manually

**Verification fails:** report error details, exit workflow
