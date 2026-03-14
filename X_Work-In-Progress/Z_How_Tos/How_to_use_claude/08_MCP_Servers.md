# 08 — MCP Servers — External Tool Integration

---

## What Is MCP?

Model Context Protocol (MCP) is a standard for connecting Claude to external tools, databases, APIs, and services. Once connected, Claude can query your MySQL database, create GitHub issues, read Figma designs, etc.

---

## How MCP Works

```
Claude Code ──► MCP Server ──► External Service
                (adapter)       (GitHub, MySQL, etc.)
```

MCP servers run locally as processes. Claude sends requests to them, and they translate into API calls.

---

## Configuration Files

| Scope | File | Shared? |
|-------|------|---------|
| Project (team) | `.mcp.json` | Git-committed |
| Personal | `~/.claude.json` | Not in git |

---

## Your Current MCP Setup

From your settings, you have:
- `plugin:laravel-boost:laravel-boost` — Laravel-specific tools
- `ide` — IDE integration tools

---

## Recommended MCP Servers for Prime-AI

### 1. GitHub — PR/Issue Management

```bash
# Add GitHub MCP server
claude mcp add --transport http github https://api.githubcopilot.com/mcp/
```

**What it enables:**
- Create/review/comment on PRs from Claude
- Search and manage issues
- View PR checks and CI status
- Read PR comments and review feedback

**Usage:**
```
"Review the latest PR on prime-ng/laravel"
"Create an issue for the N+1 query in ConstraintController"
"List open PRs on the SmartTimetable branch"
```

### 2. MySQL — Direct Database Queries

```bash
# Add MySQL MCP server (for local development only!)
claude mcp add --transport stdio mysql -- \
  npx -y @modelcontextprotocol/server-mysql \
  --host 127.0.0.1 \
  --port 3306 \
  --user root \
  --password your-local-password
```

**What it enables:**
- Query live database schemas
- Check table structures
- Verify data integrity
- Compare model vs actual schema

**Usage:**
```
"Show me the structure of tt_constraints table"
"How many constraint types are there in the tenant database?"
"Check if tt_constraint_category_scope has the ordinal column"
```

**IMPORTANT:** Only use with LOCAL development database. Never connect to production.

### 3. Filesystem — Access External Docs

```bash
# Give Claude access to the databases documentation folder
claude mcp add --transport stdio docs -- \
  npx -y @modelcontextprotocol/server-filesystem \
  "/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases"
```

**What it enables:**
- Read DDL files, documentation, requirements
- Browse Project_Documentation and Requir_Enhancements folders
- Access without needing to specify full paths

---

## Managing MCP Servers

```bash
# List all configured servers
claude mcp list

# Get details of a server
claude mcp get github

# Remove a server
claude mcp remove github

# In-session management
/mcp
```

---

## MCP Configuration File Format

### `.mcp.json` (Project-Level)

```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/"
    },
    "mysql-local": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-mysql", "--host", "127.0.0.1"],
      "env": {
        "MYSQL_PASSWORD": "from-env-or-local-config"
      }
    }
  }
}
```

### `~/.claude.json` (Personal — for credentials)

```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": {
        "Authorization": "Bearer ghp_your_token"
      }
    }
  }
}
```

---

## Token Impact

MCP servers add tool definitions to Claude's context, which consumes tokens:
- Each server adds ~500-2000 tokens for its tool schemas
- Disable unused servers with `/mcp` to save tokens
- Only enable servers you'll actively use in that session

---

## Security Notes

1. **Never put credentials in `.mcp.json`** — use `~/.claude.json` (not git-committed)
2. **Use environment variables** for passwords: `"env": {"DB_PASS": "$MYSQL_PASSWORD"}`
3. **MySQL:** Only connect to local/development databases
4. **Review MCP server source** before installing community servers
