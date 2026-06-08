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

    property string docsPath: "/home/leeeen/.config/vim/README.md"
    property string docsText: ""
    property string docsHtml: ""
    property string errorMessage: ""

    implicitWidth: 840
    implicitHeight: 500

    function escapeHtml(value: string): string {
        return (value || "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#39;");
    }

    function inlineMarkdown(value: string): string {
        let text = value || "";
        const codeTokens = [];

        text = text.replace(/`([^`]+)`/g, (_, code) => {
            codeTokens.push(code);
            return `@@CODE_${codeTokens.length - 1}@@`;
        });

        text = escapeHtml(text);
        text = text.replace(/\[([^\]]+)\]\(([^)]+)\)/g, "<a href=\"$2\">$1</a>");
        text = text.replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>");
        text = text.replace(/__([^_]+)__/g, "<strong>$1</strong>");
        text = text.replace(/\*([^*]+)\*/g, "<em>$1</em>");
        text = text.replace(/_([^_]+)_/g, "<em>$1</em>");

        for (let i = 0; i < codeTokens.length; i++)
            text = text.replace(`@@CODE_${i}@@`, `<code>${escapeHtml(codeTokens[i])}</code>`);

        return text;
    }

    function renderMarkdown(markdown: string): string {
        const lines = (markdown || "").split(/\r?\n/);
        const html = [];

        let inCode = false;
        let listType = "";

        function closeList() {
            if (!listType)
                return;
            html.push(listType === "ul" ? "</ul>" : "</ol>");
            listType = "";
        }

        for (const rawLine of lines) {
            const line = rawLine !== undefined && rawLine !== null ? rawLine : "";

            if (/^```/.test(line)) {
                closeList();
                if (!inCode) {
                    html.push("<pre><code>");
                    inCode = true;
                } else {
                    html.push("</code></pre>");
                    inCode = false;
                }
                continue;
            }

            if (inCode) {
                html.push(`${escapeHtml(line)}\n`);
                continue;
            }

            const heading = line.match(/^(#{1,6})\s+(.+)$/);
            if (heading) {
                closeList();
                const level = heading[1].length;
                html.push(`<h${level}>${inlineMarkdown(heading[2].trim())}</h${level}>`);
                continue;
            }

            const unordered = line.match(/^\s*[-*]\s+(.+)$/);
            if (unordered) {
                if (listType !== "ul") {
                    closeList();
                    html.push("<ul>");
                    listType = "ul";
                }
                html.push(`<li>${inlineMarkdown(unordered[1].trim())}</li>`);
                continue;
            }

            const ordered = line.match(/^\s*\d+\.\s+(.+)$/);
            if (ordered) {
                if (listType !== "ol") {
                    closeList();
                    html.push("<ol>");
                    listType = "ol";
                }
                html.push(`<li>${inlineMarkdown(ordered[1].trim())}</li>`);
                continue;
            }

            if (/^\s*$/.test(line)) {
                closeList();
                html.push("<p class=\"spacer\"></p>");
                continue;
            }

            closeList();
            html.push(`<p>${inlineMarkdown(line.trim())}</p>`);
        }

        closeList();
        if (inCode)
            html.push("</code></pre>");

        return `<html><head><style>
            body {
                margin: 0;
                padding: 0;
                color: ${Colours.palette.m3onSurface};
                font-family: "${Appearance.font.family.sans}";
                font-size: ${Appearance.font.size.normal + 1}px;
                line-height: 1.58;
            }
            h1, h2, h3, h4, h5, h6 {
                margin: 0 0 8px 0;
                color: ${Colours.palette.m3onSurface};
            }
            h1 { font-size: ${Appearance.font.size.extraLarge}px; }
            h2 { font-size: ${Appearance.font.size.large}px; }
            h3 { font-size: ${Appearance.font.size.normal}px; }
            p { margin: 0 0 8px 0; color: ${Colours.palette.m3onSurfaceVariant}; }
            p.spacer { margin: 0 0 10px 0; }
            ul, ol { margin: 0 0 10px 20px; padding: 0; color: ${Colours.palette.m3onSurfaceVariant}; }
            li { margin: 0 0 4px 0; }
            code {
                font-family: "${Appearance.font.family.mono}";
                background: ${Qt.alpha(Colours.palette.m3secondaryContainer, 0.55)};
                color: ${Colours.palette.m3onSecondaryContainer};
                padding: 1px 4px;
                border-radius: 6px;
            }
            pre {
                margin: 0 0 12px 0;
                white-space: pre-wrap;
                border-radius: 10px;
                border: 1px solid ${Qt.alpha(Colours.palette.m3outline, 0.2)};
                padding: 10px;
                background: ${Qt.alpha(Colours.palette.m3surfaceContainerHigh, 0.7)};
            }
            pre code {
                background: transparent;
                padding: 0;
                color: ${Colours.palette.m3onSurface};
            }
            a {
                color: ${Colours.palette.m3primary};
                text-decoration: none;
            }
            a:hover {
                text-decoration: underline;
            }
        </style></head><body>${html.join("")}</body></html>`;
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Appearance.spacing.normal

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                text: qsTr("Docs")
                color: Colours.palette.m3onSurface
                font.pointSize: Appearance.font.size.large
                font.weight: 650
            }

            Item {
                Layout.fillWidth: true
            }

            TextButton {
                text: qsTr("Open file")
                type: TextButton.Text
                onClicked: Quickshell.execDetached(["xdg-open", root.docsPath])
            }

            TextButton {
                text: qsTr("Reload")
                type: TextButton.Text
                onClicked: docsStorage.reload()
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: root.docsPath
            color: Colours.palette.m3outline
            font.pointSize: Appearance.font.size.smaller
            elide: Text.ElideMiddle
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
                id: view

                property real wheelStep: Appearance.padding.large * 11
                property real pixelStepMult: 3.2

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
                maximumFlickVelocity: 9800
                flickDeceleration: 1650

                contentWidth: width
                contentHeight: docText.implicitHeight
                clip: true

                onMovementStarted: wheelAnim.stop()

                WheelHandler {
                    target: null
                    acceptedDevices: PointerDevice.Mouse

                    onWheel: event => {
                        let delta = 0;
                        if (event.pixelDelta.y !== 0)
                            delta = -event.pixelDelta.y * view.pixelStepMult;
                        else if (event.angleDelta.y !== 0)
                            delta = (-event.angleDelta.y / 120) * view.wheelStep;

                        if (delta === 0)
                            return;
                        view.smoothScrollBy(delta);
                        event.accepted = true;
                    }
                }

                NumberAnimation {
                    id: wheelAnim

                    target: view
                    property: "contentY"
                    duration: 52
                    easing.type: Easing.OutCubic
                }

                Text {
                    id: docText

                    width: view.width
                    text: root.docsHtml
                    textFormat: Text.RichText
                    color: Colours.palette.m3onSurface
                    wrapMode: Text.Wrap
                    onLinkActivated: link => Quickshell.execDetached(["xdg-open", link])
                }
            }
        }
    }

    FileView {
        id: docsStorage

        path: root.docsPath
        watchChanges: true

        onFileChanged: reload()
        onLoaded: {
            root.errorMessage = "";
            root.docsText = text();
            root.docsHtml = root.renderMarkdown(root.docsText);
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                root.errorMessage = qsTr("Docs file not found.");
            else
                root.errorMessage = qsTr("Failed to read docs file: %1").arg(FileViewError.toString(err));

            root.docsText = "";
            root.docsHtml = "";
        }
    }
}
