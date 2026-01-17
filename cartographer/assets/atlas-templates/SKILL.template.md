---
name: atlas
description: >-
  **Primary codebase discovery tool for {{project_name}}.** ALWAYS invoke this skill FIRST
  when you need to: find files, locate components, understand where code lives,
  answer "where is X?", discover existing patterns, or explore unfamiliar areas.
  Triggers: "where is", "find the", "locate", "what file", "which component",
  "how does X work", "existing pattern for", "codebase structure".
  Provides instant routing to domain-specific documentation without
  requiring file searches. More efficient than grep/glob for this codebase.
---

# {{project_name}} Codebase Discovery

## Project Structure

```
{{project_structure}}
```

{{#if dependency_notes}}
{{dependency_notes}}
{{/if}}

## Domain Router

Read ONLY the relevant reference based on query keywords:

| Keywords | Reference |
|----------|-----------|
{{#each domain_router_rows}}
| {{this.keywords}} | [{{this.reference}}]({{this.reference}}) |
{{/each}}

## Pattern Router

For implementation tasks, read the relevant pattern guide:

| Task | Pattern Guide |
|------|---------------|
{{#each pattern_router_rows}}
| {{this.task}} | [{{this.guide}}]({{this.guide}}) |
{{/each}}

## File Location Conventions

| Type | Path Pattern |
|------|--------------|
{{#each file_conventions}}
| {{this.type}} | `{{this.pattern}}` |
{{/each}}

## Key Technologies

{{#each key_technologies}}
- {{this}}
{{/each}}

## Full Structure

For complete machine-readable structure with file counts: [references/schema.yaml](references/schema.yaml)

{{#if task_quick_reference}}
## Task-Type Quick Reference

When working on specific task types, prioritize these references:

| Task | Primary References |
|------|-------------------|
{{#each task_quick_reference}}
| {{this.task}} | {{this.references}} |
{{/each}}
{{/if}}
