---
model: sonnet
allowed-tools: Task, Glob, Grep, Read, Write, Bash(git diff:*), Bash(git log:*), Bash(git status:*), Bash(mkdir:*), AskUserQuestion
argument-hint: <spec file> [--no-agents] [--sequential]
description: Review implementation against spec and patterns (outputs JSON for iteration)
---

## Context

Arguments: `/navigator:review <SPEC_FILE> [OPTIONS]`
- **<spec_file>** - Path to spec file that was implemented
- **--no-agents** - Skip multi-agent review (faster, less thorough)
- **--sequential** - Run review agents sequentially instead of parallel

Current directory: !`pwd`
Current branch: !`git branch --show-current`

## Workflow

### 1. Pre-flight Checks

**Verify atlas exists:**
```bash
test -f ".claude/skills/atlas/references/schema.yaml" && echo "EXISTS" || echo "NOT_FOUND"
```

**If atlas not found:**
```
❌ Atlas required for navigator commands.

Run `/cartographer:chart` to generate an atlas first.
```
**STOP** - Do not proceed without atlas.

**Verify spec file exists:**
```bash
test -f "{spec_file}" && echo "EXISTS" || echo "NOT_FOUND"
```

### 2. Load Context

**Read spec file:**
- Extract success criteria
- Extract pattern guides referenced
- Extract expected files (new and modified)
- Extract composition ID if present

**Load atlas files:**
- `.claude/skills/atlas/references/schema.yaml` - Unified codebase structure
- Relevant pattern guides from spec

**Extract from schema.yaml patterns section for each pattern in spec:**
- File conventions (verify files created at correct locations)
- Test conventions (verify tests created)
- Registration steps (verify registration completed)
- Validation commands (run pattern-specific checks)

**Get implementation changes:**
```bash
git diff {base_branch}...HEAD --name-only
git diff {base_branch}...HEAD --stat
```

### 3. Review Against Spec

**Check success criteria:**

For each criterion in spec:
- Verify implementation meets criterion
- Document how it's verified
- Flag any gaps

```markdown
### Success Criteria Review

| Criterion | Status | Evidence |
|-----------|--------|----------|
| {criterion 1} | ✅/❌ | {how verified} |
| {criterion 2} | ✅/❌ | {how verified} |
```

**Check expected files:**

For each file in spec "New Files" / "Existing Files":
- Verify file was created/modified
- Check file follows expected patterns

```markdown
### File Coverage

| Expected | Status | Notes |
|----------|--------|-------|
| {file1} | ✅ Created | Follows pattern |
| {file2} | ✅ Modified | Changes appropriate |
| {file3} | ❌ Missing | Not implemented |
```

### 4. Review Against Patterns

**For each pattern in spec, check against schema.yaml patterns section:**

1. **File Convention Check:**
   - Expected location: `{file_convention from schema.yaml patterns}`
   - Actual file created: {path} → ✅/❌

2. **Test Convention Check:**
   - Expected test location: `{test_convention}`
   - Test file exists: ✅/❌

3. **Registration Check:**
   - For each registration step in schema.yaml patterns:
   - {action} in `{file}` → ✅/❌

4. **Critical Conventions Check (from pattern guide):**
   - For each convention listed in pattern guide:
   - Verify implementation follows the rule
   - Classify violations by severity

5. **Anti-Pattern Check (from pattern guide):**
   - For each anti-pattern listed in pattern guide:
   - Verify implementation does NOT exhibit the anti-pattern
   - Flag any violations as tech_debt or blocker

**Severity Classification:**

| Severity | Definition | Action Required |
|----------|------------|-----------------|
| `blocker` | Breaks functionality, security issue, fails validation | Must fix before PR |
| `tech_debt` | Works but violates patterns/conventions | Should fix, can defer |
| `skippable` | Style preferences, minor improvements | Optional |

```markdown
### Pattern Adherence: {pattern_name}

**Conventions checked (from schema.yaml patterns):**
- [ ] File at correct location (`{file_convention}`) - ✅/❌
- [ ] Test at correct location (`{test_convention}`) - ✅/❌
- [ ] Registration completed in `{registration_file}` - ✅/❌

**Critical conventions (from pattern guide):**
- [ ] {convention_1} - ✅/❌ [{severity if violated}]
- [ ] {convention_2} - ✅/❌ [{severity if violated}]

**Anti-patterns avoided (from pattern guide):**
- [ ] Does NOT {anti_pattern_1} - ✅/❌ [{severity if violated}]
- [ ] Does NOT {anti_pattern_2} - ✅/❌ [{severity if violated}]

**Reference implementation comparison:**
- Compared against: `{example_file from schema.yaml patterns}`
- Follows established patterns: ✅/❌

**Issues found:**
- `{file}:{line}` - {description} [**{severity}**]
```

