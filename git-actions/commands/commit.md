---
allowed-tools: Task, Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(git show:*), AskUserQuestion
argument-hint: [all|staged] [additional context]
description: Create commits with AI-generated messages
---

## Context

Arguments: `/git-actions:commit [MODE] [CUSTOM_INSTRUCTIONS]`
- **all** - stage all changes then commit
- **staged** - commit staged changes only
- **(empty)** - auto-detect: staged if any exist, else prompt for all mode
- **[additional context]** - custom instructions for agent (highest priority)

Current: !`git status --short`

## Workflow

### 1. Pre-flight & Mode Selection

**Check repo state:**
```bash
git rev-parse --git-dir 2>/dev/null || echo "NOT_A_REPO"
git status --short
git diff --cached --quiet && echo "NO_STAGED" || echo "HAS_STAGED"
git diff --quiet && echo "NO_UNSTAGED" || echo "HAS_UNSTAGED"
```

**Abort if:**
- Not a git repo → "Error: Not in a git repository"
- Merge/rebase in progress → "Cannot commit: merge/rebase in progress. Complete it first."
- No changes at all → "Nothing to commit (working tree clean)"

**Determine mode from first argument, extract any additional context from remaining args.**

**Execute mode:**

- **`all` mode:** Use AskUserQuestion to confirm "Stage all changes with `git add -A`?"
  - If approved → Execute `git add -A`
  - Show summary: "Staged X files (+Y -Z lines)"
  - If staging fails → Show git error, abort

- **`staged` mode:** Verify staged files exist with `git diff --cached --quiet`
  - If none → Error: "No staged changes. Use '/git-actions:commit all' or stage files manually"
  - If exist → Proceed to Step 2

- **`(empty)` auto-detect:**
  - If staged changes exist → Use staged mode
  - Else if unstaged changes exist → Use AskUserQuestion: "No staged changes. Stage all and commit?"
    - If yes → Switch to all mode (with confirmation)
    - If no → "Cancelled. Stage files manually or use '/git-actions:commit all'"
  - Else → Error: "Nothing to commit"

### 2. Gather Context

```bash
git diff --cached --name-status
git diff --cached --stat  
git diff --cached --unified=3 | head -n 300  # truncate if needed
```

**File summary:**
- ≤10 files: list all with status
- \>10 files: group by directory/type/change-type

### 3. Invoke Agent

```
Use commit-writer agent.

Context:
- mode: [staged/all]
- files: [summary]
- stats: [+X -Y lines]
- diff: [truncated preview]

[IF USER PROVIDED CUSTOM INSTRUCTIONS:]
USER INSTRUCTIONS (HIGHEST PRIORITY):
"""
[custom instructions verbatim]
"""

Agent returns structured output:
---SUBJECT---
[subject]
---BODY---
[body or empty]
---FOOTER---
[footer or empty]
---END---

Agent responsibilities: analyze changes, match repo style, generate message, warn if non-atomic
```

**Parse response into SUBJECT, BODY, FOOTER. Validate:**
- [ ] SUBJECT exists and is non-empty
- [ ] SUBJECT ≤72 characters (warn if >72, continue if ≤100, error if >100)
- [ ] No markdown artifacts in output (triple backticks, horizontal rules, headers)
- [ ] Body separated from subject by blank line (if body exists)

If validation fails → Report parse error, ask agent to retry with clearer format (max 2 retries)

### 4. Present & Approve

```markdown
## Proposed Commit

**Subject:** [subject]
[**Body:** [body] if exists]
[**Footer:** [footer] if exists]

**Files:** [summary] ([stats])
[⚠️ **Non-atomic warning** if flagged by agent]
```

**Use AskUserQuestion:** "How to proceed with this commit?"

Options:
- **"Approve"** → Execute commit with this message (proceed to Step 5)
- **"Edit manually"** → Prompt user to provide edited message text, re-present for final confirmation
- **"Request changes"** → Ask: "What changes would you like?" → Re-invoke agent with user feedback → Re-present
- **"Cancel"** → Abort without committing

### 5. Execute

**On approval:**

```bash
# Construct message using HEREDOC for proper formatting
git commit -m "$(cat <<'EOF'
[SUBJECT]

[BODY if exists]

[FOOTER if exists]
EOF
)"
```

**Check commit result and handle hooks:**

**If commit succeeds:**
```bash
# Check if pre-commit hook modified files
git status --short
git log -1 --format="%H %s"
```
- If hook modified files → Inform user: "✅ Commit created: [SHA] [subject]\n⚠️ Note: Pre-commit hook modified files (changes included in commit)"
- If no modifications → "✅ Commit created: [SHA] [subject]"

