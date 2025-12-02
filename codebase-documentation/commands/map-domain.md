---
allowed-tools: [Read, Glob, Grep, Write, AskUserQuestion]
argument-hint: <domain-name> [--compare] [--update-schema] [--update-docs] [--interactive] [--verbose] [--quiet] [--focus <area>]
description: Deep domain analysis to generate or update documentation
---

# Domain Mapping Command

Perform deep analysis of a specific domain to generate detailed documentation, identify patterns, and detect organizational issues.

## Context

Arguments: `/codebase-documentation:map-domain <domain-name> [FLAGS]`

**Required:**
- **\<domain-name\>** - Domain name from schema OR directory path

**Optional Flags:**
- **--compare** - Compare with existing documentation
- **--update-schema** - Update codebase-schema.yaml with findings
- **--update-docs** - Update/create domain documentation file
- **--interactive** - Prompt for decisions during analysis
- **--verbose** - Include detailed file listings
- **--quiet** - Minimal output (summary only)
- **--focus \<area\>** - Focus analysis on: patterns|dependencies|tests|structure

## Purpose

Use this command to:
- **Explore a domain deeply** - Get comprehensive view of structure and contents
- **Update stale documentation** - Refresh docs after major changes
- **Investigate drift** - Understand what changed since docs were generated
- **Discover patterns** - Identify conventions and anti-patterns
- **Prepare for refactoring** - Understand dependencies before changes

## Instructions

### 1. Validate Domain

**If domain name matches schema entry:**
- Read domain definition from `.claude/docs/codebase-schema.yaml`
- Use `domain.location` as target path
- Use existing context (purpose, patterns, key_files)

**If domain name is a path (starts with `/`, `./`, or contains `/`):**
- Validate path exists using Glob
- Treat as ad-hoc domain (no existing context)
- Generate documentation from scratch

**Error cases:**
- Domain not in schema AND path doesn't exist → Error
- Suggest: "Available domains: {list from schema}" or "Provide a valid directory path"

### 2. Deep Scan

Thoroughly explore the domain using Read, Glob, and Grep tools.

#### A. Filesystem Enumeration

```
# List all files recursively
Glob: {domain_location}/**/*

# Count by file type
Glob: {domain_location}/**/*.{ext} for common extensions

# Find subdirectories
Glob: {domain_location}/*/
```

**Collect:**
- Total file count
- File types and counts (.js, .ts, .test.js, .md, etc.)
- Directory structure (depth, breadth)
- Approximate lines of code (sample 5-10 files, extrapolate)

#### B. Pattern Detection

**File Naming Patterns:**
Sample 10-15 files across directory and identify:
- Case convention: `PascalCase`, `camelCase`, `kebab-case`, `snake_case`
- Suffixes: `.service.ts`, `.controller.js`, `.model.ts`, `.test.ts`
- Prefixes: `use-`, `with-`, `get-`, `_`
- Consistency level (all files follow same pattern vs mixed)

**Directory Organization:**
Classify as:
- **Flat** - All files in one level
- **Nested** - Subdirectories for categorization
- **Feature-based** - Grouped by functionality
- **Type-based** - Grouped by file type (components/, hooks/, utils/)
- **Mixed** - Combination of approaches

**Module Structure:**
- **Single-file modules** - One file = one export
- **Multi-file modules** - Directory with index.ts barrel
- **Mixed approach**

#### C. Code Analysis (sample files)

For 5-10 representative files, Read and extract:
- **Exports**: Functions, classes, types, constants
- **Imports**: Internal vs external dependencies
- **Key patterns**: React hooks, Express routes, class definitions, etc.

**Dependency Analysis:**
- **Internal imports**: Which other domains/directories does this depend on?
- **External imports**: Which npm/pip packages are used?
- **Coupling level**: High (many cross-domain imports) vs Low (isolated)

#### D. Test Coverage Detection

```
# Find test files
Glob: {domain_location}/**/*.test.{js,ts,jsx,tsx}
Glob: {domain_location}/**/*.spec.{js,ts,jsx,tsx}
Glob: {domain_location}/__tests__/**/*
```

