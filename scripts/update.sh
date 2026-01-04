#!/usr/bin/env bash
set -euo pipefail

# 用法：
#   ./scripts/update.sh            # 只覆盖 ~/.codex/prompts 下的 echospec-*.md
#   ./scripts/update.sh --agents   # 同时更新目标项目的 AGENTS.md 插入块

UPDATE_AGENTS=0
for arg in "$@"; do
  case "$arg" in
    --agents) UPDATE_AGENTS=1 ;;
    *) ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROMPTS_SRC_DIR="$SRC_ROOT/prompts"
AGENTS_BLOCK_FILE="$PROMPTS_SRC_DIR/AGENTS.md"

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
PROMPTS_DST_DIR="$CODEX_HOME/prompts"
mkdir -p "$PROMPTS_DST_DIR"

echo "[EchoSpec] Updating prompts from: $PROMPTS_SRC_DIR"
echo "[EchoSpec] To: $PROMPTS_DST_DIR"

backup_and_copy() {
  local src="$1"
  local dst="$2"
  local name
  name="$(basename "$src")"
  if [[ -f "$dst" ]]; then
    cp "$dst" "$dst.bak.$(date +%Y%m%d%H%M%S)"
    echo "[EchoSpec] Backup: $name -> $name.bak.*"
  fi
  cp "$src" "$dst"
  echo "[EchoSpec] Updated: $name"
}

for f in echospec-init.md echospec-new.md echospec-apply.md echospec-archive.md; do
  if [[ ! -f "$PROMPTS_SRC_DIR/$f" ]]; then
    echo "[EchoSpec] ERROR: missing $PROMPTS_SRC_DIR/$f"
    exit 1
  fi
  backup_and_copy "$PROMPTS_SRC_DIR/$f" "$PROMPTS_DST_DIR/$f"
done

# optional: update AGENTS.md block in target repo
if [[ "$UPDATE_AGENTS" -eq 1 ]]; then
  if [[ ! -f "$AGENTS_BLOCK_FILE" ]]; then
    echo "[EchoSpec] ERROR: missing $AGENTS_BLOCK_FILE"
    exit 1
  fi

  # target repo root from current dir
  if git rev-parse --show-toplevel >/dev/null 2>&1; then
    REPO_ROOT="$(git rev-parse --show-toplevel)"
  else
    REPO_ROOT="$(pwd)"
  fi
  cd "$REPO_ROOT"

  AGENTS_FILE="$REPO_ROOT/AGENTS.md"
  BEGIN="<!-- ECHOSPEC_RULES_BEGIN -->"
  END="<!-- ECHOSPEC_RULES_END -->"

  if [[ ! -f "$AGENTS_FILE" ]]; then
    {
      echo "# AGENTS.md"
      echo
      cat "$AGENTS_BLOCK_FILE"
      echo
    } > "$AGENTS_FILE"
    echo "[EchoSpec] Created AGENTS.md and wrote EchoSpec block."
  else
    if grep -qF "$BEGIN" "$AGENTS_FILE"; then
      tmp="$(mktemp)"
      awk -v b="$BEGIN" -v e="$END" -v repl="$AGENTS_BLOCK_FILE" '
        BEGIN{in=0}
        $0 ~ b {
          in=1
          while ((getline line < repl) > 0) print line
          close(repl)
          next
        }
        $0 ~ e { in=0; next }
        in==0 { print }
      ' "$AGENTS_FILE" > "$tmp"
      mv "$tmp" "$AGENTS_FILE"
      echo "[EchoSpec] Updated EchoSpec block inside AGENTS.md."
    else
      echo >> "$AGENTS_FILE"
      cat "$AGENTS_BLOCK_FILE" >> "$AGENTS_FILE"
      echo >> "$AGENTS_FILE"
      echo "[EchoSpec] Appended EchoSpec block to AGENTS.md."
    fi
  fi
fi

echo
echo "[EchoSpec] Update done. Restart/new Codex session to reload prompts."
