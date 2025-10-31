---
allowed-tools: Task, Bash(gh pr:*), Bash(gh api:*), Bash(gh auth:*), Bash(command -v:*), AskUserQuestion
argument-hint: <pr-number-or-url> [additional context]
description: AI-powered comprehensive PR review
---

## Context

Arguments: `/git-actions:pr-review [PR_NUMBER] [CUSTOM_INSTRUCTIONS]`
- **pr-number** - review PR #123
- **pr-url** - review from GitHub URL
- **(empty)** - review current branch PR
- **[additional context]** - custom instructions for agent (highest priority)

**Examples:**
- `/git-actions:pr-review` - Review current branch PR
- `/git-actions:pr-review 123` - Review PR #123
- `/git-actions:pr-review 123 focus on security` - Security-focused review
- `/git-actions:pr-review quick review critical only` - Fast, critical issues only

Current: !`git branch --show-current`

## Workflow

### 1. Pre-flight & Validation

**Check prerequisites:**
```bash
command -v gh &>/dev/null || echo "GH_NOT_FOUND"
gh auth status &>/dev/null || echo "GH_NOT_AUTH"
```

**Abort if:**
- gh not found → "Error: Install gh CLI: https://cli.github.com/"
- gh not authenticated → "Error: Run 'gh auth login'"

**Determine PR number:**
```bash
pr_id="$1"

if [[ "$pr_id" =~ github.com/.*/pull/([0-9]+) ]]; then
  # Extract from URL
  pr_number="${BASH_REMATCH[1]}"
elif [ -n "$pr_id" ]; then
  # Direct number
  pr_number="$pr_id"
elif gh pr view &>/dev/null; then
  # Current branch PR
  pr_number=$(gh pr view --json number -q .number)
else
  echo "ERROR: No PR found"
fi
```

**Verify PR exists:**
```bash
gh pr view "$pr_number" &>/dev/null || echo "PR_NOT_FOUND"
```

**Abort if:**
- No PR found → "Error: No PR found. Usage: /git-actions:pr-review 123"
- PR not accessible → "Error: PR #$pr_number not found or not accessible"

**Check PR state (warn only):**
```bash
pr_state=$(gh pr view "$pr_number" --json state,isDraft,merged -q)
merged=$(echo "$pr_state" | jq -r .merged)
closed=$(echo "$pr_state" | jq -r '.state=="CLOSED"')
is_draft=$(echo "$pr_state" | jq -r .isDraft)
```
- If merged → Warn: "⚠️ PR already merged"
- If closed (not merged) → Warn: "⚠️ PR closed without merge"
- If draft → Info: "ℹ️ Reviewing draft PR"

### 2. Gather Context

**Fetch PR metadata:**
```bash
pr_data=$(gh pr view "$pr_number" --json \
  number,title,body,author,baseRefName,headRefName,\
  additions,deletions,changedFiles,commits,reviews,labels)

title=$(echo "$pr_data" | jq -r .title)
body=$(echo "$pr_data" | jq -r .body)
author=$(echo "$pr_data" | jq -r .author.login)
base=$(echo "$pr_data" | jq -r .baseRefName)
head=$(echo "$pr_data" | jq -r .headRefName)
files_changed=$(echo "$pr_data" | jq -r .changedFiles)
lines_added=$(echo "$pr_data" | jq -r .additions)
lines_deleted=$(echo "$pr_data" | jq -r .deletions)
```

**Fetch diff:**
```bash
diff=$(gh pr diff "$pr_number" | head -n 5000)  # Truncate very large diffs
```

**Fetch existing reviews and comments:**
```bash
reviews=$(echo "$pr_data" | jq -r '.reviews')
comments=$(gh api "/repos/{owner}/{repo}/pulls/$pr_number/comments")
```

**Fetch project guidelines (if exist):**
```bash
guidelines=""
[ -f "CLAUDE.md" ] && guidelines=$(cat CLAUDE.md)
[ -f ".claude/CLAUDE.md" ] && [ -z "$guidelines" ] && guidelines=$(cat .claude/CLAUDE.md)
[ -f "CONTRIBUTING.md" ] && [ -z "$guidelines" ] && guidelines=$(cat CONTRIBUTING.md)
```

