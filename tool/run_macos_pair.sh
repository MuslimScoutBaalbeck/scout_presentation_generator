#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/build/macos-pair"
PROJECTOR_APP="$DIST_DIR/Scout Projector.app"
PRESENTER_APP="$DIST_DIR/Scout Presenter.app"
SERVER_PID_FILE="$DIST_DIR/presenter-server.pid"
SERVER_LOG_FILE="$DIST_DIR/presenter-server.log"
DECK_WS_PORT="${DECK_WS_PORT:-8080}"
DECK_WS_URI="${DECK_WS_URI:-ws://127.0.0.1:$DECK_WS_PORT}"
SKIP_BUILD="${SKIP_BUILD:-0}"

port_is_listening() {
  lsof -nP -iTCP:"$DECK_WS_PORT" -sTCP:LISTEN >/dev/null 2>&1
}

start_server() {
  mkdir -p "$DIST_DIR"

  if port_is_listening; then
    echo "Using the server already listening on port $DECK_WS_PORT."
    return
  fi

  echo "Starting Flutter Deck WebSocket server on port $DECK_WS_PORT..."

  (
    cd "$ROOT_DIR"

    if command -v fvm >/dev/null 2>&1; then
      nohup fvm dart run tool/presenter_server.dart "--port=$DECK_WS_PORT" \
        >"$SERVER_LOG_FILE" 2>&1 &
    else
      nohup dart run tool/presenter_server.dart "--port=$DECK_WS_PORT" \
        >"$SERVER_LOG_FILE" 2>&1 &
    fi

    echo $! >"$SERVER_PID_FILE"
  )

  local attempt=0
  while ! port_is_listening; do
    attempt=$((attempt + 1))

    if [[ "$attempt" -ge 50 ]]; then
      echo "The WebSocket server did not start." >&2
      echo "Log: $SERVER_LOG_FILE" >&2
      exit 1
    fi

    sleep 0.1
  done
}

cd "$ROOT_DIR"

start_server

if [[ "$SKIP_BUILD" != "1" ]]; then
  DECK_WS_PORT="$DECK_WS_PORT" \
  DECK_WS_URI="$DECK_WS_URI" \
    bash "$ROOT_DIR/tool/build_macos_pair.sh"
fi

if [[ ! -d "$PROJECTOR_APP" || ! -d "$PRESENTER_APP" ]]; then
  echo "The macOS app pair is missing. Run tool/build_macos_pair.sh first." >&2
  exit 1
fi

open -na "$PROJECTOR_APP"
sleep 1
open -na "$PRESENTER_APP"

cat <<EOF_MESSAGE

Opened both apps:
  Scout Projector  -> move this window to the projector and enter full screen.
  Scout Presenter  -> keep this window on the Mac for notes and controls.

Server log:
  $SERVER_LOG_FILE
EOF_MESSAGE
