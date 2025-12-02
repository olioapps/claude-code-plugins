---
allowed-tools: [Read, Glob, Grep, Write, AskUserQuestion, Task]
argument-hint: [--full-reanalysis] [--skip-audit] [--domains <list>] [--interactive] [--preserve-custom] [--force-recreate] [--no-archive] [--dry-run] [--verbose]
description: Intelligently update codebase documentation by re-analyzing and merging changes
---

# Update Documentation Command

Re-analyze the codebase and intelligently update documentation while preserving manual customizations.

## Context

Arguments: `/codebase-documentation:update-docs [FLAGS]`

**Analysis Control:**
- **--full-reanalysis** - Force complete re-analysis (ignore cached context)
- **--skip-audit** - Skip pre-flight audit check
- **--domains \<list\>** - Only update specific domains (comma-separated)

**Update Behavior:**
- **--interactive** - Prompt for decisions on conflicts
- **--preserve-custom** - Always preserve custom content (default: true)
- **--force-recreate** - Recreate all docs from scratch (lose customizations)
- **--no-archive** - Don't archive removed/replaced docs (overwrite directly)

**Output Control:**
- **--dry-run** - Show what would change without applying
- **--verbose** - Show detailed diff for each change

## When to Use This Command

**Use `/codebase-documentation:update-docs` when:**
- ✅ Codebase structure has changed significantly
- ✅ Multiple domains have drifted (audit-docs shows many issues)
- ✅ New domains or patterns have been added
- ✅ You want to refresh everything without losing customizations

**Don't use when:**
- ❌ Just checking for drift → Use `/codebase-documentation:audit-docs` instead
- ❌ Investigating one domain → Use `/codebase-documentation:map-domain <name>` instead
- ❌ Starting fresh → Re-run `/codebase-documentation:document-codebase`

## Workflow

### Phase 1: Pre-flight Check

#### 1.1: Verify Documentation Exists

Check for required files:
- `.claude/docs/codebase-schema.yaml`
- `.claude/docs/INDEX.md`

**If missing:**
- Error: "No documentation found. Run `/codebase-documentation:document-codebase` first."
- Abort update process

#### 1.2: Detect Customizations

Read existing domain docs from `.claude/docs/domains/*.md`

For each domain doc, identify custom sections (not from template):

**Template sections** (can safely regenerate):
- "## Overview" (first paragraph often template)
- "## Directory Structure" (pure data)
- "## Key Files" (table structure)
- "## Patterns & Conventions" (template structure)
- "## Common Operations" (template)
- "## Dependencies" (pure data)
- "## Related Documentation" (links)

**Custom sections** (must preserve):
- Any heading NOT in template list above
- Blockquotes (often warnings or notes: `> ...`)
- Content with personal pronouns ("we", "our")
- Business-specific terminology
- Custom diagrams (ASCII art)
- TODO/NOTE/WARNING markers
- Custom checklists beyond template

Store customization map: `{ domain: [custom_sections] }`

#### 1.3: Run Quick Audit (unless `--skip-audit`)

Execute internal audit logic (same as `/codebase-documentation:audit-docs --threshold minor`):
1. Load current schema
2. Compare against filesystem
3. Classify drift for all domains

Show summary:
```markdown
## Pre-flight Audit

**Domains with drift:**
- ⚠️ {X} domains with trivial drift
- 🔍 {X} domains with minor drift
- ❌ {X} domains with significant drift

**Customizations detected:**
- {X} domains have custom content that will be preserved
```

Use AskUserQuestion:
- Question: "Found {X} domains with drift. Continue with update?"
- Options: "Continue" | "View details first" | "Cancel"

If "View details", show drift breakdown then re-prompt.

### Phase 2: Re-analyze Codebase

#### 2.1: Invoke Codebase Analyzer

Use Task tool to invoke `codebase-analyzer` agent:

```
Re-analyze this codebase to detect changes since last documentation.

Previous analysis context:
---PREVIOUS_ANALYSIS---
{paste current codebase-schema.yaml content}
---END---

Focus on:
- New domains or structural changes
- Changed file counts and patterns
- New patterns or conventions
- Removed or moved domains

User context (preserve from original):
- Application type: {from previous metadata.type}
- Architecture: {from previous metadata.architecture}

Return updated analysis in your standard ---ANALYSIS--- format.
```

Parse response expecting `---ANALYSIS---...---END---` format.

#### 2.2: Generate Analysis Diff

Compare old schema with new analysis:

```yaml
# Analysis Diff Structure
domains:
  added:
    - {domain_name}: {location, purpose, count}
  removed:
    - {domain_name}: {last known location}
  changed:
    {domain_name}:
      count: {old} → {new}
      location: {old} → {new}  # if moved
      purpose: {old} → {new}   # if changed
      key_files:
        added: [files]
        removed: [files]

file_patterns:
  added: [{pattern_name}: {details}]
  removed: [{pattern_name}]
  changed:
    {pattern_name}:
      count: {old} → {new}
      example: {old} → {new}  # if changed
```

### Phase 3: Classify Changes

For each domain, determine update strategy:

