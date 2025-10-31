#!/bin/bash
# Auto-approve safe git and gh commands for git-actions plugin workflows
# SECURITY: Parses compound commands and validates each part independently

# Parse the command from the tool arguments JSON
command=$(echo "$ARGUMENTS" | jq -r '.command // empty')

# If we can't extract the command, ask the user
if [ -z "$command" ]; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"Could not parse command"}}'
  exit 0
fi

# Define safe command patterns (readonly git operations and gh operations)
# These are the commands used in pr-write, pr-edit, pr-review, and commit workflows
safe_patterns=(
  # Git read-only operations
  '^git branch'
  '^git show-ref'
  '^git diff-index'
  '^git rev-parse'
  '^git rev-list'
  '^git status'
  '^git diff'
  '^git log'
  '^git ls-tree'

  # Git write operations (for commit/push workflows)
  '^git add'
  '^git commit'
  '^git push'
  '^git checkout -b'
  '^git checkout'

  # GitHub CLI operations
  '^gh pr list'
  '^gh pr view'
  '^gh pr create'
  '^gh pr ready'
  '^gh pr edit'
  '^gh auth status'
  '^gh api repos'

  # Utility commands
  '^command -v'
  '^which '
  '^echo '
  '^cat <<'
)

# Function to check if a single command part is safe
is_safe_command() {
  local cmd="$1"
  # Trim whitespace
  cmd=$(echo "$cmd" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

  # Skip empty commands
  [ -z "$cmd" ] && return 0

  # Check for variable assignments (safe if the value is safe)
  if echo "$cmd" | grep -qE '^[a-zA-Z_][a-zA-Z0-9_]*='; then
    # Extract the value part after =
    local value=$(echo "$cmd" | sed 's/^[^=]*=//')

    # Check if value contains command substitution $(...) or `...`
    if echo "$value" | grep -qE '\$\(|\`'; then
      # Remove $(...) or `...` wrappers and check the inner command
      value=$(echo "$value" | sed 's/\$(\(.*\))/\1/' | sed 's/`\(.*\)`/\1/')
      # Recursively check if that command is safe
      is_safe_command "$value" && return 0
    else
      # Simple string assignment (no command substitution) is safe
      return 0
    fi
  fi

  # Check against safe patterns
  for pattern in "${safe_patterns[@]}"; do
    if echo "$cmd" | grep -qE "$pattern"; then
      return 0
    fi
  done

  return 1
}

# Parse compound commands by splitting on operators: &&, ||, ;
# Simple approach: split and validate each part
parse_and_validate_command() {
  local full_cmd="$1"

  # Split by && and || using sed (compatible with macOS)
  # This approach: replace operators with newlines, then read line by line
  local commands=()
  while IFS= read -r cmd_part; do
    [ -n "$cmd_part" ] && commands+=("$cmd_part")
  done < <(echo "$full_cmd" | sed 's/&&/\n/g' | sed 's/||/\n/g' | sed 's/;/\n/g')

  # Validate each command part
  for cmd in "${commands[@]}"; do
    # Remove common redirections (be careful not to affect command names)
    cmd=$(echo "$cmd" | sed 's/[0-9]*>&[0-9]*//g' | sed 's/&>\/dev\/null//g' | sed 's/>\/dev\/null//g' | sed 's/2>&1//g')

    # Remove test constructs [ ... ] or [[ ... ]] (but preserve their exit codes)
    # We keep the test content to validate variable refs are safe
    cmd=$(echo "$cmd" | sed 's/\[\[\s*\([^]]*\)\s*\]\]/\1/g' | sed 's/\[\s*\([^]]*\)\s*\]/\1/g')

    # Remove shell control keywords (as separate words)
    cmd=$(echo "$cmd" | sed 's/\bif\b//g' | sed 's/\bthen\b//g' | sed 's/\belse\b//g' | sed 's/\bfi\b//g' | sed 's/\bdo\b//g' | sed 's/\bdone\b//g')

    # Trim whitespace
    cmd=$(echo "$cmd" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

    # Skip empty commands after cleanup
    [ -z "$cmd" ] && continue

    # If it's just a variable reference or comparison, skip it
    if echo "$cmd" | grep -qE '^\$[a-zA-Z_][a-zA-Z0-9_]*$|^[a-zA-Z_][a-zA-Z0-9_]*$|^"[^"]*"$|^!=|^='; then
      continue
    fi

    # Check if this command part is safe
    if ! is_safe_command "$cmd"; then
      echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"Command contains unsafe operation: '"$cmd"'"}}'
      exit 0
    fi
  done

  # All parts are safe
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"Compound command validated - all parts safe"}}'
  exit 0
}

# Check if this is a simple or compound command
if echo "$command" | grep -qE '(&&|\|\||;|[^|]\|[^|])'; then
  # Compound command - parse and validate each part
  parse_and_validate_command "$command"
else
  # Simple command - check against safe patterns
  if is_safe_command "$command"; then
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"Git/GitHub command auto-approved by git-actions plugin"}}'
    exit 0
  fi
fi

# Command doesn't match safe patterns - ask user
echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"Command not in git-actions auto-approval list"}}'
exit 0
