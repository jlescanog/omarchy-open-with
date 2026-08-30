import QtQuick
import Quickshell
import Quickshell.Io

// Mounted once per shell session. Browser Picker is really a system-level
// URL handler (a .desktop file registered with xdg-mime), so this singleton
// stays deliberately thin: it never intercepts links itself and spawns
// nothing at startup. It only exposes an IPC surface so a keybinding or the
// Omarchy menu can drive the picker, and so `install` / `uninstall` can be
// run without leaving the shell.
QtObject {
  id: root

  property var shell: null
  property var manifest: null

  readonly property string pluginId: "io.github.jlescanog.browser-picker"
  readonly property string ctlPath: Qt.resolvedUrl("bin/browser-picker-ctl").toString().replace(/^file:\/\//, "")
  readonly property string pickerPath: Qt.resolvedUrl("bin/omarchy-browser-picker").toString().replace(/^file:\/\//, "")

  // "installed" once the xdg-mime default for x-scheme-handler/https points at
  // our desktop file; refreshed after every install/uninstall and on load.
  property bool installed: false

  function refreshStatus() {
    statusProc.running = true
  }

  function runCtl(action) {
    ctlProc.command = ["/bin/bash", root.ctlPath, action]
    ctlProc.running = true
  }

  Component.onCompleted: refreshStatus()

  // Keeps `installed` honest even when the handler is (de)registered outside
  // the shell — e.g. running `browser-picker-ctl install` from a terminal.
  property Timer statusPoll: Timer {
    interval: 30000
    repeat: true
    running: true
    onTriggered: root.refreshStatus()
  }

  property Process statusProc: Process {
    command: ["/bin/bash", root.ctlPath, "status", "--quiet"]
    running: false
    onExited: function(code) {
      root.installed = (code === 0)
    }
  }

  property Process ctlProc: Process {
    running: false
    onExited: function(code) {
      root.refreshStatus()
    }
  }

  // Fires `omarchy-browser-picker` with whatever URL the caller passes; with no
  // argument the script falls back to the current clipboard contents.
  property Process pickerProc: Process {
    running: false
  }

  function pick(url) {
    pickerProc.command = url && url.length > 0
      ? ["/bin/bash", root.pickerPath, url]
      : ["/bin/bash", root.pickerPath, "--clipboard"]
    pickerProc.running = true
  }

  property IpcHandler ipc: IpcHandler {
    target: root.pluginId

    // Open a specific link through the picker menu.
    function open(url: string): void { root.pick(url) }
    // Open whatever URL is on the clipboard (handy as a keybinding).
    function clipboard(): void { root.pick("") }
    // Register / unregister as the system http(s) + text/html handler.
    function install(): void { root.runCtl("install") }
    function uninstall(): void { root.runCtl("uninstall") }
    // "installed" | "not-installed"
    function status(): string { return root.installed ? "installed" : "not-installed" }
  }
}
