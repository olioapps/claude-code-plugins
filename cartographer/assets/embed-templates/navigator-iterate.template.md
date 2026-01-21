<!--
Embedded Navigator Command: iterate
Source: cartographer/commands/navigator/iterate.md
Standalone version for plugin-free operation
-->
---
model: sonnet
allowed-tools: Task, Glob, Grep, Read, Write, Edit, Bash, AskUserQuestion, TodoWrite
argument-hint: <element> [--iterations=N] [--url=URL]
description: Iteratively improve UI elements using atlas context and visual feedback
---

## Context

Arguments: `/spec-iterate <ELEMENT> [OPTIONS]`
- **<element>** - CSS selector or description of UI element to improve
- **--iterations=N** - Number of improvement iterations (default: 5)
- **--url=URL** - Local development URL to screenshot (default: http://localhost:3000)

Current directory: !`pwd`

## Purpose

Iteratively improve a UI element through repeated cycles of:
1. Screenshot the current state
2. Analyze against atlas UI conventions
3. Identify specific improvements
4. Implement changes
5. Repeat N times

Uses atlas context for codebase-specific styling conventions.

## Workflow

### 1. Pre-flight Checks

**Verify atlas exists:**
```bash
test -f ".claude/skills/atlas/references/schema.yaml" && echo "EXISTS" || echo "NOT_FOUND"
```

**If atlas not found:**
```
❌ Atlas required for navigator commands.

Run `/chart` to generate an atlas first.
```
**STOP** - Do not proceed without atlas.

**Verify development server:**
```bash
curl -s -o /dev/null -w "%{http_code}" {url} || echo "NOT_RUNNING"
```

If server not running, suggest starting it.

### 2. Load Atlas UI Context

**Read schema.yaml for UI patterns:**

From `stack` section:
- `styling` - Styling framework (Tailwind, CSS Modules, etc.)
- `state_management` - State approach
- `framework` - UI framework (React, Vue, etc.)

From `patterns` section (if UI patterns exist):
- Component patterns
- Styling conventions
- Layout standards

From `observations.md`:
- Any documented UI decisions
- Color palette notes
- Typography standards

**Build UI guidance context:**
```
UI Context for iteration:

Framework: {framework}
Styling: {styling}
Conventions:
- {ui_convention_1}
- {ui_convention_2}

Anti-patterns:
- {ui_anti_pattern_1}
```

### 3. Initial Assessment

**Take focused screenshot:**
- Navigate to {url}
- Locate element: {element}
- Capture focused screenshot of element area

**Analyze current state:**
```
Current Element Analysis:

Positive aspects:
- {what's working}

Issues identified:
- {issue_1}: {description}
- {issue_2}: {description}

Improvement opportunities:
- {opportunity_1}
- {opportunity_2}
```

### 4. Create Iteration Plan

**Initialize TodoWrite with iterations:**
```
- [ ] Iteration 1: {primary_improvement_focus}
- [ ] Iteration 2: {secondary_improvement}
- [ ] Iteration 3: {refinement_focus}
- [ ] Iteration 4: {polish_focus}
- [ ] Iteration 5: {final_touches}
```

**Priority order for improvements:**
1. Layout and spacing
2. Typography hierarchy
3. Color and contrast
4. Interactive states
5. Polish and micro-interactions

### 5. Execute Iterations

**For each iteration (1 to N):**

1. **Update TodoWrite:**
   - Mark iteration as in_progress

2. **Identify 3-5 specific improvements:**
   - Based on current screenshot
   - Following atlas UI conventions
   - Prioritized by impact

3. **Implement changes:**
   - Edit component/style files
   - Apply atlas styling patterns
   - Use documented CSS conventions

4. **Take new screenshot:**
   - Capture element after changes

5. **Analyze improvement:**
   ```
   Iteration {N} Results:

   Changes made:
   - {change_1}
   - {change_2}

   Improvement assessment:
   - {aspect}: {before} → {after}

   Remaining issues:
   - {if any}
   ```

6. **Update TodoWrite:**
   - Mark iteration as completed

### 6. Generate Before/After Report

```markdown
## Design Iteration Complete: {element}

**Iterations:** {N}
**URL:** {url}

---

### Before
{initial_screenshot}

**Initial issues:**
- {issue_1}
- {issue_2}

---

### After
{final_screenshot}

**Improvements made:**
| Aspect | Before | After |
|--------|--------|-------|
| {aspect_1} | {before} | {after} |
| {aspect_2} | {before} | {after} |

---

### Iteration Summary

| # | Focus | Changes |
|---|-------|---------|
| 1 | {focus} | {summary} |
| 2 | {focus} | {summary} |
| 3 | {focus} | {summary} |
| 4 | {focus} | {summary} |
| 5 | {focus} | {summary} |

---

### Files Modified
{list of files changed}

---

### Atlas Conventions Applied
- {convention_1} from schema.yaml
- {convention_2} from observations.md

---

### Recommendations
{any additional improvements that could be made}
```

---

## Improvement Categories

### Layout & Spacing
- Alignment consistency
- Padding uniformity
- Margin relationships
- Grid adherence
- White space balance

### Typography
- Font hierarchy
- Size relationships
- Line height
- Letter spacing
- Font weight usage

### Color & Contrast
- Color harmony
- Contrast ratios (accessibility)
- Color meaning consistency
- Background/foreground balance

### Interactive States
- Hover effects
- Focus indicators
- Active states
- Disabled appearance
- Loading states

### Polish
- Border radius consistency
- Shadow depth
- Transition smoothness
- Icon alignment
- Micro-interactions

---

## Atlas Integration

**Use atlas context for:**

| Atlas Source | Usage |
|--------------|-------|
| schema.yaml stack.styling | Determine styling framework |
| patterns.components | Component structure conventions |
| observations.md | Documented UI decisions |
| example_files | Reference implementations |

**If atlas lacks UI documentation:**
```
⚠️ Limited UI context in atlas.

Consider adding UI patterns to schema.yaml:
- Color palette
- Typography scale
- Spacing system
- Component patterns

For now, using general best practices.
```

---

## Error Handling

| Error | Action | Recovery |
|-------|--------|----------|
| No atlas | Block with message | Run /chart |
| Server not running | Prompt to start | User starts dev server |
| Element not found | Ask for clarification | User provides better selector |
| Screenshot fails | Retry with different approach | Manual inspection |

## Responsibilities

**YOU (handler):**
- Load atlas UI context
- Take screenshots at each iteration
- Identify specific improvements
- Implement changes following atlas patterns
- Document before/after with rationale
- Track progress with TodoWrite

**You iterate visually. Each cycle should produce visible improvement.**
