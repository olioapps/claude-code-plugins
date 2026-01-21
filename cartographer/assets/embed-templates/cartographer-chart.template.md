<!--
Embedded Cartographer Command: chart
Source: cartographer/commands/cartographer/chart.md
Standalone version for plugin-free operation
-->
---
model: sonnet
allowed-tools: Task, Glob, Grep, Read, Write, Bash(mkdir:*), Bash(test:*), Bash(ls:*), AskUserQuestion
argument-hint: [--interactive|--auto] [--mode=domains|layers|hybrid] [context]
description: Generate a complete atlas skill for codebase navigation
---

## Context

Arguments: `/chart [OPTIONS] [CONTEXT]`

**Options:**
- `--interactive` - (DEFAULT) Guided interview session before deep analysis
- `--auto` - Skip interview, fully automatic analysis (for CI/automation)
- `--deep` - Include import graph analysis for more accurate domain boundaries
- `--mode=<mode>` - Pre-select mapping mode (skips that interview question)
  - `domains` - Feature/directory-based organization (e.g., users/, auth/, payments/)
  - `layers` - Backend layer-based organization (e.g., controllers/, providers/, daos/)
  - `hybrid` - Generate both domain and layer views

- **[CONTEXT]** - Optional user-provided context about the project (type, architecture, focus areas)

Current directory: !`pwd`

## Interactive vs Auto Mode

| Mode | When to Use | Flow |
|------|-------------|------|
| `--interactive` (default) | First-time charting, unfamiliar codebase | Quick scan → Interview → Deep analysis → Review → Generate |
| `--auto` | CI/automation, re-charting, known codebase | Full analysis → Generate |

**Interactive mode benefits:**
- Catches surveyor mistakes early with human validation
- Identifies critical domains for deeper analysis
- Discovers custom patterns the surveyor might miss
- Lets developer choose organization style that matches their mental model

## Mapping Modes

| Mode | Best For | Output Focus |
|------|----------|--------------|
| `domains` | Feature-based codebases, frontend SPAs | Groups by business domain |
| `layers` | Backend APIs, layered architecture | Groups by architectural layer |
| `hybrid` | Complex codebases, fullstack apps | Provides both views for flexibility |

## Workflow

### 1. Pre-flight Checks

**Check for existing atlas:**
```bash
test -d ".claude/skills/atlas" && echo "EXISTS" || echo "NOT_FOUND"
```

**If atlas exists:**
- Use AskUserQuestion: "Atlas already exists. How to proceed?"
  - "Use /rechart to update" → Abort with instruction
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

**Determine mode:**
- If `--auto` flag → Skip to Step 3 (Full Analysis)
- If `--interactive` or no flag → Continue to Step 2 (Interview)

---

## Interactive Flow (Default)

### 2. Quick Reconnaissance

**Run surveyor in quick-scan mode:**
```
Use the surveyor agent in QUICK_SCAN mode.

Only analyze:
- Directory structure (top 2 levels)
- Config files (package.json, tsconfig.json, etc.)
- Obvious patterns (no deep file reading)

Return preliminary findings in 10-15 seconds.
```

**Extract from quick scan:**
- Project type guess
- Detected organization style (domains vs layers vs hybrid)
- Preliminary domain list
- Preliminary layer list (if applicable)
- Detected file patterns

### 2a. Interview Session

Use AskUserQuestion for each topic. Present quick scan findings and gather corrections.

**Question 1: Organization Style**
```
Based on my quick scan, I detected: {detected_style}

Evidence:
- {evidence_1}
- {evidence_2}

How would you like the atlas organized?
```
Options:
- "Directory/Domain-based" - Group by business domains (users/, auth/, payments/)
- "Semantic Layers" - Group by architectural layers (controllers → providers → DAOs)
- "Hybrid (both views)" - Generate both domain and layer mappings
- "Other" - Let me explain...

**Question 2: Domain Validation**
```
I detected these domains:
{table of domains with file counts}

Are there any domains I missed or should rename?
```
Options:
- "Looks correct"
- "Add domains" → Follow-up: "What domains should I add? (comma-separated)"
- "Remove/rename domains" → Follow-up: "Which domains need adjustment?"
- "Other"

**Question 3: Critical Domains**
```
Which domains are most critical and should receive deeper analysis?
(These will get more detailed documentation and pattern extraction)
```
Options: Multi-select from detected + user-added domains

**Question 4: Custom Patterns**
```
Are there any custom naming patterns I should know about?

Examples:
- "*.handler.ts for background jobs"
- "*.gateway.ts for external API clients"
- "{domain}.module.ts for module entry points"
```
Options:
- "No custom patterns"
- "Yes, let me describe them" → Follow-up text input

