# Git Actions Plugin

AI-powered git workflow automation for Claude Code. Streamline your development process with intelligent commit messages, comprehensive PR descriptions, and thorough code reviews.

## Features

- **Smart Commits**: AI-generated commit messages following best practices
- **Draft PRs**: Create comprehensive pull requests in draft mode for review before publishing
- **Flexible Targeting**: Specify target branch or default to main/master
- **Code Reviews**: Multi-dimensional PR analysis with confidence-based findings
- **Workflow Integration**: Seamless GitHub integration via `gh` CLI
- **Best Practices**: Built-in skills for concise commits and structured PRs

## Quick Start

### Installation

1. Install the plugin in your project:
```bash
# From your project directory
cd .claude/plugins
git clone <this-repo-url> git-actions
```

2. Enable the plugin in `.claude/settings.json`:
```json
{
  "enabledPlugins": ["git-actions"]
}
```

3. Ensure prerequisites are installed:
```bash
# GitHub CLI (required for PR commands)
brew install gh  # macOS
# or download from: https://cli.github.com/

# Authenticate
gh auth login
```

### Basic Usage

```bash
# Commit all changes with AI-generated message
/commit:all

# Commit only staged changes
/commit:staged

# Create a draft pull request (default: target main)
/pr:write

# Create PR targeting specific branch
/pr:write develop

# Edit PR description (existing or draft)
/pr:edit

# Mark PR ready for review
gh pr ready

# Review a pull request
/pr:review 123
```

## Commands

### `/commit` - Create Commits

Create commits with AI-generated messages that follow best practices.

**Syntax:**
```bash
/commit:all       # Stage all changes and commit
/commit:staged    # Commit only staged changes
/commit           # Auto-detect (staged if any, otherwise all)
```

**What it does:**
1. Analyzes your changes (staged or all)
2. Reviews recent commit history to match style
3. Invokes the `commit-writer` agent
4. Generates a concise, information-dense commit message
5. Creates the commit

**Example:**
```bash
$ /commit:all

Analyzing changes...
✓ Reviewed git diff (12 files changed)
✓ Analyzed recent commit history
✓ Generated commit message

Creating commit:
─────────────────────────────────────
feat(auth): add OAuth2 Google provider

Implement OAuth2 authentication flow including:
- Token exchange and refresh logic
- Session persistence with Redis
- Automatic token rotation

Fixes #234
─────────────────────────────────────

✅ Commit created: a1b2c3d
```

**Features:**
- **Style matching**: Adapts to your repository's commit conventions
- **Conventional commits**: Supports feat, fix, refactor, etc. when appropriate
- **Atomic commits**: Ensures one logical change per commit
- **Information-dense**: No redundant words, maximum clarity

**Best Practices Applied:**
- Imperative mood ("Add" not "Added")
- 50-character subject line limit
- Explains WHY and WHAT, not HOW
- References issues when relevant

### `/pr:write` - Create Pull Requests

Create **draft** pull requests with comprehensive, well-structured descriptions. PRs are always created in draft mode for review before publishing.

**Syntax:**
```bash
/pr:write              # Target main (or master if main doesn't exist)
/pr:write develop      # Target develop branch
/pr:write development  # Target development branch
```

**What it does:**
1. Verifies you're on a feature branch
2. Pushes branch to remote (if needed)
3. Analyzes all commits in the branch
4. Invokes the `pr-creator` agent
5. Generates comprehensive PR description
6. Creates **draft** PR on GitHub using `gh` CLI

**Example:**
```bash
$ /pr:write

🚀 Creating pull request...

✓ Verified not on base branch (currently: feature/oauth-google)
✓ Pushed branch to remote
✓ Generated PR description (via pr-creator agent)
✓ Created draft PR #123

🔗 https://github.com/user/repo/pull/123

📋 PR Details:
   Title: feat: Add OAuth2 authentication with Google provider
   Base: main ← feature/oauth-google
   Files changed: 12
   +432 -87 lines
   Status: DRAFT

Next steps:
  • Review description: /pr:edit
  • Mark ready: gh pr ready
  • Add reviewers: gh pr edit --add-reviewer username
```

