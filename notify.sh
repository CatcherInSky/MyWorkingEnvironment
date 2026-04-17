#!/usr/bin/env bash
# Cross-platform desktop notification.
# Usage: notify.sh "Title" "Message"

TITLE="${1:-Claude Code}"
MESSAGE="${2:-通知}"

escape_xml() {
  echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g'
}

notify_macos() {
  osascript -e "display notification \"${MESSAGE}\" with title \"${TITLE}\""
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
  # Fallback: terminal bell
  printf '\a'
fi