#### REFRESH Strategy
**Criteria:**
- Domain file count changed but structure same
- Pattern examples changed but pattern same
- Key files still exist but others added/removed
- No custom content to preserve

**Action:** Update counts/stats only, minimal changes

#### MERGE Strategy
**Criteria:**
- Domain structure changed but domain still exists
- New subdirectories or patterns within domain
- Documentation exists WITH custom content

**Action:** Regenerate template sections, preserve custom sections

#### RECREATE Strategy
**Criteria:**
- Domain completely restructured
- Domain purpose fundamentally changed
- No existing documentation OR no custom content

**Action:** Archive old (unless `--no-archive`), generate fresh

#### ADD Strategy
**Criteria:**
- New domain discovered (not in current schema)
- New pattern identified

**Action:** Create new documentation

#### REMOVE Strategy
**Criteria:**
- Domain no longer exists in codebase
- Pattern no longer used

**Action:** Archive documentation (not delete, unless `--no-archive`)

### Phase 4: Interactive Review (if `--interactive`)

For each **MERGE** or **RECREATE** change:

Use AskUserQuestion:
- Question: "Domain '{name}' has changed significantly. How should we handle custom content?"
- Show: Summary of changes + list of custom sections found
- Options:
  - "Merge intelligently" - Preserve custom sections
  - "Recreate fresh" - Overwrite with new analysis
  - "Keep current" - Don't update this domain
  - "Review diff first" - Show detailed before/after

### Phase 5: Apply Updates

#### 5.1: Update Schema

1. Start with new analysis as base
2. Preserve metadata (project name, user notes if any)
3. Apply domain changes (add/update/remove)
4. Update file_patterns
5. Update task_mappings if structure changed
6. Update `metadata.documentation.generated_at` timestamp
7. Write to `.claude/docs/codebase-schema.yaml`

#### 5.2: Update INDEX.md

1. Read existing INDEX.md
2. Identify custom sections (non-template content)
3. Regenerate standard sections:
   - Quick Domain Lookup table (add new, remove deleted, update counts)
   - Pattern Guides table
   - Common Task Mappings (if app structure changed)
   - Architecture Quick Reference
4. Preserve custom sections in original positions
5. Write updated INDEX.md

#### 5.3: Update Domain Docs

For each domain, apply determined strategy:

**REFRESH:**
```
1. Read existing doc
2. Update file counts in tables
3. Update directory structure tree
4. Update "Last Updated" timestamp
5. Keep all other content unchanged
6. Write back
```

**MERGE:**
```
1. Read existing doc
2. Parse into sections (template vs custom)
3. Regenerate template sections with new analysis data:
   - Overview (first paragraph)
   - Directory Structure
   - Key Files table
   - Dependencies
   - Related Documentation links
4. Preserve custom sections in their original positions
5. Add "Updated: {date}" note if significant changes
6. Flag conflicts (custom content references deleted files)
7. Write merged doc
```

**RECREATE:**
```
1. If --no-archive NOT set:
   - Create archive: .claude/docs/domains/_archive/{domain}-{date}.md
   - Copy existing doc to archive
2. Generate new doc from template using new analysis
3. Add note: "Previous version archived at {path}" (if archived)
4. Write new doc
```

**ADD:**
```
1. Generate new doc from template
2. Use analysis data for this domain
3. Write to .claude/docs/domains/{domain}.md
```

**REMOVE:**
```
1. If --no-archive NOT set:
   - Create archive: .claude/docs/domains/_archive/{domain}-{date}.md
   - Move existing doc to archive
2. Remove from schema
3. Remove from INDEX.md table
4. Add note in update summary
```

#### 5.4: Update Pattern Guides

Apply same strategy logic to pattern guides:
- REFRESH: Update counts, examples
- MERGE: Preserve custom examples, update template sections
- RECREATE: Archive and regenerate
- ADD: Create new guide
- REMOVE: Archive old guide

#### 5.5: Update CLAUDE.md

1. Read existing CLAUDE.md
2. Preserve all existing content
3. Update any references to changed domains (if found)
4. Update statistics if present in file
5. Write back (only if changes made)

### Phase 6: Validation

Run internal validation checks:

**Schema Validation:**
- [ ] Valid YAML syntax
- [ ] All documented domains have corresponding doc files
- [ ] All patterns have homes (domain or pattern guide)

**Documentation Validation:**
- [ ] All domain docs exist for schema entries
- [ ] INDEX table matches schema domains
- [ ] No broken internal links (doc references non-existent file)
- [ ] Custom sections preserved (if applicable)

**Report issues if validation fails but don't abort.**

### Phase 7: Generate Update Summary

Present comprehensive report:

