#!/usr/bin/env bash
# ==============================================================================
# AI Brain Daily Activity Builder & Calendar Sync Script
# Usage: ./update.sh   OR   bash /home/shailesh/shailesh/ai-brain-daily/update.sh
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔄 Updating AI Brain Calendar & Activity data..."
php -d memory_limit=2G "$SCRIPT_DIR/build.php"

echo "✅ AI Brain update complete! Data refreshed for calendar and dashboard."