**Generated PR Structure:**
- **Summary**: Business context and high-level overview
- **Changes**: Organized by component/area, not by file
- **Testing**: Comprehensive checklist of verification
- **Deployment Notes**: Database changes, config, breaking changes
- **Screenshots**: For UI changes (when applicable)
- **Related Links**: Issue references, docs, related PRs

**Features:**
- **Draft mode**: All PRs created as drafts for review before publishing
- **Comprehensive analysis**: Reviews all commits and full diff
- **Structured format**: Scannable, organized sections
- **Deployment ready**: Includes migration steps, rollback plans
- **Testing focused**: Clear validation checklist
- **Flexible targeting**: Specify target branch or default to main

### `/pr:edit` - Edit PR Descriptions

Edit existing PR descriptions or generate drafts before publishing.

**Syntax:**
```bash
/pr:edit           # Current branch's PR or generate draft
/pr:edit 123       # Edit specific PR by number
/pr:edit <url>     # Edit specific PR by URL
```

**Two Modes:**

#### Mode 1: Edit Existing PR
Updates the description of an already-published PR.

```bash
$ /pr:edit 123

📄 Current PR Description:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Title: Add OAuth support
Body: Initial implementation...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Generating updated description...

✨ Generated Updated Description:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Title: feat: Add OAuth2 authentication with Google provider

## Summary
This PR adds OAuth2 authentication...
[Full comprehensive description]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Apply these changes? [y/N] y

✅ PR #123 updated successfully!
🔗 https://github.com/user/repo/pull/123
```

#### Mode 2: Generate Draft
Creates a preview description before publishing the PR.

```bash
$ /pr:edit

No PR exists for this branch yet.
Generating draft description...

📝 Generated PR Description (Draft):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Full description preview]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

What would you like to do?
1. Create PR with this description (/pr:write)
2. Edit the description and then create PR
3. Save to file for later review
4. Cancel

Your choice: _
```

**Features:**
- **Context-aware**: Auto-detects whether PR exists
- **Non-destructive**: Always shows preview before updating
- **Flexible**: Edit, save, or publish directly
- **Comprehensive**: Re-generates full description based on current state

### `/pr:review` - Review Pull Requests

Perform comprehensive AI-powered code reviews with multi-dimensional analysis.

**Syntax:**
```bash
/pr:review           # Review current branch's PR
/pr:review 123       # Review specific PR by number
/pr:review <url>     # Review specific PR by URL
```

**What it does:**
1. Fetches PR details from GitHub
2. Retrieves full diff and file changes
3. Analyzes existing review comments
4. Loads project guidelines (CLAUDE.md)
5. Invokes the `pr-reviewer` agent
6. Performs multi-dimensional analysis
7. Generates structured review with confidence scores
8. Optionally posts review to GitHub