**Calculate:**
- Files with tests vs without tests
- Test file naming pattern
- Test location pattern (co-located vs separate __tests__ directory)
- Approximate coverage percentage

#### E. Documentation Discovery

```
# Find README files
Glob: {domain_location}/**/README.md

# Find inline docs (sample)
Grep: /\*\*/ in sample files for JSDoc/TSDoc
```

**Assess:**
- Presence of domain-level README
- Inline documentation quality (sample)
- Documentation coverage: High/Medium/Low/None

### 3. Detect Issues

#### Pattern Violations
- **Naming inconsistencies**: Mixed conventions in same directory
- **Structural inconsistencies**: Some subdirectories nested, others flat
- **Module pattern violations**: Mix of single and multi-file modules without clear reason

#### Organizational Issues
- **Orphaned files**: Files that don't fit the dominant pattern
- **Oversized files**: Files significantly larger than average (may need splitting)
- **Empty directories**: Directories with no files (cleanup candidates)

#### Quality Concerns
- **Missing tests**: Critical files without test coverage
- **Missing documentation**: Complex files without comments
- **Dead code candidates**: Files not imported anywhere (use Grep to check)

#### Cross-Cutting Patterns
- **Pattern spans domains**: Files with same naming convention across multiple domains
  - Example: `useAuth` hook, `getAuth` util, `withAuth` HOC in different directories
  - May warrant consolidation or separate "patterns" documentation

### 4. Generate Domain Map

Create comprehensive markdown report:

```markdown
# Domain Map: {domain_name}

> **Generated**: {ISO 8601 timestamp}
> **Purpose**: {from schema if exists, else inferred from analysis}

---

## Summary

| Metric | Value |
|--------|-------|
| **Location** | `{path}` |
| **Total Files** | {X} files |
| **Directories** | {X} directories |
| **Approx. Lines** | ~{XX,XXX} |
| **File Types** | {list with counts} |
| **Test Coverage** | {X}/{Y} files ({Z}%) |
| **Last Modified** | {most recent file date if detectable} |

---

## Directory Structure

```
{domain}/
├── subdirectory1/          ({X} files)
│   ├── file1.ext
│   └── file2.ext
├── subdirectory2/          ({X} files)
│   └── ...
└── README.md
```

---

## File Categorization

{Organize files by purpose, structure, or type - adapt to what makes sense for this domain}

### {Category 1} ({X} files)
| File | Purpose | Exports | Dependencies |
|------|---------|---------|--------------|
| `file1.ts` | {brief description} | {key exports} | {key deps} |

### {Category 2} ({X} files)
{Similar table}

### Uncategorized ({X} files)
{Files that don't fit clear categories - may indicate organizational issues}

---

## Patterns & Conventions

### Naming Conventions
- **Consistency**: {High|Medium|Low}
- **Primary Pattern**: {describe dominant pattern}
- **Variations**: {list any variations observed}
- **Inconsistencies**: {list if any - these are potential issues}

**Examples:**
- ✅ Follows pattern: `{example file following convention}`
- ❌ Violates pattern: `{example file not following convention}` (if any)

### File Organization
- **Structure**: {Flat|Nested|Feature-based|Type-based|Mixed}
- **Rationale**: {observed logic for organization}
- **Depth**: {max directory depth}

### Module Pattern
- **Type**: {Single-file|Multi-file|Mixed}
- **Index/Barrel Files**: {Yes/No - list locations if yes}
- **Export Style**: {Named|Default|Mixed}

### Code Patterns (if detected)
{List any recurring code patterns observed in sampled files}
- Pattern 1: {description}
- Pattern 2: {description}

---

## Test Coverage

| Metric | Value |
|--------|-------|
| **Files with Tests** | {X}/{Y} ({Z}%) |
| **Test Pattern** | `{pattern}` |
| **Test Location** | {Co-located|Separate __tests__|Mixed} |

### Untested Files (Priority Review)
{List files without corresponding tests, prioritize by apparent importance}

1. `{file}` - {why it should be tested / what it does}
2. `{file}` - {why it should be tested}

---

## Dependencies

### Internal Dependencies (This domain imports from)
| Domain/Path | Import Count | Description |
|-------------|--------------|-------------|
| `{domain}` | {X} imports | {brief description} |

### External Dependencies (npm/pip packages)
| Package | Usage | Count |
|---------|-------|-------|
| `{package}` | {how it's used} | {X} files |

### Reverse Dependencies (Other code imports this domain)
{If detectable via Grep - may require scanning outside domain}
- `{other_domain}` imports from this domain

### Coupling Assessment
- **Level**: {High|Medium|Low}
- **Rationale**: {explanation based on import analysis}

---

## Issues & Recommendations

### 🔴 High Priority

#### {Issue Title}
- **Type**: {Pattern Violation|Quality Issue|Organizational Issue}
- **Location**: `{file or directory}`
- **Description**: {what's wrong}
- **Impact**: {why it matters}
- **Recommendation**: {specific action to take}

### 🟡 Medium Priority
{Similar format}

### 🟢 Low Priority / Nice-to-Have
{Similar format}

---

{If --compare flag or existing docs found:}
## Comparison with Documentation

### Drift Detected: {TRIVIAL|MINOR|SIGNIFICANT|NONE}

#### Changed
| Item | Documented | Actual | Drift |
|------|------------|--------|-------|
| File count | {X} | {Y} | {+/- Z} ({N}%) |
| Key file | `{file}` | Moved to `{new_path}` | Location changed |

#### New (Not in docs)
- `{new_subdirectory}/` - {X} files, {purpose}
- `{new_file}` - {purpose}

#### Removed (In docs, not found)
- `{missing_file}` - {possible reason}

---

{If --update-schema flag:}
## Proposed Schema Updates

```yaml
{domain_name}:
  location: {path}
  purpose: {updated purpose description}
  count: {updated file count}
  confidence: {high|medium|low}
  key_files:
    - {updated key file 1}
    - {updated key file 2}
