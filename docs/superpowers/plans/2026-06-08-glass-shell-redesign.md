# Glass Shell Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Caelestia's vertical rounded sidebar+bar with a floating horizontal TopBar and two independent corner widgets (bottom-left notifications, bottom-right media), all using a "liquid glass" frosted style with straight edges and Material You dynamic tinting.

**Architecture:** Hybrid — keep all Caelestia services (Audio, Notifs, Players, Network, Brightness, etc.) and the Drawers module (which handles OSD, notification popups, session, launcher, lock). Replace only the visual layer: new `GlassRect` base component, new `topbar/`, `corner-notifs/`, `corner-media/` modules. The old bar is disabled inside Drawers; the new TopBar runs as a separate PanelWindow per monitor via `Variants`.

**Tech Stack:** Quickshell v0.3.0, QML, Hyprland IPC (`Quickshell.Hyprland`), WlrLayershell (`Quickshell.Wayland`), Caelestia services (`qs.services`, `qs.config`, `qs.components`), Material You color palette via `Colours.palette`.

---

## File map

| Action | Path |
|---|---|
| Modify | `quickshell/caelestia/config/AppearanceConfig.qml` |
| Create | `quickshell/caelestia/components/GlassRect.qml` |
| Create | `quickshell/caelestia/components/GlassClippingRect.qml` |
| Modify | `hypr/hyprland/rules.conf` |
| Modify | `quickshell/caelestia/modules/drawers/Drawers.qml` |
| Create | `quickshell/caelestia/modules/topbar/TopBarWrapper.qml` |
| Create | `quickshell/caelestia/modules/topbar/TopBar.qml` |
| Create | `quickshell/caelestia/modules/topbar/components/Workspaces.qml` |
| Create | `quickshell/caelestia/modules/topbar/components/ActiveWindow.qml` |
| Create | `quickshell/caelestia/modules/topbar/components/Clock.qml` |
| Create | `quickshell/caelestia/modules/topbar/components/StatusIcons.qml` |
| Create | `quickshell/caelestia/modules/topbar/components/Tray.qml` |
| Create | `quickshell/caelestia/modules/topbar/components/PowerButton.qml` |
| Modify | `quickshell/caelestia/shell.qml` |
| Create | `quickshell/caelestia/modules/corner-notifs/HotCorner.qml` |
| Create | `quickshell/caelestia/modules/corner-notifs/NotifCard.qml` |
| Create | `quickshell/caelestia/modules/corner-notifs/CornerNotifsPanel.qml` |
| Create | `quickshell/caelestia/modules/corner-notifs/CornerNotifsWrapper.qml` |
| Create | `quickshell/caelestia/modules/corner-media/HotCorner.qml` |
| Create | `quickshell/caelestia/modules/corner-media/DailyLog.qml` |
| Create | `quickshell/caelestia/modules/corner-media/MediaInfo.qml` |
| Create | `quickshell/caelestia/modules/corner-media/MediaProgress.qml` |
| Create | `quickshell/caelestia/modules/corner-media/MediaControls.qml` |
| Create | `quickshell/caelestia/modules/corner-media/CornerMediaPanel.qml` |
| Create | `quickshell/caelestia/modules/corner-media/CornerMediaWrapper.qml` |
| Modify | `quickshell/caelestia/modules/notifications/Background.qml` |
| Modify | `quickshell/caelestia/modules/osd/Background.qml` |
| Modify | `quickshell/caelestia/modules/session/Background.qml` |
| Modify | `quickshell/caelestia/modules/launcher/Background.qml` |

All paths are relative to `~/.local/share/caelestia/`.

**Test commands used throughout:**
- Launch: `qs -p ~/.local/share/caelestia/quickshell/caelestia`
- Kill: `qs -c caelestia`

---

## Task 1: Config — rounding and transparency

**Files:**
- Modify: `quickshell/caelestia/config/AppearanceConfig.qml`

> `Config.border.rounding` derives from `Appearance.rounding.large`, so zeroing `large` automatically straightens all ShapePath-based backgrounds (notifications, OSD, session, launcher) without touching those files.

- [ ] **Step 1: Edit `AppearanceConfig.qml` — Rounding**

In `component Rounding`, change `small`, `normal`, `large` to `0 * scale`:

```qml
component Rounding: JsonObject {
    property real scale: 1
    property int small: 0 * scale
    property int normal: 0 * scale
    property int large: 0 * scale
    property int full: 1000 * scale
}
```

- [ ] **Step 2: Edit `AppearanceConfig.qml` — Transparency**

In `component Transparency`, set `enabled: true`, `base: 0.55`, `layers: 0.35`:

```qml
component Transparency: JsonObject {
    property bool enabled: true
    property real base: 0.55
    property real layers: 0.35
}
```

- [ ] **Step 3: Launch and verify**

```bash
qs -p ~/.local/share/caelestia/quickshell/caelestia
```

Expected: shell loads. Existing panels (OSD, notification popups) now have straight corners. Existing bar still visible — that's fine, disabled next.

```bash
qs -c caelestia
```

- [ ] **Step 4: Commit**

```bash
git -C ~/.local/share/caelestia add quickshell/caelestia/config/AppearanceConfig.qml
git -C ~/.local/share/caelestia commit -m "feat: set rounding to 0 and enable transparency in AppearanceConfig"
```

---

## Task 2: GlassRect and GlassClippingRect

**Files:**
- Create: `quickshell/caelestia/components/GlassRect.qml`
- Create: `quickshell/caelestia/components/GlassClippingRect.qml`

- [ ] **Step 1: Create `GlassRect.qml`**

