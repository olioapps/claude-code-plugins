# Codebase Documentation Plugin

Generate AI-optimized documentation schema for any codebase. This plugin creates a structured documentation system that helps AI agents (like Claude Code) efficiently navigate and understand your codebase.

## Installation

```bash
claude plugin add olio-plugins/codebase-documentation
```

## Quick Start

```bash
# Generate documentation for your codebase
/codebase-documentation:document-codebase

# Skip clarification questions (auto-detect everything)
/codebase-documentation:document-codebase --skip-clarification

# Preview what would be generated without creating files
/codebase-documentation:document-codebase --dry-run
```

## What It Creates

Running the command generates a complete documentation system:

```
.claude/
├── commands/
│   └── prime.md              # Initialize agent context
├── docs/
│   ├── codebase-schema.yaml  # Machine-readable codebase map
│   ├── INDEX.md              # Human-readable navigation index
│   ├── domains/              # Domain-specific documentation
│   │   └── {domain}.md       # One per major domain
│   └── patterns/             # Coding convention guides
│       └── {pattern}.md      # One per key pattern
CLAUDE.md (updated with discovery system reference)
```

## Commands

### Main Command

#### `/codebase-documentation:document-codebase`

Generates the complete documentation system for your codebase.

```bash
# Standard generation (with clarification questions)
/codebase-documentation:document-codebase

# Auto-detect everything
/codebase-documentation:document-codebase --skip-clarification

# Preview what would be generated
/codebase-documentation:document-codebase --dry-run

# Combined: auto-detect + preview
/codebase-documentation:document-codebase --skip-clarification --dry-run
```

### Maintenance Commands

These commands are provided by the plugin for ongoing documentation maintenance:

#### `/codebase-documentation:audit-docs`

Detects documentation drift between the schema and actual filesystem state.

```bash
# Standard audit
/codebase-documentation:audit-docs

# Detailed file-by-file analysis
/codebase-documentation:audit-docs --verbose

# Auto-fix trivial drift (count updates, timestamps)
/codebase-documentation:audit-docs --auto-fix

# Audit specific domain only
/codebase-documentation:audit-docs --domain components

# Interactive mode - prompt for each decision
/codebase-documentation:audit-docs --interactive

# Only show significant issues
/codebase-documentation:audit-docs --threshold significant
```

**Drift Classification:**
| Level | Criteria | Action |
|-------|----------|--------|
| TRIVIAL | ≤5 files OR ≤10% difference | Auto-fixable |
| MINOR | 6-20 files OR 10-25% difference | Review recommended |
| SIGNIFICANT | >20 files OR >25% difference | Investigation required |

#### `/codebase-documentation:map-domain`

Deep analysis of a specific domain for documentation or investigation.

```bash
# Analyze a domain from schema
/codebase-documentation:map-domain components

# Analyze arbitrary directory (not in schema)
/codebase-documentation:map-domain src/custom/area

# Compare with existing documentation
/codebase-documentation:map-domain services --compare

# Update schema with findings
/codebase-documentation:map-domain auth --update-schema

# Update domain documentation
/codebase-documentation:map-domain models --update-docs

# Focus analysis on specific area
/codebase-documentation:map-domain utils --focus patterns

# Quick summary only
/codebase-documentation:map-domain api --quiet
```

#### `/codebase-documentation:update-docs`

Intelligently re-analyze and update documentation while preserving customizations.

```bash
# Standard update (preserves customizations)
/codebase-documentation:update-docs

# Preview changes without applying
/codebase-documentation:update-docs --dry-run

# Update specific domains only
/codebase-documentation:update-docs --domains components,services

# Interactive mode for conflict resolution
/codebase-documentation:update-docs --interactive

# Force complete re-analysis
/codebase-documentation:update-docs --full-reanalysis

# Recreate all (lose customizations)
/codebase-documentation:update-docs --force-recreate
```

**Update Strategies:**
| Strategy | When Applied | Behavior |
|----------|--------------|----------|
| REFRESH | Counts changed, structure same | Update stats only |
| MERGE | Structure changed, has custom content | Preserve custom sections |
| RECREATE | Fundamentally restructured | Archive old, generate new |
| ADD | New domain discovered | Create new documentation |
| REMOVE | Domain no longer exists | Archive (not delete) |

### Generated Command

#### `/prime`

Loads codebase context. Run this when starting a new session to give the AI agent full understanding of the codebase structure.

```bash
/prime
```

## How It Works

### Phase 0: Clarification

Asks about your application type (frontend, backend, mono-repo, CLI/library, mobile) and any specific architecture notes. Skip with `--skip-clarification`.

### Phase 0.5: Idempotency Check

If documentation already exists, prompts whether to regenerate or cancel.

### Phase 1: Analysis

The `codebase-analyzer` agent explores your codebase to identify:
- Technology stack (language, framework, tools)
- Logical domains and their locations
- File naming patterns and conventions
- Configuration and testing setup
- Confidence levels for each domain

### Phase 1.5: Dry Run Preview (optional)