```

**Changes from current schema:**
- {List specific differences}

---

## Next Steps

### Immediate Actions
1. {Specific actionable task}
2. {Specific actionable task}

### Documentation Tasks
- Update schema: `/codebase-documentation:map-domain {domain} --update-schema`
- Update docs: `/codebase-documentation:map-domain {domain} --update-docs`
- Full audit: `/codebase-documentation:audit-docs --domain {domain}`

### Code Tasks (if issues found)
1. {Refactoring suggestion}
2. {Test coverage improvement}
3. {Pattern standardization}
```

### 5. Interactive Mode (if `--interactive` flag)

Use AskUserQuestion for key decisions:

**Before Analysis Starts:**
- Question: "Focus areas for analysis?"
- Options: "Full analysis" (default) | "Patterns only" | "Dependencies only" | "Tests only" | "Structure only"

**After Issues Detected (for HIGH priority only):**
- Question: "Issue detected: {title}. How should we handle this?"
- Options: "Document as-is" | "Flag for refactor" | "Investigate now" | "Ignore"

**Before Schema Update (if `--update-schema`):**
- Question: "Update codebase-schema.yaml with these changes?"
- Show: YAML diff of proposed changes
- Options: "Update" | "Save draft" | "Skip"

**Before Docs Update (if `--update-docs`):**
- Question: "Update domain documentation?"
- Show: Summary of changes
- Options: "Update" | "Create new version" | "Skip"

### 6. Compare Mode (if `--compare` flag)

**Requires existing domain documentation.**

1. Check if `.claude/docs/domains/{domain}.md` exists
2. If not found: Warning "No existing documentation found for comparison", proceed with normal analysis
3. If found:
   - Parse existing doc to extract documented structure
   - Compare findings with documented state
   - Generate drift analysis using same classification as audit-docs (TRIVIAL/MINOR/SIGNIFICANT)
   - Include "Comparison with Documentation" section in report