```qml
import qs.services
import qs.config
import QtQuick

Rectangle {
    id: root

    // Dynamic tint from Material You surface color; alpha from transparency config
    color: Qt.rgba(
        Colours.palette.m3surface.r,
        Colours.palette.m3surface.g,
        Colours.palette.m3surface.b,
        Appearance.transparency.enabled ? 0.55 : 0.92
    )
    radius: 0
    border.color: Qt.rgba(1, 1, 1, 0.1)
    border.width: 1

    // Specular highlight — bright top edge simulates glass catching light
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Qt.rgba(1, 1, 1, 0.28)
        z: 1
    }

    Behavior on color { CAnim {} }
}
```

- [ ] **Step 2: Create `GlassClippingRect.qml`**

```qml
import qs.services
import qs.config
import QtQuick

Rectangle {
    id: root

    color: Qt.rgba(
        Colours.palette.m3surface.r,
        Colours.palette.m3surface.g,
        Colours.palette.m3surface.b,
        Appearance.transparency.enabled ? 0.55 : 0.92
    )
    radius: 0
    clip: true
    border.color: Qt.rgba(1, 1, 1, 0.1)
    border.width: 1

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Qt.rgba(1, 1, 1, 0.28)
        z: 1
    }

    Behavior on color { CAnim {} }
}
```

- [ ] **Step 3: Commit**

```bash
git -C ~/.local/share/caelestia add quickshell/caelestia/components/GlassRect.qml quickshell/caelestia/components/GlassClippingRect.qml
git -C ~/.local/share/caelestia commit -m "feat: add GlassRect and GlassClippingRect base components"
```

---

## Task 3: Hyprland layerrules for glass panels

**Files:**
- Modify: `hypr/hyprland/rules.conf`

- [ ] **Step 1: Append glass layerrules to `rules.conf`**

Add at the bottom of the `# Shell` section in `~/.local/share/caelestia/hypr/hyprland/rules.conf`:

```
# Glass shell panels — target by namespace instead of global shell:quickshell
layerrule = blur true, match:namespace glass-topbar
layerrule = ignorealpha 0.1, match:namespace glass-topbar
layerrule = blur true, match:namespace glass-corner-notifs
layerrule = ignorealpha 0.1, match:namespace glass-corner-notifs
layerrule = blur true, match:namespace glass-corner-media
layerrule = ignorealpha 0.1, match:namespace glass-corner-media
```

- [ ] **Step 2: Commit**

```bash
git -C ~/.local/share/caelestia add hypr/hyprland/rules.conf
git -C ~/.local/share/caelestia commit -m "feat: add Hyprland blur layerrules for glass panel namespaces"
```

---

## Task 4: Disable old bar in Drawers

**Files:**
- Modify: `quickshell/caelestia/modules/drawers/Drawers.qml`

> The old `BarWrapper` inside `Drawers.qml` is wired up via `disabled: scope.barDisabled`. We force-disable it permanently so it doesn't render alongside the new TopBar.

- [ ] **Step 1: Edit `Drawers.qml` — force-disable BarWrapper**

Find the `BarWrapper` block near the bottom of the file. Change `disabled: scope.barDisabled` to `disabled: true`:

```qml
BarWrapper {
    id: bar

    anchors.top: parent.top
    anchors.bottom: parent.bottom

    screen: scope.modelData
    visibilities: visibilities
    popouts: panels.popouts

    disabled: true  // replaced by TopBar in glass theme

    Component.onCompleted: Visibilities.bars.set(scope.modelData, this)
}
```

- [ ] **Step 2: Launch and verify bar is gone**

```bash
qs -p ~/.local/share/caelestia/quickshell/caelestia
```

Expected: old vertical sidebar bar no longer renders. Shell is otherwise functional.

```bash
qs -c caelestia
```

- [ ] **Step 3: Commit**

```bash
git -C ~/.local/share/caelestia add quickshell/caelestia/modules/drawers/Drawers.qml
git -C ~/.local/share/caelestia commit -m "feat: disable old BarWrapper in Drawers — replaced by glass TopBar"
```

---

## Task 5: TopBar — Workspaces component

**Files:**
- Create: `quickshell/caelestia/modules/topbar/components/Workspaces.qml`

> Horizontal row of workspace squares for the current monitor. Active workspace highlighted with m3primary. Shows urgent badge dot.

- [ ] **Step 1: Create directory**

```bash
mkdir -p ~/.local/share/caelestia/quickshell/caelestia/modules/topbar/components
```

- [ ] **Step 2: Create `Workspaces.qml`**

```qml
pragma ComponentBehavior: Bound

import qs.services
import qs.config
import qs.components
import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Row {
    id: root

    required property ShellScreen screen

    // Monitor object for this screen — used to filter workspaces
    readonly property var monitor: Hypr.monitorFor(screen)
    readonly property var activeWsId: monitor?.activeWorkspace?.id ?? 1

    // Workspaces that belong to this monitor, sorted by id
    readonly property var monitorWorkspaces: Hypr.workspaces.values
        .filter(ws => ws.monitor?.name === root.monitor?.name)
        .sort((a, b) => a.id - b.id)

    spacing: 4

    Repeater {
        model: ScriptModel { values: root.monitorWorkspaces }

        delegate: Item {
            required property var modelData

            readonly property bool isActive: modelData.id === root.activeWsId
            readonly property bool isUrgent: modelData.urgent

            width: 18
            height: 18

            Rectangle {
                anchors.fill: parent
                color: parent.isActive
                    ? Colours.palette.m3primary
                    : Qt.rgba(1, 1, 1, parent.isUrgent ? 0.25 : 0.08)
                radius: 0

                Behavior on color { CAnim {} }
            }

            // Urgent badge — small dot in top-right corner
            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 2
                width: 4
                height: 4
                radius: 2
                color: Colours.palette.m3error
                visible: parent.isUrgent && !parent.isActive

                Behavior on visible { CAnim {} }
            }

            StyledText {
                anchors.centerIn: parent
                text: modelData.id.toString()
                font.pointSize: Appearance.font.size.small
                color: parent.isActive
                    ? Colours.palette.m3onPrimary
                    : Colours.palette.m3onSurfaceVariant
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hypr.dispatch(`workspace ${modelData.id}`)
            }
        }
    }
}
```

