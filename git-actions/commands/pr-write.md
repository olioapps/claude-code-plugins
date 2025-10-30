---
allowed-tools: Task, Bash(git:*), Bash(gh pr create:*)
argument-hint: [base-branch] [additional context]
description: Create draft PR with AI-generated description (default: main)
---

## Context

Create PR using `pr-creator` agent + `gh` CLI.

Arguments: `/pr:write:$ARGUMENTS`
- **base-branch** - target branch (e.g., "main", "develop", "development")
- **(empty)** - default: main
- **[additional context]** - optional text after base-branch for custom instructions

**Examples:**
- `/pr:write` - Create PR to main with standard description
- `/pr:write develop` - Create PR to develop branch
- `/pr:write main focus on security changes` - Emphasize security in description
- `/pr:write brief format` - Use minimal PR description format

Current: !`git branch --show-current`
Status: !`git status --short`

## Additional Context Handling

**If additional context is provided after the base-branch argument:**
1. Parse it as custom instructions from the user
2. Pass it to the pr-creator agent with HIGHEST PRIORITY
3. Agent must follow these instructions even if they conflict with defaults
4. Example: User says "brief format" → agent uses minimal sections

## Pre-flight Checks

Execute checks before proceeding:

```bash
current=$(git branch --show-current)
base=${1:-main}

# 1. Verify not on base branch
[ "$current" != "$base" ] || { echo "ERROR: On base branch. Create feature branch first."; exit 1; }

# 2. Verify base exists (fallback main→master)
git show-ref --verify --quiet refs/heads/$base || \
  ([ "$base" = "main" ] && git show-ref --verify --quiet refs/heads/master && base="master") || \
  { echo "ERROR: Base branch '$base' not found."; exit 1; }

# 3. Check gh CLI
command -v gh &>/dev/null || { echo "ERROR: Install gh CLI: https://cli.github.com/"; exit 1; }
gh auth status &>/dev/null || { echo "ERROR: Run gh auth login"; exit 1; }

# 4. Check uncommitted changes (warn only)
git diff-index --quiet HEAD -- || echo "WARNING: Uncommitted changes won't be in PR"

# 5. Check existing PR
gh pr view &>/dev/null && { echo "PR exists. Use /pr:edit to update."; gh pr view --json url -q .url; exit 0; }
```

## Workflow

### Step 1: Determine Base Branch

```bash
base="$1"
# Default to main if not specified (fallback to master)
if [ -z "$base" ]; then
  git show-ref --verify --quiet refs/heads/main && base="main"
  [ -z "$base" ] && git show-ref --verify --quiet refs/heads/master && base="master"
  [ -z "$base" ] && { echo "ERROR: No default branch found. Specify explicitly."; exit 1; }
fi
```

### Step 2: Push Branch

```bash
# Push if no upstream or local ahead
git rev-parse --abbrev-ref --symbolic-full-name @{u} &>/dev/null && \
  [ $(git rev-list --count @{u}..HEAD) -gt 0 ] && git push || \
  git push -u origin $(git branch --show-current)
```

### Step 3: Invoke pr-creator Agent

```
Use pr-creator agent.

Context:
- branch: $(git branch --show-current)
- base: $base
- action: create PR

[IF ADDITIONAL CONTEXT WAS PROVIDED:]
ADDITIONAL CONTEXT (HIGHEST PRIORITY - OVERRIDES ALL DEFAULTS):
[insert additional context here]

YOU MUST follow the additional context instructions above, even if they
conflict with standard PR formatting guidelines. User/system requirements
take precedence over default best practices.

Agent tasks:
1. analyze commits: git log origin/$base..HEAD
2. analyze diff: git diff origin/$base...HEAD
3. apply PR formatting best practices (embedded in agent)
4. apply any additional context instructions (these override defaults)
5. generate: title, summary, changes, testing, deployment, links

Return: title + body for gh pr create
```

### Step 4: Create PR (Draft Mode)

```bash
# Parse agent response (title + body)
# Always create as draft for review before publishing
gh pr create --base "$base" --title "$title" --body "$body" --draft
```

### Step 5: Confirm

```bash
pr_url=$(gh pr view --json url -q .url)
echo "✅ Draft PR created: $pr_url"
echo "Next steps:"
echo "  - Review description: /pr:edit"
echo "  - Mark ready: gh pr ready"
echo "  - Add reviewers: gh pr edit --add-reviewer user"
```

## Error Handling

| Error | Action |
|-------|--------|
| Uncommitted changes | Warn, continue or /commit:all |
| No upstream | Push with -u flag |
| PR exists | Show URL, suggest /pr:edit |
| gh missing | Install: https://cli.github.com/ |
| gh not auth | Run: gh auth login |

## Examples

```bash
/pr:write              # Default: target main (or master)
/pr:write develop      # Target develop branch
/pr:write development  # Target development branch
```

## Advanced (post-create)

```bash
# Mark PR ready for review (removes draft status)
gh pr ready

# Add reviewers, labels, milestone
gh pr edit --add-reviewer user1,user2
gh pr edit --add-label bug,feature
gh pr edit --milestone "v1.0"

# Convert back to draft
gh pr ready --undo
```
