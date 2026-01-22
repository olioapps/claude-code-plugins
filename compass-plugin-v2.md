# Cartographer Plugin Implementation Plan

**Goal**: Create a meta-skill plugin that generates an `/atlas` skill for any repository, providing AI-optimized codebase navigation, plus optional workflow commands for spec-driven development.

## Design Philosophy

Atlas skills are **routing manifests**, not documentation. They help AI agents find relevant code quickly through keyword-based dispatch to domain-specific reference files.

The Cartographer plugin is a **generator/bootstrapper**—it can be used as an installed plugin, or it can embed its capabilities into a project and be uninstalled.

---

## Thematic Model

| Concept | Maps To | Description |
|---------|---------|-------------|
| **Cartographer** | The plugin | Map-maker—creates and maintains atlases |
| **Atlas** | Generated skill | The map—what you consult for navigation |
| **Navigator** | Command group | Traveler—uses maps to build software |

**Metaphor**: The cartographer creates atlases. The navigator uses them.

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
│   ├── help.md                      # /cartographer:help - Usage guide (plugin-only)
│   ├── orient.md                    # /cartographer:orient - CLAUDE.md setup (plugin-only)
│   ├── embed.md                     # /cartographer:embed - Export commands (plugin-only)
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
│   │   ├── domain-reference.template.md
│   │   ├── pattern-reference.template.md
│   │   └── atlas-ignore.template
│   └── embed-templates/             # Flattened templates for embedding
│       ├── cartographer-chart.template.md
│       ├── cartographer-rechart.template.md
│       ├── cartographer-calibrate.template.md
│       ├── cartographer-explore.template.md
│       ├── cartographer-where.template.md
│       ├── navigator-plan.template.md
│       ├── navigator-build.template.md
│       ├── navigator-review.template.md
│       ├── agent-surveyor.template.md
│       └── agent-auditor.template.md
└── references/
    ├── project-types.md             # Project type detection heuristics (includes monorepo strategy)
    ├── domain-heuristics.md         # Domain identification patterns
    ├── confidence-scoring.md        # Confidence thresholds and factors
    ├── atlas-format.md              # Detailed schema.yaml and reference formats
    └── failure-modes.md             # Error handling and graceful degradation
