#!/usr/bin/env bash
set -euo pipefail

die() { echo "[echospec] $*" >&2; exit 1; }

# 解析源码仓库根目录：
# - 优先用环境变量（由 link stub 注入）
# - 否则用当前脚本所在位置推导（scripts/..）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_SRC_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_ROOT="${ECHOSPEC_SRC_ROOT:-$DEFAULT_SRC_ROOT}"

[[ -d "$SRC_ROOT/scripts" ]] || die "无效的 EchoSpec 源码路径：$SRC_ROOT"
[[ -f "$SRC_ROOT/scripts/install.sh" ]] || die "缺少 $SRC_ROOT/scripts/install.sh"
[[ -f "$SRC_ROOT/scripts/update.sh" ]] || die "缺少 $SRC_ROOT/scripts/update.sh"
[[ -f "$SRC_ROOT/scripts/uninstall.sh" ]] || die "缺少 $SRC_ROOT/scripts/uninstall.sh"

usage() {
  cat <<'USAGE'
用法：
  ./scripts/cli.sh link
  echospec install [--force-prompts] [--no-agents]
  echospec update  [--agents] [--force-prompts]
  echospec uninstall [--yes] [--purge-echospec]
  echospec --version

说明：
- 本 CLI 永远只使用“你本地 clone 的 EchoSpec 仓库”作为来源；
- 想更新 EchoSpec：请你自己在该仓库 git pull，然后再运行 echospec update。
USAGE
}

cmd="${1:-help}"
shift || true

case "$cmd" in
  help|-h|--help)
    usage
    ;;

  link)
    # 在 ~/.local/bin 生成 echospec stub，固定指向当前源码仓库
    BIN_DIR="${ECHOSPEC_BIN_DIR:-$HOME/.local/bin}"
    mkdir -p "$BIN_DIR" || die "无法创建 $BIN_DIR"
    STUB="$BIN_DIR/echospec"

    cat > "$STUB" <<STUBEOF
#!/usr/bin/env bash
set -euo pipefail
export ECHOSPEC_SRC_ROOT="${SRC_ROOT}"
exec "${SRC_ROOT}/scripts/cli.sh" "\$@"
STUBEOF

    chmod +x "$STUB" || true
    echo "[echospec] linked: $STUB"
    echo "[echospec] source:  $SRC_ROOT"
    echo "[echospec] tip: make sure PATH contains: $BIN_DIR"
    ;;

  install)
    exec "$SRC_ROOT/scripts/install.sh" "$@"
    ;;

  update)
    exec "$SRC_ROOT/scripts/update.sh" "$@"
    ;;

  uninstall)
    exec "$SRC_ROOT/scripts/uninstall.sh" "$@"
    ;;

  version|--version|-v)
    if [[ -f "$SRC_ROOT/VERSION" ]]; then
      cat "$SRC_ROOT/VERSION"
    elif command -v git >/dev/null 2>&1 && git -C "$SRC_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      git -C "$SRC_ROOT" describe --tags --always 2>/dev/null || echo "unknown"
    else
      echo "unknown"
    fi
    ;;

  *)
    die "未知命令：$cmd（支持：link/install/update/uninstall/version）"
    ;;
esac