**Example:**
```bash
$ /pr:review 123

🔍 Reviewing PR #123: Add OAuth2 authentication

✓ Fetched PR details
✓ Retrieved diff for 12 files (+432/-87 lines)
✓ Found 3 existing review(s) and 7 comment(s)
✓ Loaded project guidelines (CLAUDE.md)
✓ Invoked pr-reviewer agent

⏳ Agent analyzing...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🤖 AI Code Review Results
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Summary
High-quality implementation with 1 critical issue,
3 important items, and 2 suggestions. Recommend
requesting changes to address null pointer exception.

## Critical Issues (Confidence: 90-100)

### 🔴 Null pointer exception in user lookup
**File**: `src/api/users.controller.ts:78`
**Confidence**: 95
**Severity**: Critical

**Issue**:
User lookup doesn't handle null case, will crash server.

**Current code**:
```typescript
const user = await this.userService.findById(id);
return user.profile.email; // <-- user could be null
```

**Recommended fix**:
```typescript
const user = await this.userService.findById(id);
if (!user) {
  throw new NotFoundException(`User ${id} not found`);
}
return user.profile.email;
```

## Important Issues (Confidence: 70-89)

### 🟡 Missing error handling for OAuth failures
[Details...]

### 🟡 N+1 query in dashboard endpoint
[Details...]

### 🟡 Test coverage gap for token refresh
[Details...]

## Observations (Confidence: 50-69)

### 💡 Consider extracting OAuth logic to service
[Details...]

## Positive Highlights ✨
- Excellent test coverage (95% on new code)
- Clean separation of concerns
- Comprehensive error messages
- Good use of TypeScript types

## Testing Assessment
- [x] Adequate test coverage
- [x] Edge cases addressed
- [ ] Token refresh edge cases need tests
- [x] Manual testing guidance clear

## Documentation Assessment
- [x] Complex logic explained
- [x] API changes documented
- [ ] OAuth setup guide needs more detail
- [x] Breaking changes noted

## Recommendation: REQUEST CHANGES

**Rationale**:
The null pointer exception (critical) must be fixed before
merging to prevent production crashes. The 3 important
issues should also be addressed for code quality.

**Blocking Issues**: 1 (critical)
**Non-Blocking Items**: 5 (can be addressed in follow-up)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Actions:
  1. Post review with "Request Changes"
  2. Post as comment only
  3. Save to file
  4. Cancel

Your choice: 1

✅ Review posted with "Request Changes"
🔗 https://github.com/user/repo/pull/123
```

**Review Dimensions:**

The agent analyzes PRs across five key areas:

1. **Code Quality (40% weight)**
   - Style guidelines adherence
   - Clean code principles
   - Naming conventions
   - Code organization

2. **Bugs & Correctness (30% weight)**
   - Logic errors
   - Null/undefined handling
   - Race conditions
   - Error handling

3. **Testing (15% weight)**
   - Test coverage
   - Quality of tests
   - Edge case coverage

4. **Documentation (10% weight)**
   - Code comments
   - API documentation
   - README updates

5. **Performance (5% weight)**
   - Query optimization
   - Memory leaks
   - Algorithmic efficiency

**Confidence Scoring:**

Every finding includes a confidence score (0-100):

- **90-100**: Critical issues, definite bugs
- **70-89**: Important issues, likely problems
- **50-69**: Observations, moderate confidence
- **<50**: Not reported (too speculative)

**Features:**
- **Multi-dimensional**: Reviews code from multiple angles
- **Context-aware**: Considers project guidelines and existing reviews
- **Confidence-based**: Filters out false positives
- **Actionable**: Provides specific code suggestions
- **Structured**: Clear categorization by severity

## Agents

### commit-writer

Expert agent for writing commit messages.

**Capabilities:**
- Analyzes git changes (staged or all)
- Reviews commit history for style consistency
- References the `commit-best-practices` skill
- Generates concise, information-dense messages
- Returns structured message output (subject, body, footer)

**Model**: Opus (for high-quality message generation)

**When invoked:**
- By `/commit:all` and `/commit:staged` commands
- User needs help writing commit messages

### pr-creator

Expert agent for creating PR descriptions.

**Capabilities:**
- Analyzes all commits in a branch
- Reviews complete diff vs base branch
- References the `pr-formatting` skill
- Generates comprehensive, structured PR descriptions
- Adapts to repository style

**Model**: Sonnet (balanced quality and performance)

**When invoked:**
- By `/pr:write` command (new PRs)
- By `/pr:edit` command (updates)
- User needs PR description help

### pr-reviewer

Expert agent for reviewing pull requests.

**Capabilities:**
- Fetches PR from GitHub
- Multi-dimensional code analysis
- Confidence-based finding filtering
- Respects project guidelines
- Generates structured reviews

**Model**: Opus (for thorough analysis)

