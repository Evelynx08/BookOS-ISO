// BookOS — isla dinámica del lockscreen (Live States).
// Lee el broker org.bookos.LiveStates (via `bookos-livestate get`, polling) y
// pinta pastillas: música (controles MPRIS), batería (relleno horizontal),
// rutina y timer. Click en música/rutina = abrir/cerrar detalle.
// Reglas BookOS: iconos SVG (bookbar-icons), nada de emojis; EN/ES; squircles.

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.plasma.plasma5support 2.0 as P5Support

Item {
    id: island

    property bool dark: true
    readonly property string lang: Qt.locale().name.indexOf("es") === 0 ? "es" : "en"
    function t(es, en) { return lang === "es" ? es : en }

    readonly property color cCard:   "#2c2b52"          // navy BookOS (igual en dark/light)
    readonly property color cText:   "#ffffff"
    readonly property color cSub:    "#b9b8d4"
    readonly property color cFill:   "#4a68d8"
    readonly property color cGood:   "#37c871"

    property var liveStates: ({})    // id -> objeto del broker
    property string expandedId: ""

    readonly property var order: Object.keys(liveStates).sort((a, b) => {
        const rank = id => id.indexOf("music") === 0 ? 0 : id === "battery" ? 2 : 1;
        return rank(a) - rank(b);
    })

    visible: order.length > 0
    implicitWidth: pillsRow.implicitWidth
    implicitHeight: pillsRow.implicitHeight

    // ---- transporte: broker via CLI + MPRIS via qdbus (una sola fuente exec) ----
    P5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: (source, data) => {
            if (source.indexOf("bookos-livestate get") === 0) {
                island.parseStates(data.stdout || "");
            }
            disconnectSource(source);
        }
    }
    Timer {
        interval: 2500; running: true; repeat: true; triggeredOnStart: true
        onTriggered: exec.connectSource("bookos-livestate get 2>/dev/null || \"$HOME/.local/bin/bookos-livestate\" get 2>/dev/null")
    }
    function parseStates(out) {
        const st = {};
        out.split("\n").forEach(line => {
            const sp = line.indexOf(" ");
            if (sp > 0) {
                try { st[line.substring(0, sp)] = JSON.parse(line.substring(sp + 1)); } catch (e) {}
            }
        });
        liveStates = st;
    }
    function mpris(player, method) {
        exec.connectSource("qdbus6 org.mpris.MediaPlayer2." + player
            + " /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player." + method);
    }

    // icono SVG colorizado (bookbar-icons son negros)
    component SvgIcon: Item {
        property string name
        property color tint: island.cText
        property real s: 16
        implicitWidth: s; implicitHeight: s
        Image {
            id: img; anchors.fill: parent; visible: false; smooth: true
            source: Qt.resolvedUrl("bookbar-icons/" + parent.name + ".svg")
            sourceSize.width: parent.s * 2; sourceSize.height: parent.s * 2
        }
        MultiEffect { anchors.fill: parent; source: img; colorization: 1.0; colorizationColor: parent.tint }
    }

    Row {
        id: pillsRow
        spacing: 10

        Repeater {
            model: island.order

            delegate: Rectangle {
                id: pill
                required property string modelData
                readonly property var st: island.liveStates[modelData] || ({})
                readonly property bool isMusic: (st.type || "") === "music"
                readonly property bool expanded: island.expandedId === modelData
                                                 && (isMusic || st.type === "routine")

                radius: 18
                color: island.cCard
                width: content.implicitWidth + 28
                height: expanded ? 96 : 40
                clip: true
                Behavior on width  { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                TapHandler {
                    onTapped: island.expandedId = pill.expanded ? "" : pill.modelData
                }

                ColumnLayout {
                    id: content
                    anchors.verticalCenter: expanded ? undefined : parent.verticalCenter
                    anchors.top: expanded ? parent.top : undefined
                    anchors.topMargin: expanded ? 10 : 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6

                    // ---- fila compacta (siempre visible) ----
                    RowLayout {
                        spacing: 8
                        Layout.alignment: Qt.AlignHCenter

                        // música: carátula mini o icono play
                        Item {
                            visible: pill.isMusic
                            implicitWidth: 22; implicitHeight: 22
                            Rectangle {
                                anchors.fill: parent; radius: 6
                                color: "#454379"; visible: art.status !== Image.Ready
                            }
                            Image {
                                id: art; anchors.fill: parent
                                source: pill.st.artUrl || ""
                                fillMode: Image.PreserveAspectCrop
                                layer.enabled: true
                                layer.effect: MultiEffect { maskEnabled: true; maskSource: artMask }
                            }
                            Rectangle { id: artMask; anchors.fill: parent; radius: 6; visible: false }
                        }

                        // batería: cápsula con relleno horizontal
                        Item {
                            visible: (pill.st.type || "") === "battery"
                            implicitWidth: 34; implicitHeight: 16
                            Rectangle {
                                anchors.fill: parent; radius: 8
                                color: "transparent"; border.color: island.cSub; border.width: 1.5
                            }
                            Rectangle {
                                anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                                anchors.margins: 3
                                width: Math.max(4, (parent.width - 6) * (pill.st.level || 0) / 100)
                                radius: 5
                                color: (pill.st.level || 0) <= 20 && !pill.st.plugged ? "#e5484d" : island.cGood
                            }
                            SvgIcon {
                                visible: !!pill.st.plugged
                                anchors.centerIn: parent
                                name: "charging"; s: 11
                            }
                        }

                        SvgIcon {
                            visible: pill.isMusic
                            name: pill.st.playing ? "pause" : "play"; s: 13
                            opacity: 0.9
                        }

                        Text {
                            color: island.cText
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            Layout.maximumWidth: 210
                            text: {
                                const st = pill.st;
                                switch (st.type) {
                                case "music":   return (st.title || island.t("Reproduciendo", "Now playing"))
                                                     + (st.artist ? " · " + st.artist : "");
                                case "battery": return (st.level || 0) + "%"
                                                     + (st.plugged && st.minsToFull ? " · " + st.minsToFull + " min" : "");
                                case "routine": return st.name || island.t("Rutina", "Routine");
                                case "timer":   return (st.title ? st.title + " · " : "")
                                                     + (st.remaining !== undefined
                                                        ? Math.ceil(st.remaining / 60) + " min" : "Timer");
                                default:        return st.title || pill.modelData;
                                }
                            }
                        }
                    }

                    // ---- detalle expandido ----
                    RowLayout {
                        visible: pill.expanded && pill.isMusic
                        spacing: 18
                        Layout.alignment: Qt.AlignHCenter

                        SvgIcon {
                            name: "previous-track"; s: 18
                            opacity: pill.st.canGoPrevious === false ? 0.35 : 1
                            TapHandler { onTapped: island.mpris(pill.st.player, "Previous") }
                        }
                        SvgIcon {
                            name: pill.st.playing ? "pause" : "play"; s: 24
                            TapHandler { onTapped: island.mpris(pill.st.player, "PlayPause") }
                        }
                        SvgIcon {
                            name: "next-track"; s: 18
                            opacity: pill.st.canGoNext === false ? 0.35 : 1
                            TapHandler { onTapped: island.mpris(pill.st.player, "Next") }
                        }
                    }
                    Text {
                        visible: pill.expanded && pill.st.type === "routine"
                        Layout.alignment: Qt.AlignHCenter
                        color: island.cSub
                        font.pixelSize: 12
                        text: (pill.st.started ? island.t("Desde ", "Since ") + pill.st.started : "")
                              + (pill.st.finish ? " · " + island.t("hasta ", "until ") + pill.st.finish : "")
                              + (pill.st.objective ? " · " + pill.st.objective : "")
                    }
                }
            }
        }
    }
}
