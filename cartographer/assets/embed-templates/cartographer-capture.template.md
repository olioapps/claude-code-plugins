<!--
Embedded Cartographer Command: capture
Source: cartographer/commands/cartographer/capture.md
Standalone version for plugin-free operation
-->
---
model: haiku
allowed-tools: Task, Glob, Grep, Read, Write, Edit, AskUserQuestion
argument-hint: [--pattern <id> | --domain <name> | --anti-pattern | --convention | --from-staging]
description: Interactively capture new patterns, conventions, or anti-patterns into the atlas
---

## Context

Arguments: `/capture [OPTIONS]`
- **--pattern <id>** - Add or update a specific pattern
- **--domain <name>** - Add a new domain
- **--anti-pattern** - Capture a new anti-pattern for an existing pattern
- **--convention** - Capture a new convention for an existing pattern
- **--from-staging** - Process all discoveries from staging file (created by /spec-review)
- **(empty)** - Interactive mode to choose what to capture

Current directory: !`pwd`

## Purpose

Manually enhance the atlas with knowledge discovered during development that wasn't auto-detected by `/chart`. This keeps the atlas as a living document that improves over time.

## Workflow

### 1. Pre-flight Checks

**Verify atlas exists:**
```bash
test -f ".claude/skills/atlas/references/schema.yaml" && echo "EXISTS" || echo "NOT_FOUND"
```

If not found → Error: "No atlas found. Run `/chart` first."

**Load current schema:**
- Read `.claude/skills/atlas/references/schema.yaml`
- Parse existing patterns, domains, conventions

### 2. Determine Capture Mode

**If no arguments provided, use AskUserQuestion:**
```
What would you like to capture?

Options:
1. New pattern (file naming convention, structure)
2. New domain (area of the codebase)
3. Anti-pattern (mistake to avoid)
4. Convention (rule to follow)
5. Observation (technology decision, architectural note)
```

### 3. Capture Based on Mode

#### Mode: New Pattern

**Gather information:**
```
Use AskUserQuestion for each:

1. Pattern ID (snake_case identifier):
   Example: "api_handlers", "react_hooks", "service_classes"

2. Keywords that would trigger this pattern:
   Example: "handler, endpoint, api, route"

3. File naming convention:
   Example: "src/handlers/{Name}Handler.ts"

4. Test file convention:
   Example: "src/handlers/__tests__/{Name}Handler.test.ts"

5. Example files (comma-separated):
   Example: "src/handlers/UserHandler.ts, src/handlers/AuthHandler.ts"

6. Registration location (if any):
   Example: "src/handlers/index.ts - add export"

7. Anti-patterns to avoid (2-4 short rules starting with "Don't"):
   Example: "Don't import DAOs directly - use services"
```

**Update schema.yaml:**
```yaml
patterns:
  {pattern_id}:
    keywords:
      - {keyword1}
      - {keyword2}
    file_convention: "{convention}"
    test_convention: "{test_convention}"
    example_files:
      - "{example1}"
      - "{example2}"
    registration:
      - file: "{registration_file}"
        action: "{action}"
    anti_patterns_summary:
      - "{anti_pattern1}"
      - "{anti_pattern2}"
```

**Update keyword_index:**
```yaml
keyword_index:
  {keyword1}: {pattern_id}
  {keyword2}: {pattern_id}
```

#### Mode: New Domain

**Gather information:**
```
Use AskUserQuestion for each:

1. Domain name (snake_case):
   Example: "user_auth", "payment_processing"

2. Location path:
   Example: "src/features/auth"

3. Purpose (one sentence):
   Example: "Handles user authentication and session management"

4. Key files (comma-separated):
   Example: "AuthService.ts, AuthMiddleware.ts, types.ts"
```

**Update schema.yaml domains section:**
```yaml
domains:
  {domain_name}:
    location: "{path}"
    purpose: "{purpose}"
    count: {detected_count}
    confidence: high  # User-provided = high confidence
    key_files:
      - "{file1}"
      - "{file2}"
```

**Create domain reference file:**
`.claude/skills/atlas/references/{area}/{domain}.md`

#### Mode: Anti-Pattern

**Gather information:**
```
Use AskUserQuestion:

1. Which pattern does this anti-pattern belong to?
   {list existing patterns}

2. Describe the anti-pattern (start with "Don't"):
   Example: "Don't call external APIs directly from controllers - use the integrations layer"

3. Why is this bad? (one sentence):
   Example: "Bypasses error handling and retry logic in the integrations layer"

4. What's the correct approach?
   Example: "Import from src/integrations/ instead"
```

