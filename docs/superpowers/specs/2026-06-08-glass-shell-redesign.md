# Glass Shell Redesign

**Date:** 2026-06-08
**Branch:** `glass-theme` on `github.com/sandra-aliaga/glass-caelestia`

## Summary

Full visual redesign of the Quickshell/Caelestia shell toward a "liquid glass" style with straight edges, replacing the Material You rounded look. Caelestia's internal services are kept as-is; only the visual layer is replaced.

---

## Design decisions

| Element | Decision |
|---|---|
| Glass style | Frosted/acrylic with Material You dynamic tint (from wallpaper) + specular highlight |
| Borders | Straight (`radius: 0` globally) |
| Colors | Material You dynamic — glass tint updates with wallpaper |
| Bar | Floating horizontal top bar with 10px margin |
| Left panel | Notifications in bottom-left corner, hot corner + keybind |
| Right panel | Media player + daily log in bottom-right corner, hot corner + keybind |
| Full-round | `Appearance.rounding.full` (1000) kept only for circular avatars/images |

---

## Code style

These rules apply to every new file in this project.

- **One component per file.** Each `.qml` file exports exactly one visual or logical unit.
- **Atomic components.** A component does one thing. If it needs a label, a button, AND a progress bar, break it into sub-components.
- **No business logic in components.** Components receive data via properties and emit signals. Services and singletons own state.
- **English comments only.** Comment the *why*, not the *what*. One line max per comment block.
- **Property declarations at the top.** All `property` and `required property` declarations before any children.
- **Signals before handlers.** `signal` declarations before `on*` handlers.
- **File size limit:** keep files under ~100 lines. If a file grows past that, extract a sub-component.

---

## Architecture

### Strategy
Hybrid approach: reuse Caelestia services, replace the entire visual layer.

- **Keep:** `services/` (Audio, Notifs, Players, Network, Brightness, etc.), lock logic, session logic
- **Replace:** all visual modules (`bar/`, `sidebar/`, `drawers/`) and base components (`StyledRect`, `StyledClippingRect`)
- **New modules:** `topbar/`, `corner-notifs/`, `corner-media/`

### File structure

```
quickshell/caelestia/
├── shell.qml                          ← rewrite
├── components/
│   ├── GlassRect.qml                  ← new (replaces StyledRect)
│   ├── GlassClippingRect.qml          ← new (replaces StyledClippingRect)
│   └── [rest unchanged]
├── config/
│   └── AppearanceConfig.qml           ← rounding small/normal/large → 0
└── modules/
    ├── topbar/
    │   ├── TopBarWrapper.qml          ← Variants over Quickshell.screens (multi-monitor)
    │   ├── TopBar.qml                 ← single PanelWindow instance
    │   └── components/
    │       ├── OsIcon.qml             ← atomic: just the distro icon
    │       ├── Workspaces.qml         ← adapt from bar/components/workspaces/
    │       ├── ActiveWindow.qml       ← adapt from bar/components/ActiveWindow.qml
    │       ├── Clock.qml              ← adapt from bar/components/Clock.qml
    │       ├── StatusIcons.qml        ← adapt from bar/components/StatusIcons.qml
    │       ├── Tray.qml               ← adapt from bar/components/Tray.qml
    │       └── PowerButton.qml        ← atomic: just the power button
    ├── corner-notifs/
    │   ├── CornerNotifsWrapper.qml    ← LazyLoader + HotCorner orchestration
    │   ├── CornerNotifsPanel.qml      ← PanelWindow with the notifications list
    │   ├── NotifCard.qml              ← atomic: single notification card
    │   └── HotCorner.qml             ← small PanelWindow anchored to bottom-left
    ├── corner-media/
    │   ├── CornerMediaWrapper.qml     ← LazyLoader + HotCorner orchestration
    │   ├── CornerMediaPanel.qml       ← PanelWindow with media + daily log
    │   ├── MediaControls.qml          ← atomic: prev/play/next buttons
    │   ├── MediaProgress.qml          ← atomic: progress bar + timestamps
    │   ├── MediaInfo.qml              ← atomic: album art + title + artist
    │   ├── DailyLog.qml              ← adapt from sidebar/DailyLogCard.qml
    │   └── HotCorner.qml             ← small PanelWindow anchored to bottom-right
    ├── notifications/                 ← glass restyle only (Background.qml)
    ├── osd/                           ← glass restyle only (Background.qml)
    ├── lock/                          ← glass restyle (Center.qml, InputField.qml)
    └── [bar/, sidebar/, drawers/]     ← not loaded in shell.qml
```