### 5. Multi-Agent Review (default)

**Launch review agents (parallel by default, sequential with --sequential):**

Using Task tool, spawn these agents:

1. **pattern-enforcer** (`agents/review/pattern-enforcer.md`)
   - Input: Changed files, schema.yaml
   - Output: Pattern violations with atlas references

2. **convention-checker** (`agents/review/convention-checker.md`)
   - Input: New files, schema.yaml
   - Output: Naming/location violations

3. **architecture-auditor** (`agents/review/architecture-auditor.md`)
   - Input: Changed files, schema.yaml layers
   - Output: Layer boundary violations

4. **anti-pattern-detector** (`agents/review/anti-pattern-detector.md`)
   - Input: Changed files, schema.yaml anti_patterns_summary
   - Output: Codebase-specific anti-pattern detections

**Aggregate agent findings:**

```markdown
### Multi-Agent Review Results

| Agent | Findings | Severity |
|-------|----------|----------|
| Pattern Enforcer | {count} violations | {max_severity} |
| Convention Checker | {count} violations | {max_severity} |
| Architecture Auditor | {count} violations | {max_severity} |
| Anti-Pattern Detector | {count} detections | {max_severity} |

**Total Issues:** {sum}
```

**Classify findings by severity:**
- 🔴 `error` from any agent → **Blocker**
- 🟡 `warning` from any agent → **Tech Debt**
- Recommendations → **Skippable**

### 5b. Lightweight Review (if --no-agents)

**Skip agents and do manual quality check:**

- **Readability**: Is the code clear and self-documenting?
- **Consistency**: Does it match existing codebase style?
- **Completeness**: Are edge cases handled?
- **Testing**: Are new paths tested?

**Read changed files:**
- Identify potential issues
- Note positive patterns

### 6. Check for Regressions

**Run validation commands from spec:**
```bash
{type_check_command}
{test_command}
{lint_command}
{build_command}
```

**Report results:**
```markdown
### Validation Status

| Check | Status | Details |
|-------|--------|---------|
| Type check | ✅/❌ | {errors if any} |
| Tests | ✅/❌ | {failing tests if any} |
| Lint | ✅/❌ | {violations if any} |
| Build | ✅/❌ | {errors if any} |
```

### 7. Generate Review Report

```markdown
## Navigator Review: {spec_name}

**Spec:** `{spec_file}`
**Branch:** `{current_branch}`
**Base:** `{base_branch}`
**Review Mode:** {Standard | Multi-Agent}

---

### Summary

| Category | Score | Details |
|----------|-------|---------|
| Spec Compliance | {A/B/C/F} | {X}/{Y} criteria met |
| Pattern Adherence | {A/B/C/F} | {X}/{Y} conventions followed |
| Code Quality | {A/B/C/F} | {notes} |
| Validation | {A/B/C/F} | {pass/fail counts} |

{IF multi-agent review:}
### Agent Review Summary

| Agent | Violations | Max Severity |
|-------|------------|--------------|
| Pattern Enforcer | {count} | {error/warning/none} |
| Convention Checker | {count} | {error/warning/none} |
| Architecture Auditor | {count} | {error/warning/none} |
| Anti-Pattern Detector | {count} | {error/warning/none} |

**Overall Status:** {✅ Ready for PR | ⚠️ Needs attention | ❌ Significant issues}

---

### Issue Summary by Severity

| Severity | Count | Requires Action |
|----------|-------|-----------------|
| 🔴 Blocker | {count} | Must fix before PR |
| 🟡 Tech Debt | {count} | Should fix |
| 🟢 Skippable | {count} | Optional |

---

### Detailed Findings

#### 🔴 Blockers (must fix)
{list blocker issues with file:line references}

#### 🟡 Tech Debt (should fix)
{list tech_debt issues with file:line references}

#### 🟢 Skippable (optional)
{list skippable issues}

#### ✅ Successes
{list things done well}

{IF multi-agent review:}
---

### Agent-Specific Findings

#### Pattern Enforcer
{list pattern violations with atlas references}

#### Convention Checker
{list naming/location violations}

#### Architecture Auditor
{list layer boundary violations}

#### Anti-Pattern Detector
{list codebase-specific anti-patterns detected}

---

### Success Criteria Status

{table from step 3}

---

### Pattern Adherence Details

{sections from step 4}

---

### Files Changed

```
{git diff stat output}
```

---

### Validation Results

{table from step 6}

---

### Recommendations

{if ready for PR}
**Ready for PR.** No blocking issues found.

Suggested commit message:
```
{suggested commit message based on spec}
```

{if needs attention}
**Address before PR:**
1. {issue 1}
2. {issue 2}

{if significant issues}
**Significant issues found. Please address:**
1. {critical issue 1}
2. {critical issue 2}

Consider running `/navigator:build {spec_file}` again after fixes.
```