**Update schema.yaml:**
```yaml
patterns:
  {pattern_id}:
    anti_patterns_summary:
      - "{existing_anti_patterns}"
      - "{new_anti_pattern}"  # Added
```

#### Mode: Convention

**Gather information:**
```
Use AskUserQuestion:

1. Which pattern does this convention belong to?
   {list existing patterns}

2. Describe the convention:
   Example: "Always use dependency injection for services"

3. Example of correct usage:
   {code snippet}
```

**Update pattern guide:**
`.claude/skills/atlas/references/patterns/{pattern}.md`

Add to "Key Conventions" section.

#### Mode: Observation

**Gather information:**
```
Use AskUserQuestion:

1. Category:
   Options: State Management, API Layer, Database, Testing, DevOps, Other

2. Technology/Decision observed:
   Example: "Using Redux Toolkit with RTK Query"

3. Evidence from codebase:
   Example: "store.ts uses configureStore, 40+ slice files in src/store/"

4. Notable configuration or patterns:
   Example: "All API calls go through RTK Query, no direct fetch"
```

**Update observations.md:**
```markdown
## {Category}

**Observed:** {technology}

**Evidence:**
- {evidence}

**Notable patterns:**
- {patterns}
```

#### Mode: From Staging (--from-staging)

**Check for staging file:**
```bash
test -f ".claude/skills/atlas/staging/discoveries.yaml" && echo "EXISTS" || echo "NOT_FOUND"
```

**If not found:**
```
❌ No staging file found.

Staging files are created by /spec-review when it discovers
patterns, anti-patterns, or conventions not in the atlas.

Use manual capture flags instead:
- /capture --pattern
- /capture --anti-pattern
- /capture --convention
```

**Read and parse staging file:**
- Load `.claude/skills/atlas/staging/discoveries.yaml`
- Group by type: `anti_pattern`, `convention`, `pattern`

**Present summary:**
```
📋 Staging File Contents

Found {count} discoveries:
- {count} anti-patterns
- {count} conventions
- {count} new patterns

Process all?
```
Options: "Process all" | "Review individually" | "Clear staging" | "Cancel"

**For "Process all":**

1. For each `anti_pattern`:
   - Add to `patterns.{pattern_id}.anti_patterns_summary`

2. For each `convention`:
   - Add to pattern guide or schema.yaml

3. For each new `pattern`:
   - Create full pattern entry in schema.yaml
   - Update keyword_index

**Clear staging after success:**
```bash
rm .claude/skills/atlas/staging/discoveries.yaml
```

**Report:**
```markdown
## Staging Processed

**Applied:** {count} discoveries

| Type | Pattern | Description | Status |
|------|---------|-------------|--------|
{table of processed items}

**Staging file cleared.**
```

### 4. Validate Capture

**After updating files:**
- Verify YAML is valid
- Check for duplicate entries
- Ensure links are valid

### 5. Report Results

```markdown
## Capture Complete

**Type:** {pattern | domain | anti-pattern | convention | observation}

**Added to:**
- `{file_path}`: {what was added}

**Updates:**
{summary of changes}

**Verification:**
- YAML valid: ✅
- No duplicates: ✅
- Links valid: ✅

**Next steps:**
- Run `/calibrate` to verify atlas health
- Use `/where {keywords}` to test lookup
```

---

## Capture Guidelines

### Good Anti-Patterns (Codebase-Specific)

✅ "Don't import DAOs directly in controllers - use providers"
✅ "Don't define types inline in components - import from types/"
✅ "Don't skip registration in routes/index.ts"

### Bad Anti-Patterns (Too Generic)

❌ "Don't use any types" (Claude already knows)
❌ "Don't skip error handling" (Generic advice)
❌ "Don't write bad code" (Not actionable)

### Good Conventions

✅ "Use `*.handler.ts` suffix for API handlers"
✅ "Place shared types in `src/types/{domain}.types.ts`"
✅ "Register new routes in `src/routes/index.ts`"

---

## Error Handling

| Error | Action | Recovery |
|-------|--------|----------|
| No atlas found | Error message | Run /chart |
| Invalid pattern ID | Suggest valid format | User retries |
| Duplicate entry | Warn and ask to update | User confirms |
| Invalid YAML after update | Rollback and report | User fixes input |

## Responsibilities

**YOU (handler):**
- Load current atlas state
- Guide user through capture process
- Validate inputs
- Update appropriate files
- Verify changes

**You do the capture interactively. This is a manual enhancement workflow.**
