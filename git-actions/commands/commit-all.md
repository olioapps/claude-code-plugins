---
allowed-tools: Task, Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(git add:*), Bash(git show:*), AskUserQuestion
argument-hint: [additional context]
description: Stage all changes and create commit with AI-generated message
---

## Context

Arguments: `/git-actions:commit-all [CUSTOM_INSTRUCTIONS]`
- **[additional context]** - custom instructions for agent (highest priority)

**Examples:**
- `/git-actions:commit-all` - Standard commit
- `/git-actions:commit-all use conventional commits` - Override style
- `/git-actions:commit-all keep under 50 chars` - Length constraint

Current: !`git status --short`

## Workflow

### 1. Pre-flight & Validation

**Check repo state:**
```bash
git rev-parse --git-dir 2>/dev/null || echo "NOT_A_REPO"
git status --short
```

**Abort if:**
- Not a git repo → "Error: Not in a git repository"
- Merge/rebase in progress → "Cannot commit: merge/rebase in progress. Complete it first."
- No changes to stage → "Nothing to commit (working tree clean)"

### 2. Stage All Changes

**Use AskUserQuestion to confirm:** "Stage all changes with `git add -A`?"
- If approved → Execute `git add -A`
- Show summary: "Staged X files (+Y -Z lines)"
- If staging fails → Show git error, abort
- If rejected → "Cancelled"

**Verify staged files:**
```bash
git diff --cached --name-status
git diff --cached --stat
```

### 3. Gather Context

```bash
git diff --cached --unified=3 | head -n 300
git log --oneline -10
git branch --show-current
```

**File summary:**
- ≤10 files: list all with status
- >10 files: group by directory/type

### 4. Invoke Agent

```
Use commit-writer agent.

Context:
- mode: all
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
```

**Parse response into SUBJECT, BODY, FOOTER. Validate:**
- [ ] SUBJECT exists and non-empty
- [ ] SUBJECT ≤72 characters (warn if >72, error if >100)
- [ ] No markdown artifacts
- [ ] Body separated from subject by blank line (if exists)

If validation fails → Report parse error, retry (max 2 attempts)

### 5. Present & Approve

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
- **"Approve"** → Execute commit (proceed to Step 6)
- **"Edit manually"** → Prompt user for edited message, re-present
- **"Request changes"** → Ask for feedback, re-invoke agent, re-present
- **"Cancel"** → Abort

### 6. Execute

**On approval:**

```bash
# Construct message using HEREDOC
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
git status --short
git log -1 --format="%H %s"
```
- If hook modified files → "✅ Commit created: [SHA] [subject]\n⚠️ Pre-commit hook modified files (changes included)"
- If no modifications → "✅ Commit created: [SHA] [subject]"

**If pre-commit hook fails:**
- Show hook output verbatim
- Use AskUserQuestion: "Pre-commit hook failed. How to proceed?"
  - "Fix and retry" → Abort, let user fix
  - "Skip hooks (--no-verify)" → Confirm, commit with --no-verify
  - "Cancel" → Abort

**If commit fails (other reasons):**
- Show git error verbatim
- Suggest fixes:
  - "index.lock" → "Try: rm .git/index.lock"
  - "nothing to commit" → "Changes may have been already committed"
  - Other → Show error, suggest checking git status

**On cancel:**
❌ "Cancelled. Files remain staged."

## Responsibilities

**YOU (handler):** check repo, stage files (with approval), gather context, invoke agent, present message, get approval, execute commit, handle errors

**Agent:** analyze changes, generate message matching repo style, return structured output

**Agent does NOT orchestrate or execute. You do NOT format messages.**

## Error Handling

### Pre-flight Errors
- **Not a git repo** → "Error: Not in a git repository"
- **No changes** → "Nothing to commit (working tree clean)"
- **Merge/rebase in progress** → "Cannot commit: merge/rebase in progress"
- **Detached HEAD** → Warn, allow with confirmation

### Staging Errors
- **`git add -A` fails** → Show error, suggest checking permissions
- **Index lock exists** → "Git index locked. Try: rm .git/index.lock"
- **Unreadable files** → Show which files, suggest fixing permissions

### Agent Errors
- **Agent fails** → Report error, offer retry (max 2 attempts)
- **Invalid format** → Parse error, retry with clearer format
- **Very large diffs** → Suggest splitting commits

### Commit Execution Errors
- **Commit fails** → Show git error verbatim
- **Pre-commit hook fails** → Show output, offer fix/skip/cancel
- **Pre-commit hook modifies** → Include in commit, inform user
- **Commit-msg hook rejects** → Show reason, ask how to proceed
- **GPG signing fails** → Show error, suggest checking config

### Safety Guardrails
- **Always** confirm before `git add -A`
- **Always** get approval before executing commit
- **Never** auto-commit without explicit approval
- **Never** skip hooks without user confirmation
- **Always** show what will be committed

## Examples

### Standard Usage

```bash
/git-actions:commit-all              # Stage all, generate message, commit
```

### With Custom Instructions

```bash
/git-actions:commit-all use conventional commits format
# Agent will use feat:/fix: format even if repo doesn't normally

/git-actions:commit-all keep subject under 40 chars, no body
# Forces short subject, omits body

/git-actions:commit-all emphasize security fixes
# Agent highlights security aspects

/git-actions:commit-all be concise, one-line only
# Forces single-line commit
```

### Common Workflows

```bash
# Quick commit workflow
# Make changes...
/git-actions:commit-all
# Review message, approve, done

# With pre-commit hooks
/git-actions:commit-all              # If hook fails, you'll be prompted
# Options: fix code and retry, skip hooks, or cancel

# Custom formatting
/git-actions:commit-all use emoji, fun tone
# Overrides professional tone
```
