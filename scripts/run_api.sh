#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../api"
if [[ ! -d .venv ]]; then
  python3 -m venv .venv
  source .venv/bin/activate
  pip install -r requirements.txt
else
  source .venv/bin/activate
fi
exec uvicorn app.main:app --host 0.0.0.0 --port "${PORT:-8080}"
