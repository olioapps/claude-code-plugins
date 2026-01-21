---
allowed-tools: Read, Write, Glob, Bash(test:*), Bash(mkdir:*), AskUserQuestion
argument-hint: [--cartographer | --navigator | --agents] [--output <dir>]
description: Export commands for plugin-free operation
---

## Context

Arguments: `/cartographer:embed [OPTIONS]`
- **--cartographer** - Export only cartographer commands
- **--navigator** - Export only navigator commands
- **--agents** - Include agent definitions in export
- **--output <dir>** - Custom output directory (default: `.claude/commands/`)
- **(empty)** - Export all commands

Current directory: !`pwd`

## Workflow

### 1. Parse Arguments

**Determine what to export:**
- If no flags: Export all (cartographer + navigator)
- If --cartographer: Export cartographer commands only
- If --navigator: Export navigator commands only
- If --agents: Include agent definitions

**Determine output location:**
- Default: `.claude/commands/`
- Custom: Use --output value

### 2. Discover Plugin Templates

**CRITICAL: You must locate the cartographer plugin's embed templates before proceeding.**

The templates are NOT in the current working directory. Search these locations in order:

**Search Pattern 1 - User plugins:**
```
~/.claude/plugins/*/cartographer/assets/embed-templates/*.template.md
```

**Search Pattern 2 - Marketplace plugins:**
```
~/.claude/plugins/marketplaces/*/cartographer/assets/embed-templates/*.template.md
```

**Search Pattern 3 - Project-local plugins:**
```
.claude/plugins/*/cartographer/assets/embed-templates/*.template.md
```

**Discovery Steps:**
1. Use Glob to search each pattern until you find templates
2. Store the discovered path as `{template_dir}` for use in step 5 (Export Commands)
3. Verify you found these required templates:
   - `cartographer-chart.template.md`
   - `cartographer-rechart.template.md`
   - `cartographer-calibrate.template.md`
   - `cartographer-explore.template.md`
   - `cartographer-where.template.md`
   - `navigator-plan.template.md`
   - `navigator-build.template.md`
   - `navigator-review.template.md`

**If --agents flag, also verify:**
   - `agent-surveyor.template.md`
   - `agent-auditor.template.md`

**If templates not found:**
```
❌ Could not locate cartographer plugin templates.

Searched:
- ~/.claude/plugins/*/cartographer/
- ~/.claude/plugins/marketplaces/*/cartographer/
- .claude/plugins/*/cartographer/

The cartographer plugin may not be installed correctly.
```

### 3. Pre-flight Checks

**Check output directory:**
```bash
test -d "{output_dir}" && echo "EXISTS" || echo "NOT_FOUND"
```

**If exists, check for conflicts:**
- List existing command files
- Identify which would be overwritten

**If conflicts found:**
```
⚠️ Existing command files found in {output_dir}:
{list files}

Options:
1. Overwrite all conflicting files
2. Skip existing files (export only new)
3. Backup existing to {output_dir}.bak/ then overwrite
4. Choose different output directory
5. Abort
```

### 4. Create Output Directory

```bash
mkdir -p {output_dir}
```

### 5. Export Commands

**Load and transform templates:**

For each command to export:
1. Read template from `{template_dir}` (discovered in step 2)
2. Apply project-specific transformations (see below)
3. Write to output directory

**Cartographer commands:**
- `cartographer-chart.md` → `chart.md` (or `cartographer-chart.md`)
- `cartographer-rechart.md` → `rechart.md`
- `cartographer-calibrate.md` → `calibrate.md`
- `cartographer-explore.md` → `explore.md`
- `cartographer-where.md` → `where.md`

**Navigator commands:**
- `navigator-plan.md` → `spec-plan.md` (or `navigator-plan.md`)
- `navigator-build.md` → `spec-build.md`
- `navigator-review.md` → `spec-review.md`

**Agent definitions (if --agents):**
- `agent-surveyor.md` → Include in relevant commands
- `agent-auditor.md` → Include in relevant commands

### 5a. Generate Project-Specific Pattern Mapping (Navigator commands only)

**CRITICAL**: Before writing `spec-plan.md`, generate a concrete keyword-to-pattern mapping from the project's atlas.

#### Step 5a.1: Read Project Schema

```bash
test -f ".claude/skills/atlas/references/schema.yaml" && echo "EXISTS" || echo "NOT_FOUND"
```

**If schema exists**, read it and extract:
- `documentation.patterns` - list of pattern file paths
- `task_mappings` - mapping of task types to files and patterns

#### Step 5a.2: Build Keyword Mapping

For each pattern in `documentation.patterns`:
1. Read the pattern file from `.claude/skills/atlas/references/{pattern_path}`
2. Extract the "When to Use This Pattern" section
3. Identify 4-6 keywords that would trigger this pattern
4. Extract 2-3 critical conventions from "Key Conventions" section

**Generate a project-specific mapping table:**

```markdown
## Project Pattern Mapping

| Keywords | Pattern Guide | Critical Conventions |
|----------|---------------|---------------------|
| {keywords from pattern 1} | `{pattern_path_1}` | {2-3 key rules} |
| {keywords from pattern 2} | `{pattern_path_2}` | {2-3 key rules} |
| ... | ... | ... |

### Task Type Mapping

| Task Mapping Key | Relevant Pattern |
|------------------|------------------|
| {task_mapping_key_1} | `{matching_pattern}` |
| {task_mapping_key_2} | `{matching_pattern}` |
```

