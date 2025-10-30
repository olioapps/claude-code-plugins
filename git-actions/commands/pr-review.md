---
allowed-tools: Task, Bash(gh pr:*), Bash(gh api:*)
argument-hint: <pr-number-or-url> [additional context]
description: AI-powered comprehensive PR review
---

## Context

Review PR using `pr-reviewer` agent.

Arguments: `/pr:review:$ARGUMENTS`
- **pr-number** - review PR #123
- **pr-url** - review from GitHub URL
- **(empty)** - review current branch PR
- **[additional context]** - optional text after pr-number for custom instructions

**Examples:**
- `/pr:review` - Review current branch PR comprehensively
- `/pr:review 123` - Review PR #123
- `/pr:review 123 focus on security` - Security-focused review
- `/pr:review quick review` - Fast review of critical issues only

## Additional Context Handling

**If additional context is provided after the pr-number argument:**
1. Parse it as custom instructions from the user
2. Pass it to the pr-reviewer agent with HIGHEST PRIORITY
3. Agent must follow these instructions even if they conflict with defaults
4. Example: User says "focus on security" → agent prioritizes security analysis

## Pre-flight

```bash
# Check gh CLI
command -v gh &>/dev/null || { echo "ERROR: Install gh: https://cli.github.com/"; exit 1; }
gh auth status &>/dev/null || { echo "ERROR: Run gh auth login"; exit 1; }

# Determine PR number
pr_id="$1"
if [[ "$pr_id" =~ github.com/.*pull/([0-9]+) ]]; then
  pr_number="${BASH_REMATCH[1]}"
elif [ -n "$pr_id" ]; then
  pr_number="$pr_id"
elif gh pr view &>/dev/null; then
  pr_number=$(gh pr view --json number -q .number)
else
  echo "ERROR: No PR found. Usage: /pr:review 123|<url>"; exit 1
fi

# Validate PR exists
gh pr view "$pr_number" &>/dev/null || { echo "ERROR: PR not found"; exit 1; }

# Check PR state (warn only)
pr_state=$(gh pr view "$pr_number" --json state,isDraft,merged -q)
merged=$(echo "$pr_state" | jq -r .merged)
closed=$(echo "$pr_state" | jq -r '.state=="CLOSED"')
[ "$merged" = "true" ] && echo "⚠️  PR already merged"
[ "$closed" = "true" ] && [ "$merged" = "false" ] && echo "⚠️  PR closed without merge"
```

## Gather Context

```bash
# Fetch PR metadata
pr_data=$(gh pr view "$pr_number" --json \
  number,title,body,author,baseRefName,headRefName,\
  additions,deletions,changedFiles,commits,reviews)

title=$(echo "$pr_data" | jq -r .title)
body=$(echo "$pr_data" | jq -r .body)
author=$(echo "$pr_data" | jq -r .author.login)
base=$(echo "$pr_data" | jq -r .baseRefName)
head=$(echo "$pr_data" | jq -r .headRefName)
files=$(echo "$pr_data" | jq -r .changedFiles)
lines_add=$(echo "$pr_data" | jq -r .additions)
lines_del=$(echo "$pr_data" | jq -r .deletions)

# Fetch diff
diff=$(gh pr diff "$pr_number")

# Fetch existing reviews/comments
comments=$(gh api "/repos/{owner}/{repo}/pulls/$pr_number/comments")
reviews=$(echo "$pr_data" | jq -r '.reviews')

# Fetch project guidelines
guidelines=""
[ -f "CLAUDE.md" ] && guidelines=$(cat CLAUDE.md)
[ -f ".claude/CLAUDE.md" ] && guidelines=$(cat .claude/CLAUDE.md)
[ -f "CONTRIBUTING.md" ] && [ -z "$guidelines" ] && guidelines=$(cat CONTRIBUTING.md)
```

## Invoke pr-reviewer Agent

```
Use pr-reviewer agent for comprehensive review.

PR Context:
- number: #$pr_number
- title: $title
- author: $author
- branches: $base ← $head
- changes: $files files, +$lines_add -$lines_del

Description:
$body

Diff:
$diff

Existing reviews:
$reviews

Existing comments:
$comments

Project guidelines:
$guidelines

[IF ADDITIONAL CONTEXT WAS PROVIDED:]
ADDITIONAL CONTEXT (HIGHEST PRIORITY - OVERRIDES ALL DEFAULTS):
[insert additional context here]

YOU MUST follow the additional context instructions above, even if they
conflict with standard review criteria. User/system requirements take
precedence over default review process.

Agent tasks:
1. Multi-dimensional analysis:
   - code quality (40%)
   - bugs/correctness (30%)
   - testing (15%)
   - documentation (10%)
   - performance (5%)
   - ADJUST WEIGHTS if additional context specifies focus areas

2. Apply confidence scoring (0-100)
3. Report issues with confidence ≥70 (or as specified in additional context)
4. Apply any additional context instructions (these override defaults)
5. Format output:
   - critical (90-100)
   - important (70-89)
   - observations (50-69)
   - positive highlights
   - testing/docs assessment
   - recommendation (approve/changes/comment)

6. DO NOT duplicate existing comments
7. Build on existing feedback

Return: structured review markdown
```

## Present Review

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🤖 AI Code Review: PR #$pr_number"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "$review_output"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Actions:"
echo "1. Post as comment"
echo "2. Post as review (approve/request changes based on findings)"
echo "3. Save to file"
echo "4. Cancel"
```

## Post Review

```bash
# Option 1: Comment
gh pr comment "$pr_number" --body "$review_output"

# Option 2: Official review
# Determine action from findings
if [ $critical_count -gt 0 ]; then
  action="REQUEST_CHANGES"
elif [ $important_count -gt 3 ]; then
  action="COMMENT"
else
  action="APPROVE"
fi

gh pr review "$pr_number" --$action --body "$review_output"

# Option 3: Save
review_file="PR_${pr_number}_REVIEW_$(date +%Y%m%d_%H%M%S).md"
echo "$review_output" > "$review_file"
echo "Saved: $review_file"
```

## Advanced Options

```bash
# Focus on specific areas
/pr:review 123 --focus bugs,security

# Adjust confidence threshold
/pr:review 123 --threshold 85

# Review specific files only
/pr:review 123 --files "src/**/*.ts"

# Large PR warning
[ $files -gt 50 ] && echo "⚠️  Large PR ($files files). Consider: /pr:review 123 --files path/"
```

## Error Handling

| Error | Action |
|-------|--------|
| PR not found | Verify number/URL/access |
| gh missing | Install: https://cli.github.com/ |
| gh not auth | Run: gh auth login |
| Rate limit | Wait for reset, use token with higher limits |
| Incomplete diff | Some files binary/too large, review partial |

## Examples

```bash
/pr:review          # Review current branch PR
/pr:review 123      # Review PR #123
/pr:review <url>    # Review from URL
```

## Review Dimensions

**Agent analyzes:**
- **Code quality** (40%) - style, clean code, naming, organization
- **Bugs** (30%) - logic errors, null handling, race conditions
- **Testing** (15%) - coverage, quality, edge cases
- **Documentation** (10%) - comments, API docs, README
- **Performance** (5%) - queries, algorithms, memory

**Confidence levels:**
- 90-100: critical, must fix
- 70-89: important, should fix
- 50-69: observations, consider
- <50: not reported
