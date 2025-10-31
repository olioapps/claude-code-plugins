---
allowed-tools: Task, Bash(git:*), Bash(gh pr:*), AskUserQuestion
argument-hint: [pr-number] [additional context]
description: Update PR description (existing or draft preview)
---

## Context

Arguments: `/git-actions:pr-edit [PR_NUMBER] [CUSTOM_INSTRUCTIONS]`
- **pr-number** - update specific PR (optional)
- **(empty)** - update current branch PR or generate draft
- **[additional context]** - custom instructions for agent (highest priority)

**Examples:**
- `/git-actions:pr-edit` - Update current branch PR or generate draft
- `/git-actions:pr-edit 123` - Update PR #123
- `/git-actions:pr-edit 123 brief format` - Update with minimal description
- `/git-actions:pr-edit add performance metrics` - Update current PR, add perf section

Current: !`git branch --show-current`

## Workflow

### 1. Pre-flight & Validation

**Check prerequisites:**
```bash
git rev-parse --git-dir 2>/dev/null || echo "NOT_A_REPO"
command -v gh &>/dev/null || echo "GH_NOT_FOUND"
gh auth status &>/dev/null || echo "GH_NOT_AUTH"
```

**Abort if:**
- Not a git repo → "Error: Not in a git repository"
- gh not found → "Error: Install gh CLI: https://cli.github.com/"
- gh not authenticated → "Error: Run 'gh auth login'"

### 2. Determine Mode

**Parse arguments and check PR existence:**

```bash
pr_id="$1"  # May be number, URL, or empty

if [ -n "$pr_id" ]; then
  # Specific PR provided
  gh pr view "$pr_id" &>/dev/null || echo "PR_NOT_FOUND"
  mode="existing"
  pr_number=$(gh pr view "$pr_id" --json number -q .number)
elif gh pr view &>/dev/null; then
  # Current branch has PR
  mode="existing"
  pr_number=$(gh pr view --json number -q .number)
else
  # No PR exists - generate draft
  mode="draft"
fi
```

**Modes:**
- **existing**: Update PR description (requires approval)
- **draft**: Generate preview for PR that doesn't exist yet

## Mode 1: Update Existing PR

### 3a. Fetch Current PR Data

```bash
pr_data=$(gh pr view "$pr_number" --json number,title,body,baseRefName,headRefName,state,isDraft)
current_title=$(echo "$pr_data" | jq -r .title)
current_body=$(echo "$pr_data" | jq -r .body)
base=$(echo "$pr_data" | jq -r .baseRefName)
head=$(echo "$pr_data" | jq -r .headRefName)
state=$(echo "$pr_data" | jq -r .state)
is_draft=$(echo "$pr_data" | jq -r .isDraft)
```

**Verify permissions:**
- Check current user can edit PR
- If permission denied → Error: "Only authors/maintainers can edit PRs"

### 4a. Invoke Agent

```
Use pr-creator agent.

Context:
- mode: update-existing
- PR: #$pr_number
- current_title: "$current_title"
- current_body: "$current_body"
- branches: $base ← $head
- state: $state (draft: $is_draft)

[IF USER PROVIDED CUSTOM INSTRUCTIONS:]
USER INSTRUCTIONS (HIGHEST PRIORITY):
"""
[custom instructions verbatim]
"""

Agent returns structured output:
---TITLE---
[updated title]
---BODY---
[updated body]
---END---
```

**Parse response. Validate:**
- [ ] TITLE exists and non-empty
- [ ] TITLE ≤70 characters
- [ ] BODY exists and non-empty

### 5a. Present & Approve

```markdown
## Updated PR Description

**Current Title:** [current_title]
**New Title:** [new_title]

**Current Body:**
[first 30 lines of current_body]

**New Body:**
[first 50 lines of new_body, indicate if truncated]

**Changes:** [highlight what changed]
```

**Use AskUserQuestion:** "Apply these changes to PR #$pr_number?"

Options:
- **"Approve and update"** → Update PR (proceed to Step 6a)
- **"Edit manually"** → Prompt for edited title/body, re-present
- **"Request changes"** → Ask for feedback, re-invoke agent, re-present
- **"Cancel"** → Abort

### 6a. Execute Update

**On approval:**

```bash
# Update PR with new title and body
gh pr edit "$pr_number" --title "$new_title" --body "$(cat <<'EOF'
$new_body
EOF
)"

# Get updated PR URL
pr_url=$(gh pr view "$pr_number" --json url -q .url)
```

**If update succeeds:**
```
✅ PR #$pr_number updated successfully!
🔗 $pr_url
```

**If update fails:**
- Show gh error verbatim
- Common issues:
  - "permission denied" → "Only authors/maintainers can edit"
  - "not found" → "PR may have been deleted"
  - "rate limit" → "Wait for GitHub API rate limit reset"

**On cancel:**
❌ "Cancelled. PR description unchanged."

## Mode 2: Generate Draft Preview

### 3b. Verify Branch State

