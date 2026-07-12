import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

// BookOS OOBE — asistente de primer arranque (pantalla completa en cage).
ApplicationWindow {
    id: root
    visible: true
    visibility: Window.FullScreen
    color: "#101418"

    property int step: 0   // 0 bienvenida · 1 datos · 2 listo

    readonly property color accent: "#3daee9"
    readonly property color fg: "#eff0f1"
    readonly property color fgDim: "#9aa0a6"
    readonly property color cardBg: "#1a2026"

    component OobeField: ColumnLayout {
        property alias label: lbl.text
        property alias field: input
        spacing: 6
        Layout.fillWidth: true
        Label { id: lbl; color: root.fgDim; font.pixelSize: 14 }
        TextField {
            id: input
            Layout.fillWidth: true
            font.pixelSize: 17
            color: root.fg
            placeholderTextColor: root.fgDim
            background: Rectangle {
                color: "#232a31"
                radius: 8
                border.color: input.activeFocus ? root.accent : "#2e363e"
                border.width: 1
            }
            padding: 12
        }
    }

    component OobeButton: Button {
        id: btn
        font.pixelSize: 17
        contentItem: Text {
            text: btn.text
            color: btn.enabled ? "#ffffff" : root.fgDim
            font: btn.font
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: 10
            color: btn.enabled ? (btn.down ? Qt.darker(root.accent, 1.2) : root.accent)
                               : "#2e363e"
        }
        padding: 14
        leftPadding: 32
        rightPadding: 32
    }

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(560, parent.width - 80)
        height: content.implicitHeight + 80
        radius: 18
        color: root.cardBg
        border.color: "#2e363e"

        ColumnLayout {
            id: content
            anchors.centerIn: parent
            width: parent.width - 80
            spacing: 22

            // ── Paso 0: bienvenida ──────────────────────────────────────
            ColumnLayout {
                visible: root.step === 0
                spacing: 18
                Layout.fillWidth: true
                Image {
                    source: "/usr/share/pixmaps/bookos-install.svg"
                    sourceSize.width: 96
                    sourceSize.height: 96
                    Layout.alignment: Qt.AlignHCenter
                }
                Label {
                    text: "Bienvenido a BookOS"
                    color: root.fg
                    font.pixelSize: 30
                    font.weight: Font.DemiBold
                    Layout.alignment: Qt.AlignHCenter
                }
                Label {
                    text: "Vamos a preparar tu equipo en un momento."
                    color: root.fgDim
                    font.pixelSize: 16
                    Layout.alignment: Qt.AlignHCenter
                }
                OobeButton {
                    text: "Empezar"
                    Layout.alignment: Qt.AlignHCenter
                    onClicked: root.step = 1
                }
            }

            // ── Paso 1: usuario ─────────────────────────────────────────
            ColumnLayout {
                visible: root.step === 1
                spacing: 14
                Layout.fillWidth: true
                Label {
                    text: "Crea tu usuario"
                    color: root.fg
                    font.pixelSize: 24
                    font.weight: Font.DemiBold
                }
                OobeField {
                    id: fullName
                    label: "Tu nombre"
                    field.onTextEdited: {
                        // Sugerir usuario: primer nombre en minúsculas.
                        var s = field.text.trim().split(/\s+/)[0].toLowerCase()
                        userName.field.text = s.replace(/[^a-z0-9_-]/g, "")
                    }
                }
                OobeField { id: userName; label: "Nombre de usuario" }
                OobeField {
                    id: pass1
                    label: "Contraseña"
                    field.echoMode: TextInput.Password
                }
                OobeField {
                    id: pass2
                    label: "Repite la contraseña"
                    field.echoMode: TextInput.Password
                }
                OobeField {
                    id: hostName
                    label: "Nombre del equipo"
                    field.text: "bookos"
                }
                Label {
                    id: errorLabel
                    visible: text !== ""
                    color: "#e06c75"
                    font.pixelSize: 14
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
                OobeButton {
                    text: "Crear usuario"
                    Layout.alignment: Qt.AlignHCenter
                    enabled: userName.field.text.length > 0
                             && pass1.field.text.length > 0
                    onClicked: {
                        if (pass1.field.text !== pass2.field.text) {
                            errorLabel.text = "Las contraseñas no coinciden."
                            return
                        }
                        var err = backend.createUser(fullName.field.text,
                                                     userName.field.text,
                                                     pass1.field.text,
                                                     hostName.field.text)
                        if (err !== "") {
                            errorLabel.text = err
                        } else {
                            errorLabel.text = ""
                            root.step = 2
                        }
                    }
                }
            }

            // ── Paso 2: listo ───────────────────────────────────────────
            ColumnLayout {
                visible: root.step === 2
                spacing: 18
                Layout.fillWidth: true
                Label {
                    text: "¡Todo listo!"
                    color: root.fg
                    font.pixelSize: 30
                    font.weight: Font.DemiBold
                    Layout.alignment: Qt.AlignHCenter
                }
                Label {
                    text: "Tu usuario está creado. Ahora verás la pantalla de inicio de sesión."
                    color: root.fgDim
                    font.pixelSize: 16
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }
                OobeButton {
                    text: "Empezar a usar BookOS"
                    Layout.alignment: Qt.AlignHCenter
                    onClicked: Qt.quit()
                }
            }
        }
    }
}