### 8. Write JSON Output

**Create reviews directory:**
```bash
mkdir -p specs/reviews
```

**Write JSON file:** `specs/reviews/{spec-name}-review.json`

```json
{
  "success": {true if no blockers, false otherwise},
  "spec_file": "{spec_file}",
  "base_branch": "{base_branch}",
  "current_branch": "{current_branch}",
  "timestamp": "{ISO-8601 timestamp}",
  "review_mode": "{standard|multi-agent}",
  "scores": {
    "spec_compliance": "{A/B/C/F}",
    "pattern_adherence": "{A/B/C/F}",
    "code_quality": "{A/B/C/F}",
    "validation": "{A/B/C/F}",
    "overall": "{A/B/C/F}"
  },
  "issue_counts": {
    "blocker": {count},
    "tech_debt": {count},
    "skippable": {count}
  },
  "issues": [
    {
      "issue_number": 1,
      "description": "{description}",
      "location": "{file}:{line}",
      "severity": "blocker|tech_debt|skippable",
      "resolution": "{how to fix}",
      "pattern_violated": "{pattern_id or null}",
      "source_agent": "{pattern-enforcer|convention-checker|architecture-auditor|anti-pattern-detector|manual}"
    }
  ],
  "agent_results": {
    "pattern_enforcer": {
      "violations": {count},
      "max_severity": "{error|warning|none}"
    },
    "convention_checker": {
      "violations": {count},
      "max_severity": "{error|warning|none}"
    },
    "architecture_auditor": {
      "violations": {count},
      "max_severity": "{error|warning|none}"
    },
    "anti_pattern_detector": {
      "detections": {count},
      "max_severity": "{error|warning|none}"
    }
  },
  "validation_results": [
    {
      "command": "{command}",
      "status": "passed|failed",
      "error": "{error message or null}"
    }
  ],
  "success_criteria": [
    {
      "criterion": "{description}",
      "met": true|false,
      "evidence": "{how verified}"
    }
  ]
}
```

**Report JSON output:**
```
📄 Review JSON written to: specs/reviews/{spec-name}-review.json
```

### 9. Iteration Loop Support

**If blockers exist, suggest iteration:**
```
🔄 Iteration cycle available:

1. Fix blockers listed above
2. Run `/navigator:build {spec_file}` to re-implement
3. Run `/navigator:review {spec_file}` to re-review

Or use the JSON output programmatically:
  specs/reviews/{spec-name}-review.json
```

### 10. Atlas Refinement - Incremental Pattern Learning

**Analyze findings for atlas improvements:**

During review, track discoveries that should be added to the atlas:

#### 10a. Detect Undocumented Patterns

Scan implementation for:
1. **New patterns** - File structures/conventions not in schema.yaml
2. **New anti-patterns** - Mistakes that should be documented for others
3. **Missing conventions** - Rules the code follows but atlas doesn't capture
4. **Unclassified files** - Files that don't match any pattern in atlas

**For each discovery, record:**
- Type: `pattern` | `anti_pattern` | `convention`
- Description: What was observed
- Evidence: File paths and line numbers
- Suggested pattern_id: Which pattern section it belongs to

#### 10b. Write Discoveries to Staging File

**Create staging file:** `.claude/skills/atlas/staging/discoveries.yaml`

