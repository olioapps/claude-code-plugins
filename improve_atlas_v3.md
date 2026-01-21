# Atlas v3 Plugin Improvements

**Goal**: Enhance the Atlas plugin so generated artifacts provide complete, accurate context for any downstream consumer (agents, SDLC commands, humans).

---

## Current State

When Atlas is installed via `/chart`, it generates:

```
.claude/skills/atlas/
├── SKILL.md                    # Domain/pattern/layer routers
└── references/
    ├── schema.yaml             # Codebase structure
    ├── conventions.yaml        # Pattern keyword mapping
    ├── compositions.yaml       # Multi-pattern sequences
    ├── observations.md         # Technology stack
    ├── domains/                # Domain reference guides
    ├── patterns/               # Pattern implementation guides
    └── layers/                 # Architecture layer guides
```

---

## Part 1: Schema Generation Improvements

### Current Gap

Generated `schema.yaml` captures basic structure but misses:
- Task mappings (common developer workflows → entry points)
- Integration details (external services with config locations)
- Queue/job infrastructure
- Config file inventory

### Enhanced Schema Sections

```yaml
metadata:
  name: {project-name}
  generated: {timestamp}
  atlas_version: "3.0"

# EXISTING - keep and enhance
domains: { ... }
file_patterns: { ... }

# ADD: Task-oriented entry points
task_mappings:
  add_api_endpoint:
    description: "Create new REST endpoint"
    entry_point: "{detected-app-entry}"
    patterns: [controller, provider, service, model]

  add_database_table:
    description: "Create new database table"
    entry_point: "{detected-migrations-dir}"
    patterns: [migration, model]

  add_background_job:
    description: "Create async job processor"
    entry_point: "{detected-queue-handler-dir}"
    patterns: [worker, provider]

  add_authorization:
    description: "Add permission checks"
    entry_point: "{detected-auth-dir}"
    patterns: [authorization]

# ADD: External service integrations
integrations:
  - name: "{service-name}"
    purpose: "{inferred-purpose}"
    config_location: "{detected-config-path}"
    usage_locations:
      - "{file-that-imports-it}"

# ADD: Queue/job infrastructure (if detected)
async_infrastructure:
  type: "{sqs|bullmq|rabbitmq|none}"
  queues:
    - name: "{queue-name}"
      handler: "{handler-path}"
      purpose: "{inferred-from-name-or-code}"

# ADD: Config file inventory
config_files:
  entry_point: "{main-file}"
  package_manager: "{npm|yarn|pnpm}"
  build_command: "{detected-build-cmd}"
  test_command: "{detected-test-cmd}"
  lint_command: "{detected-lint-cmd}"
  env_template: "{.env.example|.env.template|none}"
```

### Detection Heuristics

| Artifact | Detection Method |
|----------|------------------|
| Task mappings | Directory structure + common patterns |
| Integrations | package.json deps + SDK import grep |
| Queue infrastructure | SQS/Bull/RabbitMQ in deps + handler patterns |
| Config files | Standard file name matching |
| Commands | package.json scripts |

---

## Part 2: Pattern Guide Generation

### Current Gap

Generated pattern guides vary in completeness. Need consistent structure with:
- Critical conventions (must-follow rules)
- Anti-patterns (common mistakes)
- Minimal templates extracted from actual code

### Standard Pattern Guide Template

```markdown
# Pattern: {Name}

## Purpose
{One-line description of when to use this pattern}

## Location
`{detected-location}`

## Structure
```
{generated-directory-tree}
```

## Critical Conventions

<!-- Extract from code analysis - top 3-5 rules -->

1. **{Convention}**: {Explanation}
2. **{Convention}**: {Explanation}
3. **{Convention}**: {Explanation}

## Anti-Patterns

| Don't | Do Instead | Why |
|-------|------------|-----|
| {detected-anti-pattern} | {correct-approach} | {reason} |

## Template

```{language}
{minimal-working-example-extracted-from-codebase}
```

## Related Patterns
- [{pattern}](./{pattern}.md) - {relationship}
```

### Pattern Detection

Plugin should detect and generate guides for:

| Pattern Type | Detection Signal |
|--------------|------------------|
| Controller/Handler | `*controller*`, `*handler*`, route definitions |
| Provider/Service | Business logic directories, DI patterns |
| Model/Entity | ORM model files, schema definitions |
| Migration | Migration directory, knex/sequelize/prisma patterns |
| Worker/Job | Queue handlers, cron patterns |
| Middleware | Middleware directory, express/koa patterns |
| Authorization | Permission checks, RBAC/ABAC patterns |

### Convention Extraction

For each detected pattern, analyze existing files to extract:
- Common imports/dependencies
- Naming conventions
- Method signatures
- Error handling patterns
- Return value shapes

---

## Part 3: Composition Generation

### Current Gap

`compositions.yaml` defines multi-pattern sequences but lacks:
- Clear step ordering with dependencies
- File output expectations per step
- Prerequisite patterns