### 7. Update Schema (if `--update-schema` flag)

1. Read current `.claude/docs/codebase-schema.yaml`
2. Update domain section with findings:
   - File count
   - Purpose (if initial generation or significantly changed)
   - Key files (add new important files, remove missing ones)
   - Confidence level based on analysis clarity
3. If domain didn't exist in schema, add new domain section
4. Preserve all other schema content unchanged
5. Update `metadata.documentation.generated_at` timestamp if field exists
6. Write updated schema
7. Report changes made

### 8. Update Domain Docs (if `--update-docs` flag)

1. Check if `.claude/docs/domains/{domain}.md` exists
2. **If exists:**
   - Read current doc
   - Identify custom sections (non-template content)
   - Regenerate template sections with new data
   - Preserve custom sections in their original positions
   - Add "Last Updated" timestamp
3. **If doesn't exist:**
   - Create new domain doc using standard template
   - Fill with all findings from analysis
4. Write documentation file
5. Report action taken (created vs updated)

### 9. Focus Mode (if `--focus <area>` provided)

Limit analysis to specific area:

- `--focus patterns` - Only naming conventions, file organization, code patterns
- `--focus dependencies` - Only internal/external imports, coupling analysis
- `--focus tests` - Only test coverage, untested files
- `--focus structure` - Only filesystem enumeration, directory organization

Generate abbreviated report with only relevant sections.

### 10. Output Control

**Default:** Display full markdown report

**With `--quiet`:** Only show summary table, skip detailed sections

**With `--verbose`:** Include:
- Full file listings (not just counts)
- All sampled file contents
- Complete import analysis for every file

## Error Handling

### Domain Not Found
- **Error**: "Domain '{name}' not found in schema and path doesn't exist"
- **List**: Available domains from schema
- **Suggest**: "Provide a valid domain name or directory path"

### Path Not Accessible
- **Error**: "Cannot access path: `{path}`"
- **Check**: Permissions, path validity, typos

### Empty Domain
- **Warning**: "Domain `{path}` contains no files"
- **Action**: Generate minimal report noting empty state, suggest removal from schema

### Schema Update Failed
- **Error**: "Failed to update schema: {reason}"
- **Fallback**: Display proposed changes for manual application
- **Suggest**: "Check file permissions or manually update schema"

### Docs Update Failed
- **Error**: "Failed to write documentation: {reason}"
- **Fallback**: Display full report for manual saving

### Compare Mode Without Existing Docs
- **Warning**: "No existing documentation found at `.claude/docs/domains/{domain}.md`"
- **Action**: Proceed with normal analysis (no comparison section)

## Sampling Strategy

For large domains (>100 files):
1. Sample 10-15 representative files for deep analysis
2. Select files from different subdirectories
3. Include mix of file types
4. Use Glob counts for statistics
5. Note sampling approach in report summary

## Examples

```bash
# Basic domain mapping
/codebase-documentation:map-domain components

# Map with comparison against existing docs
/codebase-documentation:map-domain services --compare

# Interactive mapping with updates
/codebase-documentation:map-domain authentication --interactive --update-schema --update-docs

# Map arbitrary directory (not in schema)
/codebase-documentation:map-domain src/custom/area --verbose

# Focused analysis on patterns only
/codebase-documentation:map-domain utils --focus patterns

# Quick summary only
/codebase-documentation:map-domain models --update-schema --quiet

# Full interactive workflow
/codebase-documentation:map-domain api --interactive --compare --update-docs
```

## Success Criteria

A successful domain map should:
1. ✅ Comprehensively analyze domain structure
2. ✅ Identify patterns and conventions accurately
3. ✅ Detect organizational issues and violations
4. ✅ Provide actionable recommendations
5. ✅ Generate clear, scannable documentation
6. ✅ Work for any domain structure (not assume specific architecture)
7. ✅ Handle missing/outdated documentation gracefully
8. ✅ Allow selective updates (schema vs docs)
