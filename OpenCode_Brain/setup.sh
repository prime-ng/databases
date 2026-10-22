#!/bin/bash
# =============================================================================
# OpenCode Brain — Validate / Optional Deploy
# -----------------------------------------------------------------------------
# SAFE BY DEFAULT: with no arguments this script only validates the brain and
# prints how to use it. It writes NOTHING outside OpenCode_Brain/.
#
# To copy the OpenCode layer elsewhere, pass an explicit flag:
#   bash setup.sh --deploy project   # -> {LARAVEL_REPO}/  (AGENTS.md, opencode.json, .opencode/)
#   bash setup.sh --deploy global    # -> ~/.config/opencode/ (agents, commands, skills)
#
# Everything lives in OpenCode_Brain by default — deploy only if you want the
# brain available from another working directory.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BRAIN="$SCRIPT_DIR"

LARAVEL_DIR="/Users/bkwork/Herd/prime_ai"
GLOBAL_DIR="$HOME/.config/opencode"

echo "=========================================="
echo "  OpenCode Brain"
echo "=========================================="
echo "Brain:   $BRAIN"
echo ""

# ── Validate ────────────────────────────────────────────────────────────────
echo "── Validate ──"

check() { if [ -e "$BRAIN/$1" ]; then echo "   ✓ $1"; else echo "   ✗ MISSING: $1"; fi; }

check "AGENTS.md"
check "opencode.json"
check "Agent_UserGuide.md"
check "config/paths.md"

agents=$(ls "$BRAIN/.opencode/agents"/*.md 2>/dev/null | wc -l | tr -d ' ')
commands=$(ls "$BRAIN/.opencode/commands"/*.md 2>/dev/null | wc -l | tr -d ' ')
skills=$(ls -d "$BRAIN/.opencode/skills"/*/ 2>/dev/null | wc -l | tr -d ' ')
instructions=$(ls "$BRAIN/instructions"/*.md 2>/dev/null | wc -l | tr -d ' ')
guides=$(ls "$BRAIN/agents"/*.md 2>/dev/null | wc -l | tr -d ' ')
modules=$(ls "$BRAIN/module-knowledge"/*.md 2>/dev/null | wc -l | tr -d ' ')

echo "   ✓ .opencode/agents    : $agents role agents"
echo "   ✓ .opencode/commands  : $commands commands"
echo "   ✓ .opencode/skills    : $skills skills"
echo "   ✓ instructions/       : $instructions module rule files"
echo "   ✓ agents/ (guides)    : $guides role guides"
echo "   ✓ module-knowledge/   : $modules files"
echo ""

# ── Deploy (explicit only) ──────────────────────────────────────────────────
if [ "$1" = "--deploy" ] && [ "$2" = "project" ]; then
    echo "── Deploy → project ($LARAVEL_DIR) ──"
    mkdir -p "$LARAVEL_DIR/.opencode"
    cp "$BRAIN/AGENTS.md" "$LARAVEL_DIR/AGENTS.md"
    cp "$BRAIN/opencode.json" "$LARAVEL_DIR/opencode.json"
    cp -R "$BRAIN/.opencode/" "$LARAVEL_DIR/.opencode/"
    echo "   ✓ Copied AGENTS.md, opencode.json, .opencode/ to $LARAVEL_DIR"
fi

if [ "$1" = "--deploy" ] && [ "$2" = "global" ]; then
    echo "── Deploy → global ($GLOBAL_DIR) ──"
    mkdir -p "$GLOBAL_DIR/agents" "$GLOBAL_DIR/commands" "$GLOBAL_DIR/skills"
    cp "$BRAIN/.opencode/agents/"*.md "$GLOBAL_DIR/agents/"
    cp "$BRAIN/.opencode/commands/"*.md "$GLOBAL_DIR/commands/"
    cp -R "$BRAIN/.opencode/skills/"* "$GLOBAL_DIR/skills/"
    echo "   ✓ Copied agents/, commands/, skills/ to $GLOBAL_DIR"
fi

# ── Usage ───────────────────────────────────────────────────────────────────
echo ""
echo "=========================================="
echo "  Ready"
echo "=========================================="
echo ""
echo "Use it:"
echo "  1. cd \"$BRAIN\" && opencode"
echo "  2. AGENTS.md is auto-loaded; ask for a role or use a command"
echo "  3. Try: /agent technical-auditor  then  \"Audit StudentFee, Mode A\""
echo "  4. Try: /test, /review, /schema, /lint, /module-status"
echo ""
echo "Optional (writes outside this folder):"
echo "  bash setup.sh --deploy project   # available from the Laravel repo"
echo "  bash setup.sh --deploy global    # available from every project"
