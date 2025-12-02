---
allowed-tools: [Read, Glob, Grep, Write, AskUserQuestion, Task]
argument-hint: [--skip-clarification] [--dry-run]
description: Generate AI-optimized documentation schema for this codebase
---

## Context

Arguments: `/codebase-documentation:document-codebase [FLAGS]`
- **--skip-clarification** - Skip Phase 0 questions, auto-detect everything
- **--dry-run** - Preview what would be generated without creating files

This command generates a complete documentation system for AI agents to efficiently navigate the codebase.

## Progress Reporting

Display progress to the user at each phase transition:

```markdown
## 🔍 Generating Codebase Documentation...

**Progress:**
- [ ] Phase 0: Clarification
- [ ] Phase 0.5: Checking existing docs
- [ ] Phase 1: Analyzing codebase structure
- [ ] Phase 2: Generating documentation files
- [ ] Phase 3: Creating utility commands
- [ ] Phase 4: Summary report
```

Update checkboxes as each phase completes:
- `[x]` for completed phases
- `[ ]` for pending phases
- Show "→" arrow for current phase (e.g., `→ [ ] Phase 1: Analyzing...`)

## Workflow

### Phase 0: Clarify Application Type

**Skip if `--skip-clarification` flag is present.**

Use AskUserQuestion to gather context:

**Question 1: Application Type**
- "What type of application is this?"
- Options:
  - **Frontend** - Web UI (React, Vue, Angular, Svelte, etc.)
  - **Backend API** - Server/API (Express, FastAPI, Django, Rails, etc.)
  - **Mono-Repo** - Both frontend and backend in one repo
  - **CLI/Library** - Command-line tool or reusable library
  - **Mobile** - Native or cross-platform mobile app
  - **Other** - Let user specify

**Question 2: Architecture Notes**
- "Is there anything specific about this codebase's architecture I should know about?"
- Free text response

Store user responses for agent context.

### Phase 0.5: Check Existing Documentation

Before proceeding to analysis, check if documentation already exists:

```
Check for: .claude/docs/codebase-schema.yaml
```

**If file exists, use AskUserQuestion:**
- "Documentation already exists. What would you like to do?"
- Options:
  - **Regenerate** - Overwrite all existing documentation
  - **Cancel** - Abort the command

If user selects Regenerate, proceed to Phase 1. If Cancel, abort with message:
"Documentation generation cancelled. Existing documentation preserved."

### Phase 1: Invoke Codebase Analyzer

Use Task tool to invoke `codebase-analyzer` agent:

```
Analyze this codebase to understand its structure, technology stack, and organizational patterns.

{IF USER PROVIDED APP TYPE:}
Application Type: {user's answer}

{IF USER PROVIDED ARCHITECTURE NOTES:}
Architecture Notes:
"""
{user's notes}
"""

Return your analysis in the structured format specified in your instructions.
```

**Parse the returned analysis.** Expect format:
```
---ANALYSIS---
{YAML content}
---END---
```

Validate that analysis contains:
- [ ] metadata.project exists
- [ ] metadata.type exists
- [ ] At least one domain defined
- [ ] At least one file_pattern defined
- [ ] Each domain has a confidence level (high/medium/low)
- [ ] Each domain purpose is a single sentence (no compound "and" descriptions)

If validation fails, report error and abort.

### Phase 1.5: Dry Run Preview (if --dry-run flag)

**Only execute this phase if `--dry-run` flag is present.**

Display a comprehensive preview of what would be generated:

```markdown
## 📋 Dry Run Preview

**Files to be created:**
- `.claude/docs/codebase-schema.yaml`
- `.claude/docs/INDEX.md`
{For each domain in analysis:}
- `.claude/docs/domains/{domain_name}.md`
{For each significant pattern in analysis:}
- `.claude/docs/patterns/{pattern_name}.md`
- `.claude/commands/prime.md`
- `.claude/commands/audit-docs.md`
- `.claude/commands/map-domain.md`
- `CLAUDE.md` (update)

**Domains identified ({count}):**
| Domain | Location | Purpose | Confidence |
|--------|----------|---------|------------|
{For each domain from analysis:}
| {name} | `{location}` | {purpose} | {confidence} |

**Patterns to document ({count}):**
{For each pattern from analysis:}
- {pattern_name}: `{pattern}` ({count} files)

**Schema preview:**
```yaml
metadata:
  project: {from analysis}
  type: {from analysis}
  stack:
    language: {from analysis}
    framework: {from analysis}
  architecture: {from analysis}

domains:
  {first 2-3 domain names}:
    ...
```
```

Then use AskUserQuestion:
- "Proceed with documentation generation?"
- Options:
  - **Yes** - Generate all documentation files
  - **No** - Cancel without creating files

If Yes, proceed to Phase 2. If No, abort with message:
"Dry run complete. No files were created."

### Phase 2: Invoke Documentation Generator

Use Task tool to invoke `documentation-generator` agent:

```
Generate documentation for this codebase based on the following analysis.

---ANALYSIS---
{paste complete analysis from Phase 1}
---END---

Create all documentation files as specified in your instructions:
1. .claude/docs/codebase-schema.yaml
2. .claude/docs/INDEX.md
3. .claude/docs/domains/*.md (one per major domain)
4. .claude/docs/patterns/*.md (one per key pattern)
5. .claude/commands/prime.md
6. Update CLAUDE.md

Return confirmation of files created.
```

**Parse the returned confirmation.** Expect format:
```
---FILES_CREATED---
{file list}
---END---
```

### Phase 2.5: Completeness Verification (Optional)

**Skip if analysis had <5 domains.**

Before proceeding, verify the analysis captured structural boundaries appropriately.

