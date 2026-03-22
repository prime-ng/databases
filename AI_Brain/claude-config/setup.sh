#!/bin/bash
# =============================================================================
# AI Brain Deployment Script
# Deploys claude-config files from database repo to correct locations
# =============================================================================

set -e

# Paths
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AI_BRAIN_DIR="$(dirname "$SCRIPT_DIR")"
LARAVEL_DIR="/Users/bkwork/Herd/prime_ai"
USER_CLAUDE_DIR="$HOME/.claude"

echo "=========================================="
echo "  AI Brain — Deployment Script"
echo "=========================================="
echo ""
echo "Source:  $SCRIPT_DIR"
echo "Laravel: $LARAVEL_DIR"
echo "User:    $USER_CLAUDE_DIR"
echo ""

# ─────────────────────────────────────────────
# Step 1: Deploy path-scoped rules to .claude/rules/
# ─────────────────────────────────────────────
echo "── Step 1: Deploying path-scoped rules ──"

RULES_TARGET="$LARAVEL_DIR/.claude/rules"
mkdir -p "$RULES_TARGET"

if [ -d "$SCRIPT_DIR/rules" ]; then
    cp "$SCRIPT_DIR/rules/"*.md "$RULES_TARGET/" 2>/dev/null && \
        echo "   ✓ Copied $(ls "$SCRIPT_DIR/rules/"*.md 2>/dev/null | wc -l | tr -d ' ') rule files to $RULES_TARGET/" || \
        echo "   ⚠ No rule files found in $SCRIPT_DIR/rules/"
else
    echo "   ⚠ No rules directory found"
fi

# ─────────────────────────────────────────────
# Step 2: Ensure .claude/ is in .gitignore
# ─────────────────────────────────────────────
echo "── Step 2: Checking .gitignore ──"

GITIGNORE="$LARAVEL_DIR/.gitignore"
if [ -f "$GITIGNORE" ]; then
    if ! grep -qx ".claude/" "$GITIGNORE" 2>/dev/null; then
        echo "" >> "$GITIGNORE"
        echo "# Claude Code local config (deployed from AI_Brain)" >> "$GITIGNORE"
        echo ".claude/" >> "$GITIGNORE"
        echo "   ✓ Added .claude/ to .gitignore"
    else
        echo "   ✓ .claude/ already in .gitignore"
    fi
else
    echo "   ⚠ .gitignore not found at $GITIGNORE"
fi

# ─────────────────────────────────────────────
# Step 3: Deploy skills to ~/.claude/skills/
# ─────────────────────────────────────────────
echo "── Step 3: Deploying skills ──"

if [ -d "$SCRIPT_DIR/skills" ]; then
    SKILL_COUNT=0
    for skill_dir in "$SCRIPT_DIR/skills"/*/; do
        if [ -d "$skill_dir" ]; then
            skill_name=$(basename "$skill_dir")
            target_dir="$USER_CLAUDE_DIR/skills/$skill_name"
            mkdir -p "$target_dir"
            cp "$skill_dir"SKILL.md "$target_dir/" 2>/dev/null && \
                SKILL_COUNT=$((SKILL_COUNT + 1))
        fi
    done
    echo "   ✓ Deployed $SKILL_COUNT skills to $USER_CLAUDE_DIR/skills/"
else
    echo "   ⚠ No skills directory found"
fi

# ─────────────────────────────────────────────
# Step 4: Deploy agents to ~/.claude/agents/
# ─────────────────────────────────────────────
echo "── Step 4: Deploying agents ──"

if [ -d "$SCRIPT_DIR/agents" ]; then
    AGENT_COUNT=0
    for agent_dir in "$SCRIPT_DIR/agents"/*/; do
        if [ -d "$agent_dir" ]; then
            agent_name=$(basename "$agent_dir")
            target_dir="$USER_CLAUDE_DIR/agents/$agent_name"
            mkdir -p "$target_dir"
            cp "$agent_dir"AGENT.md "$target_dir/" 2>/dev/null && \
                AGENT_COUNT=$((AGENT_COUNT + 1))
        fi
    done
    echo "   ✓ Deployed $AGENT_COUNT agents to $USER_CLAUDE_DIR/agents/"
else
    echo "   ⚠ No agents directory found"
fi

# ─────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────
echo ""
echo "=========================================="
echo "  Deployment Complete!"
echo "=========================================="
echo ""
echo "Deployed to:"
echo "  Rules  → $RULES_TARGET/"
echo "  Skills → $USER_CLAUDE_DIR/skills/"
echo "  Agents → $USER_CLAUDE_DIR/agents/"
echo ""
echo "Next steps:"
echo "  1. Start a new Claude session in the Laravel project"
echo "  2. Touch a SmartTimetable file → smart-timetable rules auto-load"
echo "  3. Try /test, /review, /schema, /lint, /module-status"
echo ""