**When invoked:**
- By `/pr:review` command
- User needs comprehensive PR review

**Review dimensions:**
- Code quality (40%)
- Bugs & correctness (30%)
- Testing (15%)
- Documentation (10%)
- Performance (5%)

## Skills

### commit-best-practices

Guidelines for writing concise, information-dense commit messages.

**Key principles:**
- Imperative mood
- 50-character subject limit
- Information density
- No redundancy
- Focus on WHY and WHAT

**Includes:**
- Commit message format
- Good/bad examples
- Decision tree for writing commits
- Style adaptation guidelines

**Used by:** commit-writer agent

### pr-formatting

Guidelines for structuring comprehensive PR descriptions.

**Key principles:**
- Reviewer empathy
- Scannable structure
- Complete information
- Clear deployment notes

**Includes:**
- Standard PR template
- Section-by-section guidance
- Examples for different PR types
- Adaptive formatting rules

**Used by:** pr-creator agent

## Plugin Architecture

```
git-actions/
├── .claude-plugin/
│   └── plugin.json          # Plugin metadata
├── commands/
│   ├── commit.md            # /commit command
│   ├── pr-write.md          # /pr:write command
│   ├── pr-edit.md           # /pr:edit command
│   └── pr-review.md         # /pr:review command
├── agents/
│   ├── commit-writer.md     # Commit message generation
│   ├── pr-creator.md        # PR description generation
│   └── pr-reviewer.md       # PR review analysis
├── skills/
│   ├── commit-best-practices/
│   │   └── SKILL.md         # Commit guidelines
│   └── pr-formatting/
│       └── SKILL.md         # PR formatting guidelines
└── README.md                # This file
```

**Design principles:**
- **Commands**: User entry points and orchestration (workflow, user approval, execution)
- **Agents**: Pure content generators (analyze changes, generate messages/descriptions)
- **Skills**: Knowledge resources (referenced by agents)
- **Separation**: Zero duplication - agents generate, commands execute

## Prompt Writing Conventions

This plugin follows strict conventions for writing agent, command, and skill prompts to maximize clarity, reduce tokens, and improve AI comprehension.

### Information Dense Keywords (IDKs)

Use precise, unambiguous action verbs. The most effective IDKs are:

**Core Actions:**
- `create` / `update` / `delete` - primary CRUD operations
- `add` / `remove` / `move` / `replace` - modification operations
- `save` / `load` / `fetch` / `post` - I/O operations
- `analyze` / `parse` / `validate` - data processing
- `invoke` / `call` / `execute` - function/agent execution

**Code & Data:**
- `var` / `function` / `class` / `type` - code elements
- `file` / `dir` / `path` - filesystem
- `branch` / `commit` / `diff` - git operations
- `default` / `override` / `fallback` - configuration

**Avoid ambiguous variations:**
```
❌ create → write → build → make → code
✅ create (stop at the clearest keyword)

❌ helping the user create a commit
✅ Create commit using agent

❌ retrieving and analyzing the PR data
✅ Fetch PR data, analyze changes
```

### Prompt Structure

#### Commands (User Entry Points)

Commands should be **concise dispatchers** that validate inputs and invoke agents:

```markdown
---
allowed-tools: Task, Bash(git:*)
argument-hint: [all|staged]
description: Create commits with AI-generated messages
---

## Context
Create commit using `agent-name` agent.

Arguments: `/command:$ARGUMENTS`
- **arg1** - description
- **(empty)** - default behavior

Current: !`git status --short`

## Task
Invoke agent based on argument:
- arg1 → mode A
- arg2 → mode B

## Agent Invocation
```
Use agent-name.
Context: key=value
Tasks: 1) action 2) action
Return: expected output
```

## Examples
```bash
/command:arg1  # Description
/command:arg2  # Description
```
```

**Command Best Practices:**
- Keep under 100 lines
- Use bash code blocks for pre-flight checks
- Use tables for error handling
- No redundant "Important Notes" sections
- Show concrete examples with real commands

