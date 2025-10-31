---
allowed-tools: Task, Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(git show:*), AskUserQuestion
argument-hint: [additional context]
description: Create commit with AI-generated message for staged changes only
---

## Context

Arguments: `/git-actions:commit-staged [CUSTOM_INSTRUCTIONS]`
- **[additional context]** - custom instructions for agent (highest priority)

**Examples:**
- `/git-actions:commit-staged` - Standard commit
- `/git-actions:commit-staged use conventional commits` - Override style
- `/git-actions:commit-staged max 50 chars no body` - Length constraint

Current: !`git status --short`

## Workflow

### 1. Pre-flight & Validation

**Check repo state:**
```bash
git rev-parse --git-dir 2>/dev/null || echo "NOT_A_REPO"
git status --short
git diff --cached --quiet && echo "NO_STAGED" || echo "HAS_STAGED"
```

**Abort if:**
- Not a git repo → "Error: Not in a git repository"
- Merge/rebase in progress → "Cannot commit: merge/rebase in progress. Complete it first."
- No staged changes → "No staged changes to commit. Use '/git-actions:commit-all' or stage files manually."

### 2. Gather Context

```bash
git diff --cached --name-status
git diff --cached --stat
git diff --cached --unified=3 | head -n 300
git log --oneline -10
git branch --show-current
```

**File summary:**
- ≤10 files: list all with status
- >10 files: group by directory/type

### 3. Invoke Agent

```
Use commit-writer agent.

Context:
- mode: staged
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
- **"Approve"** → Execute commit (proceed to Step 5)
- **"Edit manually"** → Prompt user for edited message, re-present
- **"Request changes"** → Ask for feedback, re-invoke agent, re-present
- **"Cancel"** → Abort

### 5. Execute

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
❌ "Cancelled. Staged changes remain staged."

## Responsibilities

**YOU (handler):** check repo, verify staged files exist, gather context, invoke agent, present message, get approval, execute commit, handle errors

**Agent:** analyze changes, generate message matching repo style, return structured output

**Agent does NOT orchestrate or execute. You do NOT format messages.**

## Error Handling

### Pre-flight Errors
- **Not a git repo** → "Error: Not in a git repository"
- **No staged changes** → "No staged changes. Use '/git-actions:commit-all' or stage files manually."
- **Merge/rebase in progress** → "Cannot commit: merge/rebase in progress"
- **Detached HEAD** → Warn, allow with confirmation

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
- **Always** verify staged files exist before proceeding
- **Always** get approval before executing commit
- **Never** auto-commit without explicit approval
- **Never** skip hooks without user confirmation
- **Always** show what will be committed

## Examples

### Standard Usage

```bash
/git-actions:commit-staged           # Commit staged files only
```

### With Custom Instructions

```bash
/git-actions:commit-staged use conventional commits format
# Agent will use feat:/fix: format even if repo doesn't normally

/git-actions:commit-staged keep subject under 40 chars, no body
# Forces short subject, omits body

/git-actions:commit-staged emphasize refactoring changes
# Agent highlights refactoring aspects
```

### Common Workflows

```bash
# Partial staging workflow (atomic commits)
git add src/auth/*.ts                # Stage specific files
/git-actions:commit-staged           # Commit just those
# Result: atomic commit for auth changes only

git add src/tests/*.test.ts          # Stage tests
/git-actions:commit-staged           # Separate test commit
# Result: separate commit for tests

# Iterative development
git add feature1.ts
/git-actions:commit-staged           # First feature
git add feature2.ts feature3.ts
/git-actions:commit-staged           # Second feature
# Result: two atomic commits

# Review before commit
git add -p                           # Interactive staging
/git-actions:commit-staged           # Commit selected chunks
```

### Edge Cases

```bash
# No staged files
/git-actions:commit-staged
# Error: "No staged changes. Use '/git-actions:commit-all' or stage files manually."

# Staged and unstaged mix
git add file1.ts                     # file1.ts staged
# file2.ts unstaged
/git-actions:commit-staged           # Commits only file1.ts
```