- [ ] **Step 3: Commit**

```bash
git -C ~/.local/share/caelestia add quickshell/caelestia/modules/topbar/components/Workspaces.qml
git -C ~/.local/share/caelestia commit -m "feat: add horizontal per-monitor Workspaces component for TopBar"
```

---

## Task 6: TopBar — ActiveWindow component

**Files:**
- Create: `quickshell/caelestia/modules/topbar/components/ActiveWindow.qml`

- [ ] **Step 1: Create `ActiveWindow.qml`**

```qml
import qs.services
import qs.components
import qs.config
import QtQuick

Item {
    id: root

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    StyledText {
        id: label

        // Elide long titles — max 280px
        width: Math.min(implicitWidth, 280)
        anchors.verticalCenter: parent.verticalCenter

        text: Hypr.activeToplevel?.title ?? qsTr("Desktop")
        elide: Text.ElideRight
        font.pointSize: Appearance.font.size.smaller
        color: Colours.palette.m3onSurfaceVariant

        Behavior on text { CAnim {} }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git -C ~/.local/share/caelestia add quickshell/caelestia/modules/topbar/components/ActiveWindow.qml
git -C ~/.local/share/caelestia commit -m "feat: add ActiveWindow component for horizontal TopBar"
```

---

## Task 7: TopBar — Clock component

**Files:**
- Create: `quickshell/caelestia/modules/topbar/components/Clock.qml`

- [ ] **Step 1: Create `Clock.qml`**

```qml
import qs.services
import qs.components
import qs.config
import QtQuick

StyledText {
    text: Time.format(Config.services.useTwelveHourClock ? "hh:mm A" : "HH:mm")
    font.pointSize: Appearance.font.size.smaller
    font.family: Appearance.font.family.mono
    color: Colours.palette.m3onSurface
}
```

- [ ] **Step 2: Commit**

```bash
git -C ~/.local/share/caelestia add quickshell/caelestia/modules/topbar/components/Clock.qml
git -C ~/.local/share/caelestia commit -m "feat: add single-line Clock component for horizontal TopBar"
```

---

## Task 8: TopBar — StatusIcons component

**Files:**
- Create: `quickshell/caelestia/modules/topbar/components/StatusIcons.qml`

- [ ] **Step 1: Create `StatusIcons.qml`**

```qml
pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

Row {
    id: root

    property color colour: Colours.palette.m3secondary

    spacing: Appearance.spacing.small / 2

    // Volume
    MaterialIcon {
        visible: Config.bar.status.showAudio
        animate: true
        text: Icons.getVolumeIcon(Audio.volume, Audio.muted)
        color: root.colour
        font.pointSize: Appearance.font.size.normal
    }

    // Network
    MaterialIcon {
        visible: Config.bar.status.showNetwork && (!Nmcli.activeEthernet || Config.bar.status.showWifi)
        animate: true
        text: Nmcli.active ? Icons.getNetworkIcon(Nmcli.active.strength ?? 0) : "wifi_off"
        color: root.colour
        font.pointSize: Appearance.font.size.normal
    }

    // Ethernet
    MaterialIcon {
        visible: Config.bar.status.showNetwork && Nmcli.activeEthernet
        animate: true
        text: "cable"
        color: root.colour
        font.pointSize: Appearance.font.size.normal
    }

    // Bluetooth
    MaterialIcon {
        visible: Config.bar.status.showBluetooth
        animate: true
        text: {
            if (!Bluetooth.defaultAdapter?.enabled) return "bluetooth_disabled"
            if (Bluetooth.devices.values.some(d => d.connected)) return "bluetooth_connected"
            return "bluetooth"
        }
        color: root.colour
        font.pointSize: Appearance.font.size.normal
    }

    // Battery
    MaterialIcon {
        visible: Config.bar.status.showBattery && UPower.displayDevice.isLaptopBattery
        animate: true
        text: {
            const perc = UPower.displayDevice.percentage
            const charging = [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice.state)
            if (perc === 1) return charging ? "battery_charging_full" : "battery_full"
            let level = Math.floor(perc * 7)
            if (charging && (level === 4 || level === 1)) level--
            return charging ? `battery_charging_${(level + 3) * 10}` : `battery_${level}_bar`
        }
        color: !UPower.onBattery || UPower.displayDevice.percentage > 0.2
            ? root.colour
            : Colours.palette.m3error
        fill: 1
        font.pointSize: Appearance.font.size.normal
    }
}
```

- [ ] **Step 2: Commit**

```bash
git -C ~/.local/share/caelestia/quickshell/caelestia add quickshell/caelestia/modules/topbar/components/StatusIcons.qml
git -C ~/.local/share/caelestia commit -m "feat: add horizontal StatusIcons row for TopBar"
```

---

## Task 9: TopBar — Tray component

**Files:**
- Create: `quickshell/caelestia/modules/topbar/components/Tray.qml`

- [ ] **Step 1: Create `Tray.qml`**

```qml
pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts

Row {
    id: root

    spacing: Appearance.spacing.small / 2
    visible: items.count > 0

    Repeater {
        id: items
        model: SystemTray.items

        delegate: Item {
            required property SystemTrayItem modelData

            width: 18
            height: 18

            CachingIconImage {
                anchors.fill: parent
                source: parent.modelData.icon
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: event => {
                    if (event.button === Qt.LeftButton)
                        parent.modelData.activate()
                    else
                        parent.modelData.secondaryActivate()
                }
            }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git -C ~/.local/share/caelestia add quickshell/caelestia/modules/topbar/components/Tray.qml
git -C ~/.local/share/caelestia commit -m "feat: add horizontal compact Tray for TopBar"
```

