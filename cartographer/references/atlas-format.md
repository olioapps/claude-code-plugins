# Atlas Format Specification

This reference defines validation rules for generated atlas skills. For full templates, see `assets/atlas-templates/`.

## Directory Structure

```
.claude/skills/atlas/
├── SKILL.md                    # Routing manifest (~80-120 lines)
└── references/
    ├── schema.yaml             # Machine-readable source of truth
    ├── {domain}/               # Domain reference files
    │   └── {area}.md
    └── patterns/               # Pattern guide files
        └── {pattern}.md
```

## Templates

| File | Purpose |
|------|---------|
| `assets/atlas-templates/SKILL.template.md` | SKILL.md generation template |
| `assets/atlas-templates/schema.template.yaml` | schema.yaml generation template |
| `assets/atlas-templates/domain-reference.template.md` | Domain documentation template |
| `assets/atlas-templates/pattern-reference.template.md` | Pattern guide template |
| `assets/atlas-templates/atlas-ignore.template` | Default .atlas-ignore patterns |

## Validation Rules

### SKILL.md Validation

- [ ] Frontmatter has `name` and `description`
- [ ] Description mentions primary triggers
- [ ] Domain Router has at least 3 entries
- [ ] All reference links are valid paths
- [ ] Pattern Router exists if patterns detected
- [ ] File Location Conventions has at least 3 entries
- [ ] Key Technologies section exists

### schema.yaml Validation

- [ ] metadata section complete
- [ ] At least 2 domains defined
- [ ] All domain paths exist
- [ ] File counts are reasonable (not 0)
- [ ] At least 2 file patterns defined
- [ ] Testing section exists (even if empty)
- [ ] Documentation lists match actual files

### Reference File Validation

- [ ] All listed reference files exist
- [ ] Domain references have required sections
- [ ] Pattern guides have implementation steps
- [ ] No broken internal links

## Version History

Track schema changes for migration support. Include in schema.yaml header:

```yaml
# Schema Version: 1.0.0
# Breaking changes:
#   - 1.0.0: Initial release
#   - 1.1.0: Added task_mappings section
#   - 2.0.0: Changed domains structure (breaking)
```

## .atlas-ignore

Place at repository root. See `assets/atlas-templates/atlas-ignore.template` for default patterns.

Supports optional YAML configuration at end of file:

```yaml
# ---
# confidence:
#   project_type: 0.7
#   domain: 0.6
# custom_domains:
#   - name: legacy_code
#     location: src/legacy
#     purpose: Deprecated code pending migration
```