**Summary:**
- PR #$pr_number by @$author
- $files_changed files (+$lines_added -$lines_deleted)
- $base ← $head
- Existing reviews/comments found

### 3. Invoke Agent

```
Use pr-reviewer agent.

PR Context:
- number: #$pr_number
- title: "$title"
- author: $author
- branches: $base ← $head
- changes: $files_changed files (+$lines_added -$lines_deleted)
- state: [open/draft/merged/closed]

Description:
$body

Diff:
$diff

Existing Reviews:
$reviews

Existing Comments:
$comments

Project Guidelines:
$guidelines

[IF USER PROVIDED CUSTOM INSTRUCTIONS:]
USER INSTRUCTIONS (HIGHEST PRIORITY):
"""
[custom instructions verbatim]
"""

Agent tasks:
1. Multi-dimensional analysis:
   - Code quality (40%)
   - Bugs/correctness (30%)
   - Testing (15%)
   - Documentation (10%)
   - Performance (5%)
   - ADJUST WEIGHTS if user specifies focus areas

2. Apply confidence scoring (0-100)
3. Report issues with confidence ≥70 (or as specified)
4. DO NOT duplicate existing comments
5. Build on existing feedback
6. Format output:
   - Critical (90-100)
   - Important (70-89)
   - Observations (50-69)
   - Positive highlights
   - Testing/docs assessment
   - Recommendation (approve/changes/comment)

Agent returns structured output:
---REVIEW---
[markdown review with sections]
---RECOMMENDATION---
[APPROVE|REQUEST_CHANGES|COMMENT]
---CRITICAL_COUNT---
[number]
---IMPORTANT_COUNT---
[number]
---END---
```

**Parse response. Validate:**
- [ ] REVIEW exists and non-empty
- [ ] RECOMMENDATION is valid (APPROVE/REQUEST_CHANGES/COMMENT)
- [ ] CRITICAL_COUNT and IMPORTANT_COUNT are numbers

If validation fails → Report parse error, retry (max 2 attempts)

### 4. Present Review

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🤖 AI Code Review: PR #$pr_number
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

$review_output

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Recommendation:** $recommendation
**Critical Issues:** $critical_count
**Important Issues:** $important_count
```

**Use AskUserQuestion:** "How would you like to post this review?"

Options:
- **"Post as official review"** → gh pr review with recommendation
- **"Post as comment only"** → gh pr comment (no approval status)
- **"Save to file"** → Save to PR_${pr_number}_REVIEW_[timestamp].md
- **"Cancel"** → Discard review

### 5. Execute

**If "Post as official review":**

```bash
# Determine review action from recommendation
case "$recommendation" in
  "APPROVE")
    action="--approve"
    ;;
  "REQUEST_CHANGES")
    action="--request-changes"
    ;;
  "COMMENT")
    action="--comment"
    ;;
esac

# Post review using HEREDOC for body
gh pr review "$pr_number" $action --body "$(cat <<'EOF'
$review_output
EOF
)"

pr_url=$(gh pr view "$pr_number" --json url -q .url)
```

**If review post succeeds:**
```
✅ Review posted successfully!
🔗 $pr_url
📊 Recommendation: $recommendation
```

**If review post fails:**
- Show gh error verbatim
- Common issues:
  - "permission denied" → "Need repository access to post reviews"
  - "review already submitted" → "Edit existing review or post as comment"
  - "rate limit" → "Wait for GitHub API rate limit reset"

**If "Post as comment only":**

```bash
gh pr comment "$pr_number" --body "$(cat <<'EOF'
$review_output
EOF
)"
```

**If "Save to file":**

```bash
review_file="PR_${pr_number}_REVIEW_$(date +%Y%m%d_%H%M%S).md"
cat > "$review_file" <<EOF
# AI Code Review: PR #$pr_number

$review_output