---

## Task 10: TopBar — PowerButton component

**Files:**
- Create: `quickshell/caelestia/modules/topbar/components/PowerButton.qml`

- [ ] **Step 1: Create `PowerButton.qml`**

```qml
import qs.components
import qs.services
import qs.config
import QtQuick

Item {
    id: root

    signal clicked()

    width: icon.implicitWidth + Appearance.padding.small * 2
    height: icon.implicitHeight + Appearance.padding.small * 2

    MaterialIcon {
        id: icon
        anchors.centerIn: parent
        text: "power_settings_new"
        color: Colours.palette.m3error
        font.pointSize: Appearance.font.size.normal
        font.bold: true
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
```

- [ ] **Step 2: Commit**

```bash
git -C ~/.local/share/caelestia add quickshell/caelestia/modules/topbar/components/PowerButton.qml
git -C ~/.local/share/caelestia commit -m "feat: add PowerButton component for TopBar"
```

---

## Task 11: TopBar — TopBar + TopBarWrapper

**Files:**
- Create: `quickshell/caelestia/modules/topbar/TopBar.qml`
- Create: `quickshell/caelestia/modules/topbar/TopBarWrapper.qml`

- [ ] **Step 1: Create `TopBar.qml`**

```qml
pragma ComponentBehavior: Bound

import qs.services
import qs.config
import qs.components
import "components"
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: root

    required property ShellScreen screen

    readonly property var hyprMonitor: Hypr.monitorFor(screen)
    // Hide bar when there's a fullscreen window on this monitor
    readonly property bool hasFullscreen: hyprMonitor?.activeWorkspace?.toplevels.values
        .some(t => t.lastIpcObject.fullscreen === 2) ?? false

    screen: root.screen
    WlrLayershell.namespace: "glass-topbar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors { top: true; left: true; right: true }
    margins { top: 10; left: 10; right: 10 }
    exclusiveZone: hasFullscreen ? 0 : height
    implicitHeight: 38

    // Slide out when fullscreen window active
    y: hasFullscreen ? -height : 0
    Behavior on y {
        Anim {
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    GlassRect {
        anchors.fill: parent

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Appearance.padding.normal
            anchors.rightMargin: Appearance.padding.normal
            spacing: Appearance.spacing.normal

            // OS icon — opens launcher on click
            Item {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                Layout.alignment: Qt.AlignVCenter

                ColouredIcon {
                    anchors.centerIn: parent
                    source: SysInfo.osLogo
                    implicitSize: Appearance.font.size.large
                    colour: Colours.palette.m3tertiary
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const vis = Visibilities.getForActive()
                        if (vis) vis.launcher = !vis.launcher
                    }
                }
            }

            Workspaces {
                Layout.alignment: Qt.AlignVCenter
                screen: root.screen
            }

            ActiveWindow {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: false
            }

            // Center spacer
            Item { Layout.fillWidth: true }

            Clock {
                Layout.alignment: Qt.AlignVCenter
            }

            // Right spacer
            Item { Layout.fillWidth: true }

            StatusIcons {
                Layout.alignment: Qt.AlignVCenter
            }

            Tray {
                Layout.alignment: Qt.AlignVCenter
            }

            PowerButton {
                Layout.alignment: Qt.AlignVCenter
                onClicked: {
                    const vis = Visibilities.getForActive()
                    if (vis) vis.session = !vis.session
                }
            }
        }
    }
}
```

- [ ] **Step 2: Create `TopBarWrapper.qml`**

```qml
import Quickshell
import QtQuick

// One TopBar per connected monitor — auto created/destroyed as monitors change
Variants {
    model: Quickshell.screens

    delegate: Component {
        TopBar {
            required property var modelData
            screen: modelData
        }
    }
}
```

- [ ] **Step 3: Commit**

```bash
git -C ~/.local/share/caelestia add quickshell/caelestia/modules/topbar/
git -C ~/.local/share/caelestia commit -m "feat: add TopBar and TopBarWrapper with glass PanelWindow"
```

---

## Task 12: shell.qml — load TopBar

**Files:**
- Modify: `quickshell/caelestia/shell.qml`

- [ ] **Step 1: Edit `shell.qml`**

```qml
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import "modules"
import "modules/drawers"
import "modules/background"
import "modules/areapicker"
import "modules/lock"
import "modules/topbar"
import Quickshell

ShellRoot {
    Background {}
    Drawers {}
    AreaPicker {}
    Lock {
        id: lock
    }

    Shortcuts {}
    BatteryMonitor {}
    IdleMonitors {
        lock: lock
    }

    TopBarWrapper {}
}
```

- [ ] **Step 2: Launch and verify TopBar**

```bash
qs -p ~/.local/share/caelestia/quickshell/caelestia
```

Expected:
- Floating horizontal bar at top with 10px margins
- Visible: workspaces for current monitor, active window title, clock, status icons, power button
- Blur effect on bar (frosted glass)
- Bar hides when a window goes fullscreen

```bash
qs -c caelestia
```

- [ ] **Step 3: Commit**

```bash
git -C ~/.local/share/caelestia add quickshell/caelestia/shell.qml
git -C ~/.local/share/caelestia commit -m "feat: load TopBarWrapper in shell.qml"
```

---

## Task 13: HotCorner — shared component

**Files:**
- Create: `quickshell/caelestia/modules/corner-notifs/HotCorner.qml`
- Create: `quickshell/caelestia/modules/corner-media/HotCorner.qml`

Both are identical except for the anchor corner. Create both.

- [ ] **Step 1: Create directories**

