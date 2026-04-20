#!/usr/bin/env bash
# Sets up Claude Code: copies notify.sh, merges hooks into settings.json.
# Run from the repo root directory.

set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

info() { printf "[INFO] %s\n" "$1"; }
warn() { printf "[WARN] %s\n" "$1"; }

setup_notify_script() {
  info "安装 notify.sh"
  mkdir -p "$CLAUDE_DIR"
  cat > "${CLAUDE_DIR}/notify.sh" << 'NOTIFY_EOF'
#!/usr/bin/env bash
# Cross-platform desktop notification.
# Usage: notify.sh "Title" "Message"

TITLE="${1:-Claude Code}"
MESSAGE="${2:-通知}"

escape_xml() {
  echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g'
}

notify_macos() {
  local title_esc="${TITLE//\\/\\\\}"
  title_esc="${title_esc//\"/\\\"}"
  local msg_esc="${MESSAGE//\\/\\\\}"
  msg_esc="${msg_esc//\"/\\\"}"
  osascript -e "display notification \"${msg_esc}\" with title \"${title_esc}\""
}

notify_linux() {
  notify-send "$TITLE" "$MESSAGE"
}

notify_wsl() {
  local title_esc msg_esc
  title_esc=$(escape_xml "$TITLE")
  msg_esc=$(escape_xml "$MESSAGE")
  powershell.exe -Command "
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
\$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
\$xml.LoadXml('<toast><visual><binding template=\"ToastText02\"><text id=\"1\">${title_esc}</text><text id=\"2\">${msg_esc}</text></binding></visual></toast>')
[Windows.UI.Notifications.ToastNotification]::new(\$xml) | ForEach-Object { [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Claude Code').Show(\$_) }
" 2>/dev/null
}

if [[ "$(uname -s)" == "Darwin" ]]; then
  notify_macos
elif grep -qi microsoft /proc/version 2>/dev/null || [ -n "${WSL_DISTRO_NAME:-}" ]; then
  notify_wsl
elif command -v notify-send >/dev/null 2>&1; then
  notify_linux
else
  printf '\a'
fi
NOTIFY_EOF
  chmod +x "${CLAUDE_DIR}/notify.sh"
  info "  已写入 ${CLAUDE_DIR}/notify.sh"
}

setup_hooks() {
  info "配置 hooks"
  mkdir -p "$CLAUDE_DIR"

  # The hooks we want to ensure exist
  local stop_hook='{"type":"command","command":"~/.claude/notify.sh '\''Claude Code'\'' '\''任务已完成，等待您的输入'\'' 2>/dev/null || true","async":true}'
  local notif_hook='{"type":"command","command":"MSG=$(jq -r '\''.message // \"需要您的注意\"'\'' 2>/dev/null); ~/.claude/notify.sh '\''Claude Code 需要您的输入'\'' \"${MSG:-需要您的注意}\" 2>/dev/null || true","async":true}'

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
  trap 'rm -f "$tmp"' EXIT

  jq_merge() {
    local key="$1" val="$2"
    if ! jq -e ".hooks.${key}" "$SETTINGS_FILE" >/dev/null 2>&1; then
      if jq --argjson h "[{\"hooks\": [${val}]}]" \
          ".hooks.${key} = \$h" "$SETTINGS_FILE" > "$tmp"; then
        mv "$tmp" "$SETTINGS_FILE"
        info "  添加 ${key} hook"
      else
        warn "  jq 写入 ${key} hook 失败，settings.json 未修改"
      fi
    else
      info "  ${key} hook 已存在，跳过"
    fi
  }

  jq_merge "Stop" "$stop_hook"
  jq_merge "Notification" "$notif_hook"

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