**Check for potential missed domains:**
1. Review directories that were NOT made into domains
2. For each, verify it's appropriately covered by another domain
3. Check for file patterns that span multiple directories (cross-cutting concerns)

**Check for over-combined domains:**
1. Review any domain with `confidence: low` or `confidence: medium`
2. Review any domain with count >50 files
3. Verify sub-directories don't have distinct conventions

**If issues found:**
- Note them in observations for the documentation generator
- The generator will add them to the INDEX as "potential areas for further documentation"

**This check is about structural boundaries, not specific domain names.**

### Phase 3: Report Summary

Present final summary to user:

```markdown
## Documentation Generated Successfully

**Application Type**: {from analysis}

**Technology Stack**:
- Language: {language}
- Framework: {framework}
{other stack items}

**Structure Summary:**
- Domains documented: {count}
- File patterns covered: {count}
- Task mappings created: {count}

**Documentation Created**:
- `.claude/commands/prime.md`
- `.claude/docs/codebase-schema.yaml`
- `.claude/docs/INDEX.md`
- `.claude/docs/domains/` - {count} domain docs
- `.claude/docs/patterns/` - {count} pattern guides
- Updated `CLAUDE.md`

**Domains Documented**:
| Domain | Purpose | Files |
|--------|---------|-------|
| {name} | {purpose} | {count} |
{list all domains}

**Quality Checks**:
- [x] All structural boundaries captured
- [x] All patterns mapped to domains
- [x] INDEX table is complete
- [x] No overlapping domains

**Potential Gaps** (if any):
- {List any directories that might warrant separate docs in the future}
- {List any patterns without clear domain ownership}
- {List any medium/low confidence domains that may need review}

**Architecture Summary**:
{from analysis.metadata.architecture}

---

**Maintenance Commands** (from plugin):
- `/codebase-documentation:audit-docs` - Check for documentation drift
- `/codebase-documentation:map-domain <name>` - Deep-dive domain analysis
- `/codebase-documentation:update-docs` - Refresh documentation intelligently

**Next Steps**:
1. Run `/prime` to load codebase context
2. Review any noted "Potential Gaps" and decide if additional documentation needed
3. Use `/codebase-documentation:audit-docs` periodically to check for drift
4. Use `/codebase-documentation:update-docs` to refresh docs after major changes
```

## Responsibilities

**YOU (handler):**
- Ask clarification questions (Phase 0)
- Invoke agents and parse their outputs
- Report final summary

**codebase-analyzer agent:**
- Explore codebase thoroughly
- Identify structure, stack, domains, patterns
- Return structured analysis

**documentation-generator agent:**
- Create all documentation files
- Use templates and analysis data
- Return confirmation of files created

**You do NOT explore codebase directly - agents do the exploration.**

## Error Handling

### Phase 0 Errors
- **User cancels clarification** → Proceed with auto-detection (same as --skip-clarification)

### Phase 1 Errors
- **Codebase analyzer fails** → Report error: "Analysis failed: {error}. Ensure you're in a valid project directory."
- **Empty codebase** → "No source files found. Is this the correct directory?"
- **Invalid analysis format** → Retry once, then report parse error

### Phase 2 Errors
- **Documentation generator fails** → Report error with partial progress
- **Write permission denied** → "Cannot create files. Check directory permissions."
- **Partial file creation** → Report which files succeeded/failed

### Recovery
- If any phase partially succeeds, report what was created
- User can re-run command to retry failed parts
- Existing files will be overwritten (no merge)

## Examples

### Standard Usage

```bash
/codebase-documentation:document-codebase
# Asks clarifying questions, then generates full documentation
```

### Skip Clarification

```bash
/codebase-documentation:document-codebase --skip-clarification
# Auto-detects everything, no questions asked
```

### Dry Run Preview

```bash
/codebase-documentation:document-codebase --dry-run
# Shows preview of what would be generated, asks for confirmation
```

### Combined Flags

```bash
/codebase-documentation:document-codebase --skip-clarification --dry-run
# Auto-detect + preview before generating
```

### Typical Output

After successful run:
```
.claude/
├── commands/
│   └── prime.md
├── docs/
│   ├── codebase-schema.yaml
│   ├── INDEX.md
│   ├── domains/
│   │   ├── components.md
│   │   ├── services.md
│   │   └── utils.md
│   └── patterns/
│       ├── components.md
│       └── services.md
CLAUDE.md (updated)
```

**Note:** Utility commands (`audit-docs`, `map-domain`, `update-docs`) are provided by the plugin and invoked via `/codebase-documentation:*` namespace.

## Troubleshooting

### "Analysis failed: No source files found"
- Ensure you're in the project root directory
- Check if source code is in a subdirectory (try navigating there first)
- Verify files aren't hidden by .gitignore patterns
- Make sure the project has actual source files, not just configuration

### "Cannot create files: Permission denied"
- Ensure the `.claude/` directory is writable
- Check that you have write permissions in the project directory
- Try running with appropriate permissions

### "Domain count seems wrong"
- Use `--skip-clarification` to bypass auto-detection issues
- Manually review results with `/codebase-documentation:map-domain <name>` command
- The analyzer may have combined or split domains based on structural boundaries
- Report patterns that confused the analyzer for future improvements

### "Documentation already exists" prompt keeps appearing
- This is the idempotency check working as intended
- Select "Regenerate" to overwrite existing documentation
- Select "Cancel" to preserve existing documentation

### "Dry run shows unexpected results"
- Review the analysis output carefully before confirming
- Use `--dry-run` to preview changes without risk
- If domains look wrong, cancel and provide more specific architecture notes

### Analysis takes too long
- Large codebases (>2000 files) may take several minutes
- The analyzer samples large directories rather than reading every file
- Use `--skip-clarification` to save time on repeated runs