With `--dry-run`, shows comprehensive preview of what would be generated before proceeding.

### Phase 2: Documentation Generation

The `documentation-generator` agent creates all documentation files using the analysis results and standardized templates.

### Phase 3: Summary Report

Provides detailed summary of:
- All files created
- Domains documented with purposes
- Quality checks performed
- Potential gaps identified
- Next steps for maintenance

## Documentation Lifecycle

```
┌─────────────────────────────────────────────────────────────────┐
│                    DOCUMENTATION LIFECYCLE                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. GENERATE                                                     │
│     /codebase-documentation:document-codebase                    │
│     └── Creates initial documentation system                     │
│                                                                  │
│  2. MAINTAIN                                                     │
│     /codebase-documentation:audit-docs                           │
│     └── Periodic drift detection (run weekly/monthly)            │
│                                                                  │
│  3. UPDATE                                                       │
│     /codebase-documentation:update-docs                          │
│     └── Refresh documentation after changes                      │
│                                                                  │
│  4. INVESTIGATE                                                  │
│     /codebase-documentation:map-domain <name>                    │
│     └── Deep-dive into specific areas                            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Supported Application Types

| Type | Focus Areas |
|------|-------------|
| **Frontend** | Components, state management, routing, styling, API clients |
| **Backend** | Controllers, services, models, middleware, migrations, integrations |
| **Mono-Repo** | Package structure, shared deps, cross-package relationships |
| **CLI/Library** | Commands, public API, configuration, plugins |
| **Mobile** | Platform-specific code, native modules, navigation |

## Architecture

```
codebase-documentation/
├── .claude-plugin/
│   └── plugin.json               # Plugin metadata
├── agents/
│   ├── codebase-analyzer.md      # Explores and analyzes codebase
│   └── documentation-generator.md # Creates documentation files
├── commands/
│   ├── document-codebase.md      # Main orchestrating command
│   ├── audit-docs.md             # Drift detection command
│   ├── map-domain.md             # Domain analysis command
│   └── update-docs.md            # Intelligent update command
└── README.md
```

### Responsibility Separation

| Component | Responsibility |
|-----------|---------------|
| **document-codebase** | Orchestrates workflow, handles user input, invokes agents |
| **codebase-analyzer** | Deep exploration, identifies structure/patterns/stack |
| **documentation-generator** | Creates all documentation artifacts from analysis |
| **audit-docs** | Detects drift between schema and filesystem |
| **map-domain** | Deep analysis of specific domains |
| **update-docs** | Intelligent incremental updates with customization preservation |

## Best Practices

### When to Run Initial Generation

- After initial codebase setup
- After major architectural changes
- When onboarding new team members
- When AI agents seem confused about codebase structure

### Maintenance Workflow

1. **Regular Audits**: Run `/codebase-documentation:audit-docs` weekly or after significant changes
2. **Address Drift**: Use `/codebase-documentation:update-docs` when audit shows MINOR or SIGNIFICANT drift
3. **Investigate Issues**: Use `/codebase-documentation:map-domain <name>` for detailed analysis of problem areas
4. **Preserve Customizations**: The update command preserves your custom notes and sections by default

### Customization Tips

- Edit generated files to add project-specific details
- Add custom task mappings to `codebase-schema.yaml`
- Extend domain docs with team conventions
- Custom sections are preserved during `/codebase-documentation:update-docs`

## Example Output

### codebase-schema.yaml (excerpt)

```yaml
metadata:
  project: my-app
  type: frontend
  stack:
    language: TypeScript
    framework: React
    state_management: Redux Toolkit
    styling: Tailwind CSS

domains:
  components:
    location: src/components
    count: ~45
    purpose: Reusable UI components
    confidence: high
    key_files:
      - Button/Button.tsx
      - Modal/Modal.tsx
```

### INDEX.md (excerpt)

```markdown
## Quick Domain Lookup

| Domain | Primary Location | Key Files | Documentation |
|--------|-----------------|-----------|---------------|
| components | `src/components` | Button, Modal | [components.md](domains/components.md) |
| services | `src/services` | api, auth | [services.md](domains/services.md) |
```

## Troubleshooting

### "No source files found"

Ensure you're running the command from a directory containing source code.

### "Analysis failed"

Check that the project has recognizable config files (package.json, requirements.txt, etc.).

### Documentation seems incomplete

Try running without `--skip-clarification` to provide more context about your codebase.

### "Documentation already exists" prompt keeps appearing

This is the idempotency check working as intended. Select "Regenerate" to overwrite or "Cancel" to preserve existing docs.

### Domain count seems wrong

- Use `/codebase-documentation:map-domain <name>` to investigate specific domains
- The analyzer may have combined or split domains based on structural boundaries
- Run `/codebase-documentation:update-docs` to refresh after understanding the structure

### Analysis takes too long

- Large codebases (>2000 files) may take several minutes
- The analyzer samples large directories rather than reading every file
- Use `--skip-clarification` to save time on repeated runs

## License

MIT
