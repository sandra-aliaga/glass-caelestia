pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.config
import qs.services
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    readonly property string fallbackTodoPath: "/home/leeeen/cosas_libres/notas_u/notas_u/TODO_PROMPT.md"
    readonly property string legacyTodoPath: "/home/leeeen/cosas_libres/notas_u/notas_u/TODOs.md"
    readonly property string fallbackDescPath: "/home/leeeen/cosas_libres/notas_u/notas_u/Rutas_2026/Fases/Fase 0.md"
    property string rawText: ""
    property list<var> todos: []
    property string errorMessage: ""
    property string todoSourcePath: ""
    property string selectedTag: ""
    property string completionFilter: "all"
    property bool showSettings: false
    property string todoPathInput: ""
    property string descPathInput: ""
    readonly property string activeTodoPath: todoSourcePath || normalizePath(props.todoPath || fallbackTodoPath)

    readonly property int doneCount: todos.filter(t => t.checked).length
    readonly property var availableTags: {
        const list = [];
        for (const todo of todos) {
            for (const tag of (todo.tags || [])) {
                if (tag.length > 0 && !list.includes(tag))
                    list.push(tag);
            }
        }
        return list.sort();
    }
    readonly property var filteredTodos: {
        let result = todos;
        if (selectedTag)
            result = result.filter(t => (t.tags || []).includes(selectedTag));

        if (completionFilter === "open")
            result = result.filter(t => !t.checked);
        else if (completionFilter === "done")
            result = result.filter(t => t.checked);

        return result;
    }

    function extractTags(rawTask: string): var {
        let task = rawTask;
        const tags = [];
        let descPath = "";

        // Parse optional metadata blocks at the end:
        // [tags:os,networking] [desc:/path/to/note.md]
        while (true) {
            // Obsidian wikilink description:
            // [desc:[[Folder/Note]]]
            const wikiDesc = task.match(/\s*\[(desc|description|details|note):\s*\[\[([^\]|]+)(?:\|[^\]]+)?\]\]\]\s*$/i);
            if (wikiDesc) {
                task = task.slice(0, wikiDesc.index).trim();
                descPath = normalizeWikiPath(`[[${wikiDesc[2]}]]`);
                continue;
            }

            const block = task.match(/\s*\[([a-zA-Z_]+):([^\]]+)\]\s*$/);
            if (!block)
                break;

            task = task.slice(0, block.index).trim();

            const key = block[1].toLowerCase();
            const value = block[2].trim();

            if ((key === "tags" || key === "tag") && value.length > 0) {
                for (const part of value.split(/[,\s]+/)) {
                    const clean = part.trim().replace(/^#+/, "").toLowerCase();
                    if (clean.length > 0 && !tags.includes(clean))
                        tags.push(clean);
                }
            } else if ((key === "desc" || key === "description" || key === "details" || key === "note") && value.length > 0) {
                descPath = normalizeWikiPath(value.replace(/^["']|["']$/g, "").trim());
            }
        }

        // Inline hashtag tags: #os #networking
        const hashMatches = task.match(/#[^\s#\],]+/g) || [];
        for (const hashTag of hashMatches) {
            const clean = hashTag.slice(1).trim().toLowerCase();
            if (clean.length > 0 && !tags.includes(clean))
                tags.push(clean);
        }

        task = task.replace(/#[^\s#\],]+/g, "").replace(/\s{2,}/g, " ").trim();

        return {
            task: task,
            tags: tags,
            descPath: descPath || props.descPath || root.fallbackDescPath
        };
    }

    function parseTodos(text: string): void {
        const lines = text.split(/\r?\n/);
        const parsed = [];
        for (let i = 0; i < lines.length; i++) {
            const match = lines[i].match(/^(\s*[-*]\s\[( |x|X)\]\s*)(.*)$/);
            if (!match)
                continue;

            const extracted = extractTags(match[3].trim());

            parsed.push({
                lineNumber: i,
                checked: match[2].toLowerCase() === "x",
                text: extracted.task || qsTr("(empty TODO)"),
                tags: extracted.tags,
                descPath: extracted.descPath
            });
        }
        todos = parsed;
    }

    function normalizePath(path: string): string {
        if (!path)
            return "";
        const p = path.trim();
        if (p.startsWith("~"))
            return `${Quickshell.env("HOME")}${p.slice(1)}`;
        return p;
    }

    function parentDirectory(path: string): string {
        const idx = path.lastIndexOf("/");
        if (idx <= 0)
            return "";
        return path.slice(0, idx);
    }

    function resolvePathAgainst(path: string, baseFilePath: string): string {
        const target = normalizePath(path);
        if (!target)
            return "";
        if (target.startsWith("obsidian://") || target.startsWith("file://") || target.startsWith("/"))
            return target;

        const baseDir = parentDirectory(normalizePath(baseFilePath));
        if (baseDir.length > 0)
            return `${baseDir}/${target}`;
        return target;
    }

    function normalizeWikiPath(raw: string): string {
        let next = raw.trim();
        const wiki = next.match(/^\[\[([^\]|]+)(?:\|[^\]]+)?\]\]$/);
        if (wiki) {
            next = wiki[1].trim();
            if (!next.endsWith(".md"))
                next = `${next}.md`;
        }
        return next;
    }

    function extractTodoSource(text: string, controlFilePath: string): string {
        const lines = text.split(/\r?\n/);
        for (const line of lines) {
            const inlineMatch = line.match(/^\s*\[todo_source\s*:\s*(.+?)\]\s*$/i);
            const plainMatch = line.match(/^\s*todo_source\s*:\s*(.+?)\s*$/i);
            const match = inlineMatch || plainMatch;
            if (!match)
                continue;

            const value = normalizeWikiPath(match[1].replace(/^["']|["']$/g, "").trim());
            return resolvePathAgainst(value, controlFilePath);
        }
        return "";
    }

    function resolveOpenTarget(path: string): string {
        return resolvePathAgainst(path, activeTodoPath);
    }

    function toObsidianUri(path: string): string {
        const target = resolveOpenTarget(path);
        if (!target)
            return "";
        if (target.startsWith("obsidian://"))
            return target;

        let fsPath = target;
        if (fsPath.startsWith("file://")) {
            fsPath = fsPath.slice("file://".length);
            try {
                fsPath = decodeURIComponent(fsPath);
            } catch (err) {
            }
        }

        return `obsidian://open?path=${encodeURIComponent(fsPath)}`;
    }

    function applyPaths(): void {
        const nextTodo = normalizePath(todoPathInput);
        const nextDesc = normalizePath(descPathInput);

        if (!nextTodo) {
            errorMessage = qsTr("TODO path cannot be empty.");
            return;
        }

        props.todoPath = nextTodo;
        props.descPath = nextDesc || props.descPath || root.fallbackDescPath;
        todoSourcePath = "";
        errorMessage = "";
        storage.reload();
    }

    function resetPaths(): void {
        props.todoPath = Quickshell.env("CAELESTIA_TODO_PATH") || root.fallbackTodoPath;
        props.descPath = Quickshell.env("CAELESTIA_TODO_DESC_PATH") || root.fallbackDescPath;
        todoPathInput = props.todoPath;
        descPathInput = props.descPath;
        todoSourcePath = "";
        errorMessage = "";
        storage.reload();
    }

    function openDescription(path: string): void {
        const uri = toObsidianUri(path || props.descPath || root.fallbackDescPath);
        if (!uri) {
            Toaster.toast(qsTr("No description"), qsTr("This task has no linked description note."), "note_alt");
            return;
        }
        Quickshell.execDetached(["xdg-open", uri]);
    }

    function clearFilters(): void {
        selectedTag = "";
        completionFilter = "all";
    }

    function tagCount(tag: string): int {
        let count = 0;
        for (const todo of todos) {
            if ((todo.tags || []).includes(tag))
                count++;
        }
        return count;
    }

    function toggleTodo(lineNumber: int): void {
        const lines = rawText.split(/\r?\n/);
        if (lineNumber < 0 || lineNumber >= lines.length)
            return;

        const match = lines[lineNumber].match(/^(\s*[-*]\s\[)( |x|X)(\]\s*.*)$/);
        if (!match)
            return;

        const next = match[2].toLowerCase() === "x" ? " " : "x";
        lines[lineNumber] = `${match[1]}${next}${match[3]}`;

        const trailingNewline = rawText.endsWith("\n");
        const updated = lines.join("\n") + (trailingNewline ? "\n" : "");

        rawText = updated;
        parseTodos(updated);
        if (todoSourcePath.length > 0)
            sourceStorage.setText(updated);
        else
            storage.setText(updated);
    }

    implicitWidth: 840
    implicitHeight: Math.max(420, layout.implicitHeight)

    Component.onCompleted: {
        if (!props.todoPath || props.todoPath === legacyTodoPath)
            props.todoPath = Quickshell.env("CAELESTIA_TODO_PATH") || root.fallbackTodoPath;
        if (!props.descPath)
            props.descPath = Quickshell.env("CAELESTIA_TODO_DESC_PATH") || root.fallbackDescPath;

        showSettings = props.showSettings;
        todoPathInput = props.todoPath;
        descPathInput = props.descPath;
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Appearance.spacing.normal

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                text: qsTr("TODOs")
                color: Colours.palette.m3onSurface
                font.pointSize: Appearance.font.size.large
                font.weight: 650
            }

            Item {
                Layout.fillWidth: true
            }

            TextButton {
                text: root.showSettings ? qsTr("Hide settings") : qsTr("Settings")
                type: TextButton.Text
                onClicked: {
                    root.showSettings = !root.showSettings;
                    props.showSettings = root.showSettings;
                }
            }

            TextButton {
                text: qsTr("Reload")
                type: TextButton.Text
                onClicked: storage.reload()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            Flow {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                FilterChip {
                    tag: "all"
                    labelText: `${qsTr("All")} (${root.todos.length})`
                    selected: root.completionFilter === "all"
                    onClicked: root.completionFilter = "all"
                }

                FilterChip {
                    tag: "open"
                    labelText: `${qsTr("Open")} (${root.todos.filter(t => !t.checked).length})`
                    selected: root.completionFilter === "open"
                    onClicked: root.completionFilter = "open"
                }

                FilterChip {
                    tag: "done"
                    labelText: `${qsTr("Done")} (${root.doneCount})`
                    selected: root.completionFilter === "done"
                    onClicked: root.completionFilter = "done"
                }

                StyledText {
                    visible: root.availableTags.length > 0
                    text: "·"
                    color: Colours.palette.m3outline
                    font.pointSize: Appearance.font.size.small
                }

                FilterChip {
                    visible: root.availableTags.length > 0
                    tag: ""
                    labelText: qsTr("All tags")
                    selected: root.selectedTag.length === 0
                    onClicked: root.selectedTag = ""
                }

                Repeater {
                    model: root.availableTags

                    FilterChip {
                        required property var modelData

                        tag: modelData
                        labelText: `#${tag} (${root.tagCount(tag)})`
                        selected: root.selectedTag === tag
                        onClicked: root.selectedTag = root.selectedTag === tag ? "" : tag
                    }
                }
            }

            TextButton {
                visible: root.selectedTag.length > 0 || root.completionFilter !== "all"
                text: qsTr("Clear")
                type: TextButton.Text
                onClicked: root.clearFilters()
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: root.showSettings ? settingsCard.implicitHeight : 0
            opacity: root.showSettings ? 1 : 0
            clip: true
            visible: implicitHeight > 0 || opacity > 0

            Behavior on implicitHeight {
                Anim {}
            }

            Behavior on opacity {
                Anim {}
            }

            StyledRect {
                id: settingsCard

                anchors.left: parent.left
                anchors.right: parent.right

                implicitHeight: settingsLayout.implicitHeight + Appearance.padding.normal * 2
                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer
                border.width: 1
                border.color: Qt.alpha(Colours.palette.m3outline, 0.2)

                ColumnLayout {
                    id: settingsLayout

                    anchors.fill: parent
                    anchors.margins: Appearance.padding.normal
                    spacing: Appearance.spacing.small

                    StyledText {
                        Layout.fillWidth: true
                        text: root.activeTodoPath
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.smaller
                        elide: Text.ElideMiddle
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        StyledText {
                            text: qsTr("TODO file")
                            color: Colours.palette.m3onSurfaceVariant
                            font.pointSize: Appearance.font.size.smaller
                        }

                        StyledInputField {
                            Layout.fillWidth: true
                            text: root.todoPathInput
                            horizontalAlignment: TextInput.AlignLeft
                            onTextEdited: text => root.todoPathInput = text
                            onEditingFinished: root.applyPaths()
                        }

                        TextButton {
                            text: qsTr("Apply")
                            type: TextButton.Tonal
                            onClicked: root.applyPaths()
                        }

                        TextButton {
                            text: qsTr("Reset")
                            type: TextButton.Text
                            onClicked: root.resetPaths()
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        StyledText {
                            text: qsTr("Desc file")
                            color: Colours.palette.m3onSurfaceVariant
                            font.pointSize: Appearance.font.size.smaller
                        }

                        StyledInputField {
                            Layout.fillWidth: true
                            text: root.descPathInput
                            horizontalAlignment: TextInput.AlignLeft
                            onTextEdited: text => root.descPathInput = text
                            onEditingFinished: root.applyPaths()
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Control file: todo_source: [[path/to/todos]] • Tags: #tag or [tags:tag1,tag2] • Description: [desc:/path/to/note.md] or [desc:[[Note Path]]]")
                        color: Colours.palette.m3onSurfaceVariant
                        font.pointSize: Appearance.font.size.smaller
                    }
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: !!root.errorMessage
            text: root.errorMessage
            color: Colours.palette.m3error
            wrapMode: Text.Wrap
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: Appearance.rounding.large
            color: Colours.tPalette.m3surfaceContainer
            border.width: 1
            border.color: Qt.alpha(Colours.palette.m3outline, 0.15)
            clip: true

            Flickable {
                id: list

                property real wheelStep: Appearance.padding.large * 5.5

                function clampContentY(value: real): real {
                    return Math.max(0, Math.min(value, Math.max(0, contentHeight - height)));
                }

                function smoothScrollBy(delta: real): void {
                    const base = wheelAnim.running ? wheelAnim.to : contentY;
                    const target = clampContentY(base + delta);
                    wheelAnim.stop();
                    wheelAnim.from = contentY;
                    wheelAnim.to = target;
                    wheelAnim.start();
                }

                anchors.fill: parent
                anchors.margins: Appearance.padding.normal

                flickableDirection: Flickable.VerticalFlick
                boundsBehavior: Flickable.StopAtBounds
                boundsMovement: Flickable.StopAtBounds
                maximumFlickVelocity: 6500
                flickDeceleration: 2200

                contentWidth: width
                contentHeight: tasks.implicitHeight
                clip: true

                onMovementStarted: wheelAnim.stop()

                WheelHandler {
                    target: null
                    acceptedDevices: PointerDevice.Mouse

                    onWheel: event => {
                        const delta = event.angleDelta.y !== 0 ? (-event.angleDelta.y / 120) * list.wheelStep : -event.pixelDelta.y;
                        if (delta === 0)
                            return;
                        list.smoothScrollBy(delta);
                        event.accepted = true;
                    }
                }

                NumberAnimation {
                    id: wheelAnim

                    target: list
                    property: "contentY"
                    duration: 95
                    easing.type: Easing.OutCubic
                }

                ColumnLayout {
                    id: tasks

                    width: list.width
                    spacing: Appearance.spacing.small

                    Repeater {
                        model: root.filteredTodos

                        delegate: StyledRect {
                            id: row

                            required property var modelData

                            Layout.fillWidth: true
                            implicitHeight: Math.max(checkFrame.implicitHeight, textBlock.implicitHeight) + Appearance.padding.small * 2

                            radius: Appearance.rounding.normal
                            color: row.modelData.checked ? Qt.alpha(Colours.palette.m3secondaryContainer, 0.72) : Colours.tPalette.m3surfaceContainerLow
                            border.width: 1
                            border.color: row.modelData.checked ? Qt.alpha(Colours.palette.m3secondary, 0.3) : Qt.alpha(Colours.palette.m3outline, 0.12)

                            MouseArea {
                                id: mouse

                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.right: descButton.left
                                anchors.rightMargin: Appearance.spacing.small

                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.toggleTodo(row.modelData.lineNumber)
                            }

                            StyledRect {
                                anchors.fill: parent
                                radius: parent.radius
                                color: Colours.palette.m3onSurface
                                opacity: mouse.containsMouse ? 0.045 : 0

                                Behavior on opacity {
                                    Anim {}
                                }
                            }

                            StyledRect {
                                id: checkFrame

                                anchors.left: parent.left
                                anchors.leftMargin: Appearance.padding.normal
                                anchors.verticalCenter: parent.verticalCenter

                                implicitWidth: 24
                                implicitHeight: 24
                                radius: Appearance.rounding.full
                                color: row.modelData.checked ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3outlineVariant, 0.5)

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    text: row.modelData.checked ? "check" : "radio_button_unchecked"
                                    color: row.modelData.checked ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                                    font.pointSize: Appearance.font.size.normal
                                }
                            }

                            Column {
                                id: textBlock

                                anchors.left: checkFrame.right
                                anchors.right: descButton.left
                                anchors.leftMargin: Appearance.spacing.normal
                                anchors.rightMargin: Appearance.spacing.small
                                anchors.verticalCenter: parent.verticalCenter

                                spacing: Appearance.spacing.smaller

                                StyledText {
                                    width: parent.width
                                    text: row.modelData.text
                                    color: row.modelData.checked ? Colours.palette.m3onSurfaceVariant : Colours.palette.m3onSurface
                                    wrapMode: Text.Wrap
                                    font.strikeout: row.modelData.checked
                                }

                                Flow {
                                    width: parent.width
                                    spacing: Appearance.spacing.smaller
                                    visible: row.modelData.tags.length > 0

                                    Repeater {
                                        model: row.modelData.tags

                                        StyledRect {
                                            id: tagChip

                                            required property var modelData

                                            implicitWidth: tagLabel.implicitWidth + Appearance.padding.small * 2
                                            implicitHeight: tagLabel.implicitHeight + Appearance.padding.small
                                            radius: Appearance.rounding.full
                                            color: Qt.alpha(Colours.palette.m3tertiaryContainer, 0.8)

                                            StyledText {
                                                id: tagLabel

                                                anchors.centerIn: parent
                                                text: `#${tagChip.modelData}`
                                                color: Colours.palette.m3onTertiaryContainer
                                                font.pointSize: Appearance.font.size.smaller
                                            }
                                        }
                                    }
                                }
                            }

                            IconButton {
                                id: descButton

                                anchors.right: parent.right
                                anchors.rightMargin: Appearance.padding.small
                                anchors.verticalCenter: parent.verticalCenter

                                type: IconButton.Text
                                icon: "note_alt"
                                disabled: !row.modelData.descPath

                                onClicked: root.openDescription(row.modelData.descPath)
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: !root.errorMessage && root.filteredTodos.length === 0
                        spacing: Appearance.spacing.smaller

                        MaterialIcon {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.todos.length === 0 ? "inbox" : "filter_alt_off"
                            color: Colours.palette.m3outline
                            font.pointSize: Appearance.font.size.extraLarge
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: root.todos.length === 0 ? qsTr("No checklist TODOs found.\nUse lines like \"- [ ] task\" or \"- [x] task\" in your markdown file.") : qsTr("No tasks match current filters.")
                            color: Colours.palette.m3onSurfaceVariant
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }
        }
    }

    FileView {
        id: storage

        path: props.todoPath || root.fallbackTodoPath
        watchChanges: true

        onFileChanged: reload()
        onLoaded: {
            root.errorMessage = "";
            const controlPath = root.normalizePath(props.todoPath || root.fallbackTodoPath);
            const controlText = text();
            const sourcePath = root.extractTodoSource(controlText, controlPath);

            if (sourcePath.length > 0 && sourcePath !== controlPath) {
                root.todoSourcePath = sourcePath;
                sourceStorage.reload();
                return;
            }

            root.todoSourcePath = "";
            root.rawText = controlText;
            root.parseTodos(root.rawText);
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                root.errorMessage = qsTr("TODO file not found.");
            else
                root.errorMessage = qsTr("Failed to read TODO file: %1").arg(FileViewError.toString(err));

            root.todoSourcePath = "";
            root.rawText = "";
            root.todos = [];
        }
    }

    FileView {
        id: sourceStorage

        path: root.todoSourcePath
        watchChanges: true

        onFileChanged: reload()
        onLoaded: {
            root.errorMessage = "";
            root.rawText = text();
            root.parseTodos(root.rawText);
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                root.errorMessage = qsTr("Source TODO file not found.");
            else
                root.errorMessage = qsTr("Failed to read source TODO file: %1").arg(FileViewError.toString(err));

            root.rawText = "";
            root.todos = [];
        }
    }

    PersistentProperties {
        id: props

        property string todoPath
        property string descPath
        property bool showSettings: false

        reloadableId: "dashboardTodo"
    }

    component FilterChip: TextButton {
        required property string tag
        required property string labelText
        required property bool selected

        text: labelText
        type: TextButton.Tonal
        checked: selected
        toggle: false
        horizontalPadding: Appearance.padding.small
        verticalPadding: Appearance.padding.small / 2
    }
}
