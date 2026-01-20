# {{pattern_name}} Pattern

> {{description}}

## File Convention

**Location:** `{{file_location}}`
**Naming:** `{{naming_convention}}`
{{#if test_location}}
**Tests:** `{{test_location}}`
{{/if}}

## Template (This Codebase)

```{{language}}
{{codebase_template}}
```

## Implementation Checklist

{{#each checklist_items}}
- [ ] {{this}}
{{/each}}

{{#if registration_steps}}
### Registration

{{#each registration_steps}}
- [ ] {{this.action}} in `{{this.file}}`
{{/each}}
{{/if}}

## Reference Implementations

| File | Demonstrates |
|------|--------------|
{{#each reference_files}}
| `{{this.file}}` | {{this.demonstrates}} |
{{/each}}

## Validation

```bash
{{#each validation_commands}}
{{this}}
{{/each}}
```

{{#if related_patterns}}
## Related Patterns

{{#each related_patterns}}
- [{{this.name}}]({{this.path}}) - {{this.relationship}}
{{/each}}
{{/if}}