```

**Directory purposes:**
- `assets/atlas-templates/` - Templates for generated atlas skill
- `assets/embed-templates/` - Flattened templates for plugin-free operation
- `references/` - Guidance for Claude during analysis (not copied to projects)

---

## Agents

### Surveyor Agent (`agents/surveyor.md`)
**Purpose**: Combined codebase analysis

**Process**:
1. Detect project type using `references/project-types.md`
2. Map domains using `references/domain-heuristics.md`
3. Score confidence using `references/confidence-scoring.md`
4. Extract patterns and conventions
5. Generate atlas artifacts

**Outputs**:
- `.claude/skills/atlas/SKILL.md`
- `.claude/skills/atlas/references/schema.yaml`
- `.claude/skills/atlas/references/{domain}/*.md`
- `.claude/skills/atlas/references/patterns/*.md`

### Auditor Agent (`agents/auditor.md`)
**Purpose**: Detect drift between atlas and codebase

**Checks**:
- Path existence for documented domains
- File count drift (threshold-based)
- Key file existence
- Orphan directories
- Schema version compatibility

---

## Degrees of Freedom

| Operation | Freedom | Rationale |
|-----------|---------|-----------|
| Template file structure | **Low** | Must match exact format |
| SKILL.md routing tables | **Low** | Specific format required |
| Domain detection | **Medium** | Heuristics with confidence scoring |
| Keyword extraction | **High** | Context-dependent |
| Validation command detection | **Medium** | Pattern-based with confirmation |
| Pattern guide content | **Medium-High** | Codebase-specific |

---

## Commands

### Setup Commands

#### `/cartographer:help` - Usage Guide
Outputs lifecycle and usage information on-demand.

**Shows:**
- Installation → Chart → Use → Maintain → Embed workflow
- Command quick reference
- Common workflows with examples
- Current atlas status (location, last updated)
- Removal instructions (manual steps to delete atlas)

#### `/cartographer:orient` - CLAUDE.md Setup
1. Check for existing CLAUDE.md
2. Append atlas discovery section (preserve existing content)
3. Use `<!-- ATLAS_SECTION_START/END -->` markers

#### `/cartographer:embed` - Export Commands to Project
Exports commands for plugin-free operation.

**Syntax**:
```
/cartographer:embed                # Embed both cartographer and navigator
/cartographer:embed --cartographer # Embed only cartographer commands
/cartographer:embed --navigator    # Embed only navigator commands
/cartographer:embed --agents       # Also embed agent definitions
```

**Output structure** (nested folders in target):
```
.claude/
├── commands/
│   ├── cartographer/
│   │   ├── chart.md
│   │   ├── rechart.md
│   │   ├── calibrate.md
│   │   ├── explore.md
│   │   └── where.md
│   └── navigator/
│       ├── plan.md
│       ├── build.md
│       └── review.md
├── agents/                    # Only if --agents flag
│   ├── surveyor.md
│   └── auditor.md
.atlas-ignore                      # Ignore patterns (repo root)
```

**Conflict handling**: If target files exist, prompt user:
- `overwrite` - Replace existing files
- `skip` - Keep existing, skip conflicts
- `abort` - Cancel embed operation

---

### Cartographer Commands (Atlas Maintenance)

Available as `/cartographer:cartographer:*` (plugin) or `/cartographer:*` (embedded).

#### `/cartographer:chart` - Full Atlas Generation
Invokes Surveyor Agent.

**Flags**:
- `--skip-clarification` - Skip prompts for low-confidence detections
- `--dry-run` - Preview without writing
- `--exclude <patterns>` - Additional exclude patterns

#### `/cartographer:rechart` - Incremental Update
1. Load existing schema.yaml
2. Check schema version, **auto-migrate if needed**
3. Detect changes via git diff or mtimes
4. Regenerate only changed references
5. Update counts and timestamps

**Flags**:
- `--full` - Force full regeneration
- `--domains <list>` - Update specific domains only

#### `/cartographer:calibrate` - Drift Detection
Invokes Auditor Agent. Reports:
- Stale domains
- Missing domains
- File count drift
- Schema version warnings

**Flags**:
- `--verbose` - Show all checked items
- `--threshold <level>` - TRIVIAL | MINOR | SIGNIFICANT

#### `/cartographer:explore <domain>` - Deep Domain Analysis
Deep-dive for enriched reference generation.

#### `/cartographer:where <query>` - Quick Path Lookup
Searches schema.yaml keywords, returns paths.

**Flags**:
- `--exact` - Only exact matches
- `--files` - Return only files

---

### Navigator Commands (Development Workflow)

Available as `/cartographer:navigator:*` (plugin) or `/navigator:*` (embedded).

**Atlas requirement**: Navigator commands **block and prompt** if no atlas exists:
```
⚠️ No atlas found. Run `/cartographer:chart` first to generate codebase navigation.
```

#### `/navigator:plan` - Create Implementation Plan
1. Load `/atlas` for context
2. Gather requirements
3. Identify relevant patterns
4. Generate spec with atlas references

**Output**: `specs/{feature-name}.md`

#### `/navigator:build` - Execute Spec
1. Load `/atlas` and spec
2. Implement according to spec
3. Reference atlas patterns
4. Run validation commands

**Flags**:
- `--spec <path>` - Path to spec file
- `--step <n>` - Execute specific step
- `--validate` - Validate after each step

#### `/navigator:review` - Review Implementation
Compare implementation to spec and atlas patterns.

---

## Workflow Command Templates

Navigator commands use templates from `assets/embed-templates/` customized with project-specific values.

### Template Customization Points

```yaml
# Detected from project analysis
{working_directory}:        # e.g., "packages/grow-ui", "src", "."
{type_check_command}:       # e.g., "npx tsc --noEmit", "go build ./...", "cargo check"
{test_command}:             # e.g., "yarn test --watchAll=false", "pytest", "go test ./..."
{lint_command}:             # e.g., "yarn lint", "eslint .", "golangci-lint run"
{build_command}:            # e.g., "yarn build", "npm run build", "go build"
{branch_prefix}:            # e.g., "chore/", "feature/", "fix/"
{spec_directory}:           # e.g., "specs/", ".specs/"
{atlas_skill_path}:         # e.g., ".claude/skills/atlas"
```

### Detection Strategy

1. **Build/Test Commands**: Inspect `package.json` scripts, `Makefile`, `pyproject.toml`, `go.mod`, `Cargo.toml`
2. **Working Directory**: Detect from monorepo structure or default to root
3. **Branch Conventions**: Check git history for patterns or use defaults
4. **Validation Order**: Type check → Test → Lint → Build (ordered by feedback speed)

### Generated Command Structure

Each generated command follows the same pattern:
1. **Initialize**: Load `/atlas` for codebase context
2. **Reference Patterns**: Use atlas pattern guides for consistency
3. **Execute**: Project-specific workflow steps
4. **Validate**: Run detected validation commands
5. **Report**: Structured output format

---

## Confidence Scoring

| Level | Score | Action |
|-------|-------|--------|
| HIGH | > 0.8 | Auto-classify |
| MEDIUM | 0.5 - 0.8 | Auto-classify with note |
| LOW | < 0.5 | Prompt user or mark "unclassified" |

Detailed scoring factors in `references/confidence-scoring.md`.

---

## Domain Detection Heuristics

### Project Types
| Indicators | Type |
|------------|------|
| react/vue/angular in package.json + src/components | frontend_spa |
| express/fastify/koa/nest + routes/ or controllers/ | backend_api |
| packages/ + workspaces config | monorepo |
| bin/ + main in package.json | cli_tool |
| ios/ + android/ + React Native | mobile_app |
| django/flask/fastapi in requirements.txt | python_backend |
| go.mod + cmd/ or internal/ | go_backend |
| Cargo.toml + src/main.rs | rust_backend |

### Frontend Domain Patterns
| Directory Pattern | Domain | Keywords |
|-------------------|--------|----------|
| `*/pages/*`, `*/views/*` | Pages | page, route, navigation |
| `*/components/*` | Components | component, UI |
| `*/redux/*`, `*/store/*`, `*/state/*` | State | redux, state, store, zustand |
| `*/hooks/*` | Hooks | hook, use* |
| `*/services/*`, `*/api/*` (client) | API Client | api, fetch, client |
| `*/models/*`, `*/types/*` | Types | type, interface, model |
| `*/utils/*`, `*/helpers/*` | Utils | util, helper |
| `*/styles/*`, `*/theme/*` | Styling | theme, style, css, token |
| `*/assets/*`, `*/public/*` | Assets | asset, image, icon |

### Backend Domain Patterns
| Directory Pattern | Domain | Keywords |
|-------------------|--------|----------|
| `*/routes/*`, `*/controllers/*` | Routes/Controllers | route, endpoint, controller, handler |
| `*/services/*`, `*/business/*` | Business Logic | service, business, logic, use case |
| `*/models/*`, `*/entities/*` | Data Models | model, entity, schema, ORM |
| `*/repositories/*`, `*/data/*` | Data Access | repository, DAO, query, database |
| `*/middleware/*` | Middleware | middleware, auth, logging, validation |
| `*/config/*`, `*/settings/*` | Configuration | config, settings, env |
| `*/migrations/*` | Database Migrations | migration, schema change |
| `*/jobs/*`, `*/workers/*`, `*/queues/*` | Background Jobs | job, worker, queue, async |
| `*/events/*`, `*/listeners/*` | Events | event, listener, handler, pubsub |
| `*/validators/*`, `*/schemas/*` | Validation | validator, schema, joi, zod, yup |
| `*/dtos/*`, `*/contracts/*` | Data Transfer | dto, contract, request, response |
| `*/tests/*`, `*/__tests__/*` | Testing | test, spec, mock, fixture |
| `*/docs/*`, `*/openapi/*` | API Docs | swagger, openapi, docs |

### Backend Pattern Examples
| Pattern | Trigger Keywords | Example Files |
|---------|------------------|---------------|
| REST Endpoint | endpoint, route, handler | `routes/users.ts`, `controllers/userController.ts` |
| Database Query | query, repository, ORM | `repositories/userRepository.ts` |
| Middleware | middleware, guard, interceptor | `middleware/auth.ts` |
| Background Job | job, worker, queue | `jobs/emailSender.ts` |
| Event Handler | event, listener | `events/userCreated.handler.ts` |
| Validation Schema | validate, schema | `validators/createUser.schema.ts` |
| Database Migration | migration | `migrations/001_create_users.ts` |
| Service Layer | service, use case | `services/userService.ts` |

---

## Generated Atlas Structure

```
.claude/
├── skills/atlas/
│   ├── SKILL.md                    # ~100 lines routing manifest
│   └── references/
│       ├── schema.yaml             # Machine-readable structure
│       ├── {domain}/
│       │   └── {area}.md
│       └── patterns/
│           └── {pattern}.md
.atlas-ignore                         # Ignore patterns (repo root)
```

### SKILL.md Format
- YAML frontmatter: name, description, triggers
- Structure overview (monorepo/single app)
- Domain Router table: Keywords → reference file
- Pattern Router table: Task → pattern guide
- File Location Conventions table
- Key Technologies list
- Task-Type Quick Reference

### schema.yaml Format (Source of Truth)
Machine-readable structure for programmatic access and validation.
- `schema_version` - Semver format (e.g., "1.0.0"); major bump = breaking changes
- `metadata` - Project info and stack
- `domains` - Location, count, confidence, purpose, key_files, documentation link
- `file_patterns` - Glob patterns with examples
- `task_mappings` - Common tasks → starting locations
- `config_files` - Important config file purposes
- `testing` - Framework, locations
- `validation_commands` - Detected build/test/lint commands

**Relationship to references**: schema.yaml is the authoritative source. Domain/pattern references are human/AI-readable expansions derived from schema data.

### Domain Reference Format
Human/AI-readable documentation for understanding and navigation.
- **Table of Contents** (required if >100 lines)
- Purpose/Location/Confidence header
- Overview paragraph
- Directory structure tree
- Key files table
- Patterns & Conventions with code examples
- Common Operations (how-to guides)
- Dependencies (internal/external)
- Related Documentation links

### Pattern Reference Format
- **Table of Contents** (required if >100 lines)
- "When to Use This Pattern"
- File Location Convention
- Code Template (full example)
- Key Conventions (do/don't)
- Anti-Patterns
- Reference Implementations
- Checklist

---

## CLAUDE.md Integration

```markdown
<!-- ATLAS_SECTION_START -->
## Code Discovery System

This project uses `/atlas` for codebase discovery.

**Quick reference:**
- `chart` = generate atlas from scratch
- `rechart` = update existing atlas
- `calibrate` = check if atlas matches reality

**Maintenance:** `/cartographer:chart`, `/cartographer:rechart`, `/cartographer:calibrate`

**Development:** `/navigator:plan`, `/navigator:build`, `/navigator:review`
<!-- ATLAS_SECTION_END -->
```

### Preservation Rules
- Never overwrite content before `<!-- ATLAS_SECTION_START -->`
- Never overwrite content after `<!-- ATLAS_SECTION_END -->`
- Only update content between markers
- If markers don't exist, append section at end of file

---

## Error Handling

See `references/failure-modes.md` for details.

| Scenario | Behavior |
|----------|----------|
| No recognizable structure | Prompt for project type hints |
| Conflicting domain signals | Use confidence scoring, prompt if LOW |
| Navigator without atlas | Block and prompt to run `/cartographer:chart` |
| Schema version mismatch | Auto-migrate on rechart |
| Embed file conflicts | Prompt user for each conflict |

---

## Implementation Order

### Phase 1: Foundation
1. `plugin.json` manifest
2. `references/project-types.md`
3. `references/domain-heuristics.md`
4. `references/confidence-scoring.md`
5. `references/atlas-format.md`
6. `references/failure-modes.md`

### Phase 2: Atlas Templates
1. `assets/atlas-templates/SKILL.template.md`
2. `assets/atlas-templates/schema.template.yaml`
3. `assets/atlas-templates/domain-reference.template.md`
4. `assets/atlas-templates/pattern-reference.template.md`
5. `assets/atlas-templates/atlas-ignore.template`

### Phase 3: Agents
1. `agents/surveyor.md`
2. `agents/auditor.md`

### Phase 4: Cartographer Commands
1. `commands/cartographer/chart.md`
2. `commands/cartographer/rechart.md`
3. `commands/cartographer/calibrate.md`
4. `commands/cartographer/explore.md`
5. `commands/cartographer/where.md`

### Phase 5: Navigator Commands
1. `commands/navigator/plan.md`
2. `commands/navigator/build.md`
3. `commands/navigator/review.md`

### Phase 6: Setup Commands
1. `commands/help.md`
2. `commands/orient.md`
3. `commands/embed.md`

### Phase 7: Embed Templates
1. All `assets/embed-templates/*.template.md` files

### Phase 8: Testing
1. Test on frontend SPA
2. Test on backend API
3. Test on monorepo
4. Test embed → uninstall → use flow

---

## Verification Checklist

### Atlas Generation
- [ ] `/cartographer:chart` creates complete atlas
- [ ] Frontend/backend/monorepo detection works
- [ ] Confidence scoring produces reasonable classifications
- [ ] Low-confidence prompts user for clarification
- [ ] `/atlas` skill loads and routes correctly

### Cartographer Commands
- [ ] `/cartographer:rechart` updates only changed domains
- [ ] `/cartographer:rechart` auto-migrates old schema versions
- [ ] `/cartographer:calibrate` detects drift
- [ ] `/cartographer:explore <domain>` enriches references
- [ ] `/cartographer:where <query>` returns relevant paths

### Navigator Commands
- [ ] Commands block when atlas missing
- [ ] `/navigator:plan` creates spec with atlas references
- [ ] `/navigator:build` loads atlas context
- [ ] `/navigator:review` checks pattern adherence

### Setup Commands
- [ ] `/cartographer:help` outputs lifecycle and command reference
- [ ] `/cartographer:orient` updates CLAUDE.md with section markers
- [ ] `/cartographer:embed` exports both command sets
- [ ] `--cartographer` and `--navigator` flags work
- [ ] `--agents` includes agent definitions
- [ ] Embedded commands work without plugin
- [ ] File conflicts prompt user

---

## Reference Files

### Plugin Reference Files (in `references/`)

These files guide Claude during analysis and are NOT copied to target projects:

| File | Purpose |
|------|---------|
| `project-types.md` | Heuristics for detecting project type (frontend SPA, backend API, monorepo, CLI, mobile). Includes **monorepo strategy**: treat each package as a sub-domain, detect workspace config, handle shared dependencies |
| `domain-heuristics.md` | Patterns for identifying domains by directory names, file patterns, and import analysis. Covers both frontend (pages, components, state, hooks) and backend (routes, services, models, middleware) |
| `confidence-scoring.md` | Scoring factors for domain classification. Defines HIGH/MEDIUM/LOW thresholds and when to prompt user |
| `atlas-format.md` | Detailed specification for schema.yaml structure and domain/pattern reference formats |
| `failure-modes.md` | Error handling strategies: unrecognizable structure, conflicting signals, missing atlas, schema migration |

### Example Implementations (for template development)

**Atlas Skill Examples:**
- **SKILL.md**: `/Users/dustinherboldshimer/dev/backrs/backrs_ui/.claude/skills/atlas/SKILL.md`
- **schema.yaml**: `/Users/dustinherboldshimer/dev/backrs/backrs_ui/.claude/skills/atlas/references/schema.yaml`

**Workflow Command Examples:**
- **spec-plan.md**: `/Users/dustinherboldshimer/dev/backrs/backrs_ui/.claude/commands/spec-plan.md`
- **spec-build.md**: `/Users/dustinherboldshimer/dev/backrs/backrs_ui/.claude/commands/spec-build.md`
- **spec-review.md**: `/Users/dustinherboldshimer/dev/backrs/backrs_ui/.claude/commands/spec-review.md`

**Existing Plugin Reference:**
- **codebase-documentation**: `/Users/dustinherboldshimer/.claude/plugins/marketplaces/olio-plugins/codebase-documentation/`