```yaml
# Atlas Discoveries - Pending Review
# Generated by /navigator:review on {timestamp}
# Run /cartographer:capture --from-staging to process

discoveries:
  - type: anti_pattern
    pattern_id: controllers
    description: "Direct database queries in controller"
    evidence:
      - file: src/controllers/UserController.ts
        line: 45
        snippet: "db.query('SELECT * FROM users')"
    suggested_rule: "Don't query database directly in controllers - use provider layer"

  - type: convention
    pattern_id: providers
    description: "All providers use dependency injection constructor pattern"
    evidence:
      - file: src/providers/UserProvider.ts
        line: 10
      - file: src/providers/AuthProvider.ts
        line: 8
    suggested_rule: "Inject dependencies via constructor, not inline imports"

  - type: pattern
    pattern_id: null  # New pattern
    description: "Background job handlers follow consistent structure"
    evidence:
      - file: src/jobs/EmailJob.ts
      - file: src/jobs/ReportJob.ts
    suggested_addition:
      id: background_jobs
      keywords: [job, worker, queue, background, async]
      file_convention: "src/jobs/{Name}Job.ts"
```

```bash
mkdir -p .claude/skills/atlas/staging
```

Write discoveries to staging file if any found.

#### 10c. Prompt for Immediate Capture

**If discoveries found, use AskUserQuestion:**

```
📚 Atlas Learning Opportunity

I discovered {count} items that could improve the atlas:
- {count} new anti-patterns
- {count} new conventions
- {count} potential new patterns

Options:
```
- "Capture all now" → Run `/cartographer:capture --from-staging`
- "Review staging file first" → Show path to staging file
- "Skip for now" → Continue without capturing
- "Never suggest during reviews" → Add preference to atlas

**If "Capture all now":**
```
Capturing discoveries to atlas...

Added to schema.yaml:
- patterns.controllers.anti_patterns_summary: +1 item
- patterns.providers.conventions: +1 item
- patterns.background_jobs: NEW pattern

Staging file cleared.
```

#### 10d. Include in JSON Output

Add discoveries to the review JSON:

```json
{
  "discoveries": {
    "count": 3,
    "staging_file": ".claude/skills/atlas/staging/discoveries.yaml",
    "items": [
      {
        "type": "anti_pattern",
        "pattern_id": "controllers",
        "description": "Direct database queries in controller",
        "auto_capturable": true
      }
    ]
  }
}
```

#### 10e. Report Atlas Refinements

```markdown
## Atlas Learning

**Discoveries:** {count} items found

| Type | Pattern | Description | Status |
|------|---------|-------------|--------|
| Anti-pattern | controllers | Direct DB queries | 📋 Staged |
| Convention | providers | DI constructor pattern | 📋 Staged |
| New Pattern | background_jobs | Job handler structure | 📋 Staged |

**Staging file:** `.claude/skills/atlas/staging/discoveries.yaml`

**To capture:**
```bash
/cartographer:capture --from-staging
```

**To review individual items:**
```bash
/cartographer:capture --anti-pattern --pattern controllers
/cartographer:capture --convention --pattern providers
/cartographer:capture --pattern background_jobs
```
```

---

## Scoring Criteria

### Spec Compliance
- **A**: All success criteria met, all expected files present
- **B**: 80%+ criteria met, most files present
- **C**: 60%+ criteria met, some gaps
- **F**: <60% criteria met or major gaps

### Pattern Adherence
- **A**: All conventions followed, no anti-patterns
- **B**: Most conventions followed, minor deviations
- **C**: Some conventions followed, notable deviations
- **F**: Patterns largely ignored

### Code Quality
- **A**: Clean, readable, well-organized
- **B**: Good quality with minor issues
- **C**: Acceptable but needs improvement
- **F**: Significant quality concerns

### Validation
- **A**: All checks pass
- **B**: Minor warnings only
- **C**: Some failures, non-critical
- **F**: Critical failures

---

## Error Handling

| Error | Action | Recovery |
|-------|--------|----------|
| No atlas | Block with message | Run /cartographer:chart |
| No spec | Error with path | User provides correct path |
| No changes | Note implementation may be missing | Check if on correct branch |
| Validation fails | Report failures | User fixes or accepts |

---

## Error Recovery Protocol

### Agent Failures

When review agents fail after 3 attempts:

