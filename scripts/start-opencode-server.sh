#!/usr/bin/env bash
set -euo pipefail

OPENCODE_SERVER_HOSTNAME="${OPENCODE_SERVER_HOSTNAME:-0.0.0.0}"
OPENCODE_SERVER_PORT="${OPENCODE_SERVER_PORT:-4096}"
OPENCODE_SERVER_LOG="${OPENCODE_SERVER_LOG:-/tmp/opencode-serve.log}"
OPENCODE_SERVER_PIDFILE="${OPENCODE_SERVER_PIDFILE:-/tmp/opencode-serve.pid}"
OPENCODE_SERVER_READY_TIMEOUT_SECS="${OPENCODE_SERVER_READY_TIMEOUT_SECS:-30}"
OPENCODE_SERVER_READY_URL="${OPENCODE_SERVER_READY_URL:-http://127.0.0.1:${OPENCODE_SERVER_PORT}/}"

log() {
  echo "[start-opencode-server] $*"
}

is_server_ready() {
  curl -sS -o /dev/null --connect-timeout 2 "$OPENCODE_SERVER_READY_URL"
}

if ! command -v opencode >/dev/null 2>&1; then
  echo "opencode is not installed or not on PATH" >&2
  exit 1
fi

mkdir -p "$(dirname "$OPENCODE_SERVER_LOG")" "$(dirname "$OPENCODE_SERVER_PIDFILE")"

if [[ -f "$OPENCODE_SERVER_PIDFILE" ]]; then
  existing_pid="$(cat "$OPENCODE_SERVER_PIDFILE")"
  if [[ -n "$existing_pid" ]] && kill -0 "$existing_pid" 2>/dev/null; then
    if is_server_ready; then
      log "opencode serve already running on port ${OPENCODE_SERVER_PORT} (pid ${existing_pid})"
      exit 0
    fi

    log "stale opencode serve process found (pid ${existing_pid}); terminating before restart"
    kill "$existing_pid" 2>/dev/null || true
    sleep 1
  fi

  rm -f "$OPENCODE_SERVER_PIDFILE"
fi

if is_server_ready; then
  log "port ${OPENCODE_SERVER_PORT} is already serving traffic; leaving existing opencode server untouched"
  exit 0
fi

log "starting opencode serve on ${OPENCODE_SERVER_HOSTNAME}:${OPENCODE_SERVER_PORT}"
nohup opencode serve \
  --hostname "$OPENCODE_SERVER_HOSTNAME" \
  --port "$OPENCODE_SERVER_PORT" \
  >>"$OPENCODE_SERVER_LOG" 2>&1 &
server_pid=$!
echo "$server_pid" > "$OPENCODE_SERVER_PIDFILE"

for ((attempt = 1; attempt <= OPENCODE_SERVER_READY_TIMEOUT_SECS; attempt++)); do
  if is_server_ready; then
    log "opencode serve is ready (pid ${server_pid}); logs: ${OPENCODE_SERVER_LOG}"
    exit 0
  fi

  if ! kill -0 "$server_pid" 2>/dev/null; then
    echo "opencode serve exited before becoming ready; tail of log:" >&2
    tail -n 50 "$OPENCODE_SERVER_LOG" >&2 || true
    exit 1
  fi

  sleep 1
done

echo "Timed out waiting ${OPENCODE_SERVER_READY_TIMEOUT_SECS}s for opencode serve on ${OPENCODE_SERVER_READY_URL}" >&2
tail -n 50 "$OPENCODE_SERVER_LOG" >&2 || true
exit 1