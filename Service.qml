import QtQuick
import Quickshell
import Quickshell.Io

// Mounted once per shell session. Open With is really a system-level URL
// handler (a .desktop file registered with xdg-mime), so this singleton stays
// deliberately thin: it never intercepts links itself and runs no long-lived
// process. It exposes an IPC surface so a keybinding can summon the menu, and
// so `install` / `uninstall` can be run without leaving the shell.
QtObject {
  id: root

  property var shell: null
  property var manifest: null

  readonly property string pluginId: "io.github.jlescanog.open-with"
  readonly property string ctlPath: Qt.resolvedUrl("bin/open-with-ctl").toString().replace(/^file:\/\//, "")
  readonly property string pickerPath: Qt.resolvedUrl("bin/omarchy-open-with").toString().replace(/^file:\/\//, "")

  // true once the xdg-mime default for x-scheme-handler/https points at us.
  property bool installed: false

  function refreshStatus() { statusProc.running = true }

  function runCtl(action) {
    ctlProc.command = ["/bin/bash", root.ctlPath, action]
    ctlProc.running = true
  }

  function pick(url) {
    pickerProc.command = url && url.length > 0
      ? ["/bin/bash", root.pickerPath, url]
      : ["/bin/bash", root.pickerPath, "--clipboard"]
    pickerProc.running = true
  }

  Component.onCompleted: refreshStatus()

  // Keeps `installed` honest even when the handler is (de)registered from a
  // terminal rather than through the IPC calls below.
  property Timer statusPoll: Timer {
    interval: 30000
    repeat: true
    running: true
    onTriggered: root.refreshStatus()
  }

  property Process statusProc: Process {
    command: ["/bin/bash", root.ctlPath, "status", "--quiet"]
    running: false
    onExited: function(code) { root.installed = (code === 0) }
  }

  property Process ctlProc: Process {
    running: false
    onExited: function(code) { root.refreshStatus() }
  }

  property Process pickerProc: Process { running: false }

  property IpcHandler ipc: IpcHandler {
    target: root.pluginId

    function open(url: string): void { root.pick(url) }       // menu for a link
    function clipboard(): void { root.pick("") }              // menu for the clipboard URL
    function install(): void { root.runCtl("install") }
    function uninstall(): void { root.runCtl("uninstall") }
    function status(): string { return root.installed ? "installed" : "not-installed" }
  }
}