#### Agents (Specialized Workers)

Agents should be **focused instruction sets** with clear task breakdowns:

```markdown
---
name: agent-name
description: Expert at X. Use when Y. Analyze Z, create W.
model: opus|sonnet|haiku
color: blue
---

Expert at [specific capability].

## Mission
When invoked:
1. Action A
2. Action B
3. Return result

## Context Gathering
```bash
# Fetch required data
command1
command2
```

## Process

### Step 1: Analyze
- Check X
- Validate Y
- Extract Z

### Step 2: Generate
Apply rules:
- Rule 1 with example
- Rule 2 with code

### Step 3: Execute
```bash
command --flag value
```

## Examples

**Case 1:**
Input: ...
Output: ...

**Case 2:**
Input: ...
Output: ...

## Checklist
- [ ] Item 1
- [ ] Item 2
```

**Agent Best Practices:**
- Keep under 300 lines
- Use numbered steps for sequential processes
- Include concrete code examples
- Show input/output pairs
- Reference skills by name (don't duplicate content)
- Use tables for categorization (error types, confidence levels, etc.)

#### Skills (Knowledge Resources)

Skills should be **reference documentation** with examples:

```markdown
---
name: skill-name
description: Guidelines for X. Use when creating/updating/analyzing Y.
---

# Skill Name

## Core Principles
1. Principle A
2. Principle B

## Rules

### Rule Category 1
- Specific rule with constraint
- Example: `code here`
- Counter-example: ❌ `bad code`

### Rule Category 2
| Pattern | Usage | Example |
|---------|-------|---------|
| X | When Y | `code` |

## Decision Tree
1. Check A → do X
2. Check B → do Y
3. Default → do Z

## Examples

**Good:**
```
example with explanation
```

**Bad:**
```
anti-pattern with reason
```
```

**Skill Best Practices:**
- Keep focused on single domain
- Use decision trees for complex choices
- Show good/bad examples side-by-side
- Include checklists for validation
- Reference external templates when appropriate

### Token Optimization

**Reduce verbosity:**
```markdown
❌ "You are helping the user create a pull request using the specialized pr-creator agent"
✅ "Create PR using `pr-creator` agent"

❌ "Before proceeding, you should verify that..."
✅ "Pre-flight checks:"

❌ "If there are uncommitted changes, you should warn the user that..."
✅ "Uncommitted changes → warn user"
```

**Consolidate bash:**
```bash
❌ Multiple separate checks
if ! command -v gh &>/dev/null; then
  echo "ERROR: gh not found"
  exit 1
fi

✅ Inline with || operator
command -v gh &>/dev/null || { echo "ERROR: Install gh"; exit 1; }
```

**Use tables:**
```markdown
❌ Paragraph per error case
✅ | Error | Action |
   |-------|--------|
   | Case 1 | Fix A |
   | Case 2 | Fix B |
```

### Clarity Best Practices

1. **Start with the action**: Begin sections with verbs (Create, Analyze, Fetch, Post)
2. **Use concrete examples**: Show actual commands, not placeholders
3. **Minimize nesting**: Keep heading hierarchy flat (##, ###, avoid ####)
4. **Inline short code**: Use backticks for commands, blocks for multi-line
5. **Front-load context**: Put the most important information first
6. **Avoid meta-commentary**: Don't explain that you're explaining

### Testing Prompts

Validate prompts by:
1. **Word count**: Commands <500 words, Agents <1500 words, Skills <2000 words
2. **Line count**: Commands <100 lines, Agents <300 lines, Skills <400 lines
3. **Token efficiency**: Every sentence must add unique value
4. **Clarity test**: Can you execute the instructions without interpretation?
5. **Example coverage**: Each major path has a concrete example

### Anti-Patterns

**Avoid these common mistakes:**

❌ **Redundant explanations**
```markdown
## Important Notes
1. The agent does X (already stated in task description)
2. You must do Y (already in the workflow)
```

❌ **Verbose transitions**
```markdown
"Now that we have completed the previous step, we can move on to..."
✅ "Next:"
```

❌ **Hypothetical scenarios**
```markdown
"If the user might want to possibly consider..."
✅ State definite behaviors only
```

❌ **Repeating tool documentation**
```markdown
"The gh pr create command is used to create pull requests..."
✅ Assume tool knowledge, show usage only
```

## Requirements

### Required
- **Git**: Version control (built-in on most systems)
- **Claude Code**: AI-powered CLI assistant

### For PR Commands
- **GitHub CLI (`gh`)**: Required for `/pr:*` commands
  - Install: https://cli.github.com/
  - Authenticate: `gh auth login`

### Optional
- **Project guidelines**: Place `CLAUDE.md` in repo root for custom review criteria

## Configuration

### Custom Commit Format

The plugin adapts to your repository's commit style automatically by analyzing recent commits. To enforce a specific format, add guidelines to `CLAUDE.md`:

```markdown
# Commit Message Guidelines

Use conventional commits format:
- feat: New features
- fix: Bug fixes
- docs: Documentation only
- style: Formatting changes
- refactor: Code restructuring
- test: Test additions
- chore: Maintenance

Example: `feat(auth): add OAuth2 support`
```

### Custom PR Template

If your repository has a PR template at `.github/PULL_REQUEST_TEMPLATE.md`, the plugin will follow it automatically.

### Custom Review Criteria

Add project-specific guidelines to `CLAUDE.md`:

```markdown
# Code Review Guidelines

## Critical Requirements
- All API endpoints must have OpenAPI documentation
- Database queries must use parameterized statements
- All user input must be validated

## Style Requirements
- Use TypeScript strict mode
- Prefer async/await over promises
- Components should be under 200 lines
```

The `pr-reviewer` agent will apply these guidelines with high priority.

## Examples

### Complete Workflow Example

```bash
# 1. Make changes
echo "new feature" > feature.ts

# 2. Commit with AI-generated message
/commit:all
# ✅ Commit created: feat(core): add new feature implementation

# 3. Make more changes
echo "tests" > feature.test.ts

# 4. Commit tests separately
/commit:staged
# ✅ Commit created: test(core): add tests for new feature

# 5. Create draft PR with comprehensive description
/pr:write
# ✅ Draft PR #123 created
# 🔗 https://github.com/user/repo/pull/123

# 6. Review the PR description
/pr:edit
# (or review on GitHub)

# 7. Mark PR ready for review
gh pr ready

# 8. Review the PR code
/pr:review 123
# [Comprehensive AI review generated]
# Recommendation: Approve ✅

# 9. Merge PR
gh pr merge 123 --squash
```

### Fixing a Bug

```bash
# 1. Fix the bug
vim src/auth/login.ts

# 2. Commit with descriptive message
/commit:all
# ✅ Commit: fix(auth): prevent race condition in login flow
#
#    Add request locking to prevent duplicate sessions
#    when user clicks login button multiple times rapidly.
#
#    Fixes #456

# 3. Create draft PR
/pr:write
# Draft PR includes reproduction steps, fix explanation, testing

# 4. Mark ready and get it reviewed
gh pr ready
/pr:review
# AI catches potential edge case in the fix
```

### Updating a PR

```bash
# 1. Make additional changes based on review
vim src/auth/oauth.ts

# 2. Commit the improvements
/commit:staged
# ✅ Commit: refactor(auth): extract token validation to helper

# 3. Update PR description to reflect changes
/pr:edit
# Shows diff between old and new description
# ✅ PR #123 updated with new changes section
```

## Troubleshooting

### GitHub CLI Issues

**Problem**: `gh: command not found`

**Solution**:
```bash
# Install gh CLI
brew install gh  # macOS
# or visit: https://cli.github.com/

# Authenticate
gh auth login
```

**Problem**: `gh` authentication failed

**Solution**:
```bash
# Re-authenticate
gh auth logout
gh auth login

# Verify
gh auth status
```

### Commit Message Issues

**Problem**: Commit message doesn't match repo style

**Solution**: The plugin analyzes recent commits to match style. If it's not working:
1. Check that your repo has consistent commit history
2. Add explicit guidelines to `CLAUDE.md`
3. Review the generated message before confirming

### PR Creation Issues

**Problem**: "Already on base branch" error

**Solution**: Create a feature branch first:
```bash
git checkout -b feature/my-feature
# make changes
/commit:all
/pr:write
```

**Problem**: "No commits to create PR from"

**Solution**: Your branch is up to date with base. Make changes and commit:
```bash
# make changes
/commit:all
/pr:write
```

### Review Issues

**Problem**: Review doesn't catch obvious issues

**Solution**:
1. Check confidence threshold (default: 70)
2. Ensure project guidelines in CLAUDE.md are clear
3. Try focusing on specific areas: `/pr:review 123 --focus bugs`

**Problem**: Too many false positives

**Solution**:
1. Increase confidence threshold: `/pr:review 123 --threshold 85`
2. Update CLAUDE.md with project-specific patterns to ignore

## Best Practices

### Commits
- **Atomic changes**: One logical change per commit
- **Clear messages**: Future developers (including you) will thank you
- **Consistent style**: Let the plugin analyze and match your repo's style

### Pull Requests
- **Regular updates**: Use `/pr:edit` when making substantial changes
- **Comprehensive descriptions**: Include testing, deployment, rollback info
- **Reviewer empathy**: Write for someone unfamiliar with the context

### Reviews
- **Thorough analysis**: Review the full AI report, don't just skim
- **Act on high-confidence findings**: 90+ confidence issues are real problems
- **Discuss medium-confidence items**: 70-89 confidence deserves discussion
- **Consider observations**: 50-69 confidence might spark improvements

## FAQ

**Q: Does this replace human code review?**
A: No. AI review catches common issues and provides structure, but human judgment, business context, and team collaboration are irreplaceable.

**Q: Can I customize the commit message format?**
A: Yes. Add guidelines to `CLAUDE.md` or let the plugin adapt to your repo's existing style.

**Q: How does the plugin handle large PRs?**
A: The pr-reviewer agent can handle large PRs but may warn if context limits are approached. Consider reviewing specific files or splitting large PRs.

**Q: Can I use this with GitLab or Bitbucket?**
A: Currently, PR commands require GitHub CLI (`gh`). Commit commands work with any git repository. GitLab/Bitbucket support could be added in the future.

**Q: Does the plugin store my code anywhere?**
A: No. All analysis happens locally or through Claude's API. The plugin doesn't store or transmit code to third-party services (except GitHub via `gh` CLI for PR operations).

**Q: Can I disable specific commands?**
A: Yes. Commands are individual markdown files. Remove or rename command files you don't want to use.

**Q: How do I report issues or contribute?**
A: [Add your contribution guidelines here]

## Changelog

### v1.0.0 (Initial Release)
- `/commit:all` and `/commit:staged` commands
- `/pr:write` command for creating draft PRs (default: main branch)
- Flexible PR targeting - specify branch or default to main
- All PRs created in draft mode for review before publishing
- `/pr:edit` command for updating PRs or generating draft previews
- `/pr:review` command for AI-powered reviews
- Three specialized agents (commit-writer, pr-creator, pr-reviewer)
- Two skills (commit-best-practices, pr-formatting)
- GitHub integration via gh CLI
- Confidence-based review filtering (70+ threshold)
- Project guideline awareness (CLAUDE.md)
- Information-dense prompt design with IDKs

## License

[Add your license here]

## Credits

Built with [Claude Code](https://docs.claude.com/en/docs/claude-code) plugin system.
