---
allowed-tools: Task, Glob, Grep, Read, Write, Bash(mkdir:*), Bash(test:*), Bash(ls:*), AskUserQuestion
argument-hint: [project context]
description: Generate a complete atlas skill for codebase navigation
---

## Context

Arguments: `/cartographer:chart [CONTEXT]`
- **[CONTEXT]** - Optional user-provided context about the project (type, architecture, focus areas)

Current directory: !`pwd`

## Workflow

### 1. Pre-flight Checks

**Check for existing atlas:**
```bash
test -d ".claude/skills/atlas" && echo "EXISTS" || echo "NOT_FOUND"
```

**If atlas exists:**
- Use AskUserQuestion: "Atlas already exists. How to proceed?"
  - "Use /cartographer:rechart to update" → Abort with instruction
  - "Overwrite existing atlas" → Continue with warning
  - "Cancel" → Abort

**Check write permissions:**
```bash
mkdir -p .claude/skills/atlas/references && echo "WRITABLE" || echo "NO_PERMISSION"
```

If no permission → Error with fix instructions.

**Check for .atlas-ignore:**
```bash
test -f ".atlas-ignore" && echo "FOUND" || echo "NOT_FOUND"
```

### 2. Invoke Surveyor Agent

```
Use the surveyor agent to analyze the codebase.

User context (HIGHEST PRIORITY):
"""
{user_provided_context}
"""

The agent will return structured analysis in ---ANALYSIS--- format.
```

**Parse surveyor output:**
- Extract metadata, domains, file_patterns, config_files, testing, validation
- Validate all required sections present
- If parsing fails → Report error, suggest retry

### 3. Handle Low Confidence

For any element with LOW confidence:

**Project type LOW confidence:**
- Use AskUserQuestion with detected signals and options
- Apply user selection with HIGH confidence

**Domain LOW confidence (>30% of domains):**
- List low-confidence domains
- Use AskUserQuestion: "Please confirm or adjust these domain classifications"
- Apply user corrections

### 4. Generate Atlas Structure

**Create directory structure:**
```bash
mkdir -p .claude/skills/atlas/references/patterns
```

**Create directories for each domain area:**
- Group domains by logical area (e.g., grow/, common/, api/)
- Create reference subdirectories as needed

### 5. Generate schema.yaml

Using template from `assets/atlas-templates/schema.template.yaml`:

1. Populate metadata section
2. Add all domains with paths, counts, purposes
3. Add file patterns with examples
4. Add task mappings based on detected patterns
5. Add config files list
6. Add testing configuration
7. Add validation commands

**Write to:** `.claude/skills/atlas/references/schema.yaml`

### 6. Generate SKILL.md

Using template from `assets/atlas-templates/SKILL.template.md`:

1. Create project structure ASCII tree
2. Build domain router table (keywords → references)
3. Build pattern router table (tasks → pattern guides)
4. Add file location conventions
5. Add key technologies list

**Keywords for domain router:**
- Extract from domain names and purposes
- Include common synonyms (e.g., "redux, state, slice, store")

**Write to:** `.claude/skills/atlas/SKILL.md`

### 7. Generate Domain References

For each domain:

1. Create directory if needed
2. Generate reference file using `domain-reference.template.md`
3. Include directory tree, key files, patterns
4. Add related domains links

**Write to:** `.claude/skills/atlas/references/{area}/{domain}.md`

### 8. Generate Pattern Guides

For each detected pattern type:

1. Generate pattern guide using `pattern-reference.template.md`
2. Include implementation steps
3. Add conventions from observed code
4. Include codebase examples

**Write to:** `.claude/skills/atlas/references/patterns/{pattern}.md`

### 9. Create .atlas-ignore (if not exists)

If no .atlas-ignore found in pre-flight:
- Copy from `assets/atlas-templates/atlas-ignore.template`
- Write to repository root

### 10. Validate Generated Atlas

**Check all files created:**
- SKILL.md exists and has content
- schema.yaml is valid YAML
- All referenced files exist
- No broken links in SKILL.md

**If validation fails:**
- Report specific issues
- Attempt to fix or regenerate affected files
- Warn user of partial generation

### 11. Report Results

```markdown
## Atlas Generated Successfully

**Location:** `.claude/skills/atlas/`

**Summary:**
- Project type: {type} (confidence: {confidence})
- Domains identified: {count}
- File patterns detected: {count}
- Reference files created: {count}

**Files created:**
- `.claude/skills/atlas/SKILL.md`
- `.claude/skills/atlas/references/schema.yaml`
{list of domain references}
{list of pattern guides}

**Next steps:**
- Run `/atlas` to use the generated skill
- Run `/cartographer:calibrate` to verify accuracy
- Run `/cartographer:explore <domain>` to enrich specific domains
```

## Error Handling

| Error | Action | Recovery |
|-------|--------|----------|
| Atlas exists | Prompt for overwrite/rechart | User decides |
| No write permission | Show error with fix | User fixes permissions |
| Surveyor fails | Report error | Suggest retry with more context |
| Low confidence (>50%) | Interactive prompts | User confirms classifications |
| Template missing | Report missing template | Check plugin installation |
| Validation fails | Report specific issues | Attempt auto-fix or manual fix |

## Responsibilities

**YOU (handler):**
- Pre-flight checks and permissions
- Invoke surveyor agent
- Handle low confidence prompts
- Generate all atlas files from templates
- Validate output
- Report results

**Surveyor agent:**
- Analyze codebase structure
- Detect project type, domains, patterns
- Return structured analysis

**You do NOT explore the codebase directly. The surveyor agent does that.**