**Question 5: Areas to Skip**
```
Any directories I should ignore during deep analysis?
(Besides standard exclusions like node_modules, .git, dist, etc.)
```
Options:
- "No additional exclusions"
- "Yes, skip these" → Follow-up: "Which directories? (comma-separated)"

**Question 6: Import Graph Analysis** (skip if `--deep` already specified)
```
Would you like me to analyze import relationships for more accurate domain boundaries?

This helps detect:
- Hidden coupling between domains
- Layering violations (e.g., controllers importing DAOs directly)
- Domains that should be split or merged

Takes ~30-60 seconds extra for medium codebases.
```
Options:
- "Yes, run import analysis" → Set `deep_analysis: true`
- "No, directory-based detection is sufficient" → Set `deep_analysis: false`

### 2b. Compile Interview Results

Build enhanced context for deep analysis:
```yaml
interview_results:
  organization_style: {user_selected}
  domains:
    confirmed: [...]
    added: [...]
    removed: [...]
    critical: [...]
  custom_patterns:
    - pattern: "*.handler.ts"
      purpose: "background job handlers"
  exclusions:
    - "legacy/"
    - "deprecated/"
  deep_analysis: {true|false}  # From Question 6 or --deep flag
```

---

## Full Analysis (Both Modes)

### 3. Invoke Surveyor Agent (Deep Analysis)

```
Use the surveyor agent to analyze the codebase.

Mode: {--auto → full | --interactive → guided}

{IF interactive, include interview results:}
Interview context (HIGHEST PRIORITY):
"""
Organization style: {user_selected}
Additional domains to find: {added_domains}
Critical domains (analyze deeply): {critical_domains}
Custom patterns: {custom_patterns}
Directories to skip: {exclusions}
"""

User context:
"""
{user_provided_context}
"""

The agent will return structured analysis in ---ANALYSIS--- format.
```

**Parse surveyor output:**
- Extract metadata, domains, layers, file_patterns, config_files, testing, validation
- Validate all required sections present
- If parsing fails → Report error, suggest retry

### 3b. Import Graph Analysis (Optional)

**If `--deep` flag OR `deep_analysis: true` from interview:**

```
Use the import-analyzer agent to analyze import relationships.

Context from surveyor:
"""
Domains detected: {list of domains with paths}
Layers detected: {list of layers if applicable}
Organization style: {domains|layers|hybrid}
"""

The agent will return structured analysis in ---IMPORT_ANALYSIS--- format.
```

**Parse import-analyzer output:**
- Extract coupling_analysis, layering_violations, domain_adjustments
- Extract extracted_anti_patterns for injection into schema.yaml

**Merge import analysis into surveyor results:**

1. **Domain adjustments:**
   - If split_candidates found → Present to user for confirmation
   - If merge_candidates found → Present to user for confirmation
   - If new_domain_candidates found → Add to domain list with LOW confidence

2. **Anti-patterns injection:**
   - For each pattern in `extracted_anti_patterns`:
   - Add to corresponding pattern's `anti_patterns_summary`

3. **Coupling insights:**
   - Add to observations section
   - Flag high-coupling domains in their documentation

**If not running import analysis:**
- Skip this step
- Proceed with surveyor-only results

### 3a. Draft Review (Interactive Only)

**If interactive mode, present draft for review:**

```markdown
## Draft Atlas Preview

### Project Summary
- **Type:** {project_type}
- **Organization:** {organization_style}
- **Framework:** {framework}

### Domains ({count})
| Domain | Files | Confidence | Priority |
|--------|-------|------------|----------|
{domain_table}

{IF hybrid or layers:}
### Layers ({count})
| Layer | Files | Pattern |
|-------|-------|---------|
{layer_table}

### Patterns ({count})
| Pattern | Files | Example |
|---------|-------|---------|
{pattern_table}

### Does this look correct?
```

Options:
- "Looks good, generate the atlas"
- "I need to make corrections" → Loop back to specific question
- "Start over with different settings"

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

**Structure section:**
1. Populate metadata section (project, atlas_version, type, stack)
2. Add all domains with paths, counts, purposes, key_files
3. Add file patterns with examples
4. Add task mappings based on detected patterns
5. Add integrations (external services)
6. Add async_infrastructure (if detected)
7. Add config files list (with commands)
8. Add testing configuration
9. Add validation commands

**Pattern conventions section (embedded in schema.yaml):**
1. Build keyword_index from all pattern keywords
2. Add patterns section with for each pattern:
   - keywords
   - file_convention and test_convention
   - registration steps
   - validation_commands
   - example_files
   - related patterns
   - pattern_guide reference
   - anti_patterns_summary (2-4 codebase-specific rules)

