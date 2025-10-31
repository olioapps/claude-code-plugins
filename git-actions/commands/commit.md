---
allowed-tools: Task, Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(git rev-list:*)
argument-hint: [all|staged] [additional context]
description: Create commits with AI-generated messages (/commit:all or /commit:staged)
---

## Context

Create git commit using `commit-writer` agent.

Arguments: `/commit:$ARGUMENTS`
- **all** - stage all changes, create commit
- **staged** - commit staged changes only
- **(empty)** - default: staged if any exist, else all
- **[additional context]** - optional text after the mode argument for custom instructions

**Examples:**
- `/commit:all` - Standard commit with all changes
- `/commit:staged` - Commit staged changes only
- `/commit:all use conventional commits format` - Override style
- `/commit:staged keep it under 40 chars` - Length constraint
- `/commit:all emphasize performance improvements` - Focus guidance

Current status: !`git status --short`

## Additional Context Handling

**If additional context is provided after the mode argument:**
1. Parse it as custom instructions from the user
2. Pass it to the commit-writer agent with HIGHEST PRIORITY
3. Agent must follow these instructions even if they conflict with defaults
4. Example: User says "no body" → agent must not include body, even for complex changes

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

**YOU invoke the commit-writer agent:**

```
Use commit-writer agent.

Context:
- mode: [staged-only or stage-all based on Step 1]
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
YOU inform user: "Commit cancelled. No changes were committed."
```

## Critical Rules - Separation of Responsibilities

### Command Handler (YOU) Responsibilities:
1. ✅ Stage files (if /commit:all) - requires user approval
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

## Examples

```bash
/commit:all      # Stage all + commit
/commit:staged   # Commit staged only
/commit          # Auto-detect
```

## Error Handling

**Agent fails:** report error, suggest fixes (resolve conflicts, check config), no retry

**No changes:** inform user, skip agent invocation