```bash
mkdir -p ~/.local/share/caelestia/quickshell/caelestia/modules/corner-notifs
mkdir -p ~/.local/share/caelestia/quickshell/caelestia/modules/corner-media
```

- [ ] **Step 2: Create `corner-notifs/HotCorner.qml`** (bottom-left)

```qml
import Quickshell
import Quickshell.Wayland
import QtQuick

// Invisible 20x20 trigger area anchored to bottom-left corner
PanelWindow {
    id: root

    signal triggered()
    signal released()

    WlrLayershell.namespace: "glass-hotcorner"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"

    anchors { bottom: true; left: true }
    // No exclusiveZone — does not push windows
    width: 20
    height: 20

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.triggered()
        onExited: root.released()
    }
}
```

- [ ] **Step 3: Create `corner-media/HotCorner.qml`** (bottom-right)

```qml
import Quickshell
import Quickshell.Wayland
import QtQuick

// Invisible 20x20 trigger area anchored to bottom-right corner
PanelWindow {
    id: root

    signal triggered()
    signal released()

    WlrLayershell.namespace: "glass-hotcorner"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"

    anchors { bottom: true; right: true }
    width: 20
    height: 20

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.triggered()
        onExited: root.released()
    }
}
```

- [ ] **Step 4: Commit**

```bash
git -C ~/.local/share/caelestia add quickshell/caelestia/modules/corner-notifs/HotCorner.qml quickshell/caelestia/modules/corner-media/HotCorner.qml
git -C ~/.local/share/caelestia commit -m "feat: add HotCorner components for bottom-left and bottom-right corners"
```

---

## Task 14: CornerNotifs — NotifCard

**Files:**
- Create: `quickshell/caelestia/modules/corner-notifs/NotifCard.qml`

- [ ] **Step 1: Create `NotifCard.qml`**

```qml
pragma ComponentBehavior: Bound

import qs.components
import qs.components.images
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

GlassRect {
    id: root

    required property Notifs.Notif modelData

    readonly property color urgencyColor: {
        switch (modelData.urgency) {
            case "critical": return Colours.palette.m3error
            case "normal":   return Colours.palette.m3primary
            default:         return Colours.palette.m3outline
        }
    }

    implicitHeight: layout.implicitHeight + Appearance.padding.normal * 2
    implicitWidth: parent?.width ?? 320

    // Left urgency stripe
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 2
        color: root.urgencyColor
    }

    RowLayout {
        id: layout

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Appearance.padding.normal
            leftMargin: Appearance.padding.normal + 4
        }
        spacing: Appearance.spacing.small

        // App icon
        CachingIconImage {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            Layout.alignment: Qt.AlignTop
            source: root.modelData.appIcon
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                text: root.modelData.summary
                elide: Text.ElideRight
                font.pointSize: Appearance.font.size.smaller
                color: Colours.palette.m3onSurface
            }

            StyledText {
                Layout.fillWidth: true
                visible: text.length > 0
                text: root.modelData.body
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.WordWrap
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }

        // Dismiss button
        MaterialIcon {
            Layout.alignment: Qt.AlignTop
            text: "close"
            font.pointSize: Appearance.font.size.small
            color: Colours.palette.m3outlineVariant

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.modelData.dismiss()
            }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git -C ~/.local/share/caelestia add quickshell/caelestia/modules/corner-notifs/NotifCard.qml
git -C ~/.local/share/caelestia commit -m "feat: add NotifCard component with urgency stripe and dismiss button"
```

---

## Task 15: CornerNotifsPanel

**Files:**
- Create: `quickshell/caelestia/modules/corner-notifs/CornerNotifsPanel.qml`

- [ ] **Step 1: Create `CornerNotifsPanel.qml`**

```qml
pragma ComponentBehavior: Bound

import qs.services
import qs.config
import qs.components
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: root

    property bool open: false

    WlrLayershell.namespace: "glass-corner-notifs"
    WlrLayershell.layer: open ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors { bottom: true; left: true }
    margins { bottom: 10; left: 10 }
    // No exclusiveZone — panels float above windows

    implicitWidth: open ? 320 : 0
    implicitHeight: Math.min(
        column.implicitHeight + Appearance.padding.normal * 2,
        screen.height * 0.4
    )

    visible: implicitWidth > 0
    color: "transparent"

    Behavior on implicitWidth {
        Anim {
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    GlassClippingRect {
        anchors.fill: parent

        ColumnLayout {
            id: column

            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: Appearance.padding.normal
            }
            spacing: Appearance.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Notifications")
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3outlineVariant
                font.capitalization: Font.AllUppercase
                letterSpacing: 1
            }

            Repeater {
                model: ScriptModel { values: Notifs.list.values.slice(0, 8) }

                NotifCard {
                    Layout.fillWidth: true
                    modelData: modelData
                }
            }

            // Empty state
            StyledText {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                visible: Notifs.list.values.length === 0
                text: qsTr("No notifications")
                font.pointSize: Appearance.font.size.smaller
                color: Colours.palette.m3outline
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git -C ~/.local/share/caelestia add quickshell/caelestia/modules/corner-notifs/CornerNotifsPanel.qml
git -C ~/.local/share/caelestia commit -m "feat: add CornerNotifsPanel with animated reveal and notification list"
```

---

## Task 16: CornerNotifsWrapper

**Files:**
- Create: `quickshell/caelestia/modules/corner-notifs/CornerNotifsWrapper.qml`

- [ ] **Step 1: Create `CornerNotifsWrapper.qml`**