**1. Partial results handling:**
```
⚠️ Agent failures during review

Completed:
- Pattern Enforcer: ✅ 5 violations
- Architecture Auditor: ✅ 2 violations

Failed:
- Anti-Pattern Detector: ❌ (3 attempts)
- Convention Checker: ❌ (timeout)

Options:
1. Continue with partial results
2. Retry failed agents only
3. Skip agent review, do manual review
4. Abort review
```

**2. Continue with partial results:**
- Generate report with available data
- Mark missing sections as "Not Available"
- Add warning to review summary

**3. Preserve partial state:**
Write `.claude/review-partial.json`:
```json
{
  "spec_file": "{spec}",
  "timestamp": "{ISO-8601}",
  "completed_agents": ["pattern-enforcer", "architecture-auditor"],
  "failed_agents": [
    {"name": "anti-pattern-detector", "error": "{error}", "attempts": 3},
    {"name": "convention-checker", "error": "timeout", "attempts": 3}
  ],
  "partial_results": {
    "pattern_violations": [...],
    "architecture_violations": [...]
  }
}
```

### Validation Command Failures

When validation commands fail:

**1. Classify failure type:**

| Type | Example | Action |
|------|---------|--------|
| Build error | `npm run build` fails | Report errors, suggest fixes |
| Test failure | `npm test` has failures | List failing tests with reasons |
| Lint error | `npm run lint` has issues | List lint violations |
| Timeout | Command exceeds limit | Report timeout, suggest async |
| Not found | Command doesn't exist | Warn, skip that validation |

**2. Continue despite failures:**
```
⚠️ Validation command failed: npm run build

Exit code: 1
Error output:
  {first 500 chars of stderr}

Impact: Build validation marked as failed
Continuing with remaining validations...
```

**3. Summary handling:**
- Failed validations appear in Validation section with ❌
- Don't block entire review for validation failures
- User can still see other review findings

---

## JSON Output Specification

### Consumers

The review JSON (`.claude/reviews/{spec}-{timestamp}.json`) is consumed by:

| Consumer | Purpose | Required Fields |
|----------|---------|-----------------|
| `/cartographer:capture --from-staging` | Import discoveries | `discoveries.items[]` |
| CI/CD pipelines | Block merge on blockers | `summary.blockers`, `summary.grade` |
| Review dashboards | Aggregate metrics | `summary.*`, `scores.*` |
| `/navigator:build --resume` | Continue after fixes | `blockers[]`, `tech_debt[]` |
| Atlas analytics | Track pattern usage | `atlas_context.patterns_involved` |

### Complete JSON Schema

```json
{
  "version": "1.0",
  "generated": "{ISO-8601 timestamp}",
  "spec_file": "{spec path}",
  "implementation_branch": "{branch name}",
  "base_branch": "{base branch}",

  "summary": {
    "overall_grade": "A|B|C|F",
    "blockers": 0,
    "tech_debt": 0,
    "skippable": 0,
    "recommendation": "merge|fix_blockers|needs_work"
  },

  "scores": {
    "spec_compliance": {"grade": "A", "percentage": 100},
    "pattern_adherence": {"grade": "B", "percentage": 85},
    "code_quality": {"grade": "A", "percentage": 95},
    "validation": {"grade": "A", "all_passed": true}
  },

  "atlas_context": {
    "atlas_path": ".claude/skills/atlas",
    "patterns_involved": ["controllers", "providers"],
    "composition_used": "add_api_endpoint|null",
    "anti_patterns_checked": 12
  },

  "blockers": [
    {
      "id": "BLOCK-001",
      "severity": "blocker",
      "category": "pattern_violation|architecture|validation",
      "file": "{file path}",
      "line": 45,
      "message": "{description}",
      "atlas_reference": "schema.yaml patterns.controllers.anti_patterns_summary[0]",
      "fix": "{suggested fix}"
    }
  ],

  "tech_debt": [
    {
      "id": "DEBT-001",
      "severity": "tech_debt",
      "category": "convention|style|test_coverage",
      "file": "{file path}",
      "message": "{description}",
      "effort": "low|medium|high"
    }
  ],

  "skippable": [
    {
      "id": "SKIP-001",
      "category": "recommendation|suggestion",
      "message": "{description}"
    }
  ],

  "validation_results": {
    "commands_run": 4,
    "passed": 3,
    "failed": 1,
    "results": [
      {"command": "npm run typecheck", "status": "passed", "duration_ms": 2500},
      {"command": "npm run lint", "status": "failed", "errors": 2, "output": "..."}
    ]
  },

  "discoveries": {
    "count": 3,
    "staging_file": ".claude/skills/atlas/staging/discoveries.yaml",
    "items": [
      {
        "type": "anti_pattern|convention|pattern",
        "pattern_id": "{pattern_id}",
        "description": "{what was discovered}",
        "evidence": ["{file paths}"],
        "auto_capturable": true
      }
    ]
  },

  "files_reviewed": [
    {
      "path": "{file path}",
      "status": "new|modified",
      "patterns_matched": ["controllers"],
      "violations": 0,
      "grade": "A"
    }
  ]
}
```

