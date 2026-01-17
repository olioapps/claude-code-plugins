---
allowed-tools: Read, Write, Bash(test:*), AskUserQuestion
argument-hint: [--reset]
description: Set up CLAUDE.md with atlas section markers
---

## Context

Arguments: `/cartographer:orient [OPTIONS]`
- **--reset** - Remove existing atlas section and regenerate
- **(empty)** - Add/update atlas section preserving existing content

Current directory: !`pwd`

## Workflow

### 1. Pre-flight Checks

**Check if CLAUDE.md exists:**
```bash
test -f "CLAUDE.md" && echo "EXISTS" || echo "NOT_FOUND"
```

**Check if atlas exists:**
```bash
test -f ".claude/skills/atlas/SKILL.md" && echo "EXISTS" || echo "NOT_FOUND"
```

### 2. Determine Action

**If CLAUDE.md doesn't exist:**
- Create new CLAUDE.md with atlas section

**If CLAUDE.md exists:**
- Check for existing atlas section markers:
  - `<!-- atlas:start -->`
  - `<!-- atlas:end -->`
- If markers exist and not --reset: Update between markers
- If markers exist and --reset: Remove section, regenerate
- If no markers: Add new section at appropriate location

### 3. Generate Atlas Section

**Read atlas SKILL.md:**
```bash
test -f ".claude/skills/atlas/SKILL.md"
```

**Create atlas section:**

```markdown
<!-- atlas:start -->
## Codebase Navigation

This project uses an atlas skill for AI-optimized codebase navigation.

### Quick Reference

Run `/atlas` or ask "where is X?" to get instant routing to relevant code.

### Atlas Location

- **SKILL.md**: `.claude/skills/atlas/SKILL.md`
- **Schema**: `.claude/skills/atlas/references/schema.yaml`
- **References**: `.claude/skills/atlas/references/`

### Key Domains

{domain_summary_table}

### Maintenance

- **Check health**: `/cartographer:calibrate`
- **Update atlas**: `/cartographer:rechart`
- **Deep dive**: `/cartographer:explore <domain>`

<!-- atlas:end -->
```

**Generate domain summary from schema:**
- Read schema.yaml
- Create table with top domains (up to 10)
- Include path and purpose

### 4. Update CLAUDE.md

**If creating new:**
```markdown
# {Project Name}

{atlas_section}

## Development

{placeholder for user to add}
```

**If updating existing:**

1. Find insertion point:
   - After title/description
   - Before first major section
   - Or at end if structure unclear

2. Insert/replace atlas section

3. Preserve all other content

### 5. Handle Conflicts

**If malformed markers found:**
```
⚠️ Found malformed atlas section markers in CLAUDE.md

Current state:
{show markers found}

Options:
1. Fix markers and update atlas section
2. Remove all atlas markers and regenerate
3. Show me the file for manual fix
4. Abort
```

**If multiple marker pairs:**
```
⚠️ Multiple atlas sections found in CLAUDE.md

This may cause issues. Options:
1. Keep first section, remove others
2. Remove all and add single section
3. Show me the file for manual fix
4. Abort
```

### 6. Report Results

**Success:**
```markdown
## CLAUDE.md Updated

**Action:** {Created | Updated | Reset}

**Atlas section location:** Lines {start}-{end}

**Content added:**
- Domain summary table ({count} domains)
- Quick reference instructions
- Maintenance commands

**Next steps:**
- Review CLAUDE.md for accuracy
- Add project-specific instructions as needed
- Commit changes when ready
```

**If atlas not found:**
```markdown
## CLAUDE.md Updated (Partial)

**Note:** Atlas not found at `.claude/skills/atlas/`

Added placeholder atlas section. To complete setup:
1. Run `/cartographer:chart` to generate atlas
2. Run `/cartographer:orient` again to populate domain table
```

---

## Section Format

The atlas section uses HTML comments as markers for reliable detection:

```markdown
<!-- atlas:start -->
{content}
<!-- atlas:end -->
```

This allows:
- Easy detection for updates
- Clean rendering (markers hidden in preview)
- Preservation during manual edits

---

## Error Handling

| Error | Action | Recovery |
|-------|--------|----------|
| Can't write CLAUDE.md | Report permission error | User fixes permissions |
| Malformed markers | Interactive prompt | User chooses fix |
| Multiple sections | Interactive prompt | User chooses resolution |
| Atlas not found | Add placeholder | User runs chart then orient |

## Responsibilities

**YOU (handler):**
- Check CLAUDE.md state
- Generate atlas section from current atlas
- Insert/update section preserving other content
- Handle conflicts interactively
- Report results

**You manage CLAUDE.md integration. Keep changes minimal and targeted.**