```qml
import qs.components
import Quickshell
import QtQuick

// Orchestrates: LazyLoader for the panel + HotCorner + keybind + close timer
Item {
    id: root

    property bool open: false

    // Close delay after cursor leaves hot corner
    Timer {
        id: closeTimer
        interval: 500
        onTriggered: root.open = false
    }

    HotCorner {
        onTriggered: {
            closeTimer.stop()
            root.open = true
        }
        onReleased: closeTimer.restart()
    }

    // Keybind: Super+N — reuses $kbShowSidebar
    CustomShortcut {
        name: "showCornerNotifs"
        description: "Toggle corner notifications panel"
        // Bind in Hyprland keybinds.conf:
        // bind = Super, N, exec, qs-ipc shortcut showCornerNotifs
        onPressed: root.open = !root.open
    }

    LazyLoader {
        id: panelLoader
        loading: true  // preload in background immediately on shell start

        CornerNotifsPanel {
            open: root.open
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git -C ~/.local/share/caelestia add quickshell/caelestia/modules/corner-notifs/CornerNotifsWrapper.qml
git -C ~/.local/share/caelestia commit -m "feat: add CornerNotifsWrapper with LazyLoader, HotCorner and keybind"
```

---

## Task 17: shell.qml — load CornerNotifsWrapper

**Files:**
- Modify: `quickshell/caelestia/shell.qml`

- [ ] **Step 1: Add import and component**

```qml
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import "modules"
import "modules/drawers"
import "modules/background"
import "modules/areapicker"
import "modules/lock"
import "modules/topbar"
import "modules/corner-notifs"
import Quickshell

ShellRoot {
    Background {}
    Drawers {}
    AreaPicker {}
    Lock {
        id: lock
    }

    Shortcuts {}
    BatteryMonitor {}
    IdleMonitors {
        lock: lock
    }

    TopBarWrapper {}
    CornerNotifsWrapper {}
}
```

- [ ] **Step 2: Launch and test hot corner**

```bash
qs -p ~/.local/share/caelestia/quickshell/caelestia
```

Expected:
- Move cursor to bottom-left corner → notifications panel animates in
- Move cursor away → panel closes after 500ms delay
- Panel shows notification list or "No notifications"

```bash
qs -c caelestia
```

- [ ] **Step 3: Commit**

```bash
git -C ~/.local/share/caelestia add quickshell/caelestia/shell.qml
git -C ~/.local/share/caelestia commit -m "feat: load CornerNotifsWrapper in shell.qml"
```

---

## Task 18: CornerMedia — DailyLog

**Files:**
- Create: `quickshell/caelestia/modules/corner-media/DailyLog.qml`

- [ ] **Step 1: Create `DailyLog.qml`**

```qml
import qs.components
import qs.services
import qs.config
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    spacing: Appearance.spacing.small / 2

    StyledText {
        Layout.fillWidth: true
        text: Time.format("dddd d MMM").toLowerCase()
        font.pointSize: Appearance.font.size.small
        color: Colours.palette.m3outlineVariant
    }

    // Read daily log from ~/.local/share/caelestia/daily-log (one task per line)
    FileView {
        id: logFile
        path: `${StandardPaths.writableLocation(StandardPaths.HomeLocation)}/.local/share/caelestia/daily-log`
    }

    Repeater {
        model: logFile.text
            ? logFile.text.split("\n").filter(l => l.trim().length > 0).slice(0, 5)
            : []

        StyledText {
            required property var modelData
            Layout.fillWidth: true
            text: `→ ${modelData}`
            elide: Text.ElideRight
            font.pointSize: Appearance.font.size.small
            color: Colours.palette.m3onSurfaceVariant
        }
    }

    // Placeholder when no log file exists
    StyledText {
        Layout.fillWidth: true
        visible: !logFile.text || logFile.text.trim().length === 0
        text: qsTr("No tasks today")
        font.pointSize: Appearance.font.size.small
        color: Colours.palette.m3outline
        font.italic: true
    }
}
```

- [ ] **Step 2: Commit**

```bash
git -C ~/.local/share/caelestia add quickshell/caelestia/modules/corner-media/DailyLog.qml
git -C ~/.local/share/caelestia commit -m "feat: add DailyLog component reading from ~/.local/share/caelestia/daily-log"
```

---

## Task 19: CornerMedia — MediaInfo, MediaProgress, MediaControls

**Files:**
- Create: `quickshell/caelestia/modules/corner-media/MediaInfo.qml`
- Create: `quickshell/caelestia/modules/corner-media/MediaProgress.qml`
- Create: `quickshell/caelestia/modules/corner-media/MediaControls.qml`

- [ ] **Step 1: Create `MediaInfo.qml`**

```qml
import qs.services
import qs.components
import qs.components.images
import qs.config
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    spacing: Appearance.spacing.normal

    // Album art
    CachingImage {
        Layout.preferredWidth: 48
        Layout.preferredHeight: 48
        Layout.alignment: Qt.AlignVCenter
        source: Players.active?.trackCoverUrl ?? ""
        fillMode: Image.PreserveAspectCrop

        // Fallback icon when no cover art
        MaterialIcon {
            anchors.centerIn: parent
            visible: parent.source.toString().length === 0
            text: "music_note"
            color: Colours.palette.m3outline
            font.pointSize: Appearance.font.size.extraLarge
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        StyledText {
            Layout.fillWidth: true
            text: Players.active?.trackTitle ?? qsTr("Nothing playing")
            elide: Text.ElideRight
            font.pointSize: Appearance.font.size.smaller
            color: Colours.palette.m3onSurface
        }

        StyledText {
            Layout.fillWidth: true
            text: Players.active?.trackArtists?.join(", ") ?? ""
            elide: Text.ElideRight
            font.pointSize: Appearance.font.size.small
            color: Colours.palette.m3onSurfaceVariant
        }
    }
}
```

- [ ] **Step 2: Create `MediaProgress.qml`**

