import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui

// Operator on/off/status control for the Zenbook Duo bottom OLED (eDP-2).
// Community plugin bar widget (not a Hermes Desktop pane). Default is off.
// Shells out to plugin/bin/zenbook-duo-bottom-oled when present; otherwise no-op.
BarWidget {
  id: root
  moduleName: "squinto.zenbook-duo-bottom-oled"

  property bool cliPresent: false
  property string desired: "off"
  property string statusHint: ""

  readonly property string statePath: {
    var home = Quickshell.env("HOME")
    var xdg = Quickshell.env("XDG_STATE_HOME")
    var dir = (xdg && xdg.length) ? xdg : (home + "/.local/state")
    return dir + "/omarchy/zenbook-duo-bottom-oled"
  }

  readonly property string scriptPath: {
    var u = Qt.resolvedUrl("bin/zenbook-duo-bottom-oled").toString()
    if (u.indexOf("file://") === 0)
      return u.substring(7)
    return u
  }

  readonly property bool panelOn: root.desired === "on"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function applyDesiredText(raw) {
    root.desired = String(raw || "").trim() === "on" ? "on" : "off"
  }

  function runCli(args) {
    if (!root.cliPresent || cliProc.running)
      return
    var cmd = [root.scriptPath]
    for (var i = 0; i < args.length; i++)
      cmd.push(args[i])
    cliProc.command = cmd
    cliProc.running = true
  }

  function probeCli() {
    if (!root.scriptPath.length || probeProc.running)
      return
    probeProc.command = ["test", "-x", root.scriptPath]
    probeProc.running = true
  }

  Component.onCompleted: probeCli()
  onScriptPathChanged: probeCli()

  FileView {
    id: stateView
    path: root.statePath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.applyDesiredText(text())
    onLoadFailed: root.desired = "off"
  }

  Process {
    id: probeProc
    onExited: function (code) {
      root.cliPresent = (code === 0)
      if (root.cliPresent)
        root.runCli(["status", "--json"])
    }
  }

  Process {
    id: cliProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var out = String(text || "").trim()
        if (!out.length || out.charAt(0) !== "{")
          return
        try {
          var parsed = JSON.parse(out)
          if (parsed && parsed.desired)
            root.applyDesiredText(parsed.desired)
          var sku = parsed && parsed.sku ? String(parsed.sku) : "UX8406CA"
          var bottom = parsed && parsed.bottom ? String(parsed.bottom) : "eDP-2"
          var live = parsed && parsed.bottomDisabled === true ? "disabled" : "enabled"
          root.statusHint = sku + " " + bottom + " live=" + live
        } catch (e) {
        }
      }
    }
    onExited: function () {
      stateView.reload()
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    dimmed: !root.cliPresent
    text: root.panelOn ? "OLED" : "OLED·"
    tooltipText: {
      if (!root.cliPresent)
        return "Bottom OLED CLI missing — widget is a no-op"
      var hint = root.statusHint.length ? " (" + root.statusHint + ")" : ""
      if (root.panelOn)
        return "Bottom OLED on — click to turn off" + hint
      return "Bottom OLED off (default) — click to turn on" + hint
    }
    onPressed: function (buttonCode) {
      if (!root.cliPresent)
        return
      if (buttonCode === Qt.RightButton) {
        root.runCli(["status", "--json"])
        return
      }
      if (buttonCode !== Qt.LeftButton)
        return
      root.runCli(["toggle"])
    }
  }
}
