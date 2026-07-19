#!/usr/bin/env bash
# render.sh <run-id> <nonce> [url-path] — serve fresh, print to PDF, assert size.
set -euo pipefail
[[ $# -ge 2 && $# -le 3 ]] || { echo "usage: render.sh <run-id> <nonce> [url-path]" >&2; exit 2; }
RUN_ID=$1
NONCE=$2
URL_PATH=${3:-/resume/$RUN_ID/}

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../../../.." && pwd)
PORT=${PORT:-4000}
CHROME_BIN=${CHROME_BIN:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}
MIN_PDF_BYTES=${MIN_PDF_BYTES:-150000}

WORKSPACE="$REPO_ROOT/.tmp/dump-targeted-pdf/$RUN_ID"
SERVER_DIR="$REPO_ROOT/.tmp/dump-targeted-pdf/server"
mkdir -p "$WORKSPACE" "$SERVER_DIR"
PDF_OUT="$WORKSPACE/resume.pdf"

url() { echo "http://127.0.0.1:$1/about$URL_PATH"; }

fresh() { # $1=port: 200 + nonce present (nonce '-' skips body check)
  local body
  body=$(curl -fsS --max-time 2 "$(url "$1")" 2>/dev/null) || return 1
  [[ $NONCE == - ]] && return 0
  grep -qF "$NONCE" <<<"$body"
}

start_server() { # $1=port
  (cd "$REPO_ROOT" && nohup bundle exec jekyll serve --port "$1" --host 127.0.0.1 \
    >"$SERVER_DIR/jekyll-$1.log" 2>&1 &
   echo $! >"$SERVER_DIR/jekyll-$1.pid")
}

wait_fresh() { # $1=port $2=seconds
  local i
  for ((i = 0; i < $2; i++)); do
    fresh "$1" && return 0
    sleep 1
  done
  return 1
}

if curl -fsS --max-time 2 "http://127.0.0.1:$PORT/about/" >/dev/null 2>&1; then
  # something serves the site root; only trust it if the target page goes fresh
  if ! wait_fresh "$PORT" 60; then
    echo "render.sh: server on :$PORT is stale or foreign; starting on alternate port" >&2
    PORT=$((PORT + 1))
    start_server "$PORT"
    wait_fresh "$PORT" 180 || { echo "render.sh: $(url "$PORT") never became fresh" >&2; exit 1; }
  fi
else
  start_server "$PORT"
  wait_fresh "$PORT" 180 || { echo "render.sh: $(url "$PORT") never became fresh" >&2; exit 1; }
fi

print_pdf() {
  rm -f "$PDF_OUT"
  "$CHROME_BIN" --headless=new --disable-gpu --no-pdf-header-footer \
    --run-all-compositor-stages-before-draw --virtual-time-budget=10000 \
    --print-to-pdf="$PDF_OUT" "$(url "$PORT")" >"$WORKSPACE/chrome.log" 2>&1 &
  local pid=$! waited=0
  while kill -0 "$pid" 2>/dev/null; do
    ((waited += 1))
    if ((waited > 60)); then
      echo "render.sh: chrome hung; killing and retrying" >&2
      kill -9 "$pid" 2>/dev/null || true
      return 1
    fi
    sleep 1
  done
  wait "$pid"
}

print_pdf || print_pdf || { echo "render.sh: chrome failed twice; see $WORKSPACE/chrome.log" >&2; exit 1; }

[[ -s $PDF_OUT ]] || { echo "render.sh: no output at $PDF_OUT" >&2; exit 1; }
size=$(stat -f%z "$PDF_OUT")
if ((size < MIN_PDF_BYTES)); then
  echo "render.sh: PDF only $size bytes (< $MIN_PDF_BYTES) — badges likely failed to load; check network and retry" >&2
  exit 1
fi
echo "$PDF_OUT"