```qml
import qs.services
import qs.config
import QtQuick

Item {
    id: root

    implicitHeight: 3
    implicitWidth: parent?.width ?? 200

    // Track bar
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(1, 1, 1, 0.08)
        radius: 0
    }

    // Progress fill
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        radius: 0
        color: Colours.palette.m3primary

        readonly property real progress: {
            const active = Players.active
            return active?.length ? active.position / active.length : 0
        }
        width: parent.width * progress

        Behavior on width {
            Anim { duration: Appearance.anim.durations.large }
        }
        Behavior on color { CAnim {} }
    }
}
```

- [ ] **Step 3: Create `MediaControls.qml`**

```qml
import qs.services
import qs.components
import qs.config
import QtQuick
import QtQuick.Layouts

Row {
    id: root

    spacing: Appearance.spacing.normal

    MediaButton {
        text: "skip_previous"
        onClicked: Players.active?.previous()
    }

    MediaButton {
        text: Players.active?.isPlaying ? "pause" : "play_arrow"
        highlighted: true
        onClicked: Players.active?.togglePlaying()
    }

    MediaButton {
        text: "skip_next"
        onClicked: Players.active?.next()
    }

    component MediaButton: Item {
        id: btn

        property string text
        property bool highlighted: false
        signal clicked()

        width: highlighted ? 28 : 20
        height: highlighted ? 28 : 20

        Rectangle {
            anchors.fill: parent
            radius: 0
            color: parent.highlighted
                ? Qt.rgba(Colours.palette.m3primary.r, Colours.palette.m3primary.g, Colours.palette.m3primary.b, 0.2)
                : Qt.rgba(1, 1, 1, 0.06)
            border.color: parent.highlighted
                ? Qt.rgba(Colours.palette.m3primary.r, Colours.palette.m3primary.g, Colours.palette.m3primary.b, 0.3)
                : "transparent"
            border.width: 1
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: btn.text
            font.pointSize: Appearance.font.size.normal
            color: btn.highlighted ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            animate: true
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }
}
```

- [ ] **Step 4: Commit**

```bash
git -C ~/.local/share/caelestia add quickshell/caelestia/modules/corner-media/MediaInfo.qml quickshell/caelestia/modules/corner-media/MediaProgress.qml quickshell/caelestia/modules/corner-media/MediaControls.qml
git -C ~/.local/share/caelestia commit -m "feat: add MediaInfo, MediaProgress, MediaControls atomic components"
```

---

## Task 20: CornerMediaPanel + CornerMediaWrapper

**Files:**
- Create: `quickshell/caelestia/modules/corner-media/CornerMediaPanel.qml`
- Create: `quickshell/caelestia/modules/corner-media/CornerMediaWrapper.qml`

- [ ] **Step 1: Create `CornerMediaPanel.qml`**

```qml
import qs.services
import qs.config
import qs.components
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: root

    property bool open: false

    WlrLayershell.namespace: "glass-corner-media"
    WlrLayershell.layer: open ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors { bottom: true; right: true }
    margins { bottom: 10; right: 10 }

    implicitWidth: open ? 280 : 0
    implicitHeight: content.implicitHeight + Appearance.padding.large * 2

    visible: implicitWidth > 0
    color: "transparent"

    Behavior on implicitWidth {
        Anim {
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    GlassClippingRect {
        anchors.fill: parent

        ColumnLayout {
            id: content

            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: Appearance.padding.large
            }
            spacing: Appearance.spacing.normal

            StyledText {
                text: qsTr("Media")
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3outlineVariant
                font.capitalization: Font.AllUppercase
                letterSpacing: 1
            }

            MediaInfo { Layout.fillWidth: true }
            MediaProgress { Layout.fillWidth: true }
            MediaControls { Layout.alignment: Qt.AlignHCenter }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            StyledText {
                text: qsTr("Daily log")
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3outlineVariant
                font.capitalization: Font.AllUppercase
                letterSpacing: 1
            }

            DailyLog { Layout.fillWidth: true }
        }
    }
}
```

- [ ] **Step 2: Create `CornerMediaWrapper.qml`**

```qml
import qs.components
import Quickshell
import QtQuick

Item {
    id: root

    property bool open: false

    Timer {
        id: closeTimer
        interval: 500
        onTriggered: root.open = false
    }

    HotCorner {
        onTriggered: {
            closeTimer.stop()
            root.open = true
        }
        onReleased: closeTimer.restart()
    }

    // Keybind: Super+M — reuses $kbMusic
    CustomShortcut {
        name: "showCornerMedia"
        description: "Toggle corner media panel"
        onPressed: root.open = !root.open
    }

    LazyLoader {
        id: panelLoader
        loading: true

        CornerMediaPanel {
            open: root.open
        }
    }
}
```

- [ ] **Step 3: Commit**

```bash
git -C ~/.local/share/caelestia add quickshell/caelestia/modules/corner-media/CornerMediaPanel.qml quickshell/caelestia/modules/corner-media/CornerMediaWrapper.qml
git -C ~/.local/share/caelestia commit -m "feat: add CornerMediaPanel and CornerMediaWrapper"
```

---

## Task 21: shell.qml — load CornerMediaWrapper

**Files:**
- Modify: `quickshell/caelestia/shell.qml`

- [ ] **Step 1: Final shell.qml**

```qml
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import "modules"
import "modules/drawers"
import "modules/background"
import "modules/areapicker"
import "modules/lock"
import "modules/topbar"
import "modules/corner-notifs"
import "modules/corner-media"
import Quickshell

ShellRoot {
    Background {}
    Drawers {}
    AreaPicker {}
    Lock {
        id: lock
    }

    Shortcuts {}
    BatteryMonitor {}
    IdleMonitors {
        lock: lock
    }

    TopBarWrapper {}
    CornerNotifsWrapper {}
    CornerMediaWrapper {}
}
```

- [ ] **Step 2: Launch and test both corner panels**

