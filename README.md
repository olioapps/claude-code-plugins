# claude-code-plugins

Olio Apps' Claude Code plugin marketplace - custom agents, commands, and workflows for enhanced AI-assisted development.

## Overview

A Claude Code plugin marketplace providing custom agents, commands, and workflows for AI-assisted development.

## Quick Start

### Adding This Marketplace to Claude Code

Add this marketplace to your Claude Code settings to install plugins:

1. Open your Claude Code `settings.json` file in `~/.claude`
2. Add this marketplace to the `extraKnownMarketplaces` object:

```json
{
  "extraKnownMarketplaces": {
    "olio-plugins": {
      "source": {
        "source": "github",
        "repo": "olio-apps/claude-code-plugins"
      }
    }
  }
}
```

3. The marketplace should automatically be added when instantiating Claude Code. If not, in Claude Code terminal, run:
```bash
/plugin marketplace add olio-plugins
```

4. Install plugins from the marketplace:
```bash
/plugin install git-actions@olio-plugins
```

5. A plugin should be enabled by default. If not, run:
```bash
/plugin enable git-actions@olio-plugins
```

6. The plugin should be available as a slash command. To run:
```bash
/git-actions
```

## Available Plugins

### git-actions
**Category**: Productivity

AI-powered git workflow automation with intelligent commit messages, comprehensive PR descriptions, and thorough code reviews.

## Plugin Structure

All plugins follow the standard Claude Code plugin structure:

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json          # Plugin metadata
├── agents/                   # AI agent definitions
│   └── agent-name.md
├── commands/                 # Slash commands
│   └── command-name.md
├── hooks/                    # Tool execution hooks
│   └── hooks.json
└── scripts/                  # Helper scripts
    └── script-name.sh
```

## Marketplace Manifest

This repository includes a marketplace manifest at `.claude-plugin/marketplace.json` that catalogs available plugins with detailed metadata including:

- Plugin name, description, and version
- Author and repository information
- Keywords and categorization
- Commands and agents inventory

## Documentation

Detailed documentation for each plugin is available in [`plugins/README.md`](plugins/README.md), including:

- Plugin architecture
- Usage examples
- Development tips
- Command and agent reference

## Development

This marketplace provides production-ready plugins for enhancing your development workflow with AI-powered automation.

### Key Features Demonstrated

✓ **Commands**: Markdown-based slash commands with YAML frontmatter
✓ **Agents**: Specialized AI personas with specific capabilities
✓ **Plugin Composition**: Commands that invoke agents

## Installation Methods

### Method 1: Via Marketplace (Recommended)
Add to `settings.json` and use `/plugin install` (see Quick Start above)

### Method 2: Local Development
Clone this repository and point Claude Code to it:
```bash
git clone https://github.com/your-org/claude-code-plugins.git
cd claude-code-plugins
# Use /plugin enable <plugin-name> in Claude Code
```

### Method 3: Individual Plugin
Copy a single plugin directory to your `.claude/plugins/` directory

## Requirements

- Claude Code CLI v1.0.123+

## License

MIT License - See [LICENSE](LICENSE) file for details

## Contributing

Plugins are provided as-is. Feel free to fork and modify for your own use.

## Resources

- [Claude Code Documentation](https://docs.claude.com/claude-code)
- [Plugin Development Guide](plugins/README.md)
- [MCP Specification](https://modelcontextprotocol.io)

---

**Author**: Dustin Herboldshimer
**Organization**: Olio Apps
**Created**: 2025
**Purpose**: AI-powered development workflow automation
