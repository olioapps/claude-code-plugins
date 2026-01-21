# Cartographer Plugin Implementation Plan v3

**Goal**: Create a meta-skill plugin that generates an `/atlas` skill for any repository, providing AI-optimized codebase navigation, plus optional workflow commands for spec-driven development.

## What's New in v3

- **Interactive chart mode** - Quick scan → interview → guided analysis → draft review
- **Organization styles** - Support for domains, layers, or hybrid mapping
- **Conventions system** - Machine-readable pattern conventions for lifecycle commands
- **Compositions** - Multi-pattern task sequences detected from git history
- **Technology observations** - Document what's used without inventing rationale

---

## Design Philosophy

Atlas skills are **routing manifests**, not documentation. They help AI agents find relevant code quickly through keyword-based dispatch to domain-specific reference files.

**Key principle**: Extract only what's objectively observable from code. Never invent decision rationale, "when to use" philosophy, or fragility assessments—Claude already knows generic best practices.

The Cartographer plugin is a **generator/bootstrapper**—it can be used as an installed plugin, or it can embed its capabilities into a project and be uninstalled.

---

## Thematic Model

| Concept | Maps To | Description |
|---------|---------|-------------|
| **Cartographer** | The plugin | Map-maker—creates and maintains atlases |
| **Atlas** | Generated skill | The map—what you consult for navigation |
| **Navigator** | Command group | Traveler—uses maps to build software |
| **Surveyor** | Analysis agent | Explorer—scouts terrain before mapping |

**Metaphor**: The cartographer dispatches surveyors to explore, then creates atlases. The navigator uses them.

---

## Plugin Structure

```
cartographer/
├── .claude-plugin/
│   └── plugin.json
├── agents/
│   ├── surveyor.md                  # Survey + domain mapping + pattern extraction
│   └── auditor.md                   # Drift detection
├── commands/
│   ├── help.md                      # /cartographer:help - Usage guide
│   ├── orient.md                    # /cartographer:orient - CLAUDE.md setup
│   ├── embed.md                     # /cartographer:embed - Export commands
│   ├── cartographer/                # Embeddable cartographer commands
│   │   ├── chart.md                 # /cartographer:chart - Full survey
│   │   ├── rechart.md               # /cartographer:rechart - Incremental update
│   │   ├── calibrate.md             # /cartographer:calibrate - Drift check
│   │   ├── explore.md               # /cartographer:explore <domain> - Deep analysis
│   │   └── where.md                 # /cartographer:where <query> - Path lookup
│   └── navigator/                   # Embeddable navigator commands
│       ├── plan.md                  # /navigator:plan - Create spec
│       ├── build.md                 # /navigator:build - Execute spec
│       └── review.md                # /navigator:review - Review implementation
├── assets/
│   ├── atlas-templates/             # Templates for generated atlas
│   │   ├── SKILL.template.md
│   │   ├── schema.template.yaml
│   │   ├── conventions.template.yaml    # NEW: Pattern conventions
│   │   ├── compositions.template.yaml   # NEW: Multi-pattern sequences
│   │   ├── observations.template.md     # NEW: Technology observations
│   │   ├── domain-reference.template.md
│   │   ├── pattern-reference.template.md
│   │   └── atlas-ignore.template
│   └── embed-templates/             # Flattened templates for embedding
│       └── *.template.md
└── references/
    ├── project-types.md             # Project type detection heuristics
    ├── domain-heuristics.md         # Domain identification patterns
    ├── confidence-scoring.md        # Confidence thresholds and factors
    ├── atlas-format.md              # Detailed schema and reference formats
    └── failure-modes.md             # Error handling and graceful degradation
```

---

## Agents

### Surveyor Agent (`agents/surveyor.md`)

**Purpose**: Codebase analysis with two operating modes

#### QUICK_SCAN Mode

Fast reconnaissance for interactive charting (~10-15 seconds).

**What it does:**
- Read ONLY config files (package.json, tsconfig.json, etc.)
- List top-level directories (2 levels max)
- Detect obvious patterns from directory names only
- NO deep file reading
- NO file content analysis beyond configs

