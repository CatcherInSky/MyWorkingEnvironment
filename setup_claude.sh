#!/usr/bin/env bash
# Sets up Claude Code: copies notify.sh, merges hooks into settings.json.
# Run from the repo root directory.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

info() { printf "[INFO] %s\n" "$1"; }
warn() { printf "[WARN] %s\n" "$1"; }

setup_notify_script() {
  info "安装 notify.sh"
  mkdir -p "$CLAUDE_DIR"
  cp "${SCRIPT_DIR}/notify.sh" "${CLAUDE_DIR}/notify.sh"
  chmod +x "${CLAUDE_DIR}/notify.sh"
  info "  已复制到 ${CLAUDE_DIR}/notify.sh"
}

setup_hooks() {
  info "配置 hooks"
  mkdir -p "$CLAUDE_DIR"

  # The hooks we want to ensure exist
  local stop_hook='{"type":"command","command":"~/.claude/notify.sh '\''Claude Code'\'' '\''任务已完成，等待您的输入'\'' 2>/dev/null || true","async":true}'
  local notif_hook='{"type":"command","command":"MSG=$(python3 -c \"import sys,json; d=json.load(sys.stdin); print(d.get('\''message'\'','\''需要您的注意'\''))\" 2>/dev/null); ~/.claude/notify.sh '\''Claude Code 需要您的输入'\'' \"${MSG:-需要您的注意}\" 2>/dev/null || true","async":true}'

  if [ ! -f "$SETTINGS_FILE" ]; then
    # No existing settings — write fresh
    cat > "$SETTINGS_FILE" <<EOF
{
  "hooks": {
    "Stop": [{"hooks": [${stop_hook}]}],
    "Notification": [{"hooks": [${notif_hook}]}]
  }
}
EOF
    info "  已创建 ${SETTINGS_FILE}"
    return
  fi

  # Existing settings — merge with jq if available, otherwise warn
  if ! command -v jq >/dev/null 2>&1; then
    warn "jq 未安装，无法自动合并 settings.json"
    warn "请手动将以下内容添加到 ${SETTINGS_FILE} 的 hooks 字段："
    cat <<EOF
  "Stop": [{"hooks": [${stop_hook}]}],
  "Notification": [{"hooks": [${notif_hook}]}]
EOF
    return
  fi

  local tmp
  tmp=$(mktemp)

  # Add Stop hook if not already present
  if ! jq -e '.hooks.Stop' "$SETTINGS_FILE" >/dev/null 2>&1; then
    jq --argjson h "[{\"hooks\": [${stop_hook}]}]" \
      '.hooks.Stop = $h' "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"
    info "  添加 Stop hook"
  else
    info "  Stop hook 已存在，跳过"
  fi

  # Add Notification hook if not already present
  if ! jq -e '.hooks.Notification' "$SETTINGS_FILE" >/dev/null 2>&1; then
    jq --argjson h "[{\"hooks\": [${notif_hook}]}]" \
      '.hooks.Notification = $h' "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"
    info "  添加 Notification hook"
  else
    info "  Notification hook 已存在，跳过"
  fi

  rm -f "$tmp"
  info "  settings.json 更新完成"
}

print_plugin_instructions() {
  echo ""
  info "claude-hud 插件需在 Claude Code 会话中手动安装："
  echo ""
  echo "    /plugin marketplace add jarrodwatts/claude-hud"
  echo "    /plugin install claude-hud"
  echo "    /claude-hud:setup"
  echo ""
}

main() {
  setup_notify_script
  setup_hooks
  print_plugin_instructions
  info "Claude Code 配置完成"
}

main "$@"
