---
name: commit-best-practices
description: Create git commits with AI-generated messages following best practices. Use when the user needs to commit changes with a well-crafted message.
---

# Creating Commits with Best Practices

When the user needs to create a git commit, use the `/commit` slash command. This command orchestrates the entire workflow with best practices built-in.

## Usage

```bash
/commit:all      # Stage all changes and commit
/commit:staged   # Commit only staged changes
/commit          # Auto-detect (staged if any, else all)
```

## What the Command Does

1. Stages files (if needed)
2. Analyzes changes using git diff
3. Reviews recent commit history to match repository style
4. Generates a concise, information-dense commit message
5. Presents the message for user approval
6. Creates the commit after approval

## The commit-writer Agent

The `/commit` command invokes the `commit-writer` agent, which has commit best practices embedded:
- Concise, information-dense messages (50-char subject limit)
- Imperative mood ("Add" not "Added")
- Explains WHAT and WHY, not HOW
- Adapts to repository commit conventions
- References issues when relevant
- Atomic commits (one logical change)

## Custom Instructions

You can pass additional context to override defaults:

```bash
/commit:all use conventional commits format
/commit:staged keep it under 40 chars
/commit:all emphasize performance improvements
/commit:staged no body
```

## When to Use

- User has made changes and needs to commit
- User asks for help writing a commit message
- User wants a commit that follows best practices
- User wants the commit to match repository style

## Examples

**User:** "I've updated the authentication logic, can you commit this?"
**You:** Use `/commit:all` to stage all changes and create a commit with a well-crafted message.

**User:** "Commit my staged files"
**You:** Use `/commit:staged` to commit only the staged changes.

**User:** "I need a brief commit message for this fix"
**You:** Use `/commit:all keep it under 40 chars` to create a concise commit.
