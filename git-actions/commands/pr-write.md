---
allowed-tools: Task, Bash(git:*), Bash(gh pr:*), Bash(gh auth:*), Bash(command -v:*), AskUserQuestion
argument-hint: [base-branch] [additional context]
description: Create draft PR with AI-generated description
---

## Context

Arguments: `/git-actions:pr-write [BASE_BRANCH] [CUSTOM_INSTRUCTIONS]`
- **base-branch** - target branch (default: main)
- **[additional context]** - custom instructions for agent (highest priority)

**Examples:**
- `/git-actions:pr-write` - Create PR targeting main
- `/git-actions:pr-write develop` - Target develop branch
- `/git-actions:pr-write main brief format` - Minimal description
- `/git-actions:pr-write focus on security` - Emphasize security

Current: !`git branch --show-current`

## Workflow

### 1. Pre-flight & Validation

**Check prerequisites:**
```bash
git rev-parse --git-dir 2>/dev/null || echo "NOT_A_REPO"
command -v gh &>/dev/null || echo "GH_NOT_FOUND"
gh auth status &>/dev/null || echo "GH_NOT_AUTH"
git branch --show-current
git status --short
```

**Abort if:**
- Not a git repo → "Error: Not in a git repository"
- gh CLI not found → "Error: Install gh CLI: https://cli.github.com/"
- gh not authenticated → "Error: Run 'gh auth login'"
- Uncommitted changes → Warn only: "⚠️ Uncommitted changes. Use '/git-actions:commit-all' first."

**Determine base branch:**
- Parse first argument as base (default: "main")
- Verify base exists: `git show-ref --verify refs/heads/$base`
- If base="main" and not found → Try "master" as fallback
- If still not found → Error: "Base branch '$base' not found"

**Verify not on base branch:**
- Current branch == base → Error: "Already on base branch. Create feature branch first."

**Check for existing PR:**
```bash
gh pr view &>/dev/null && echo "PR_EXISTS"
```
- If PR exists → Show URL, suggest '/git-actions:pr-edit', abort

### 2. Push Branch

**Check if branch needs push:**
```bash
git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "NO_UPSTREAM"
```

**Use AskUserQuestion:** "Push branch to origin?"
- If no upstream → `git push -u origin <current-branch>`
- If upstream exists:
  ```bash
  commits_ahead=$(git rev-list --count @{u}..HEAD)
  ```
  - If ahead > 0 → `git push`
  - If ahead == 0 → Skip push (already up-to-date)
- If push fails → Show error, abort

### 3. Gather Context

```bash
git log origin/$base..HEAD --oneline
git diff --stat origin/$base...HEAD
git diff origin/$base...HEAD | head -n 500
```

**Summary:**
- N commits in this branch
- X files changed (+Y -Z lines)

### 4. Invoke Agent

```
Use pr-creator agent.

Context:
- branch: $(git branch --show-current)
- base: $base
- commits: [N commits]
- files: [X files]
- stats: [+Y -Z lines]

[IF USER PROVIDED CUSTOM INSTRUCTIONS:]
USER INSTRUCTIONS (HIGHEST PRIORITY):
"""
[custom instructions verbatim]
"""

Agent returns structured output:
---TITLE---
[title]
---BODY---
[body]
---END---
```

**Parse response into TITLE, BODY. Validate:**
- [ ] TITLE exists and non-empty
- [ ] TITLE ≤70 characters (warn if >70, continue if ≤100)
- [ ] BODY exists and non-empty
- [ ] No markdown artifacts in TITLE

If validation fails → Report parse error, retry (max 2 attempts)

### 5. Present & Approve

```markdown
## Proposed PR

**Title:** [title]

**Description:**
[body - show first 50 lines, indicate if truncated]

**Target:** [current-branch] → [base]
**Commits:** [N commits]
**Files:** [X files] (+Y -Z lines)
```

**Use AskUserQuestion:** "How to proceed with this PR?"

Options:
- **"Approve and create"** → Create draft PR (proceed to Step 6)
- **"Edit manually"** → Prompt for edited title/body, re-present
- **"Request changes"** → Ask for feedback, re-invoke agent, re-present
- **"Cancel"** → Abort

### 6. Execute

