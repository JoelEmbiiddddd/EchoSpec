#!/usr/bin/env bash
set -euo pipefail

# 用法：
#   ./scripts/update.sh            # 覆盖 ~/.codex/prompts 下的 echospec-*.md
#   ./scripts/update.sh --agents   # 同时更新目标项目的 AGENTS.md（块写在最上方）

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

# 同步 kit scripts（prompts 会调用 ~/.echospec/kit/scripts/*.sh）
KIT_HOME="${ECHOSPEC_HOME:-$HOME/.echospec}"
KIT_DIR="$KIT_HOME/kit"
KIT_SCRIPTS_DIR="$KIT_DIR/scripts"
mkdir -p "$KIT_SCRIPTS_DIR"

echo "[EchoSpec] Updating prompts from: $PROMPTS_SRC_DIR"
echo "[EchoSpec] To: $PROMPTS_DST_DIR"

echo "[EchoSpec] Updating kit scripts to: $KIT_SCRIPTS_DIR"

copy_kit_script() {
  local src="$1"
  local dst="$2"
  local name
  name="$(basename "$src")"
  cp "$src" "$dst"
  chmod +x "$dst" || true
  echo "[EchoSpec] Updated kit script: $name"
}

shopt -s nullglob
kit_scripts=( "$SRC_ROOT/scripts"/*.sh )
shopt -u nullglob

for f in "${kit_scripts[@]}"; do
  case "$(basename "$f")" in
    cli.sh|install.sh|update.sh|uninstall.sh) continue ;;
    *) copy_kit_script "$f" "$KIT_SCRIPTS_DIR/$(basename "$f")" ;;
  esac
done

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

# 复制所有 echospec-*.md（自动包含 echospec-reflect.md）
shopt -s nullglob
files=( "$PROMPTS_SRC_DIR"/echospec-*.md )
shopt -u nullglob

if [[ ${#files[@]} -eq 0 ]]; then
  echo "[EchoSpec] ERROR: no echospec-*.md under $PROMPTS_SRC_DIR"
  exit 1
fi

for f in "${files[@]}"; do
  backup_and_copy "$f" "$PROMPTS_DST_DIR/$(basename "$f")"
done

# optional: update AGENTS.md block in target repo (write at top)
if [[ "$UPDATE_AGENTS" -eq 1 ]]; then
  [[ -f "$AGENTS_BLOCK_FILE" ]] || { echo "[EchoSpec] ERROR: missing $AGENTS_BLOCK_FILE"; exit 1; }

  if git rev-parse --show-toplevel >/dev/null 2>&1; then
    REPO_ROOT="$(git rev-parse --show-toplevel)"
  else
    REPO_ROOT="$(pwd)"
  fi
  cd "$REPO_ROOT"

  AGENTS_FILE="$REPO_ROOT/AGENTS.md"
  BEGIN="<!-- ECHOSPEC_RULES_BEGIN -->"
  END="<!-- ECHOSPEC_RULES_END -->"

  tmp="$(mktemp)"
  if [[ -f "$AGENTS_FILE" ]]; then
    # 去掉旧 block（如果有），保留其余内容
    awk -v b="$BEGIN" -v e="$END" '
      $0 ~ b {in=1; next}
      $0 ~ e {in=0; next}
      in!=1 {print}
    ' "$AGENTS_FILE" > "$tmp"
  else
    : > "$tmp"
  fi

  # 新 block 一定写到最上方
  {
    cat "$AGENTS_BLOCK_FILE"
    echo
    cat "$tmp"
  } > "$AGENTS_FILE"

  rm -f "$tmp"
  echo "[EchoSpec] AGENTS.md updated (EchoSpec block at top)."
fi

echo
echo "[EchoSpec] Update done. Restart/new Codex session to reload prompts."