---

## Quickshell patterns used

### Multi-monitor TopBar — `Variants`
`TopBarWrapper.qml` wraps the bar in `Variants { model: Quickshell.screens }` so one `TopBar` instance is created per connected monitor, created/destroyed automatically as monitors are added or removed.

```qml
// TopBarWrapper.qml
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

### Corner panels — `LazyLoader`
Each corner panel is wrapped in `LazyLoader { loading: true }` so it starts loading in the background immediately on shell start. By the time the user first triggers it (hover or keybind), it's ready with no jank.

```qml
// CornerNotifsWrapper.qml
LazyLoader {
    id: panelLoader
    loading: true  // preload in background

    CornerNotifsPanel {
        visible: panelLoader.active
    }
}
```

### Hot corners — small anchored `PanelWindow`
Each hot corner is a small (20×20px) `PanelWindow` anchored to its corner with no `exclusiveZone`. It contains a `MouseArea` with `hoverEnabled: true`. When entered, it signals the wrapper to reveal the panel.

```qml
// HotCorner.qml
PanelWindow {
    // No exclusiveZone — does not push windows away
    anchors { bottom: true; left: true }
    width: 20
    height: 20
    color: "transparent"

    signal triggered()
    signal released()

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: triggered()
        onExited: released()
    }
}
```

### `exclusiveZone` on TopBar
`TopBar.qml` sets `exclusiveZone` so compositor-managed windows don't cover the bar area.

```qml
PanelWindow {
    anchors { top: true; left: true; right: true }
    margins { top: 10; left: 10; right: 10 }
    exclusiveZone: height
    implicitHeight: 38
}
```

---

## Base component: GlassRect

Replaces `StyledRect` in all new modules. Does not touch the original to avoid breaking inherited modules.

```qml
// components/GlassRect.qml
Rectangle {
    // Dynamic tint from Material You palette, alpha from transparency config
    color: Qt.rgba(
        Colours.palette.m3surface.r,
        Colours.palette.m3surface.g,
        Colours.palette.m3surface.b,
        Appearance.transparency.enabled ? 0.55 : 0.92
    )
    radius: 0

    // Specular highlight — top edge catches light
    Rectangle {
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 1
        color: Qt.rgba(1, 1, 1, 0.28)
    }

    border.color: Qt.rgba(1, 1, 1, 0.1)
    border.width: 1

    Behavior on color { CAnim {} }
}
```

Blur comes from the compositor. Hyprland's `rules.conf` must have:
```
layerrule = blur, shell:quickshell
layerrule = ignorealpha 0.1, shell:quickshell
```
And `Appearance.transparency.enabled: true` must be set in the config.

---

## TopBar

**Position:** `anchors.top`, 10px margin top and sides.
**Height:** ~38px
**Exclusive zone:** yes — reserves space so windows don't go under the bar.

**Layout (left → right):**

```
[OS icon] [Workspaces] [Active window title]    [Clock]    [Status icons] [Tray] [Power]
```

- `OsIcon`: distro SVG from Caelestia's existing asset
- `Workspaces`: straight squares (`radius: 0`), active workspace tinted with `m3primary`
- `ActiveWindow`: text with elide, passive — no click
- `Clock`: positioned with absolute anchors (`anchors.centerIn: parent` on the bar row)
- `StatusIcons` + `Tray`: popouts on click (inherited from `bar/popouts/` with glass restyle)
- `PowerButton`: opens session menu

---

## Corner Notifs (bottom-left)

**Reveal:** hot corner (bottom-left, 20×20px) OR keybind `$kbShowSidebar` (`Super, N`) — reuses the sidebar keybind being removed.
**Behavior:** animates `width` 0 → content on hover or keybind. Closes when cursor leaves + 500ms delay.
**Size:** ~320px wide, dynamic height based on notification count (max ~40% screen height).

**Layout:**
```
┌─────────────────────────────┐  ← specular highlight (1px top)
│ NOTIFICATIONS               │
│ ┌──────────────────────────┐│
│ │ [icon] App title  • time ││  ← NotifCard (GlassRect)
│ │ Summary                  ││
│ └──────────────────────────┘│
│ ┌──────────────────────────┐│
│ │ [icon] App               ││
│ └──────────────────────────┘│
└─────────────────────────────┘
```

Each `NotifCard`: `GlassRect` with left border colored by urgency level, swipe-to-dismiss inherited from `sidebar/Notif.qml`.

---

## Corner Media (bottom-right)

**Reveal:** hot corner (bottom-right, 20×20px) OR keybind `$kbMusic` (`Super, M`) — reuses the music special workspace keybind being removed.
**Behavior:** animates `width` 0 → content on hover or keybind. Closes when cursor leaves + 500ms delay.
**Size:** ~280px wide, fixed height ~160px.

**Layout:**
```
┌────────────────────────────┐  ← specular highlight (1px top)
│ MEDIA                      │
│ [album art] Song title     │  ← MediaInfo
│             Artist name    │
│             ════════░░░░   │  ← MediaProgress
│         [⏮] [⏸] [⏭]      │  ← MediaControls
├────────────────────────────┤  ← divider line (1px, rgba white 0.08)
│ DAILY LOG                  │
│ Sunday 8 Jun               │  ← DailyLog
│ → Task 1                   │
└────────────────────────────┘
```

---

## Inherited modules — glass restyle only

Only `Background.qml` is modified in these: change `color` to `GlassRect` pattern, remove `radius`.

| Module | File to modify |
|---|---|
| Notification popup | `notifications/Background.qml` |
| OSD (volume/brightness) | `osd/Background.qml` |
| Session menu | `session/Background.qml` |
| Launcher | `launcher/Background.qml` |
| Lock screen | `lock/Center.qml`, `lock/InputField.qml` |

---

## Config changes

```qml
// config/AppearanceConfig.qml — Rounding
property int small: 0   // was 12
property int normal: 0  // was 17
property int large: 0   // was 25
property int full: 1000 // unchanged — circular avatars only