### Enhanced Composition Format

```yaml
compositions:
  add_authenticated_endpoint:
    description: "Add API endpoint with auth"
    patterns: [controller, provider, authorization]

    prerequisites:
      patterns: [authorization]
      description: "Auth system must exist"

    steps:
      - pattern: controller
        description: "Create HTTP handler"
        outputs:
          - "{controllers-dir}/{name}.controller.{ext}"
        depends_on: []

      - pattern: provider
        description: "Create business logic"
        outputs:
          - "{providers-dir}/{name}/{Name}Provider.{ext}"
        depends_on: [controller]

      - pattern: authorization
        description: "Add permission checks"
        outputs: []  # Modifies existing files
        depends_on: [provider]

  add_background_job:
    description: "Add async job processor"
    patterns: [worker, provider]

    steps:
      - pattern: worker
        description: "Create queue handler"
        outputs:
          - "{workers-dir}/{name}.handler.{ext}"

      - pattern: provider
        description: "Create job processing logic"
        outputs:
          - "{providers-dir}/{name}/{Name}Provider.{ext}"
```

---

## Part 4: Domain Reference Generation

### Current Gap

Domain references vary in depth. Need consistent structure.

### Standard Domain Reference Template

```markdown
# Domain: {Name}

## Overview
{Brief description of domain responsibility}

## Location
`{primary-location}`

## Key Files
| File | Purpose |
|------|---------|
| {file} | {purpose} |

## Patterns Used
- [{pattern}](../patterns/{pattern}.md)

## Related Domains
- [{domain}](./{domain}.md) - {relationship}

## Entry Points
| Task | Start Here |
|------|------------|
| {common-task} | {file} |

## External Dependencies
- {integration}: {how-used}
```

---

## Part 5: SKILL.md Generation

### Current Structure

SKILL.md contains three routers:
- Domain Router (keyword → domain)
- Pattern Router (task → pattern)
- Layer Router (layer → location)

### Improvements

**Domain Router Enhancement:**
```markdown
| Keywords | Domain | Location | Patterns | Reference |
|----------|--------|----------|----------|-----------|
| auth, jwt, login, token | authentication | /src/auth/ | middleware, provider | [→](./references/domains/authentication.md) |
```

Add patterns column to show which patterns are commonly used in that domain.

**Pattern Router Enhancement:**
```markdown
| Task | Pattern | Location | Template | Reference |
|------|---------|----------|----------|-----------|
| Add endpoint | controller | /src/controllers/ | Yes | [→](./references/patterns/controller.md) |
```

Add template column to indicate if a code template is available.

**Add Quick Facts Section:**
```markdown
## Quick Facts

| Metric | Value |
|--------|-------|
| Domains | {count} |
| Patterns | {count} |
| Integrations | {count} |
| Test command | `{cmd}` |
| Build command | `{cmd}` |
```

---

## Part 6: SDLC Command Improvements

The SDLC commands (`/spec-plan`, `/spec-build`, `/spec-review`) consume Atlas for context. These improvements make that consumption more effective.

### 6.1 `/spec-plan` Enhancements

**Use Atlas for prerequisite detection:**

When generating specs, query Atlas to identify:
- Required files that must exist (from domain key_files)
- Required patterns that must be in place (from compositions.prerequisites)
- Relevant integrations (from schema.integrations)

```markdown
## Prerequisites

### Required Files
<!-- Pulled from Atlas domain references -->
- [ ] `{file}` - {why-needed}

### Verification
```bash
{commands-from-atlas-config_files}
```

### Blocking Tickets
If prerequisites missing, complete these first:
- {description-of-what-needs-to-exist}
```

**Use Atlas for branch convention:**

```markdown
## Branch

**Name**: `{type}/{slug}`
**Base**: `{detected-default-branch-from-atlas}`

Type: `feature` | `chore` | `bugfix` | `hotfix`
```

**Use Atlas for validation commands:**

Pull from `schema.config_files`:
```markdown
## Validation

```bash
# Build
{schema.config_files.build_command}

# Test
{schema.config_files.test_command}

# Lint
{schema.config_files.lint_command}
```
```

**Inject pattern context into specs:**

For each pattern identified in the task, embed from Atlas:
- Critical conventions (from pattern guide)
- Anti-patterns to avoid (from pattern guide)
- Template code (from pattern guide)
- Expected file outputs (from compositions)

---

### 6.2 `/spec-build` Enhancements

**Phase 0: Prerequisite Verification**

Before implementation begins:

1. Parse spec for prerequisites section
2. Run verification commands
3. If any fail → EXIT with clear message
4. If prerequisite tickets listed → Ask user to confirm completion

**Phase 1: Branch Management**

```
1. Extract branch name from spec
2. Check current git state:
   - On correct branch, clean → Proceed
   - On correct branch, dirty → Ask: stash or continue?
   - On wrong branch, clean → Checkout/create branch
   - On wrong branch, dirty → Ask: stash, commit, or abort?
3. Verify base branch is current (warn if stale)
```