### Backward Compatibility

When adding new fields:
- Add with default values
- Document version in `version` field
- Consumers should ignore unknown fields

## Responsibilities

**YOU (reviewer):**
- Load spec and atlas context
- Review implementation against spec criteria
- Check pattern adherence
- Run validations
- Generate comprehensive review report
- Provide clear recommendations

**You are an objective reviewer. Be thorough but constructive.**

---

## Output Parsing Protocol

### Multi-Agent Review Parsing

When running with `--agents`, parse output from all four review agents:

#### Pattern Enforcer Output

**Delimiters:** `---PATTERN-ENFORCEMENT---` and `---END---`

```yaml
# Extract from pattern-enforcer
summary:
  files_reviewed: number
  violations_found: number
  patterns_checked: [strings]

violations: []               # Array of violation objects
  - file: string
    line: number|null
    pattern: string          # pattern_id
    rule: string             # what was violated
    evidence: string
    atlas_reference: string  # "schema.yaml patterns.{id}.{field}"
    severity: string         # error|warning
    fix: string

compliant: []                # Files with no violations
unclassified: []             # Files not matching any pattern
```

#### Architecture Auditor Output

**Delimiters:** `---ARCHITECTURE-AUDIT---` and `---END---`

```yaml
# Extract from architecture-auditor
summary:
  files_audited: number
  layers_validated: [strings]
  violations: number
  organization_style: string

layer_violations: []         # Import boundary violations
  - file: string
    source_layer: string
    import: string
    target_layer: string
    violation: string        # upward_dependency|skip_layer
    severity: string         # error|warning
    fix: string

domain_violations: []        # Cross-domain coupling
circular_dependencies: []    # Dependency cycles
```

#### Anti-Pattern Detector Output

**Delimiters:** `---ANTI-PATTERN-SCAN---` and `---END---`

```yaml
# Extract from anti-pattern-detector
summary:
  files_scanned: number
  patterns_checked: [strings]
  detections: number

detections: []               # Anti-pattern violations
  - file: string
    line: number
    pattern: string
    anti_pattern: string     # "Don't..."
    evidence: string         # Code snippet
    atlas_reference: string
    severity: string
    fix: string
    fix_example: string|null # Corrected code

clean_files: []              # Files with no anti-patterns
```

#### Convention Checker Output

**Delimiters:** `---CONVENTION-CHECK---` and `---END---`

```yaml
# Extract from convention-checker
summary:
  files_checked: number
  new_files: number
  violations: number
  compliant: number

file_location_violations: []
naming_violations: []
missing_tests: []
orphan_directories: []
compliant_files: []
```

### Aggregation Protocol

After parsing all agent outputs:

```
1. Collect all violations from all agents
2. Classify by severity:
   - error from any agent → blocker
   - warning from any agent → tech_debt
   - recommendations → skippable
3. Deduplicate (same file:line from multiple agents)
4. Sort by: severity (desc), then file path
5. Count totals for summary table
```

**Severity mapping:**

| Agent | Output Field | Mapped Severity |
|-------|--------------|-----------------|
| pattern-enforcer | `severity: error` | blocker |
| pattern-enforcer | `severity: warning` | tech_debt |
| architecture-auditor | `severity: error` | blocker |
| architecture-auditor | `severity: warning` | tech_debt |
| anti-pattern-detector | `severity: error` | blocker |
| anti-pattern-detector | `severity: warning` | tech_debt |
| convention-checker | any violation | tech_debt |
| convention-checker | `missing_tests` | skippable |

### Parsing Failures

If any agent output fails to parse:

```
⚠️ Failed to parse {agent_name} output

Error: {parsing_error}
Agent output preview: {first 300 chars}

Continuing with results from other agents.
```

Continue review with successfully parsed agent results. Note partial results in final report.
