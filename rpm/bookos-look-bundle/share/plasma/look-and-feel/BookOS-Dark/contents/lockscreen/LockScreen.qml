/*
    BookOS Lock Screen — entry point loaded by KScreenLocker
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.5
import org.kde.plasma.private.sessions 2.0
import org.kde.breeze.components

Item {
    id: root
    property bool debug: false
    property string notification
    signal clearPassword()
    signal notificationRepeated()

    // KScreenLocker magic properties
    property bool viewVisible: false
    property bool suspendToRamSupported: false
    property bool suspendToDiskSupported: false

    // KScreenLocker magic signals
    signal suspendToDisk()
    signal suspendToRam()

    LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    implicitWidth: 800
    implicitHeight: 600

    LockScreenUi {
        anchors.fill: parent
    }
}