**If pre-commit hook fails:**
- Show hook output verbatim
- Use AskUserQuestion: "Pre-commit hook failed. How to proceed?"
  - "Fix and retry" → Abort, let user fix, they can re-run command
  - "Skip hooks (--no-verify)" → Ask confirmation, then commit with --no-verify
  - "Cancel" → Abort

**If commit fails (other reasons):**
- Show git error verbatim
- Suggest fixes based on error pattern:
  - "index.lock" → "Try: rm .git/index.lock"
  - "nothing to commit" → "Changes may have been already committed"
  - Other → Show error, suggest checking git status

**On cancel:**
❌ "Cancelled. Files remain staged." (if mode was 'all', files are still staged)

## Responsibilities

**YOU (handler):** check repo, parse args, stage files (with approval), gather context, invoke agent, present message, get user approval, execute commit, handle errors

**Agent:** analyze changes, generate message matching repo style, return structured output

**Agent does NOT orchestrate or execute. You do NOT format messages.**

## Error Handling

### Pre-flight Errors
- **Not a git repo** → "Error: Not in a git repository"
- **No changes to commit** → "Nothing to commit (working tree clean)"
- **Merge/rebase in progress** → "Cannot commit: merge/rebase in progress. Complete it first."
- **Detached HEAD** → Warn user but allow commit with confirmation

### Staging Errors (all mode)
- **`git add -A` fails** → Show git error, suggest checking .gitignore or file permissions
- **Index lock exists** → "Git index is locked. Try: rm .git/index.lock"
- **Unreadable files** → Show which files, suggest fixing permissions

### Agent Errors
- **Agent fails to respond** → Report error, offer retry (max 2 attempts)
- **Agent returns invalid format** → Parse error, request retry with clearer format instructions
- **Agent cannot parse diff** → For very large diffs (>1000 files), suggest splitting commits

### Commit Execution Errors
- **Commit command fails** → Show git error verbatim
- **Pre-commit hook fails** → Show hook output, offer fix/skip/cancel options
- **Pre-commit hook modifies files** → Include in commit, inform user
- **Commit-msg hook rejects** → Show rejection reason, ask how to proceed
- **GPG signing fails** → Show GPG error, suggest checking signing config

### Safety Guardrails
- **Always** confirm before `git add -A`
- **Always** get user approval before executing commit
- **Never** auto-commit without explicit approval
- **Never** skip hooks without user confirmation
- **Always** show what will be committed before committing

## Examples

### Standard Usage

```bash
/git-actions:commit all              # Stage all changes, generate message, commit
/git-actions:commit staged           # Commit only staged files
/git-actions:commit                  # Auto-detect: staged if any, else prompt for all
```

### With Custom Instructions (Override Defaults)

Custom instructions have **highest priority** and override all agent defaults:

```bash
/git-actions:commit all use conventional commits format
# Agent will use feat:/fix:/etc. format even if repo doesn't normally

/git-actions:commit staged keep subject under 40 chars, no body
# Forces short subject, omits body even for complex changes

/git-actions:commit all emphasize security fixes in message
# Agent will highlight security aspects in commit message

/git-actions:commit staged include performance metrics in body
# Agent will add performance details to commit body

/git-actions:commit all be concise, one-line only
# Forces single-line commit (no body/footer)
```

### Common Workflows

```bash
# Partial staging workflow (commit specific files only)
git add src/auth/*.ts                # Stage specific files manually
/git-actions:commit staged           # Commit just those files
# Result: atomic commit for auth changes only

# Quick fixes
/git-actions:commit all quick typo fix
# Custom context helps agent write appropriate message

# Working with pre-commit hooks
/git-actions:commit all              # If hook fails, you'll be prompted
# Options: fix code and retry, skip hooks, or cancel

# Multiple small commits from staging
git add file1.ts
/git-actions:commit staged           # First atomic commit
git add file2.ts file3.ts
/git-actions:commit staged           # Second atomic commit
```

### Edge Cases

```bash
# Empty mode with mixed changes
/git-actions:commit                  # Detects: staged exist → commits staged only
/git-actions:commit                  # Detects: no staged → prompts "Stage all?"

# Very large changesets
/git-actions:commit all              # Agent may warn: "Consider splitting commits"
# You can still proceed or split manually

# Custom formatting requirements
/git-actions:commit staged use emoji, fun tone
# Overrides professional tone, adds emoji to message
```