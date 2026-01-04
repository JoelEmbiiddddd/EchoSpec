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

# EchoSpec kit（供 prompts 调用的稳定路径，不依赖仓库位置）
KIT_HOME="${ECHOSPEC_HOME:-$HOME/.echospec}"
KIT_DIR="$KIT_HOME/kit"
KIT_SCRIPTS_DIR="$KIT_DIR/scripts"

# target repo root
if git rev-parse --show-toplevel >/dev/null 2>&1; then
  REPO_ROOT="$(git rev-parse --show-toplevel)"
else
  REPO_ROOT="$(pwd)"
fi

echo "[EchoSpec] Source: $SRC_ROOT"
echo "[EchoSpec] Target repo: $REPO_ROOT"
echo "[EchoSpec] Codex prompts dir: $PROMPTS_DST_DIR"
echo "[EchoSpec] Kit dir: $KIT_DIR"

# 1) init target repo .echospec (idempotent)
cd "$REPO_ROOT"
mkdir -p .echospec/changes .echospec/records .echospec/spec
[[ -f .echospec/current ]] || : > .echospec/current
[[ -f .echospec/index.jsonl ]] || : > .echospec/index.jsonl
echo "[EchoSpec] Ensured .echospec structure."

# 1.5) install kit scripts（prompts 会调用 ~/.echospec/kit/scripts/*.sh）
mkdir -p "$KIT_SCRIPTS_DIR"

copy_kit_script() {
  local src="$1"
  local dst="$2"
  local name
  name="$(basename "$src")"
  cp "$src" "$dst"
  chmod +x "$dst" || true
  echo "[EchoSpec] Installed kit script: $name"
}

shopt -s nullglob
kit_scripts=( "$SRC_ROOT/scripts"/*.sh )
shopt -u nullglob

for f in "${kit_scripts[@]}"; do
  # cli.sh/install.sh/update.sh/uninstall.sh 属于安装器本身，不需要复制进 kit
  case "$(basename "$f")" in
    cli.sh|install.sh|update.sh|uninstall.sh) continue ;;
    *) copy_kit_script "$f" "$KIT_SCRIPTS_DIR/$(basename "$f")" ;;
  esac
done

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

shopt -s nullglob
files=( "$PROMPTS_SRC_DIR"/echospec-*.md )
shopt -u nullglob

if [[ ${#files[@]} -eq 0 ]]; then
  echo "[EchoSpec] ERROR: no echospec-*.md under $PROMPTS_SRC_DIR"
  exit 1
fi

for f in "${files[@]}"; do
  copy_prompt "$f" "$PROMPTS_DST_DIR/$(basename "$f")"
done

# 3) write AGENTS.md block at top (no overwrite of other content)
if [[ "$NO_AGENTS" -eq 0 ]]; then
  [[ -f "$AGENTS_BLOCK_FILE" ]] || { echo "[EchoSpec] ERROR: missing $AGENTS_BLOCK_FILE"; exit 1; }

  AGENTS_FILE="$REPO_ROOT/AGENTS.md"
  BEGIN="<!-- ECHOSPEC_RULES_BEGIN -->"
  END="<!-- ECHOSPEC_RULES_END -->"

  tmp="$(mktemp)"
  if [[ -f "$AGENTS_FILE" ]]; then
    # 若已有 block 就不重复插入；但如果没有 block，则把 block 前置到最上方
    if grep -qF "$BEGIN" "$AGENTS_FILE"; then
      echo "[EchoSpec] AGENTS.md already has EchoSpec block. Skipped."
      rm -f "$tmp"
    else
      cat "$AGENTS_FILE" > "$tmp"
      {
        cat "$AGENTS_BLOCK_FILE"
        echo
        cat "$tmp"
      } > "$AGENTS_FILE"
      rm -f "$tmp"
      echo "[EchoSpec] Prepended EchoSpec block to AGENTS.md (at top)."
    fi
  else
    {
      cat "$AGENTS_BLOCK_FILE"
      echo
    } > "$AGENTS_FILE"
    echo "[EchoSpec] Created AGENTS.md (EchoSpec block at top)."
  fi
else
  echo "[EchoSpec] Skipped AGENTS.md (--no-agents)."
fi

echo
echo "[EchoSpec] Install done."
echo "[EchoSpec] Next: restart/new Codex session to reload prompts."
