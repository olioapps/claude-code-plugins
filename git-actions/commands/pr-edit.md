---
allowed-tools: Task, Bash(git:*), Bash(gh pr:*)
argument-hint: [pr-number]
description: Update PR description (existing or draft preview)
---

## Context

Update PR description using `pr-creator` agent.

Arguments: `/pr:edit:$ARGUMENTS`
- **pr-number/url** - update specific PR
- **(empty)** - update current branch PR or create draft

Current: !`git branch --show-current`

## Determine Mode

```bash
pr_id="$1"

if [ -n "$pr_id" ]; then
  # Validate PR exists
  gh pr view "$pr_id" &>/dev/null || { echo "ERROR: PR not found"; exit 1; }
  mode="existing"
  pr_number="$pr_id"
elif gh pr view &>/dev/null; then
  # Current branch has PR
  mode="existing"
  pr_number=$(gh pr view --json number -q .number)
else
  # No PR exists - create draft
  mode="draft"
fi
```

## Mode 1: Update Existing PR

### Fetch Current Data
```bash
pr_data=$(gh pr view "$pr_number" --json number,title,body,baseRefName,headRefName)
current_title=$(echo "$pr_data" | jq -r .title)
current_body=$(echo "$pr_data" | jq -r .body)
base=$(echo "$pr_data" | jq -r .baseRefName)
head=$(echo "$pr_data" | jq -r .headRefName)
```

### Invoke pr-creator Agent
```
Use pr-creator agent.

Context:
- mode: update-existing
- PR: #$pr_number
- current: title="$current_title", body="$current_body"
- branches: $base ← $head

Agent tasks:
1. analyze commits in branch
2. analyze diff vs base
3. generate updated description
4. reference pr-formatting skill

Return: updated title + body
```

### Apply Update
```bash
# Show preview
echo "━━━ Updated Description ━━━"
echo "Title: $new_title"
echo "$new_body"
echo "━━━━━━━━━━━━━━━━━━━━━━━━"

# Confirm
read -p "Apply? [y/N] " confirm
[ "$confirm" = "y" ] && gh pr edit "$pr_number" --title "$new_title" --body "$new_body"
```

## Mode 2: Generate Draft

### Verify Branch State
```bash
current=$(git branch --show-current)
base=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
[ -z "$base" ] && base="main"

# Check commits exist
commits=$(git rev-list --count origin/$base..HEAD 2>/dev/null)
[ "$commits" -eq 0 ] && { echo "ERROR: No commits vs $base"; exit 1; }
```

### Invoke pr-creator Agent
```
Use pr-creator agent.

Context:
- mode: draft-preview
- branch: $current
- base: $base
- commits: $commits

Agent tasks:
1. analyze: git log origin/$base..HEAD
2. analyze: git diff origin/$base...HEAD
3. generate draft PR description
4. reference pr-formatting skill

Return: draft title + body
```

### Present Draft
```bash
echo "━━━ Draft PR Description ━━━"
echo "Title: $draft_title"
echo "$draft_body"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Options:"
echo "1. Create PR: /pr:write"
echo "2. Save to file"
echo "3. Cancel"
```

### Save Option
```bash
# If user chooses save
draft_file=".github/PR_DRAFT_$(date +%Y%m%d_%H%M%S).md"
echo "# $draft_title\n\n$draft_body" > "$draft_file"
echo "Saved: $draft_file"
```

## Advanced: Targeted Updates

Update specific sections only:

```bash
# Title only
gh pr edit "$pr_number" --title "new title"

# Body only
gh pr edit "$pr_number" --body "$new_body"

# Append section
current=$(gh pr view "$pr_number" --json body -q .body)
gh pr edit "$pr_number" --body "$current\n\n## New Section\nContent"
```

## Error Handling

| Error | Action |
|-------|--------|
| PR not found | Verify number/URL, check access |
| No permission | Only authors/maintainers can update |
| No commits | Branch up-to-date, nothing to draft |
| gh not auth | Run: gh auth login |

## Examples

```bash
/pr:edit          # Auto: update PR or create draft
/pr:edit 123      # Update PR #123
/pr:edit <url>    # Update PR by URL
```
