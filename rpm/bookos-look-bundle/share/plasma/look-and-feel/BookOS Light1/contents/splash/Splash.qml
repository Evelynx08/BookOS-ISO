import QtQuick 2.15

Rectangle {
    id: root
    color: "#000000"

    property int stage

    onStageChanged: {
        if (stage == 1) {
            fadeIn.start()
        }
    }

    Item {
        anchors.centerIn: parent
        width: Math.round(root.width * 0.28)
        height: childrenRect.height

        Image {
            id: logo
            source: "images/logo.png"
            sourceSize.width: Math.round(root.width * 0.28)
            sourceSize.height: Math.round(root.width * 0.28)
            width: sourceSize.width
            height: sourceSize.height
            smooth: true
            antialiasing: true
            mipmap: true
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: 0

            NumberAnimation on opacity {
                id: fadeIn
                from: 0; to: 1
                duration: 600
                easing.type: Easing.OutCubic
                running: false
            }
        }

        // Windows-style spinner: arco rotando continuo
        Item {
            id: spinner
            width: Math.round(root.width * 0.05)
            height: width
            anchors.top: logo.bottom
            anchors.topMargin: Math.round(root.height * 0.05)
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: 0

            NumberAnimation on opacity {
                from: 0; to: 1
                duration: 800
                easing.type: Easing.OutCubic
                running: fadeIn.running
            }

            Canvas {
                id: arc
                anchors.fill: parent
                property real rotationAngle: 0
                property real strokeW: Math.max(2, Math.round(width * 0.09))

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    var cx = width / 2
                    var cy = height / 2
                    var r = (width / 2) - strokeW
                    ctx.lineWidth = strokeW
                    ctx.lineCap = "round"

                    // base ring (faint)
                    ctx.strokeStyle = "rgba(255,255,255,0.10)"
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, 0, Math.PI * 2)
                    ctx.stroke()

                    // moving arc
                    ctx.strokeStyle = "#0a84ff"
                    ctx.beginPath()
                    var start = (rotationAngle - 90) * Math.PI / 180
                    var end = start + Math.PI * 0.55
                    ctx.arc(cx, cy, r, start, end)
                    ctx.stroke()
                }

                onRotationAngleChanged: requestPaint()

                NumberAnimation on rotationAngle {
                    from: 0; to: 360
                    duration: 1100
                    loops: Animation.Infinite
                    running: true
                }
            }
        }
    }

    Text {
        text: "Powered by KDE Plasma and Fedora"
        color: "#8e8e93"
        font.pixelSize: Math.round(root.width * 0.010)
        font.family: "SF Pro Text, -apple-system, Inter, Segoe UI, sans-serif"
        font.weight: Font.Normal
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: Math.round(root.width * 0.020)
        anchors.bottomMargin: Math.round(root.height * 0.025)
        opacity: 0

        NumberAnimation on opacity {
            from: 0; to: 0.8
            duration: 1200
            easing.type: Easing.OutCubic
            running: fadeIn.running
        }
    }
}
