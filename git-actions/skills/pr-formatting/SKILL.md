---
name: pr-formatting
description: Create and update pull request descriptions with comprehensive, well-structured content. Use when the user needs to create or update a PR description.
---

# Creating and Updating Pull Requests

When the user needs to create or update a pull request, use the appropriate slash command. These commands orchestrate the workflow with best practices built-in.

## Commands

### Create New PR
```bash
/pr:write              # Target main (or master if main doesn't exist)
/pr:write develop      # Target specific branch
/pr:write main focus on security changes  # With custom guidance
```

**What it does:**
1. Verifies not on base branch
2. Pushes branch to remote (if needed)
3. Analyzes all commits and changes
4. Generates comprehensive PR description
5. Presents for user approval
6. Creates **draft** PR on GitHub (requires gh CLI)

### Update Existing PR
```bash
/pr:edit           # Update current branch's PR
/pr:edit 123       # Update specific PR by number
/pr:edit 123 add performance metrics  # With custom guidance
```

**What it does:**
1. Fetches current PR description
2. Analyzes commits and changes
3. Generates updated description
4. Presents for user approval
5. Updates PR on GitHub

## The pr-creator Agent

Both commands invoke the `pr-creator` agent, which has PR best practices embedded:
- Checks for repository PR template first (follows if exists)
- Generates clear, scannable structure
- Includes: Summary, Changes, Testing, Deployment Notes
- Organizes changes by component/area, not by file
- Provides comprehensive testing checklist
- Adapts to repository style

## Custom Instructions

You can pass additional context to customize the output:

```bash
/pr:write brief format
/pr:edit 123 emphasize breaking changes
/pr:write main focus on performance improvements
```

## Draft Mode

All PRs are created in **draft mode** for review before publishing:
- Review the generated description
- Edit if needed: `/pr:edit`
- Mark ready when satisfied: `gh pr ready`

## When to Use

### Use `/pr:write` when:
- User has committed changes and wants to create a PR
- User is on a feature branch ready to merge
- User asks to "create a pull request"

### Use `/pr:edit` when:
- User wants to update an existing PR description
- User has made new commits and wants to refresh PR
- User asks to "update the PR description"

## Examples

**User:** "I'm done with this feature, create a PR"
**You:** Use `/pr:write` to create a draft PR with a comprehensive description.

**User:** "Create a PR to develop branch"
**You:** Use `/pr:write develop` to target the develop branch instead of main.

**User:** "Update the PR description with the new changes"
**You:** Use `/pr:edit` to regenerate the PR description based on current commits.

**User:** "The PR needs more emphasis on the security fixes"
**You:** Use `/pr:edit focus on security changes` to update the description with security emphasis.