**On approval:**

```bash
# Create draft PR using HEREDOC for body
gh pr create --base "$base" --title "$title" --body "$(cat <<'EOF'
$body
EOF
)" --draft

# Get PR URL
pr_url=$(gh pr view --json url -q .url)
pr_number=$(gh pr view --json number -q .number)
```

**Check result:**

**If PR creation succeeds:**
```
✅ Draft PR created: #$pr_number
🔗 $pr_url

Next steps:
  - Review description: /git-actions:pr-edit
  - Mark ready: gh pr ready
  - Add reviewers: gh pr edit --add-reviewer username
  - Add labels: gh pr edit --add-label bug,feature
```

**If PR creation fails:**
- Show gh error verbatim
- Common issues:
  - "already exists" → PR may exist, check: `gh pr list`
  - "no commits" → Branch up-to-date with base
  - "permission denied" → Check repo access
  - "rate limit" → Wait for GitHub API rate limit reset

**On cancel:**
❌ "Cancelled. Branch remains pushed to origin."

## Responsibilities

**YOU (handler):** check prerequisites, determine base branch, push branch (with approval), gather context, invoke agent, present description, get approval, execute gh pr create, handle errors

**Agent:** analyze commits/diff, check for PR template, generate description, return structured title + body

**Agent does NOT orchestrate or execute. You do NOT format PR descriptions.**

## Error Handling

### Pre-flight Errors
- **Not a git repo** → "Error: Not in a git repository"
- **gh not installed** → "Install: https://cli.github.com/"
- **gh not authenticated** → "Run: gh auth login"
- **On base branch** → "Create feature branch first: git checkout -b feature/name"
- **Base branch not found** → "Branch '$base' not found. Check branch name."
- **PR already exists** → Show URL, suggest '/git-actions:pr-edit $pr_number'

### Push Errors
- **No upstream, push fails** → Show error, suggest checking remote/permissions
- **Rejected (non-fast-forward)** → "Pull changes first: git pull origin <branch>"
- **Permission denied** → "Check repository access/permissions"

### Agent Errors
- **Agent fails** → Report error, offer retry (max 2 attempts)
- **Invalid format** → Parse error, retry with clearer format
- **Very large PR** → Agent may warn: "Consider splitting into smaller PRs"

### PR Creation Errors
- **gh pr create fails** → Show error verbatim
- **Already exists** → Check existing PRs: `gh pr list`
- **No commits** → "Branch up-to-date with $base. Make changes first."
- **Rate limit** → "GitHub API rate limit exceeded. Try again later."
- **Permission denied** → "Check repository write access"

### Safety Guardrails
- **Always** confirm before pushing branch
- **Always** get approval before creating PR
- **Always** create as draft (never publish immediately)
- **Never** push --force without user confirmation
- **Always** show PR content before creating

## Examples

### Standard Usage

```bash
/git-actions:pr-write              # Target main (or master fallback)
/git-actions:pr-write develop      # Target develop branch
/git-actions:pr-write development  # Target development branch
```

### With Custom Instructions

```bash
/git-actions:pr-write main brief format
# Agent uses minimal sections, omits detailed breakdown

/git-actions:pr-write develop focus on security changes
# Agent emphasizes security implications heavily

/git-actions:pr-write main include performance metrics
# Agent adds detailed performance section

/git-actions:pr-write skip testing section
# Agent omits testing details
```

### Common Workflows

```bash
# Standard workflow
git checkout -b feature/oauth-login
# Make changes...
/git-actions:commit-all
/git-actions:pr-write
# Review, approve, PR created as draft

# Target specific branch
git checkout -b feature/dashboard
# Make changes...
/git-actions:pr-write develop      # Target develop, not main

# After creating PR
gh pr ready                        # Mark ready for review
gh pr edit --add-reviewer user1    # Add reviewers
gh pr edit --add-label feature     # Add labels
```

### Post-Creation Commands

```bash
# Mark PR ready for review
gh pr ready

# Add reviewers, labels, milestone
gh pr edit --add-reviewer user1,user2
gh pr edit --add-label bug,feature
gh pr edit --milestone "v1.0"

# Convert back to draft
gh pr ready --undo

# Update PR description
/git-actions:pr-edit
```