// config/AppearanceConfig.qml — Transparency
component Transparency: JsonObject {
    property bool enabled: true  // was false
    property real base: 0.55
    property real layers: 0.35
}
```

---

## New shell.qml

```qml
// Load only new modules + required inherited ones
import "modules/topbar"
import "modules/corner-notifs"
import "modules/corner-media"
import "modules/notifications"
import "modules/osd"
import "modules/lock"
import "modules/session"
import "modules/launcher"
import "modules/background"
import "modules/areapicker"

ShellRoot {
    Background {}
    TopBarWrapper {}
    CornerNotifsWrapper {}
    CornerMediaWrapper {}
    // Notifications popup, OSD, Lock, Session, Launcher, AreaPicker — inherited unchanged
}
```

Modules `bar/`, `sidebar/`, `drawers/`, `dashboard/`, `utilities/`, `windowinfo/`, `controlcenter/` are not loaded in this phase.

---

## Implementation sequence

1. `config/AppearanceConfig.qml` — rounding → 0, transparency → true
2. `components/GlassRect.qml` — new base component
3. `modules/topbar/` — TopBarWrapper + TopBar + all sub-components
4. `shell.qml` — load TopBar, remove bar/sidebar/drawers
5. `modules/corner-notifs/` — panel + hot corner + LazyLoader wrapper
6. `modules/corner-media/` — panel + hot corner + LazyLoader wrapper
7. Glass restyle on notifs popup, OSD, session, launcher, lock

---

## Out of scope for this phase

- Control center (Bluetooth, Network, Audio panes) — inherited without restyling
- Dashboard — not loaded
- Utilities (toggles, recorder) — not loaded
- Window info — not loaded