**Pattern-guided implementation:**

For each step in the spec:
1. Load relevant pattern guide from Atlas
2. Keep conventions and anti-patterns in context
3. Use template as starting point
4. Verify outputs match composition expectations

**Retry limits on validation:**

For each validation command:
- Run command
- If fails: attempt fix (max 3 attempts)
- After 3 failures: log error, continue to next
- Final report shows pass/fail with attempt counts

---

### 6.3 `/spec-review` Enhancements

**Pattern adherence checking:**

For each pattern used, verify against Atlas:
- Conventions followed (from pattern guide)
- Anti-patterns avoided (from pattern guide)
- File structure matches (from pattern guide)

**Severity classification:**

| Severity | Definition | Action |
|----------|------------|--------|
| `blocker` | Breaks functionality, security issue, fails validation | Must fix |
| `tech_debt` | Works but violates patterns | Should fix |
| `skippable` | Style preferences | Optional |

**JSON output for iteration:**

Write to `specs/reviews/{spec-name}-review.json`:

```json
{
  "success": false,
  "spec_file": "specs/{name}.md",
  "base_branch": "{base}",
  "current_branch": "{branch}",
  "timestamp": "{iso-8601}",
  "scores": {
    "spec_compliance": "B",
    "pattern_adherence": "A",
    "validation": "C",
    "overall": "B"
  },
  "issues": [
    {
      "issue_number": 1,
      "description": "{description}",
      "location": "{file}:{line}",
      "severity": "blocker|tech_debt|skippable",
      "resolution": "{how-to-fix}",
      "pattern_violated": "{pattern-name|null}"
    }
  ],
  "validation_results": [
    { "command": "{cmd}", "status": "passed|failed", "error": "{msg}" }
  ]
}
```

**Enable iteration loop:**

`/spec-review` → `/patch-spec` → `/spec-build` → `/spec-review`

---

## Part 7: Calibration Improvements

### Current Gap

`/calibrate` detects drift but output isn't actionable.

### Enhanced Calibration Output

```markdown
## Calibration Report

### Critical Drift
Issues that will cause incorrect context:

| Item | Expected | Actual | Impact |
|------|----------|--------|--------|
| Domain: notifications | exists | missing | Agents won't find notification code |
| Pattern: migration | /migrations/ | /db/migrate/ | Wrong path in specs |

### Minor Drift
Issues that reduce accuracy:

| Item | Expected | Actual | Impact |
|------|----------|--------|--------|
| Controller count | 128 | 135 | File counts outdated |

### New Discoveries
Items detected but not in atlas:

| Item | Location | Suggested Action |
|------|----------|------------------|
| New domain: webhooks | /src/webhooks/ | Add to domains |
| New integration: stripe | /src/services/stripe/ | Add to integrations |

### Recommendations
1. Run `/rechart` to regenerate
2. Or run `/rechart --incremental` to update only changed sections
```

---

## Part 8: Generation Quality Checklist

When `/chart` runs, verify:

### Schema Completeness
- [ ] All domains detected with key files
- [ ] File patterns with accurate counts
- [ ] Task mappings for common workflows
- [ ] Integration inventory from package.json
- [ ] Config file inventory
- [ ] Build/test/lint commands detected

### Pattern Guide Quality
- [ ] Each pattern has 3-5 critical conventions
- [ ] Each pattern has anti-patterns table
- [ ] Each pattern has code template from actual codebase
- [ ] Related patterns linked

### Domain Reference Quality
- [ ] Each domain has key files listed
- [ ] Each domain has patterns used
- [ ] Each domain has entry points
- [ ] Related domains linked

### Composition Quality
- [ ] Multi-step tasks have compositions
- [ ] Steps have clear ordering
- [ ] Prerequisites identified
- [ ] Expected outputs listed

### SKILL.md Quality
- [ ] All routers complete
- [ ] Quick facts accurate
- [ ] All references linked

---

## Success Criteria

Atlas v3 plugin is complete when:

**Generated Artifacts:**
1. **Schema completeness**: Includes task mappings, integrations, infrastructure, commands
2. **Pattern consistency**: All guides follow template with conventions, anti-patterns, templates
3. **Domain depth**: All domains have key files, patterns, entry points
4. **Composition clarity**: Multi-pattern tasks defined with steps and outputs
5. **Routing accuracy**: SKILL.md routers cover all domains/patterns/layers
6. **Drift detection**: `/calibrate` produces actionable, categorized output

**SDLC Command Integration:**
7. **Spec planning**: `/spec-plan` pulls prerequisites, patterns, and validation from Atlas
8. **Spec execution**: `/spec-build` handles prerequisites, branches, retries with pattern guidance
9. **Spec review**: `/spec-review` outputs severity-classified JSON with pattern adherence checks
10. **Iteration loop**: Review → patch → build cycle works seamlessly

