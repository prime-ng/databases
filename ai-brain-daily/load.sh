#!/usr/bin/env bash
set -euo pipefail

BRAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATE="$(TZ=Asia/Kolkata date +%F)"

echo "=============================================="
echo " AI BRAIN LOAD — $DATE (Asia/Kolkata)"
echo " Location: $BRAIN"
echo "=============================================="

section() { printf '\n----- %s -----\n' "$1"; }

section "README"
if [ -f "$BRAIN/README.md" ]; then
  sed -n '1,120p' "$BRAIN/README.md"
else
  echo "(README.md missing)"
fi

section "MASTER INDEX"
if [ -f "$BRAIN/00-INDEX.md" ]; then
  cat "$BRAIN/00-INDEX.md"
else
  echo "(00-INDEX.md missing)"
fi

section "LATEST DAILY REPORTS (max 3)"
if compgen -G "$BRAIN/daily/*.md" > /dev/null; then
  ls -1 "$BRAIN/daily"/*.md | sort | tail -3 | while IFS= read -r f; do
    echo
    echo "### $(basename "$f")"
    cat "$f"
  done
else
  echo "(no daily reports yet)"
fi

section "TODAY'S LIVE JOURNALS"
TODAY_DIR="$BRAIN/live/$DATE"
if [ -d "$TODAY_DIR" ]; then
  find "$TODAY_DIR" -maxdepth 1 -type f -name '*.md' | sort | while IFS= read -r f; do
    echo
    echo "### $(basename "$f")"
    cat "$f"
  done
else
  echo "(no live journal for $DATE yet)"
fi

section "MODULE ROLLUP INDEX"
if [ -f "$BRAIN/modules/00-INDEX.md" ]; then
  cat "$BRAIN/modules/00-INDEX.md"
else
  echo "(modules/00-INDEX.md missing)"
fi

echo
echo "=============================================="
echo " Loaded. Follow:"
echo " $BRAIN/README.md"
echo " /home/shailesh/shailesh/prime_ai/GEMINI.md"
echo "=============================================="
