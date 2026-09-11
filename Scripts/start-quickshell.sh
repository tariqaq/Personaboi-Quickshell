#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="$HOME/.local/state/personaboi/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/quickshell-latest.log"

printf '\n[%s] Starting Quickshell for Personaboi\n' "$(date '+%F %T %z')" >> "$LOG_FILE"
exec qs -c "$HOME/.config/quickshell/persona" >> "$LOG_FILE" 2>&1
