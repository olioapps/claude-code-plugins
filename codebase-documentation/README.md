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
```

## What It Creates

Running the command generates a complete documentation system:

```
.claude/
├── commands/
│   ├── prime.md              # Initialize agent context
│   ├── audit-docs.md         # Detect documentation drift
│   └── map-domain.md         # Deep-dive into domains
├── docs/
│   ├── codebase-schema.yaml  # Machine-readable codebase map
│   ├── INDEX.md              # Human-readable navigation index
│   ├── domains/              # Domain-specific documentation
│   │   └── {domain}.md       # One per major domain
│   └── patterns/             # Coding convention guides
│       └── {pattern}.md      # One per key pattern
CLAUDE.md (updated with discovery system reference)
```

## Generated Commands

After running `document-codebase`, you'll have access to:

### `/prime`
Loads codebase context. Run this when starting a new session to give the AI agent full understanding of the codebase structure.

### `/audit-docs`
Checks for documentation drift. Compares the schema against actual filesystem state and reports discrepancies.

```bash
/audit-docs                    # Standard audit
/audit-docs --verbose          # Detailed output
/audit-docs --auto-fix         # Auto-fix trivial drift
/audit-docs --domain auth      # Audit specific domain
```

### `/map-domain`
Deep analysis of a specific domain. Use this to explore or update documentation for a particular area.

```bash
/map-domain components         # Analyze components domain
/map-domain src/services --update-docs  # Update docs
```

## How It Works

### Phase 0: Clarification
Asks about your application type (frontend, backend, mono-repo, CLI/library, mobile) and any specific architecture notes. Skip with `--skip-clarification`.

### Phase 1: Analysis
The `codebase-analyzer` agent explores your codebase to identify:
- Technology stack (language, framework, tools)
- Logical domains and their locations
- File naming patterns and conventions
- Configuration and testing setup

### Phase 2: Documentation Generation
The `documentation-generator` agent creates all documentation files using the analysis results and standardized templates.

### Phase 3: Utility Commands
Creates maintenance commands (`audit-docs`, `map-domain`) for ongoing documentation upkeep.

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
│   └── plugin.json           # Plugin metadata
├── agents/
│   ├── codebase-analyzer.md  # Explores and analyzes codebase
│   └── documentation-generator.md  # Creates documentation files
├── commands/
│   └── document-codebase.md  # Main orchestrating command
└── README.md
```

### Responsibility Separation

| Component | Responsibility |
|-----------|---------------|
| **document-codebase** | Orchestrates workflow, handles user input, creates utility commands |
| **codebase-analyzer** | Deep exploration, identifies structure/patterns/stack |
| **documentation-generator** | Creates all documentation artifacts from analysis |

## Best Practices

### When to Run
- After initial codebase setup
- After major architectural changes
- When onboarding new team members
- When AI agents seem confused about codebase structure

### Maintenance
- Run `/audit-docs` periodically to catch drift
- Update documentation when adding new domains
- Use `/map-domain` for detailed updates to specific areas

### Customization
- Edit generated files to add project-specific details
- Add custom task mappings to `codebase-schema.yaml`
- Extend domain docs with team conventions

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

## License

MIT
