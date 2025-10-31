---
allowed-tools: Task, Bash(git status:*), Bash(git branch:*), Bash(git log:*), Bash(git diff:*), Bash(git show-ref:*), Bash(git rev-parse:*), Bash(git rev-list:*), Bash(git diff-index:*), Bash(git symbolic-ref:*), Bash(gh pr view:*), Bash(gh pr list:*), Bash(gh auth status:*), Bash(command -v:*)
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

## Task

**YOU (the command handler) orchestrate the entire PR creation workflow. The pr-creator agent ONLY generates descriptions, it does NOT execute gh pr create.**

Follow the workflow below step-by-step.

## Workflow - FOLLOW EXACTLY

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

### Step 3: Generate PR Description (Agent)

**YOU invoke the pr-creator agent:**

```
Use pr-creator agent.

Context:
- branch: $(git branch --show-current)
- base: $base
- action: create PR

[IF ADDITIONAL CONTEXT WAS PROVIDED:]
ADDITIONAL CONTEXT (HIGHEST PRIORITY - OVERRIDES ALL DEFAULTS):
[insert additional context here]

The pr-creator agent will:
- Gather all necessary git context
- Check for repository PR template
- Analyze changes and generate comprehensive PR description
- Return title + body ready for presentation

YOU (command handler) do NOT need to know how the agent formats PRs.
The agent owns all content generation logic.
```

### Step 4: Present for User Approval

**YOU present the generated PR description to the user:**

Display:
```markdown
## Proposed PR

**Title:** [title from agent]

**Description:**
[body from agent - show first 50 lines with "..." if longer]

**Target:** [current-branch] → [base-branch]
**Commits:** [N commits]
```

**YOU use AskUserQuestion tool:**
```
Options:
- "Approve and create PR" → Proceed with gh pr create
- "Request changes" → Ask user for feedback, re-invoke agent
- "Cancel" → Abort PR creation
```

### Step 5: Execute Based on User Decision

**If "Approve and create PR":**
```bash
# YOU execute the PR creation using Bash tool
gh pr create --base "$base" --title "$title" --body "$body" --draft

# Get the PR URL
pr_url=$(gh pr view --json url -q .url)

# Inform user of success
```

**If "Request changes":**
```
1. YOU ask user: "What changes would you like to the PR description?"
2. YOU re-invoke pr-creator agent with:
   - Same commit/diff analysis
   - User's feedback included in additional context
   - GENERATE ONLY (still no execution)
3. Return to Step 4 (present new description for approval)
```

**If "Cancel":**
```
YOU inform user: "PR creation cancelled. Branch remains pushed to origin."
```

### Step 6: Confirm Success

```bash
pr_url=$(gh pr view --json url -q .url)
echo "✅ Draft PR created: $pr_url"
echo "Next steps:"
echo "  - Review description: /pr:edit"
echo "  - Mark ready: gh pr ready"
echo "  - Add reviewers: gh pr edit --add-reviewer user"
```

## Critical Rules - Separation of Responsibilities

### Command Handler (YOU) Responsibilities:
1. ✅ Run pre-flight checks
2. ✅ Determine base branch
3. ✅ Push branch to origin (requires user approval)
4. ✅ Invoke pr-creator agent with context
5. ✅ Present description to user for approval
6. ✅ Use AskUserQuestion for verification
7. ✅ Execute `gh pr create` ONLY after user approves
8. ✅ Handle change requests by re-invoking agent
9. ✅ Report final PR URL

### PR-Creator Agent Responsibilities:
1. ✅ All content generation (title, body, formatting)
2. ✅ PR template checking and following
3. ✅ Best practices application
4. ✅ Return structured title + body output

**The agent has ZERO orchestration responsibilities. You have ZERO content formatting knowledge.**

### Two-Phase Workflow
**Phase 1 - Generation:** Agent analyzes and generates → returns title + body
**Phase 2 - Approval:** User approves → Command executes `gh pr create`

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