```markdown
## Documentation Updated Successfully

**Re-analysis Date**: {ISO 8601 timestamp}
**Update Strategy**: {Interactive|Automatic}
**Customizations**: {Preserved|None found|Lost (if --force-recreate)}

---

## Changes Applied

### Schema Updates
- **Domains**: {X} updated, {Y} added, {Z} removed
- **Patterns**: {X} updated, {Y} added, {Z} removed
- **File Count Drift**: {total files changed across all domains}

### Documentation Updates

#### Domains Updated ({count})
| Domain | Strategy | Changes |
|--------|----------|---------|
| {domain} | REFRESH | File count: {old} → {new} |
| {domain} | MERGE | Added subdomain, preserved {X} custom sections |
| {domain} | RECREATE | Structure completely changed, archived previous |

#### New Domains ({count})
| Domain | Location | Purpose |
|--------|----------|---------|
| {new_domain} | `{path}` | {purpose} |

#### Removed Domains ({count})
| Domain | Archived To | Reason |
|--------|-------------|--------|
| {old_domain} | `_archive/{file}` | No longer exists in codebase |

#### Patterns Updated ({count})
| Pattern | Change | Impact |
|---------|--------|--------|
| {pattern} | Count: {old} → {new} | REFRESH |
| {pattern} | NEW | Added guide |

---

## Preserved Customizations

{If custom sections found and preserved:}

**Domains with custom content preserved:**
- `{domain}.md` - {X} custom sections merged
- `{domain}.md` - {Y} custom examples preserved

**Custom INDEX.md sections preserved:**
- {Section name}

---

## Conflicts & Manual Review Needed

{If issues detected during merge:}

⚠️ **{Domain name}**
- Issue: Custom content references deleted file `{filename}`
- Action needed: Review and update custom section
- Location: `.claude/docs/domains/{domain}.md`

---

## Archived Files

{If domains/patterns removed:}

The following files were archived (not deleted):
- `.claude/docs/domains/_archive/{domain}-{date}.md`
- `.claude/docs/patterns/_archive/{pattern}-{date}.md`

Review archived content before permanent deletion.

---

## Validation Results

✅ Schema syntax valid
✅ All domains documented
✅ All patterns have homes
✅ INDEX table complete
✅ No broken links detected
{Or list issues if validation failed}

---

## Next Steps

1. **Review changes**: Check updated domain docs for accuracy
2. **Resolve conflicts**: Address any flagged issues above
3. **Test discovery**: Run `/prime` to verify updated docs work
4. **Audit periodically**: Schedule `/codebase-documentation:audit-docs` to catch future drift

{If conflicts exist:}
⚠️ **Manual review required for {X} conflicts** - See "Conflicts" section above
```

### Dry Run Mode (if `--dry-run`)

Execute all phases EXCEPT Phase 5 (Apply Updates).

Instead of writing files, show:
```markdown
## Dry Run Preview

**The following changes WOULD be applied:**

### Schema Changes
{Show YAML diff}

### Domain Doc Changes
{For each domain, show strategy + summary of changes}

### Files to Create
- {new files}

### Files to Archive
- {files to archive}

**No files were modified.**

To apply these changes, run:
`/codebase-documentation:update-docs` (without --dry-run)
```

## Error Handling

### No Existing Documentation
- **Error**: "No documentation found. Run `/codebase-documentation:document-codebase` first."
- **Abort**: Cannot update what doesn't exist

### Codebase Analyzer Fails
- **Error**: "Re-analysis failed: {reason}"
- **Fallback**: Offer to run `/codebase-documentation:audit-docs` instead
- **Recovery**: Allow retry or abort

### Merge Conflicts
- **Warning**: "Cannot automatically merge {domain}.md - structure changed too much"
- **Interactive options**:
  - "Keep current version" (no update)
  - "Use new version" (lose customizations)
  - "Save both versions" (new as {domain}-new.md)
  - "Manual merge" (show diff, let user decide)

### Write Failures
- **Error**: "Cannot write {file}: {reason}"
- **Fallback**: Save to temporary location, report path
- **Recovery**: Report partial success, list failed files

### Validation Failures
- **Warning**: "Documentation updated but validation found issues"
- **Action**: Complete update, flag issues in summary
- **Suggest**: "Manual review recommended"

## Examples

```bash
# Standard update (interactive, preserve customizations)
/codebase-documentation:update-docs

# Update specific domains only
/codebase-documentation:update-docs --domains components,services,models

# Dry run to preview changes
/codebase-documentation:update-docs --dry-run

# Force complete recreation (lose customizations)
/codebase-documentation:update-docs --force-recreate

# Non-interactive, preserve everything possible
/codebase-documentation:update-docs --preserve-custom

# Update with full reanalysis and verbose output
/codebase-documentation:update-docs --full-reanalysis --verbose

# Quick update, skip audit, no prompts
/codebase-documentation:update-docs --skip-audit

# Update without archiving removed docs
/codebase-documentation:update-docs --no-archive
```

## Success Criteria

A successful update should:
1. ✅ Re-analyze entire codebase accurately
2. ✅ Preserve all user customizations (unless --force-recreate)
3. ✅ Update stale counts, examples, structures
4. ✅ Add documentation for new domains/patterns
5. ✅ Archive removed domains (not delete)
6. ✅ Update INDEX.md and schema consistently
7. ✅ Pass validation checks
8. ✅ Generate clear summary of changes
9. ✅ Handle conflicts gracefully
10. ✅ Work incrementally (don't require full regeneration)