**Output format:**
```yaml
---QUICK_SCAN---
project_name: {name}
project_type: {frontend_spa|backend_api|fullstack|monorepo|cli|library}
type_confidence: {high|medium|low}

organization_style_detected: {domains|layers|hybrid}
organization_evidence:
  - "{evidence 1}"
  - "{evidence 2}"

preliminary_domains:
  - name: {domain_name}
    location: {path}
    file_count: {~approximate}

preliminary_layers:
  - name: {layer_name}
    location: {path}
    pattern_guess: "{*.controller.ts}"

detected_patterns:
  - "{pattern description}"

framework: {React|Express|FastAPI|etc.}
language: {TypeScript|Python|Go|etc.}
---END_QUICK_SCAN---
```

#### FULL Mode (Default)

Complete codebase analysis for atlas generation.

**Workflow:**
1. Identify project type (with confidence scoring)
2. Extract technology stack
3. Map directory structure
4. Identify domains
5. Detect architectural layers (if layers/hybrid mode)
6. Detect file patterns
7. Identify configuration files
8. Identify testing setup
9. Extract validation commands
10. Extract pattern conventions (keywords, file conventions, registration, validation)
11. Detect technology observations (with evidence)
12. Detect pattern compositions (from git history and import analysis)

**Interview context (HIGHEST priority when provided):**
- `organization_style` - Use instead of auto-detecting
- `domains.added` - Actively look for these
- `domains.critical` - Analyze more thoroughly
- `custom_patterns` - Include in pattern detection
- `exclusions` - Skip these directories

**Output format:**
```yaml
---ANALYSIS---
metadata:
  project: {name}
  type: {project_type}
  type_confidence: {high|medium|low}
  organization_style: {domains|layers|hybrid}
  stack:
    language: {language}
    version: {version}
    framework: {framework}
    framework_version: {version}
  architecture: {brief description}

domains:
  {domain_name}:
    location: {path}
    purpose: {one sentence}
    count: {number or ~approximate}
    confidence: {high|medium|low}
    key_files:
      - {file1}
      - {file2}

layers:  # If organization_style is layers or hybrid
  {layer_name}:
    location: {path or pattern}
    file_pattern: {glob}
    count: {number}
    purpose: {one sentence}
    key_files: [...]
    domains_served: [...]

file_patterns:
  {pattern_name}:
    pattern: {glob}
    example: {file}
    count: {number}
    purpose: {description}

config_files:
  {filename}:
    path: {path}
    purpose: {description}

testing:
  framework: {Jest|pytest|etc.}
  location: {path}
  pattern: {glob}
  coverage: {command}

validation:
  working_dir: {directory}
  commands:
    - name: {name}
      command: {command}

conventions:
  patterns:
    {pattern_name}:
      keywords: [...]
      file_convention: "{path/pattern}"
      test_convention: "{test/pattern}"
      registration:
        - file: "{path}"
          action: "{description}"
      validation_commands: [...]
      example_files: [...]
      related: [...]

technology_observations:
  - category: "{category}"
    observed: "{technology}"
    evidence: [...]

compositions:
  detected:
    - id: {id}
      files_commonly_changed_together: [...]
      suggested_composition: "{name}"
      confidence: {level}
  standard_applicable: [...]

observations:
  - {notable observation}
---END---
```

### Auditor Agent (`agents/auditor.md`)

**Purpose**: Detect drift between atlas and codebase

**Checks:**
- Path existence for documented domains
- File count drift (threshold-based)
- Key file existence
- Orphan directories
- Schema version compatibility

---

## Commands

### `/cartographer:chart` - Atlas Generation

**Syntax:**
```
/cartographer:chart [--interactive|--auto] [--mode=domains|layers|hybrid] [context]
```

**Options:**
- `--interactive` (DEFAULT) - Guided interview session before deep analysis
- `--auto` - Skip interview, fully automatic analysis
- `--mode=<mode>` - Pre-select mapping mode

