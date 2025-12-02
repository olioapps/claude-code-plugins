---
allowed-tools: [Read, Glob, Grep, Write, AskUserQuestion, Task]
argument-hint: [--skip-clarification]
description: Generate AI-optimized documentation schema for this codebase
---

## Context

Arguments: `/codebase-documentation:document-codebase [FLAGS]`
- **--skip-clarification** - Skip Phase 0 questions, auto-detect everything

This command generates a complete documentation system for AI agents to efficiently navigate the codebase.

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

If validation fails, report error and abort.

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

### Phase 3: Create Utility Commands

Write these template files directly:

**`.claude/commands/audit-docs.md`:**
```markdown
---
description: Detect documentation drift between schema and actual codebase
argument-hint: [--verbose] [--auto-fix] [--domain <name>]
---

# Documentation Audit Command

Compare `.claude/docs/codebase-schema.yaml` against actual filesystem structure to detect drift.

## Instructions

### 1. Load Baseline
Read `.claude/docs/codebase-schema.yaml` to establish expected state.

### 2. Scan Filesystem
For each domain in the schema:
- Navigate to the documented location
- Count files and compare to documented count
- Verify key files still exist
- Check for new undocumented directories

### 3. Classify Drift

**TRIVIAL** (Auto-fixable):
- File counts differ by ±5 or less
- Can auto-update with `--auto-fix`

**MINOR** (Review needed):
- File counts differ by >5
- New directories following existing patterns
- Needs manual review

**SIGNIFICANT** (Investigation required):
- Completely undocumented domains
- Pattern violations
- Major structural changes

### 4. Generate Report

```markdown
# Documentation Audit Report
Generated: {date}

## Summary
- ✓ X domains up-to-date
- ⚠ X domains with drift

## Drift Details

### TRIVIAL
{List items}

### MINOR
{List items}

### SIGNIFICANT
{List items}

## Recommended Actions
1. {Actions to take}
```

### 5. Auto-fix (if `--auto-fix`)
Update counts and timestamps for TRIVIAL drift only.

## Examples
```bash
/audit-docs
/audit-docs --verbose
/audit-docs --auto-fix
/audit-docs --domain {domain_name}
```
```

**`.claude/commands/map-domain.md`:**
```markdown
---
description: Deep domain analysis to generate/update documentation
argument-hint: <domain-name> [--update-schema] [--update-docs]
---

# Domain Mapping Command

Perform deep analysis of a specified domain to generate or update its documentation.

## Instructions

### 1. Validate Domain
Verify the domain exists in the schema or as a valid path.

### 2. Deep Scan
Thoroughly explore the domain:
- Enumerate all files and directories
- Identify file types and counts
- Extract exports and dependencies
- Detect naming conventions
- Find patterns and anti-patterns

### 3. Generate Domain Map

```markdown
# Domain Map: {domain_name}

## Summary
- **Location**: {path}
- **Files**: X files
- **Last Modified**: {date}

## Structure
{Directory tree}

## Key Files
{Important files with descriptions}

## Patterns Detected
{Naming, organization, coding patterns}

## Dependencies
{Internal and external dependencies}

## Recommendations
{Suggested improvements or documentation updates}
```

### 4. Update Docs (if flags provided)
- `--update-schema`: Update codebase-schema.yaml with findings
- `--update-docs`: Update or create domain documentation

## Examples
```bash
/map-domain {domain_name}
/map-domain {domain_name} --update-docs
/map-domain {path/to/directory} --update-schema --update-docs
```
```

### Phase 4: Report Summary

Present final summary to user:

```markdown
## Documentation Generated Successfully

**Application Type**: {from analysis}

**Technology Stack**:
- Language: {language}
- Framework: {framework}
{other stack items}

**Documentation Created**:
- `.claude/commands/prime.md`
- `.claude/commands/audit-docs.md`
- `.claude/commands/map-domain.md`
- `.claude/docs/codebase-schema.yaml`
- `.claude/docs/INDEX.md`
- `.claude/docs/domains/` - {count} domain docs
- `.claude/docs/patterns/` - {count} pattern guides
- Updated `CLAUDE.md`

**Domains Documented**:
{list domains with brief descriptions}

**Patterns Documented**:
{list patterns with brief descriptions}

**Architecture Summary**:
{from analysis.metadata.architecture}

---

**Next Steps**:
1. Run `/prime` to load codebase context
2. Use `/audit-docs` periodically to check for drift
3. Use `/map-domain <name>` for deep dives into specific areas
```

## Responsibilities

**YOU (handler):**
- Ask clarification questions (Phase 0)
- Invoke agents and parse their outputs
- Create utility command files directly
- Report final summary

**codebase-analyzer agent:**
- Explore codebase thoroughly
- Identify structure, stack, domains, patterns
- Return structured analysis

**documentation-generator agent:**
- Create all documentation files
- Use templates and analysis data
- Return confirmation of files created

**Agents do NOT create utility commands. You do NOT explore codebase directly.**

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

### Phase 3 Errors
- **Cannot write utility commands** → Report error, documentation is still usable

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

### Typical Output

After successful run:
```
.claude/
├── commands/
│   ├── prime.md
│   ├── audit-docs.md
│   └── map-domain.md
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