**Compositions section (embedded in schema.yaml):**
Compositions are **optional and manually curated** by the team. Include standard compositions based on codebase type:
- Backend API: `add_api_endpoint`, `add_database_table`, `add_background_job`
- Frontend SPA: `add_frontend_feature`, `add_page_route`, `add_state_slice`

Teams can later customize these in schema.yaml to match their actual workflows.

**Important:** Only include codebase-specific, objectively extractable facts:
- ✅ File naming conventions (pattern matching)
- ✅ Registration locations (import graph analysis)
- ✅ Validation commands (from package.json scripts)
- ✅ Actual example file paths
- ✅ Codebase-specific anti-patterns (layering violations, naming inconsistencies)
- ❌ Fragility/freedom levels (human judgment)
- ❌ Generic anti-patterns (Claude already knows)
- ❌ "When to use" philosophy

**Write to:** `.claude/skills/atlas/references/schema.yaml`

### 6. Generate SKILL.md

Using template from `assets/atlas-templates/SKILL.template.md`:

1. Create project structure ASCII tree
2. Build domain router table (keywords → references)
3. Build pattern router table (tasks → pattern guides)

**Keywords for domain router:**
- Extract from domain names and purposes
- Include common synonyms (e.g., "redux, state, slice, store")

**Note:** File patterns, technologies, and anti-patterns are in schema.yaml (not duplicated in SKILL.md).

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

### 8b. Generate Technology Observations

Using template from `assets/atlas-templates/observations.template.md`:

**Purpose:** Document observed technologies with evidence (not decision rationale)

1. Use technology_observations from surveyor output
2. For each observation, include:
   - Category (State Management, API Layer, Database, etc.)
   - Technology name
   - Evidence from codebase (specific files, patterns, counts)
   - Notable configuration or patterns if relevant
3. Include explicit note that decision rationale is NOT extractable

**Write to:** `.claude/skills/atlas/references/observations.md`

### 9. Create .atlas-ignore (if not exists)

If no .atlas-ignore found in pre-flight:
- Copy from `assets/atlas-templates/atlas-ignore.template`
- Write to repository root

### 10. Validate Generated Atlas

**Check all files created:**
- SKILL.md exists and has content
- schema.yaml is valid YAML (includes patterns, keyword_index)
- observations.md exists and has content
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
- Pattern conventions extracted: {count}
- Reference files created: {count}
- Import analysis: {✅ Completed | ⏭️ Skipped}

{IF import analysis was run:}
**Import Analysis Insights:**
- Coupling issues detected: {count}
- Layering violations found: {count}
- Domain adjustments suggested: {count}

**Files created:**
- `.claude/skills/atlas/SKILL.md`
- `.claude/skills/atlas/references/schema.yaml` (unified: structure + patterns)
- `.claude/skills/atlas/references/observations.md`
{list of domain references}
{list of pattern guides}

**Next steps:**
1. **Use the atlas:** It's auto-discovered - just ask questions like "where is X" or "how does Y work"
2. **Update CLAUDE.md (optional):** Run `/orient` to add atlas awareness for human readers
3. **Verify accuracy:** Run `/calibrate` to check for drift
4. **Enrich domains:** Run `/explore <domain>` for deeper analysis

**Note:** This embedded command generates the atlas only.
For auto-embedding of all commands, use the plugin: `/cartographer:chart`
```

## Error Handling

| Error | Action | Recovery |
|-------|--------|----------|
| Atlas exists | Prompt for overwrite/rechart | User decides |
| No write permission | Show error with fix | User fixes permissions |
| Surveyor fails | Report error | Suggest retry with more context |
| Import-analyzer fails | Warn, continue without import analysis | Atlas still generated, less accurate |
| Low confidence (>50%) | Interactive prompts | User confirms classifications |
| Template missing | Report missing template | Check plugin installation |
| Validation fails | Report specific issues | Attempt auto-fix or manual fix |

## Responsibilities

**YOU (handler):**
- Pre-flight checks and permissions
- Invoke surveyor agent
- Optionally invoke import-analyzer agent (if --deep or user requests)
- Handle low confidence prompts
- Generate all atlas files from templates
- Validate output
- Report results

**Surveyor agent:**
- Analyze codebase structure
- Detect project type, domains, patterns
- Return structured analysis

**Import-analyzer agent (optional):**
- Analyze import relationships between domains
- Detect coupling patterns and layering violations
- Suggest domain boundary adjustments
- Extract codebase-specific anti-patterns

**You do NOT explore the codebase directly. The agents do that.**
