#!/bin/bash
# Desktop notification via Windows Toast (WSL2)
# Usage: notify.sh "Title" "Message"
TITLE="${1:-Claude Code}"
MESSAGE="${2:-通知}"

# Escape XML special chars
escape_xml() {
  echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g'
}

TITLE_ESC=$(escape_xml "$TITLE")
MSG_ESC=$(escape_xml "$MESSAGE")

powershell.exe -Command "
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
\$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
\$xml.LoadXml('<toast><visual><binding template=\"ToastText02\"><text id=\"1\">$TITLE_ESC</text><text id=\"2\">$MSG_ESC</text></binding></visual></toast>')
[Windows.UI.Notifications.ToastNotification]::new(\$xml) | ForEach-Object { [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Claude Code').Show(\$_) }
" 2>/dev/null