#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR" || exit 1
export PATH="/home/shailesh/.local/bin:/home/shailesh/.local/node/bin:$PATH"

# Kill any existing instance on port 3050
fuser -k 3050/tcp 2>/dev/null

echo "Starting Server on http://localhost:3050 ..."
node server.js &
SERVER_PID=$!
sleep 1

echo "Opening http://localhost:3050 in Google Chrome..."
google-chrome "http://localhost:3050" 2>/dev/null || xdg-open "http://localhost:3050" 2>/dev/null

wait $SERVER_PID