```bash
current=$(git branch --show-current)
base=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
[ -z "$base" ] && base="main"

# Check commits exist
commits=$(git rev-list --count origin/$base..HEAD 2>/dev/null)
[ "$commits" -eq 0 ] && echo "NO_COMMITS"
```

**Abort if:**
- No commits vs base → "Error: No commits to create PR from. Branch up-to-date with $base."

### 4b. Invoke Agent

```
Use pr-creator agent.

Context:
- mode: draft-preview
- branch: $current
- base: $base
- commits: $commits

[IF USER PROVIDED CUSTOM INSTRUCTIONS:]
USER INSTRUCTIONS (HIGHEST PRIORITY):
"""
[custom instructions verbatim]
"""

Agent returns structured output:
---TITLE---
[draft title]
---BODY---
[draft body]
---END---
```

**Parse response. Validate:**
- [ ] TITLE exists and non-empty
- [ ] TITLE ≤70 characters
- [ ] BODY exists and non-empty

### 5b. Present Draft

```markdown
## Draft PR Description

**Title:** [title]

**Body:**
[body]

**Target:** $current → $base
**Commits:** $commits
```

**Use AskUserQuestion:** "What would you like to do with this draft?"

Options:
- **"Create PR now"** → Run `/git-actions:pr-write` with this description
- **"Save to file"** → Save to .github/PR_DRAFT_[timestamp].md
- **"Revise"** → Ask for changes, re-invoke agent
- **"Cancel"** → Discard draft

### 6b. Handle Choice

**If "Create PR now":**
- Invoke `/git-actions:pr-write` command
- Pass generated title and body

**If "Save to file":**
```bash
draft_file=".github/PR_DRAFT_$(date +%Y%m%d_%H%M%S).md"
cat > "$draft_file" <<EOF
# $title

$body
EOF
echo "✅ Saved: $draft_file"
```

**If "Revise":**
- Ask: "What changes would you like?"
- Re-invoke agent with feedback
- Return to Step 5b

**If "Cancel":**
❌ "Draft discarded."

## Responsibilities

**YOU (handler):** determine mode, fetch PR data (if exists), invoke agent, present changes, get approval, execute gh pr edit or save draft, handle errors

**Agent:** analyze current PR or branch changes, generate updated/draft description, return structured title + body

**Agent does NOT orchestrate or execute. You do NOT format PR descriptions.**

## Error Handling

### Pre-flight Errors
- **Not a git repo** → "Error: Not in a git repository"
- **gh not found** → "Install: https://cli.github.com/"
- **gh not authenticated** → "Run: gh auth login"

### PR Validation Errors (Existing Mode)
- **PR not found** → "PR #$pr_number not found. Check number or URL."
- **No permission** → "Only authors/maintainers can edit PRs"
- **PR closed/merged** → Warn: "⚠️ PR is closed/merged. Editing anyway?"

### Branch Validation Errors (Draft Mode)
- **No commits** → "Branch up-to-date with $base. No changes to PR."
- **Base branch not found** → "Branch $base not found. Check base branch."

### Agent Errors
- **Agent fails** → Report error, offer retry (max 2 attempts)
- **Invalid format** → Parse error, retry with clearer format

### Update Errors
- **gh pr edit fails** → Show error verbatim
- **Permission denied** → "Check repository write access"
- **Rate limit** → "GitHub API rate limit exceeded. Try again later."

### Safety Guardrails
- **Always** show current vs. new description before updating
- **Always** get approval before updating PR
- **Never** auto-update without explicit approval
- **Always** preserve draft status when editing drafts

## Examples

### Standard Usage

```bash
/git-actions:pr-edit                 # Auto: update PR or create draft
/git-actions:pr-edit 123             # Update PR #123
/git-actions:pr-edit https://github.com/user/repo/pull/123  # Update by URL
```

### With Custom Instructions

```bash
/git-actions:pr-edit brief format
# Update current PR with minimal description

/git-actions:pr-edit 123 add performance metrics
# Update PR #123, add performance section

/git-actions:pr-edit focus on security
# Update current PR, emphasize security

/git-actions:pr-edit 123 skip testing section
# Update PR #123, omit testing details
```

### Common Workflows

```bash
# Update after adding commits
git commit -m "Additional fixes"
git push
/git-actions:pr-edit                 # Regenerate description with new commits

# Preview before creating
git checkout -b feature/new
# Make changes...
/git-actions:pr-edit                 # Generate draft preview
# Option: "Create PR now" or "Save to file"

# Iterate on description
/git-actions:pr-edit                 # Generate
# Option: "Revise" → provide feedback
# Agent regenerates with feedback
```

### Manual Updates

```bash
# Title only
gh pr edit 123 --title "new title"

# Body only
gh pr edit 123 --body "$(cat PR_DESCRIPTION.md)"

# Append section
current=$(gh pr view 123 --json body -q .body)
gh pr edit 123 --body "$current

## Additional Section
New content here"
```
