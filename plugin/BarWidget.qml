import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui

// Operator toggle for the Zenbook Duo bottom OLED (eDP-2).
// Default is off; this widget does not keep the panel composited.
BarWidget {
  id: root
  moduleName: "squinto.zenbook-duo-bottom-oled"

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

  readonly property bool panelOn: stateView.text.trim() === "on"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  FileView {
    id: stateView
    path: root.statePath
    watchChanges: true
  }

  Process {
    id: toggleProc
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.panelOn ? "OLED" : "OLED·"
    tooltipText: root.panelOn
      ? "Bottom OLED on — click to turn off (UX8406CA eDP-2)"
      : "Bottom OLED off (default) — click to turn on (UX8406CA eDP-2)"
    onPressed: function (buttonCode) {
      if (buttonCode !== Qt.LeftButton)
        return
      if (toggleProc.running)
        return
      toggleProc.command = [root.scriptPath, "toggle"]
      toggleProc.running = true
    }
  }
}
