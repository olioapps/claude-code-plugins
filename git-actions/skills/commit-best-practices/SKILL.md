---
name: commit-best-practices
description: Generate concise, information-dense commit messages following git best practices. Use when writing commit messages, analyzing changes for commits, or helping users create clear version control history.
---

# Commit Message Best Practices

## Core Principles

Write commit messages that are **concise yet information-dense**. Every word should add value. No redundant points, no extraneous context unrelated to the changes.

## Format Guidelines

### Subject Line (Required)
- **Length**: 50 characters or less
- **Mood**: Imperative present tense ("Add feature" not "Added feature" or "Adds feature")
- **Capitalization**: Start with capital letter
- **Punctuation**: No period at the end
- **Content**: Describe WHAT changed and WHY, not HOW

### Body (Optional - use when subject alone is insufficient)
- **When to use**: Complex changes requiring explanation of motivation or context
- **Format**: Separate from subject with blank line
- **Line length**: Wrap at 72 characters
- **Content**: Explain WHY and WHAT, not implementation details
- **Structure**: Use bullet points for multiple distinct changes

### Footer (Optional)
- **Breaking changes**: `BREAKING CHANGE: description`
- **Issue references**: `Fixes #123`, `Closes #456`, `Related to #789`
- **Co-authors**: `Co-authored-by: Name <email>`

## Writing Strategy

### 1. Analyze Changes
- Review git diff to understand scope
- Identify the primary purpose of changes
- Look for patterns in recent commits to match style

### 2. Determine Type
**For conventional commits (if repo uses them):**
- `feat`: New feature or capability
- `fix`: Bug fix
- `refactor`: Code restructuring without behavior change
- `perf`: Performance improvement
- `docs`: Documentation only
- `style`: Formatting, whitespace, no code change
- `test`: Adding or updating tests
- `build`: Build system or dependencies
- `ci`: CI/CD configuration
- `chore`: Maintenance tasks

**For simple descriptive commits:**
Start with a clear action verb:
- Add, Remove, Update, Fix, Improve, Refactor, Optimize, Document

### 3. Craft Message
**Good examples:**
```
Add OAuth2 authentication with Google provider

Implement OAuth2 flow for Google sign-in including:
- Token exchange and refresh logic
- Session persistence in Redis
- Automatic token rotation

Fixes #234
```

```
Fix race condition in payment processing

Introduce request locking to prevent duplicate charges
when users double-click the payment button.
```

```
Refactor user validation logic into middleware
```

```
Optimize database queries in user dashboard

Reduce N+1 queries by eager loading relationships.
Improves page load from 2.3s to 0.4s.
```

**Bad examples (and why):**
```
Update files
// TOO VAGUE - what changed and why?

Added new feature to the authentication system that allows users to log in
// VERBOSE AND PAST TENSE - should be "Add OAuth2 login support"

Fixed bug
// NO CONTEXT - which bug? what was the impact?

Refactored code to make it better and more maintainable going forward
// REDUNDANT WORDS - "better", "going forward" add no value

This commit updates the user service to handle edge cases properly
// UNNECESSARY PREAMBLE - remove "This commit"
```

## Commit Scope Rules

### Atomic Commits
- Each commit should represent ONE logical change
- If you use "and" in your subject line, consider splitting commits
- Exception: Related changes that must work together

### What to Exclude
- Don't commit commented-out code
- Don't commit debugging statements
- Don't commit sensitive data (.env, keys, tokens)
- Don't commit unrelated changes in the same commit

### When to Amend
- Fixing typos in previous commit
- Adding forgotten files to previous commit
- Only if commit hasn't been pushed

## Project-Specific Patterns

### Analyze Repository Style
Before committing, examine recent history:
```bash
git log --oneline -20
```

Look for:
- Conventional commit format vs. simple descriptions
- Emoji usage (some teams prefix with 🎨, 🐛, etc.)
- Scope conventions (module names in parentheses)
- Length patterns (terse vs. detailed)

### Adapt to Team Conventions
Match the established style. Consistency matters more than any specific format.

## Red Flags to Avoid

❌ "Fix stuff" / "Update things" - TOO VAGUE
❌ "WIP" / "temp" / "asdf" - NOT DESCRIPTIVE
❌ Past tense - WRONG MOOD
❌ "Fixed the bug where the user couldn't log in because of a typo in the validation" - TOO LONG FOR SUBJECT
❌ Multiple unrelated changes - NOT ATOMIC
❌ Explaining HOW instead of WHAT/WHY - WRONG FOCUS

## Quick Decision Tree

1. **Is this a single logical change?**
   - No → Split into multiple commits
   - Yes → Continue

2. **Can I describe it in 50 chars or less?**
   - Yes → Write subject line only
   - No → Write subject + body

3. **Does the repo use conventional commits?**
   - Yes → Prefix with type (feat, fix, etc.)
   - No → Start with action verb

4. **Is this a breaking change or fixing an issue?**
   - Yes → Add footer with BREAKING CHANGE or issue reference
   - No → Subject (and optionally body) is sufficient

## Remember

- **Clarity > Brevity**: If you need more words to be clear, use them
- **Context matters**: Future developers (including you) will thank you
- **No redundancy**: Every word should add unique information
- **Focus on intent**: Explain WHY this change was made
