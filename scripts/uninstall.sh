#!/usr/bin/env bash
set -euo pipefail

# 用法：
#   ./scripts/uninstall.sh --yes
#   ./scripts/uninstall.sh --yes --purge-echospec   # 删除项目 .echospec（危险：会删历史）

YES=0
PURGE=0

for arg in "$@"; do
  case "$arg" in
    --yes) YES=1 ;;
    --purge-echospec) PURGE=1 ;;
    *) ;;
  esac
done

confirm() {
  local msg="$1"
  if [[ "$YES" -eq 1 ]]; then return 0; fi
  read -r -p "$msg [y/N] " ans
  [[ "$ans" == "y" || "$ans" == "Y" ]]
}

# target repo root
if git rev-parse --show-toplevel >/dev/null 2>&1; then
  REPO_ROOT="$(git rev-parse --show-toplevel)"
else
  REPO_ROOT="$(pwd)"
fi
cd "$REPO_ROOT"

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
PROMPTS_DST_DIR="$CODEX_HOME/prompts"

echo "[EchoSpec] Target repo: $REPO_ROOT"
echo "[EchoSpec] Codex prompts dir: $PROMPTS_DST_DIR"

# 1) remove prompts
PROMPTS=( "echospec-init.md" "echospec-new.md" "echospec-apply.md" "echospec-archive.md" )
if [[ -d "$PROMPTS_DST_DIR" ]]; then
  for p in "${PROMPTS[@]}"; do
    f="$PROMPTS_DST_DIR/$p"
    if [[ -f "$f" ]]; then
      if confirm "Delete prompt $f ?"; then
        rm -f "$f"
        echo "[EchoSpec] Deleted: $f"
      else
        echo "[EchoSpec] Kept: $f"
      fi
    fi
  done
else
  echo "[EchoSpec] No prompts dir found; skipped."
fi

# 2) remove EchoSpec block in AGENTS.md
AGENTS_FILE="$REPO_ROOT/AGENTS.md"
BEGIN="<!-- ECHOSPEC_RULES_BEGIN -->"
END="<!-- ECHOSPEC_RULES_END -->"

if [[ -f "$AGENTS_FILE" ]]; then
  if grep -qF "$BEGIN" "$AGENTS_FILE"; then
    if confirm "Remove EchoSpec block from AGENTS.md ?"; then
      tmp="$(mktemp)"
      awk -v b="$BEGIN" -v e="$END" '
        $0 ~ b {in=1; next}
        $0 ~ e {in=0; next}
        in==0 {print}
      ' "$AGENTS_FILE" > "$tmp"
      mv "$tmp" "$AGENTS_FILE"
      echo "[EchoSpec] Removed EchoSpec block from AGENTS.md"
    else
      echo "[EchoSpec] Kept AGENTS.md unchanged"
    fi
  else
    echo "[EchoSpec] No EchoSpec block in AGENTS.md; skipped."
  fi
else
  echo "[EchoSpec] No AGENTS.md found; skipped."
fi

# 3) optional purge project .echospec
if [[ "$PURGE" -eq 1 ]]; then
  if [[ -d "$REPO_ROOT/.echospec" ]]; then
    if confirm "Purge .echospec directory (THIS DELETES HISTORY) ?"; then
      rm -rf "$REPO_ROOT/.echospec"
      echo "[EchoSpec] Purged .echospec/"
    else
      echo "[EchoSpec] Kept .echospec/"
    fi
  else
    echo "[EchoSpec] .echospec not found; skipped."
  fi
else
  echo "[EchoSpec] Kept project .echospec/ (use --purge-echospec to delete it)"
fi

echo
echo "[EchoSpec] Uninstall done."
