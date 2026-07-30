#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/build/macos-pair"
SERVER_PID_FILE="$DIST_DIR/presenter-server.pid"

osascript -e 'tell application id "net.fenixsoftware.scoutPresentationGenerator.projector" to quit' >/dev/null 2>&1 || true
osascript -e 'tell application id "net.fenixsoftware.scoutPresentationGenerator.presenter" to quit' >/dev/null 2>&1 || true

if [[ -f "$SERVER_PID_FILE" ]]; then
  SERVER_PID="$(cat "$SERVER_PID_FILE")"

  if kill -0 "$SERVER_PID" >/dev/null 2>&1; then
    kill "$SERVER_PID"
  fi

  rm -f "$SERVER_PID_FILE"
fi

echo "Stopped the Scout Projector, Scout Presenter, and local WebSocket server."