---
Recommendation: $recommendation
Critical Issues: $critical_count
Important Issues: $important_count
EOF

echo "✅ Saved: $review_file"
```

**If "Cancel":**
❌ "Review discarded."

## Responsibilities

**YOU (handler):** check prerequisites, determine PR number, fetch PR data/diff/reviews/guidelines, invoke agent, present review, get user choice, execute gh pr review or comment or save, handle errors

**Agent:** multi-dimensional analysis, confidence scoring, generate structured review with findings, return review + recommendation + counts

**Agent does NOT orchestrate or execute. You do NOT format reviews.**

## Error Handling

### Pre-flight Errors
- **gh not found** → "Install: https://cli.github.com/"
- **gh not authenticated** → "Run: gh auth login"
- **No PR specified** → "Usage: /git-actions:pr-review 123"
- **PR not found** → "PR #$pr_number not found or not accessible"

### Data Fetch Errors
- **Diff too large** → Truncate to 5000 lines, warn: "⚠️ Large PR, diff truncated"
- **API rate limit** → "GitHub API rate limit exceeded. Try again later."
- **Permission denied** → "Cannot access PR. Check repository permissions."

### Agent Errors
- **Agent fails** → Report error, offer retry (max 2 attempts)
- **Invalid format** → Parse error, retry with clearer format
- **Very large PR** → Agent may warn: "⚠️ Large PR ($files_changed files). Review may be partial."

### Review Post Errors
- **gh pr review fails** → Show error verbatim
- **Already reviewed** → "You've already reviewed. Edit existing or post as comment."
- **Permission denied** → "Need write access to post reviews"
- **Rate limit** → "GitHub API rate limit exceeded. Try again later."

### Safety Guardrails
- **Always** show review before posting
- **Always** get user choice on how to post
- **Never** auto-post without approval
- **Always** specify review action (approve/request changes/comment)
- **Always** check for existing reviews to avoid duplication

## Examples

### Standard Usage

```bash
/git-actions:pr-review                   # Review current branch PR
/git-actions:pr-review 123               # Review PR #123
/git-actions:pr-review https://github.com/user/repo/pull/123  # Review from URL
```

### With Custom Instructions

```bash
/git-actions:pr-review 123 focus on security
# Agent prioritizes security analysis (adjusts weights)

/git-actions:pr-review quick review critical only
# Agent uses higher confidence threshold, reports critical issues only

/git-actions:pr-review 123 focus on performance and bugs
# Agent emphasizes performance (5%→20%) and bugs (30%→40%)

/git-actions:pr-review emphasize testing coverage
# Agent gives higher weight to testing analysis
```

### Common Workflows

```bash
# Review your own PR before requesting reviewers
/git-actions:pr-review                   # Review current PR
# Option: "Save to file" → address issues locally
# Fix issues, commit, push
/git-actions:pr-review                   # Re-review
# Option: "Post as comment" → document self-review

# Review someone else's PR
/git-actions:pr-review 123               # Comprehensive review
# Option: "Post as official review"
# Recommendation: REQUEST_CHANGES if critical issues

# Focus review on specific aspect
/git-actions:pr-review 123 security only
# Agent focuses analysis on security implications
```

### Review Dimensions

**Agent analyzes across:**
- **Code quality** (40%) - style, clean code, naming, organization
- **Bugs/correctness** (30%) - logic errors, null handling, edge cases
- **Testing** (15%) - coverage, quality, edge cases
- **Documentation** (10%) - comments, API docs, README updates
- **Performance** (5%) - query optimization, algorithms, memory

**Confidence levels:**
- **90-100**: Critical issues (must fix before merge)
- **70-89**: Important issues (should fix)
- **50-69**: Observations (consider addressing)
- **<50**: Not reported (too speculative)

### Large PR Handling

```bash
# For very large PRs (>50 files, >1000 lines)
/git-actions:pr-review 123
# ⚠️ Large PR warning
# Diff may be truncated, review may be partial

# Consider reviewing specific areas
# (Future: focus on specific files/paths)
```
