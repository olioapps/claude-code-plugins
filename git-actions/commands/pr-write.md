---
allowed-tools: Task, Bash(git status:*), Bash(git branch:*), Bash(git log:*), Bash(git diff:*), Bash(git show-ref:*), Bash(git rev-parse:*), Bash(git rev-list:*), Bash(git diff-index:*), Bash(git symbolic-ref:*), Bash(gh pr view:*), Bash(gh pr list:*), Bash(gh auth status:*), Bash(command -v:*)
argument-hint: [base-branch] [additional context]
description: Create draft PR with AI-generated description (default: main)
---

## Context

Create PR using `pr-creator` agent + `gh` CLI.

Arguments: `/git-actions:pr-write $ARGUMENTS`
- **base-branch** - target branch (e.g., "main", "develop", "development")
- **(empty)** - default: main
- **[additional context]** - optional text after base-branch for custom instructions

**Examples:**
- `/git-actions:pr-write` - Create PR to main with standard description
- `/git-actions:pr-write develop` - Create PR to develop branch
- `/git-actions:pr-write main focus on security changes` - Emphasize security in description
- `/git-actions:pr-write brief format` - Use minimal PR description format

Current: !`git branch --show-current`
Status: !`git status --short`

## Additional Context Handling

**If additional context is provided after the base-branch argument:**
1. Parse it as custom instructions from the user
2. Pass it to the pr-creator agent with HIGHEST PRIORITY
3. Agent must follow these instructions even if they conflict with defaults
4. Example: User says "brief format" → agent uses minimal sections

## Pre-flight Checks

Run simple readonly checks (auto-approved):

1. Get current branch: `git branch --show-current`
2. Check if base branch exists: `git show-ref --verify refs/heads/$base`
3. Check gh CLI installed: `command -v gh`
4. Check gh auth: `gh auth status`
5. Check for existing PR: `gh pr view`
6. Check uncommitted changes: `git diff-index --quiet HEAD`

Handle logic in code:
- If current == base → error "On base branch"
- If base not found and base == "main" → try master fallback
- If gh missing → error "Install gh CLI"
- If not authenticated → error "Run gh auth login"
- If PR exists → show URL, suggest /git-actions:pr-edit
- If uncommitted changes → warn only

## Task

**YOU (the command handler) orchestrate the entire PR creation workflow. The pr-creator agent ONLY generates descriptions, it does NOT execute gh pr create.**

Follow the workflow below step-by-step.

## Workflow - FOLLOW EXACTLY

### Step 1: Determine Base Branch

Parse argument: base = $1 or default to "main"

Check base branch exists:
- Run `git show-ref --verify refs/heads/$base`
- If fails and base == "main", try `git show-ref --verify refs/heads/master`
- If both fail, error "Base branch not found"

### Step 2: Push Branch

Check if branch needs push:
- Run `git rev-parse --abbrev-ref --symbolic-full-name @{u}` to check upstream
- If no upstream, run `git push -u origin <current-branch>`
- If upstream exists, run `git rev-list --count @{u}..HEAD` to check commits ahead
- If ahead, run `git push`
- If already up to date, skip push

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
echo "  - Review description: /git-actions:pr-edit"
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
| Uncommitted changes | Warn, continue or /git-actions:commit all |
| No upstream | Push with -u flag |
| PR exists | Show URL, suggest /git-actions:pr-edit |
| gh missing | Install: https://cli.github.com/ |
| gh not auth | Run: gh auth login |

## Examples

```bash
/git-actions:pr-write              # Default: target main (or master)
/git-actions:pr-write develop      # Target develop branch
/git-actions:pr-write development  # Target development branch
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