**Modes:**
| Mode | Best For | Output Focus |
|------|----------|--------------|
| `domains` | Feature-based codebases, frontend SPAs | Groups by business domain |
| `layers` | Backend APIs, layered architecture | Groups by architectural layer |
| `hybrid` | Complex codebases, fullstack apps | Provides both views |

#### Interactive Flow (Default)

```
┌─────────────────┐
│  Pre-flight     │ Check existing atlas, permissions, .atlas-ignore
└────────┬────────┘
         ▼
┌─────────────────┐
│  Quick Scan     │ Surveyor QUICK_SCAN mode (~10-15 seconds)
└────────┬────────┘
         ▼
┌─────────────────┐
│  Interview      │ 5 AskUserQuestion calls
│  Session        │
└────────┬────────┘
         ▼
┌─────────────────┐
│  Full Analysis  │ Surveyor FULL mode with interview context
└────────┬────────┘
         ▼
┌─────────────────┐
│  Draft Review   │ Show preview, user confirms or corrects
└────────┬────────┘
         ▼
┌─────────────────┐
│  Generate       │ Create all atlas files
└────────┬────────┘
         ▼
┌─────────────────┐
│  Validate       │ Check all files created correctly
└─────────────────┘
```

**Interview Questions:**

1. **Organization Style**
   - Shows detected style and evidence
   - Options: Directory/Domain-based, Semantic Layers, Hybrid, Other

2. **Domain Validation**
   - Shows table of detected domains with file counts
   - Options: Looks correct, Add domains, Remove/rename, Other

3. **Critical Domains**
   - Multi-select from detected + user-added domains
   - These receive deeper analysis

4. **Custom Patterns**
   - Options: No custom patterns, Yes let me describe them
   - Example: "*.handler.ts for background jobs"

5. **Areas to Skip**
   - Options: No additional exclusions, Yes skip these
   - Beyond standard exclusions (node_modules, .git, dist)

**Interview Results Format:**
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
```

**Draft Review:**
After full analysis, show preview table:
- Project summary (type, organization, framework)
- Domains table (name, files, confidence, priority)
- Layers table (if hybrid/layers mode)
- Patterns table (pattern, files, example)

Options:
- "Looks good, generate the atlas"
- "I need to make corrections" → loop back
- "Start over with different settings"

#### Auto Flow

Skip interview, run full analysis immediately. Use for:
- CI/automation
- Re-charting known codebases
- When user provides sufficient context

### `/cartographer:rechart` - Incremental Update

1. Load existing schema.yaml
2. Check schema version, auto-migrate if needed
3. Detect changes via git diff or mtimes
4. Regenerate only changed references
5. Update counts and timestamps

**Flags:**
- `--full` - Force full regeneration
- `--domains <list>` - Update specific domains only

### `/cartographer:calibrate` - Drift Detection

Invokes Auditor Agent. Reports:
- Stale domains
- Missing domains
- File count drift
- Schema version warnings

**Flags:**
- `--verbose` - Show all checked items
- `--threshold <level>` - TRIVIAL | MINOR | SIGNIFICANT

### `/cartographer:explore <domain>` - Deep Domain Analysis

Deep-dive for enriched reference generation.

### `/cartographer:where <query>` - Quick Path Lookup

Searches schema.yaml keywords, returns paths.

**Flags:**
- `--exact` - Only exact matches
- `--files` - Return only files

### `/cartographer:help` - Usage Guide

Shows lifecycle and usage information.

### `/cartographer:orient` - CLAUDE.md Setup

Appends atlas discovery section with markers.

### `/cartographer:embed` - Export Commands

Exports commands for plugin-free operation.

**Syntax:**
```
/cartographer:embed                # Embed both cartographer and navigator
/cartographer:embed --cartographer # Embed only cartographer commands
/cartographer:embed --navigator    # Embed only navigator commands
/cartographer:embed --agents       # Also embed agent definitions
```

---

## Navigator Commands

**Atlas requirement**: Navigator commands block if no atlas exists.

### `/navigator:plan` - Create Implementation Spec

**Workflow:**
1. Verify atlas exists
2. Load atlas context (schema.yaml, conventions.yaml, compositions.yaml)
3. Analyze task description
   - Extract keywords
   - Look up keywords in `keyword_index` → pattern IDs
   - Check if patterns suggest a composition
4. Research codebase for relevant files
5. Generate spec with:
   - Pattern sequence (from composition or matched patterns)
   - File conventions (from conventions.yaml)
   - Registration steps
   - Validation commands (global + pattern-specific)

**Output:** `specs/{task-slug}.md`

**Spec Structure:**
```markdown
# {Task Type}: {Title}

