# 07 — Hooks — Automation Scripts

---

## What Are Hooks?

Hooks are shell commands that run automatically at specific lifecycle events. They let you:
- Auto-format PHP after edits
- Block dangerous commands
- Get desktop notifications when Claude finishes
- Validate tenancy context before DB queries
- Log all actions for auditing

---

## Hook Events

| Event | When It Fires | Common Use |
|-------|--------------|------------|
| `PreToolUse` | Before any tool runs | Block dangerous commands, validate inputs |
| `PostToolUse` | After tool succeeds | Auto-format, lint, log changes |
| `PostToolUseFailure` | After tool fails | Cleanup, error logging |
| `Notification` | Claude needs attention | Desktop notifications |
| `Stop` | Claude finishes response | Verify completeness |
| `PreCompact` | Before context compression | Inject critical reminders |
| `SessionStart` | Session begins | Load context, show status |

---

## Configuration

Hooks live in settings files:

```
Project (team-shared):   .claude/settings.json
Personal (this project): .claude/settings.local.json
Global (all projects):   ~/.claude/settings.json
```

### Format

```json
{
  "hooks": {
    "EventName": [
      {
        "matcher": "ToolPattern",
        "hooks": [
          {
            "type": "command",
            "command": "your-script.sh"
          }
        ]
      }
    ]
  }
}
```

### Matcher Patterns

| Matcher | Matches |
|---------|---------|
| `"Edit"` | Only Edit tool |
| `"Write"` | Only Write tool |
| `"Edit\|Write"` | Edit OR Write |
| `"Bash"` | Only Bash tool |
| `"*"` | All tools |
| `""` | All (empty = wildcard) |

### Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Allow — operation proceeds |
| `2` | Block — operation is stopped, stderr shown to Claude |
| Other | Allow but log stderr (in verbose mode) |

---

## Recommended Hooks for Prime-AI

### Hook 1: Desktop Notification When Claude Needs Input

Add to `~/.claude/settings.json`:
```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "osascript -e 'display notification \"Claude Code needs your attention\" with title \"Claude Code\" sound name \"Glass\"'"
          }
        ]
      }
    ]
  }
}
```

### Hook 2: Block Dangerous Database Commands

Create `.claude/hooks/validate-bash.sh`:
```bash
#!/bin/bash
# Read tool input from stdin
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Block production database operations
if echo "$COMMAND" | grep -qiE '(DROP\s+TABLE|DROP\s+DATABASE|TRUNCATE|DELETE\s+FROM.*WHERE\s+1|migrate:fresh|migrate:reset)'; then
  echo "BLOCKED: Destructive database operation detected: $COMMAND" >&2
  echo "Use explicit migration rollback or ask for confirmation first." >&2
  exit 2
fi

# Block force push to main/master
if echo "$COMMAND" | grep -qE 'git\s+push.*--force.*(main|master|multi-tenancy)'; then
  echo "BLOCKED: Force push to protected branch" >&2
  exit 2
fi

exit 0
```

```bash
chmod +x .claude/hooks/validate-bash.sh
```

Add to `.claude/settings.json`:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/validate-bash.sh"
          }
        ]
      }
    ]
  }
}
```

### Hook 3: Auto-Format PHP After Edits

If you use Laravel Pint (code formatter):

Create `.claude/hooks/format-php.sh`:
```bash
#!/bin/bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only format PHP files
if [[ "$FILE_PATH" == *.php ]]; then
  ./vendor/bin/pint "$FILE_PATH" --quiet 2>/dev/null
fi

exit 0
```

```bash
chmod +x .claude/hooks/format-php.sh
```

Add to `.claude/settings.json`:
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/format-php.sh"
          }
        ]
      }
    ]
  }
}
```

### Hook 4: Log All Claude Actions

Create `.claude/hooks/log-action.sh`:
```bash
#!/bin/bash
INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Log to file
echo "[$TIMESTAMP] Tool: $TOOL" >> .claude/action-log.txt

exit 0
```

Add to `.claude/settings.json`:
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/log-action.sh"
          }
        ]
      }
    ]
  }
}
```

---

## Hook Types

### `type: command` (Most Common)
Runs a shell script. Receives tool input as JSON on stdin.

### `type: prompt`
Asks Claude a yes/no question before proceeding:
```json
{
  "type": "prompt",
  "prompt": "Does this change follow tenancy isolation rules?"
}
```

### `type: http`
Sends a POST request to a URL:
```json
{
  "type": "http",
  "url": "https://your-webhook.com/claude-events",
  "headers": { "Authorization": "Bearer token" }
}
```

---

## Setup Checklist

```bash
# 1. Create hooks directory
mkdir -p .claude/hooks

# 2. Create validation script
cat > .claude/hooks/validate-bash.sh << 'SCRIPT'
#!/bin/bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
if echo "$COMMAND" | grep -qiE '(DROP\s+TABLE|migrate:fresh|migrate:reset)'; then
  echo "BLOCKED: Destructive operation" >&2
  exit 2
fi
exit 0
SCRIPT
chmod +x .claude/hooks/validate-bash.sh

# 3. Add to settings
# Edit .claude/settings.json or use /hooks command in Claude Code

# 4. Test
# Start Claude session and try a blocked command — should see BLOCKED message
```

---

## Managing Hooks

Use `/hooks` command inside Claude Code for interactive management:
- View all configured hooks
- Add new hooks
- Edit existing hooks
- Test hook scripts
