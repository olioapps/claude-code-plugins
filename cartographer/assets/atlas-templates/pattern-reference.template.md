# {{pattern_name}} Pattern

> Applies to: {{applicable_domains}}

## Overview

{{overview}}

## When to Use

{{#each use_cases}}
- {{this}}
{{/each}}

## File Structure

```
{{file_structure}}
```

## Implementation Steps

{{#each implementation_steps}}
### {{this.step_number}}. {{this.title}}

{{this.description}}

{{#if this.code_example}}
```{{this.language}}
{{this.code_example}}
```
{{/if}}

{{/each}}

## Conventions

| Convention | Example | Rationale |
|------------|---------|-----------|
{{#each conventions}}
| {{this.convention}} | `{{this.example}}` | {{this.rationale}} |
{{/each}}

{{#if anti_patterns}}
## Anti-Patterns

{{#each anti_patterns}}
❌ **Don't**: {{this.dont}}
✅ **Do**: {{this.do}}

{{/each}}
{{/if}}

{{#if codebase_examples}}
## Examples in Codebase

| File | Demonstrates |
|------|-------------|
{{#each codebase_examples}}
| `{{this.file}}` | {{this.demonstrates}} |
{{/each}}
{{/if}}

{{#if related_patterns}}
## Related Patterns

{{#each related_patterns}}
- [{{this.name}}]({{this.path}}) - {{this.relationship}}
{{/each}}
{{/if}}
