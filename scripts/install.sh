#!/usr/bin/env bash
set -euo pipefail

# 用法：
#   ./scripts/install.sh
#   ./scripts/install.sh --force-prompts   # 覆盖已存在的 echospec prompts
#   ./scripts/install.sh --no-agents       # 不写/不追加 AGENTS.md

FORCE_PROMPTS=0
NO_AGENTS=0

for arg in "$@"; do
  case "$arg" in
    --force-prompts) FORCE_PROMPTS=1 ;;
    --no-agents) NO_AGENTS=1 ;;
    *) ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROMPTS_SRC_DIR="$SRC_ROOT/prompts"
AGENTS_BLOCK_FILE="$PROMPTS_SRC_DIR/AGENTS.md"

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
PROMPTS_DST_DIR="$CODEX_HOME/prompts"

# target repo root
if git rev-parse --show-toplevel >/dev/null 2>&1; then
  REPO_ROOT="$(git rev-parse --show-toplevel)"
else
  REPO_ROOT="$(pwd)"
fi

echo "[EchoSpec] Source: $SRC_ROOT"
echo "[EchoSpec] Target repo: $REPO_ROOT"
echo "[EchoSpec] Codex prompts dir: $PROMPTS_DST_DIR"

# 1) init target repo .echospec (idempotent)
cd "$REPO_ROOT"
mkdir -p .echospec/changes .echospec/records .echospec/spec
[[ -f .echospec/current ]] || : > .echospec/current
[[ -f .echospec/index.jsonl ]] || : > .echospec/index.jsonl
echo "[EchoSpec] Ensured .echospec structure."

# 2) install prompts to ~/.codex/prompts
mkdir -p "$PROMPTS_DST_DIR"

copy_prompt() {
  local src="$1"
  local dst="$2"
  local name
  name="$(basename "$src")"

  if [[ -f "$dst" && "$FORCE_PROMPTS" -ne 1 ]]; then
    echo "[EchoSpec] Prompt exists, skipped: $name (use --force-prompts to overwrite)"
    return
  fi

  if [[ -f "$dst" && "$FORCE_PROMPTS" -eq 1 ]]; then
    cp "$dst" "$dst.bak.$(date +%Y%m%d%H%M%S)"
    echo "[EchoSpec] Backup: $name -> $name.bak.*"
  fi

  cp "$src" "$dst"
  echo "[EchoSpec] Installed: $name"
}

for f in echospec-init.md echospec-new.md echospec-apply.md echospec-archive.md; do
  if [[ ! -f "$PROMPTS_SRC_DIR/$f" ]]; then
    echo "[EchoSpec] ERROR: missing $PROMPTS_SRC_DIR/$f"
    exit 1
  fi
  copy_prompt "$PROMPTS_SRC_DIR/$f" "$PROMPTS_DST_DIR/$f"
done

# 3) append AGENTS.md block (no overwrite)
if [[ "$NO_AGENTS" -eq 0 ]]; then
  if [[ ! -f "$AGENTS_BLOCK_FILE" ]]; then
    echo "[EchoSpec] ERROR: missing $AGENTS_BLOCK_FILE"
    exit 1
  fi

  AGENTS_FILE="$REPO_ROOT/AGENTS.md"
  BEGIN="<!-- ECHOSPEC_RULES_BEGIN -->"

  if [[ ! -f "$AGENTS_FILE" ]]; then
    {
      echo "# AGENTS.md"
      echo
      cat "$AGENTS_BLOCK_FILE"
      echo
    } > "$AGENTS_FILE"
    echo "[EchoSpec] Created AGENTS.md (new file)."
  else
    if grep -qF "$BEGIN" "$AGENTS_FILE"; then
      echo "[EchoSpec] AGENTS.md already has EchoSpec block. Skipped."
    else
      echo >> "$AGENTS_FILE"
      cat "$AGENTS_BLOCK_FILE" >> "$AGENTS_FILE"
      echo >> "$AGENTS_FILE"
      echo "[EchoSpec] Appended EchoSpec block to existing AGENTS.md (no overwrite)."
    fi
  fi
else
  echo "[EchoSpec] Skipped AGENTS.md (--no-agents)."
fi

echo
echo "[EchoSpec] Install done."
echo "[EchoSpec] Next: restart/new Codex session to reload prompts."