#### Step 5a.3: Inject Into Template

In the `navigator-plan.template.md` output:
- Replace the generic "Example mapping generation" section with the actual project-specific mapping
- Replace example conventions with real conventions from the project's pattern files

**Example transformation:**

Template has:
```markdown
**Example mapping generation:**
If schema.yaml contains:
...
Generate a mental map like:
| Keywords | Pattern Guide |
|----------|---------------|
| "api", "endpoint", "fetch"... | `patterns/rtk_query.md` |
```

Replace with:
```markdown
**Project Pattern Mapping:**

This project's atlas defines the following patterns:

| Keywords | Pattern Guide | Critical Conventions |
|----------|---------------|---------------------|
| "api", "endpoint", "RTK Query", "fetch", "cache" | `patterns/rtk_query.md` | Use `.api.ts` suffix; Import shared `baseQuery`; Use tag-based cache invalidation |
| "slice", "redux", "state", "reducer" | `patterns/redux_slices.md` | Register in store.ts; Use createSlice from RTK |
| "component", "atom", "molecule" | `patterns/atomic_design.md` | Use Backrs* prefix; Co-locate Storybook stories |

### Task Mappings

| Task | Pattern |
|------|---------|
| `add_api_endpoint` | `patterns/rtk_query.md` |
| `add_redux_slice` | `patterns/redux_slices.md` |
| `create_reusable_component` | `patterns/atomic_design.md` |
```

#### Step 5a.4: Inject Validation Commands

Also inject the project's actual validation commands from `schema.validation`:

Template has:
```markdown
## Validation Commands
{working_dir from schema.validation.working_dir, if specified}
{For each command in schema.validation.commands:}
```

Replace with actual commands:
```markdown
## Validation Commands

**Execute ALL commands to confirm completion with zero regressions.**

```bash
# From {working_dir}:
cd {working_dir}

# {command_1.name}
{command_1.command}

# {command_2.name}
{command_2.command}
```

**Expected Result**: All commands complete successfully with no errors.
```

### 6. Inline Agent Definitions

**If --agents flag:**

For commands that use agents, inline the agent definition:

```markdown
{original command content}

---

## Surveyor Agent Definition

{full surveyor.md content}
```

This makes commands self-contained without needing the agents/ directory.

### 7. Transform for Standalone Use

**Adjustments needed for embedded commands:**

1. **Remove plugin-specific paths:**
   - Change `assets/atlas-templates/` references to inline or relative paths

2. **Add standalone header:**
   ```markdown
   <!--
   Embedded Cartographer Command
   Generated from cartographer plugin v1.0.0
   Original: cartographer/commands/cartographer/chart.md
   -->
   ```

3. **Update tool permissions if needed:**
   - Embedded commands may need broader permissions

### 8. Create Help File

**Generate embedded help:**
```markdown
# Embedded Cartographer Commands

These commands were exported from the Cartographer plugin for standalone use.

## Available Commands

{list exported commands with descriptions}

## Usage

Commands work the same as plugin versions:
- `/chart` - Generate atlas
- `/rechart` - Update atlas
- etc.

## Notes

- These commands don't auto-update with plugin changes
- Re-run `/cartographer:embed` to get latest versions
- Original plugin: cartographer/
```

### 9. Update CLAUDE.md (Optional)

**If CLAUDE.md exists, offer to add command references:**

```
Would you like to add command references to CLAUDE.md?

This will add a section listing the embedded commands.

Options:
1. Yes, add command references
2. No, skip CLAUDE.md update
```

**If yes, add:**
```markdown
## Embedded Commands

The following commands are available in this repository:

{command list with descriptions}

See `.claude/commands/help.md` for full documentation.
```

### 10. Report Results

```markdown
## Commands Embedded Successfully

**Output directory:** `{output_dir}`

**Commands exported:**
{list each file created}

**Flags used:**
- Cartographer: {yes/no}
- Navigator: {yes/no}
- Agents inlined: {yes/no}

**Files created:**
- `{output_dir}/chart.md`
- `{output_dir}/rechart.md`
- etc.

**Next steps:**
- Commands are ready to use without the plugin
- Run `/chart` to generate atlas (equivalent to `/cartographer:chart`)
- Re-run `/cartographer:embed` if you update the plugin

**Note:** Embedded commands are snapshots. They won't auto-update when the plugin is updated.
```

---

## Template Transformations

| Plugin Command | Embedded Name | Notes |
|----------------|---------------|-------|
| `/cartographer:chart` | `/chart` | Shorter name without namespace |
| `/cartographer:rechart` | `/rechart` | |
| `/cartographer:calibrate` | `/calibrate` | |
| `/cartographer:explore` | `/explore` | |
| `/cartographer:where` | `/where` | |
| `/navigator:plan` | `/spec-plan` | Matches existing convention |
| `/navigator:build` | `/spec-build` | |
| `/navigator:review` | `/spec-review` | |

---

## Error Handling

| Error | Action | Recovery |
|-------|--------|----------|
| Can't create directory | Report permission error | User fixes or uses different path |
| Template not found | Report missing template | Check plugin installation |
| Write conflict | Interactive prompt | User chooses resolution |
| Partial export | Report what succeeded | User can retry failed files |

## Responsibilities

**YOU (handler):**
- Parse arguments and determine scope
- Check for conflicts and handle interactively
- Read templates and transform for standalone use
- Write embedded commands to output
- Report comprehensive results

**You create standalone versions. They should work without the plugin installed.**
