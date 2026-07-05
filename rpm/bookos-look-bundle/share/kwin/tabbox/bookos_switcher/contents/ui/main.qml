/*
 BookOS Switcher — conmutador Alt+Tab.
 Basado en el layout big_icons de KWin (SPDX GPL-2.0-or-later, Martin Gräßlin),
 con dos cambios BookOS:
   · el icono va CENTRADO a su tamaño real dentro del tile, con aire uniforme,
     así los iconos de marca a-sangre (VSCode, Chromium…) no desbordan.
   · el SELECCIONADO (el actual del Alt+Tab) lleva un anillo sutil casi
     cuadrado, sin relleno, en vez del recuadro gris del tema.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kwin as KWin

KWin.TabBoxSwitcher {
    id: tabBox

    currentIndex: (instantiator.object as BigIconsDialog)?.currentIndex ?? currentIndex

    Instantiator {
        id: instantiator
        // instanciado UNA vez al cargar (no en cada Alt+Tab): apertura sin lag
        active: true
        delegate: BigIconsDialog { }
    }

    component BigIconsDialog: PlasmaCore.Dialog {
        property alias currentIndex: icons.currentIndex
        location: PlasmaCore.Types.Floating
        visible: tabBox.visible
        flags: Qt.Popup | Qt.X11BypassWindowManagerHint
        x: tabBox.screenGeometry.x + tabBox.screenGeometry.width * 0.5 - dialogMainItem.width * 0.5
        y: tabBox.screenGeometry.y + tabBox.screenGeometry.height * 0.5 - dialogMainItem.height * 0.5

        mainItem: ColumnLayout {
            id: dialogMainItem
            spacing: Kirigami.Units.smallSpacing * 2

            width: Math.min(Math.max(tabBox.screenGeometry.width * 0.3, icons.implicitWidth), tabBox.screenGeometry.width * 0.9)

            property int maxItemsPerRow: Math.floor(tabBox.screenGeometry.width * 0.9 / icons.delegateWidth)
            // icons.count (no model.rowCount()): rowCount() es llamada a función sin
            // notificación de cambio y se congelaba con el nº de ventanas del arranque
            property int actualItemsPerRow: Math.min(icons.count, maxItemsPerRow)

            property int gridViewWidth: Math.max(4, actualItemsPerRow) * icons.delegateWidth
            property int gridViewHeight: Math.ceil(icons.count / maxItemsPerRow) * icons.delegateHeight

            GridView {
                id: icons

                readonly property int iconSize: Kirigami.Units.iconSizes.huge
                // aire uniforme entre el icono y el borde del tile
                readonly property int iconPadding: Math.round(Kirigami.Units.iconSizes.huge * 0.18)
                readonly property int tileSize: iconSize + iconPadding * 2
                readonly property int delegateWidth: tileSize + Kirigami.Units.smallSpacing * 2
                readonly property int delegateHeight: tileSize + Kirigami.Units.smallSpacing * 2

                implicitWidth: dialogMainItem.actualItemsPerRow * delegateWidth
                implicitHeight: dialogMainItem.gridViewHeight
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: tabBox.screenGeometry.width * 0.9
                Layout.fillWidth: false
                Layout.fillHeight: true
                cellWidth: delegateWidth
                cellHeight: delegateHeight

                currentIndex: tabBox.currentIndex
                focus: true
                flow: GridView.LeftToRight
                keyNavigationWraps: true

                model: tabBox.model
                delegate: Item {
                    id: cell
                    property string caption: model.caption
                    width: icons.delegateWidth
                    height: icons.delegateHeight

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: icons.iconSize
                        height: icons.iconSize
                        source: model.icon
                        active: index == icons.currentIndex
                        Accessible.name: cell.caption
                    }

                    TapHandler {
                        onSingleTapped: {
                            if (index === icons.currentIndex) {
                                icons.model.activate(index);
                                return;
                            }
                            icons.currentIndex = index;
                        }
                        onDoubleTapped: icons.model.activate(index)
                    }
                }

                // Seleccionado estilo macOS Cmd+Tab: relleno neutro suave, SIN borde.
                highlight: Item {
                    width: icons.tileSize
                    height: icons.tileSize
                    Rectangle {
                        anchors.fill: parent
                        radius: width * 0.16
                        color: Qt.rgba(Kirigami.Theme.textColor.r,
                                       Kirigami.Theme.textColor.g,
                                       Kirigami.Theme.textColor.b, 0.12)
                        antialiasing: true
                    }
                }
                highlightMoveDuration: 0

                Kirigami.PlaceholderMessage {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: Math.round(captionLabel.height / 2)
                    width: parent.width - Kirigami.Units.largeSpacing * 2
                    icon.source: "edit-none"
                    text: i18ndc("kwin", "@info:placeholder no entries in the task switcher", "No open windows")
                    visible: icons.count === 0
                }

                boundsBehavior: Flickable.StopAtBounds
            }

            PlasmaComponents3.Label {
                id: captionLabel
                text: icons.currentItem ? icons.currentItem.caption : ""
                textFormat: Text.PlainText
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideMiddle
                font.weight: Font.Bold
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing
            }

            Connections {
                target: tabBox
                function onCurrentIndexChanged() {
                    icons.currentIndex = tabBox.currentIndex;
                }
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Up) {
                    icons.moveCurrentIndexUp()
                } else if (event.key === Qt.Key_Down) {
                    icons.moveCurrentIndexDown()
                } else if (event.key === Qt.Key_Left) {
                    icons.moveCurrentIndexLeft()
                } else if (event.key === Qt.Key_Right) {
                    icons.moveCurrentIndexRight()
                }
            }
        }

        onSceneGraphError: () => {}
    }
}