```bash
qs -p ~/.local/share/caelestia/quickshell/caelestia
```

Expected:
- Bottom-left corner → notifications panel
- Bottom-right corner → media player + daily log panel
- Both animate on hover
- Media controls respond to player state

```bash
qs -c caelestia
```

- [ ] **Step 3: Commit**

```bash
git -C ~/.local/share/caelestia add quickshell/caelestia/shell.qml
git -C ~/.local/share/caelestia commit -m "feat: load CornerMediaWrapper — core glass shell complete"
```

---

## Task 22: Glass restyle — notification popups, OSD, session, launcher

**Files:**
- Modify: `quickshell/caelestia/modules/notifications/Background.qml`
- Modify: `quickshell/caelestia/modules/osd/Background.qml`
- Modify: `quickshell/caelestia/modules/session/Background.qml`
- Modify: `quickshell/caelestia/modules/launcher/Background.qml`

> All four files are `ShapePath` components with `fillColor: Colours.palette.m3surface`. Their rounding already derives from `Appearance.rounding.large` (now 0) via `Config.border.rounding`, so corners are already straight after Task 1. We only need to add transparency to `fillColor`.

- [ ] **Step 1: Edit `notifications/Background.qml` — add transparency**

Change `fillColor` from:
```qml
fillColor: Colours.palette.m3surface
```
to:
```qml
fillColor: Qt.rgba(
    Colours.palette.m3surface.r,
    Colours.palette.m3surface.g,
    Colours.palette.m3surface.b,
    Appearance.transparency.enabled ? 0.55 : 0.92
)
```

Add `import qs.config` to imports if not present.

- [ ] **Step 2: Edit `osd/Background.qml` — same change**

Same `fillColor` replacement as Step 1.

Add `import qs.config` to imports if not present.

- [ ] **Step 3: Edit `session/Background.qml` — same change**

Same `fillColor` replacement.

- [ ] **Step 4: Edit `launcher/Background.qml` — same change**

Same `fillColor` replacement.

- [ ] **Step 5: Launch and verify**

```bash
qs -p ~/.local/share/caelestia/quickshell/caelestia
```

Expected:
- OSD (change volume) → frosted glass bar, straight corners
- Notification popup → frosted glass card, straight corners
- Session menu (`Ctrl+Alt+Delete`) → frosted glass, straight corners
- Launcher → frosted glass, straight corners

```bash
qs -c caelestia
```

- [ ] **Step 6: Commit**

```bash
git -C ~/.local/share/caelestia add quickshell/caelestia/modules/notifications/Background.qml quickshell/caelestia/modules/osd/Background.qml quickshell/caelestia/modules/session/Background.qml quickshell/caelestia/modules/launcher/Background.qml
git -C ~/.local/share/caelestia commit -m "feat: apply glass transparency to notification popup, OSD, session, launcher backgrounds"
```

---

## Self-review

**Spec coverage check:**

| Spec requirement | Task |
|---|---|
| rounding → 0 globally | Task 1 |
| transparency → true | Task 1 |
| `Config.border.rounding` → 0 (via Appearance.rounding.large) | Task 1 (automatic) |
| GlassRect base component | Task 2 |
| GlassClippingRect base component | Task 2 |
| Hyprland blur layerrules by namespace | Task 3 |
| Disable old bar | Task 4 |
| TopBar: Variants multi-monitor | Task 11 (TopBarWrapper) |
| TopBar: exclusiveZone | Task 11 (TopBar.qml) |
| TopBar: WlrLayershell.namespace glass-topbar | Task 11 |
| TopBar: auto-hide on fullscreen | Task 11 |
| TopBar: Workspaces per-monitor | Task 5 |
| TopBar: Workspaces urgent badge | Task 5 |
| TopBar: ActiveWindow | Task 6 |
| TopBar: Clock | Task 7 |
| TopBar: StatusIcons | Task 8 |
| TopBar: Tray | Task 9 |
| TopBar: PowerButton | Task 10 |
| TopBar loaded in shell.qml | Task 12 |
| HotCorner (both) | Task 13 |
| CornerNotifs: NotifCard | Task 14 |
| CornerNotifs: Panel + reveal animation | Task 15 |
| CornerNotifs: LazyLoader + keybind | Task 16 |
| CornerNotifs loaded in shell.qml | Task 17 |
| DailyLog | Task 18 |
| MediaInfo (atomic) | Task 19 |
| MediaProgress (atomic) | Task 19 |
| MediaControls (atomic) | Task 19 |
| CornerMedia: Panel + WlrLayer.Overlay | Task 20 |
| CornerMedia: LazyLoader + keybind | Task 20 |
| CornerMedia loaded in shell.qml | Task 21 |
| Notification popup glass restyle | Task 22 |
| OSD glass restyle | Task 22 |
| Session glass restyle | Task 22 |
| Launcher glass restyle | Task 22 |
| Lock screen — out of scope for this plan | — |

> **Note on lock screen:** `lock/Center.qml` is a ColumnLayout (clock + input field), not a Background ShapePath. The lock screen background is handled by Hyprland's hyprlock or a separate component. Restyle deferred to a follow-up.

> **Note on PopupWindow for status icon popouts:** The spec mentions using `PopupWindow` for tray/status popouts. The existing popout system in `Drawers.qml` handles this via `panels.popouts`. Since we disabled the old bar but kept Drawers, the popout infrastructure is still loaded. The TopBar's status icons and tray don't have popouts in this plan — that's a phase 2 enhancement.

**No placeholders found.** All steps have complete code.

**Type consistency verified:** `GlassRect` and `GlassClippingRect` used consistently. `Notifs.Notif` type in NotifCard matches Caelestia's Notifs service API. `Players.active` used consistently across MediaInfo, MediaProgress, MediaControls.
