import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons

// Draws the screen trackpad on the bottom OLED (state "on"), or blacks the
// whole panel out (state "dark"). screen-trackpadd grabs the digitizer, so
// pad touches never reach this surface; touches outside the pad come back
// through its touchscreen clone. Geometry comes from config.json (mm).
Item {
  id: root

  property string desired: "off"
  property var cfg: ({ output: "eDP-2", panelWidthMm: 306.25, widthMm: 120, heightMm: 70, bottomMm: 4 })

  readonly property string statePath: {
    var xdg = Quickshell.env("XDG_STATE_HOME")
    var dir = (xdg && xdg.length) ? xdg : (Quickshell.env("HOME") + "/.local/state")
    return dir + "/omarchy/zenbook-duo-screen-trackpad"
  }

  readonly property var targetScreen: {
    var list = Quickshell.screens
    for (var i = 0; i < list.length; i++)
      if (list[i].name === root.cfg.output) return list[i]
    return null
  }

  FileView {
    path: root.statePath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: { var s = String(text() || "").trim(); root.desired = (s === "on" || s === "dark") ? s : "off" }
    onLoadFailed: root.desired = "off"
  }

  FileView {
    path: Qt.resolvedUrl("config.json").toString().replace(/^file:\/\//, "")
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      try { root.cfg = JSON.parse(text()) } catch (e) { }
    }
  }

  // Dark mode: the panel must stay lit for the digitizer, so blank all of it.
  // Black OLED pixels emit no light. The touch area eats the clone's
  // pass-through touches so nothing on the hidden panel gets pressed.
  LazyLoader {
    active: root.desired === "dark" && root.targetScreen !== null

    PanelWindow {
      screen: root.targetScreen
      anchors { top: true; bottom: true; left: true; right: true }
      exclusionMode: ExclusionMode.Ignore
      color: "black"

      WlrLayershell.namespace: "zenbook-duo-screen-trackpad-dark"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

      MultiPointTouchArea {
        anchors.fill: parent
        mouseEnabled: false
      }
    }
  }

  LazyLoader {
    active: root.desired === "on" && root.targetScreen !== null

    PanelWindow {
      id: pad

      readonly property real pxPerMm: root.targetScreen.width / root.cfg.panelWidthMm

      screen: root.targetScreen
      anchors.bottom: true
      margins.bottom: Math.round(root.cfg.bottomMm * pxPerMm)
      implicitWidth: Math.round(root.cfg.widthMm * pxPerMm)
      implicitHeight: Math.round(root.cfg.heightMm * pxPerMm)
      exclusiveZone: implicitHeight
      color: "transparent"

      WlrLayershell.namespace: "zenbook-duo-screen-trackpad"
      WlrLayershell.layer: WlrLayer.Top
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

      Rectangle {
        anchors.fill: parent
        radius: 18
        color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.06)
        border.width: 1
        border.color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.5)
      }
    }
  }
}