## Prerequisites
{Required files and tasks}

## Branch Information
**Implementation Branch**: `{branch}`
**Base Branch**: `{base}`

## Task Description
**What**: {description}
**Why**: {reason}
**Success Criteria**: [...]

## Atlas Context

### Relevant Domains
{domains with paths}

### Pattern Sequence
**Composition:** `{composition_id}` - {description}

| Order | Pattern | Condition | File Convention |
|-------|---------|-----------|-----------------|
| 1 | {pattern} | {condition} | `{convention}` |

### File Conventions (from conventions.yaml)
**{pattern_id}:**
- File: `{file_convention}`
- Test: `{test_convention}`

### Registration Steps (from conventions.yaml)
- [ ] {action} in `{file}`

### Pattern Guides
{links to patterns/*.md}

## Relevant Files
### Existing Files
{files with relevance}

### New Files (derived from file conventions)
{files to create}

## Step-by-Step Tasks
### 1. {Step}
{actions}

### N. Run Validation
{commands}

## Validation Commands

### Global Validation (from schema.yaml)
```bash
{commands}
```

### Pattern-Specific Validation (from conventions.yaml)
**{pattern_id}:**
```bash
{commands}
```

### Composition Validation Sequence
```bash
{validation_sequence from compositions.yaml}
```
```

### `/navigator:build` - Execute Spec

**Workflow:**
1. Load spec and atlas
2. Verify prerequisites
3. Load pattern guidance from conventions.yaml
   - File conventions
   - Test conventions
   - Registration steps
   - Validation commands
   - Example files to study
4. Execute steps in order
   - Follow spec instructions
   - Use file_convention for new files
   - Complete registration steps
   - Run pattern-specific validation after each step
5. Run all validation commands
6. Report results

### `/navigator:review` - Review Implementation

**Workflow:**
1. Load spec and atlas
2. Get implementation changes (git diff)
3. Check files against spec
4. Review against conventions.yaml:
   - File convention check (correct location?)
   - Test convention check (test exists?)
   - Registration check (wired up correctly?)
5. Review against pattern guides
6. Run validation commands
7. Generate review report

---

## Generated Atlas Structure

```
.claude/
├── skills/atlas/
│   ├── SKILL.md                    # Routing manifest
│   └── references/
│       ├── schema.yaml             # Machine-readable structure
│       ├── conventions.yaml        # Pattern conventions for lifecycle commands
│       ├── compositions.yaml       # Multi-pattern task sequences
│       ├── observations.md         # Technology observations with evidence
│       ├── {domain}/
│       │   └── {area}.md
│       └── patterns/
│           └── {pattern}.md
.atlas-ignore                       # Ignore patterns (repo root)
```

### schema.yaml

Machine-readable structure. Source of truth.

```yaml
metadata:
  project: {name}
  type: {type}
  organization_style: {domains|layers|hybrid}
  stack: {...}
  architecture: {description}

domains:
  {domain_name}:
    location: {path}
    count: {number}
    purpose: {sentence}
    confidence: {level}
    key_files: [...]
    documentation: {path}

layers:  # If organization_style is layers or hybrid
  {layer_name}:
    location: {path}
    file_pattern: {glob}
    count: {number}
    purpose: {sentence}
    key_files: [...]
    domains_served: [...]
    documentation: {path}

file_patterns: {...}
task_mappings: {...}
config_files: {...}
testing: {...}
validation: {...}

companion_files:
  conventions: references/conventions.yaml
  compositions: references/compositions.yaml
  observations: references/observations.md
```

### conventions.yaml

Machine-readable pattern conventions for lifecycle command auto-injection.

```yaml
version: "1.0"

keyword_index:
  endpoint: controllers
  route: controllers
  service: providers
  # Maps keywords to pattern IDs

patterns:
  controllers:
    keywords: [controller, route, endpoint, API]
    file_convention: "src/controllers/{name}.controller.ts"
    test_convention: "src/controllers/{name}.controller.test.ts"
    registration:
      - file: "src/routes/index.ts"
        action: "Import and register route"
    validation_commands:
      - "npm run lint"
      - "npm test -- controllers"
    pattern_file: "patterns/controllers.md"
    example_files:
      - "src/controllers/user.controller.ts"
      - "src/controllers/auth.controller.ts"
    related:
      - providers
      - routes
```

**What to include (codebase-specific facts):**
- File naming conventions
- Registration file paths
- Actual validation commands
- Real example file paths

**What to exclude (Claude already knows):**
- Generic anti-patterns
- Framework best practices
- "When to use" philosophy
- Fragility/freedom assessments

### compositions.yaml

Multi-pattern task sequences for lifecycle command guidance.

```yaml
version: "1.0"

compositions:
  add_api_endpoint:
    description: "Full REST endpoint with controller, provider, and route"
    patterns:
      - pattern: controllers
        order: 1
        condition: "always"
      - pattern: providers
        order: 2
        condition: "if business logic needed"
      - pattern: data_access
        order: 3
        condition: "if database access needed"
      - pattern: routes
        order: 4
        condition: "always"
    validation_sequence:
      - "npm run lint"
      - "npm test"
      - "npm run build"

  add_database_table:
    description: "Schema, model, and migrations for new table"
    patterns:
      - pattern: migrations
        order: 1
        condition: "always"
      - pattern: models
        order: 2
        condition: "always"
      - pattern: data_access
        order: 3
        condition: "always"
    validation_sequence:
      - "npm run migrate"
      - "npm test"

detected_correlations:
  - files_commonly_changed_together:
      - "src/controllers/*.ts"
      - "src/providers/*.ts"
      - "src/routes/*.ts"
    suggested_composition: "add_api_endpoint"
    confidence: high
```

**Detection methods:**
1. Git history analysis - `git log --name-only` to find files changed together
2. Import graph analysis - trace dependencies between patterns

### observations.md

Technology observations with evidence, NOT decision rationale.

```markdown
# {Project} - Technology Observations

> Documents WHAT is used, not WHY it was chosen.

**Note:** Decision rationale cannot be extracted from code.

---

## State Management

**Observed:** Redux Toolkit

**Evidence:**
- store.ts uses configureStore
- 40+ slice files in src/store/
- RTK Query for API caching

---

## What This Document Does NOT Include

- Decision rationale
- Trade-off analysis
- Historical context
- Future plans

For this information, consult team documentation or ADRs.
```

### SKILL.md

Routing manifest (~100 lines).

- YAML frontmatter with triggers
- Project structure overview
- Domain Router table (keywords → reference)
- Pattern Router table (task → guide)
- File Location Conventions table
- Key Technologies list

### Pattern Reference Format

Focused on codebase-specific facts.

```markdown
# {Pattern} Pattern

> {description}

## File Convention

**Location:** `{path}`
**Naming:** `{convention}`
**Tests:** `{test_path}`

## Template (This Codebase)

```{language}
{actual_template_from_codebase}
```

## Implementation Checklist

- [ ] {step 1}
- [ ] {step 2}

### Registration

- [ ] {action} in `{file}`

## Reference Implementations

| File | Demonstrates |
|------|--------------|
| `{file}` | {what} |

## Validation

```bash
{commands}
```

## Related Patterns

- [{pattern}]({path}) - {relationship}
```

---

## Organization Styles

### Domains Mode

Group by business/feature domain.

```
src/
├── users/
│   ├── user.controller.ts
│   ├── user.service.ts
│   └── user.model.ts
├── auth/
│   ├── auth.controller.ts
│   └── auth.service.ts
└── payments/
    └── ...
```

**Best for:** Feature-based codebases, frontend SPAs, microservices

### Layers Mode

Group by architectural layer.

```
src/
├── controllers/
│   ├── user.controller.ts
│   └── auth.controller.ts
├── providers/
│   ├── user.provider.ts
│   └── auth.provider.ts
├── dataAccess/
│   └── user.dao.ts
└── models/
    └── user.model.ts
```

**Best for:** Backend APIs, traditional layered architecture

**Layer detection signals:**

| Layer | Directory Signals | File Pattern Signals |
|-------|-------------------|---------------------|
| controllers | controllers/, api/, routes/ | *.controller.ts, *.routes.ts |
| providers | providers/, services/, business/ | *.provider.ts, *.service.ts |
| data_access | dataAccess/, repositories/, dao/ | *.dao.ts, *.repository.ts |
| models | models/, entities/, schemas/ | *.model.ts, *.entity.ts |
| middleware | middleware/, interceptors/ | *.middleware.ts |
| external_apis | integrations/, external/, clients/ | *.client.ts, *.api.ts |

### Hybrid Mode

Generate both domain and layer views.

**Best for:** Complex codebases, fullstack apps, when team thinks in both dimensions

---

## Domain Detection Heuristics

### Project Types

| Indicators | Type |
|------------|------|
| react/vue/angular + src/components | frontend_spa |
| express/fastify/nest + routes/ | backend_api |
| Both frontend and backend indicators | fullstack |
| packages/ + workspaces config | monorepo |
| bin/ + main in package.json | cli |
| publishConfig or main pointing to dist | library |

### Frontend Domain Patterns

| Directory Pattern | Domain | Keywords |
|-------------------|--------|----------|
| `*/pages/*`, `*/views/*` | Pages | page, route, navigation |
| `*/components/*` | Components | component, UI |
| `*/redux/*`, `*/store/*` | State | redux, state, store |
| `*/hooks/*` | Hooks | hook, use* |
| `*/services/*`, `*/api/*` | API Client | api, fetch, client |

### Backend Domain Patterns

| Directory Pattern | Domain | Keywords |
|-------------------|--------|----------|
| `*/routes/*`, `*/controllers/*` | Routes/Controllers | route, endpoint, handler |
| `*/services/*`, `*/business/*` | Business Logic | service, business |
| `*/models/*`, `*/entities/*` | Data Models | model, entity, schema |
| `*/repositories/*`, `*/data/*` | Data Access | repository, DAO, query |
| `*/middleware/*` | Middleware | middleware, auth |
| `*/jobs/*`, `*/workers/*` | Background Jobs | job, worker, queue |

---

## Confidence Scoring

| Level | Score | Action |
|-------|-------|--------|
| HIGH | > 0.8 | Auto-classify |
| MEDIUM | 0.5 - 0.8 | Auto-classify with note |
| LOW | < 0.5 | Prompt user (interactive) or mark "unclassified" (auto) |

---

## Error Handling

| Scenario | Behavior |
|----------|----------|
| Atlas exists | Prompt: overwrite / rechart / cancel |
| No write permission | Error with fix instructions |
| No recognizable structure | Prompt for project type hints |
| Conflicting signals | Use confidence scoring, prompt if LOW |
| Navigator without atlas | Block, prompt to run /cartographer:chart |
| Schema version mismatch | Auto-migrate on rechart |
| Surveyor fails | Report error, suggest retry with context |
| Low confidence (>50%) | Interactive prompts in interview |
| Template missing | Report missing, check installation |
| Validation fails | Report issues, attempt auto-fix |

---

## Implementation Phases

### Phase 1: Foundation ✓
1. plugin.json manifest
2. references/project-types.md
3. references/domain-heuristics.md
4. references/confidence-scoring.md
5. references/atlas-format.md
6. references/failure-modes.md

### Phase 2: Atlas Templates ✓
1. SKILL.template.md
2. schema.template.yaml
3. conventions.template.yaml (NEW)
4. compositions.template.yaml (NEW)
5. observations.template.md (NEW)
6. domain-reference.template.md
7. pattern-reference.template.md
8. atlas-ignore.template

### Phase 3: Agents ✓
1. surveyor.md (with QUICK_SCAN + FULL modes)
2. auditor.md

### Phase 4: Cartographer Commands
1. chart.md (with interactive flow) ✓
2. rechart.md
3. calibrate.md
4. explore.md
5. where.md

### Phase 5: Navigator Commands ✓
1. plan.md (using conventions + compositions)
2. build.md (using conventions)
3. review.md (using conventions)

### Phase 6: Setup Commands
1. help.md
2. orient.md
3. embed.md

### Phase 7: Embed Templates
1. All embed-templates/*.template.md files

### Phase 8: Testing
1. Test on frontend SPA
2. Test on backend API (layers mode)
3. Test on fullstack (hybrid mode)
4. Test on monorepo
5. Test interactive vs auto mode
6. Test embed → uninstall → use flow

---

## Verification Checklist

### Interactive Chart Mode
- [ ] Quick scan completes in ~10-15 seconds
- [ ] Interview questions present quick scan findings
- [ ] User corrections propagate to full analysis
- [ ] Draft review shows accurate preview
- [ ] Corrections loop back correctly
- [ ] "Start over" resets properly

### Organization Styles
- [ ] Domains mode generates domain-focused atlas
- [ ] Layers mode detects architectural layers
- [ ] Hybrid mode generates both views
- [ ] --mode flag pre-selects style

### Conventions System
- [ ] conventions.yaml generated with keyword_index
- [ ] Pattern conventions include file/test conventions
- [ ] Registration steps extracted from import analysis
- [ ] Validation commands extracted from package.json
- [ ] Example files are real paths

### Compositions System
- [ ] Git history analysis detects file correlations
- [ ] Standard compositions applied based on project type
- [ ] Composition sequences have correct ordering
- [ ] Validation sequences are complete

### Navigator Integration
- [ ] /navigator:plan uses keyword_index for pattern matching
- [ ] /navigator:plan uses compositions for multi-pattern tasks
- [ ] /navigator:build uses file_convention for new files
- [ ] /navigator:build completes registration steps
- [ ] /navigator:review checks against conventions

### Atlas Generation
- [ ] All companion files created (conventions, compositions, observations)
- [ ] schema.yaml references companion files
- [ ] Pattern guides use new focused format
- [ ] Validation step checks all files

---

## Degrees of Freedom

| Operation | Freedom | Rationale |
|-----------|---------|-----------|
| Template file structure | **Low** | Must match exact format |
| SKILL.md routing tables | **Low** | Specific format required |
| Quick scan output | **Low** | Must match expected format |
| Interview questions | **Low** | Fixed question sequence |
| Domain detection | **Medium** | Heuristics with confidence |
| Layer detection | **Medium** | Pattern-based with signals |
| Keyword extraction | **High** | Context-dependent |
| Composition detection | **Medium** | Git history + import analysis |
| Pattern guide content | **Medium** | Codebase-specific extraction |

---

## File References

### Example Implementations

**Atlas Skill:**
- SKILL.md: `/Users/dustinherboldshimer/dev/backrs/backrs_ui/.claude/skills/atlas/SKILL.md`
- schema.yaml: `/Users/dustinherboldshimer/dev/backrs/backrs_ui/.claude/skills/atlas/references/schema.yaml`

**Workflow Commands:**
- spec-plan.md: `/Users/dustinherboldshimer/dev/backrs/backrs_ui/.claude/commands/spec-plan.md`
- spec-build.md: `/Users/dustinherboldshimer/dev/backrs/backrs_ui/.claude/commands/spec-build.md`
- spec-review.md: `/Users/dustinherboldshimer/dev/backrs/backrs_ui/.claude/commands/spec-review.md`

**Plugin Reference:**
- codebase-documentation: `/Users/dustinherboldshimer/.claude/plugins/marketplaces/olio-plugins/codebase-documentation/`
