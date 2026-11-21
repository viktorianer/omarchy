import QtQuick
import qs.Commons
import qs.Commons as Commons
import "KeypadModel.js" as KeypadModel

Item {
  id: root
  objectName: "lockKeypad"

  property string keyLayer: "digits"
  property bool shifted: false
  property int keyHeight: 56
  property int keySpacing: 8
  property int fontSize: Style.font.heading
  readonly property real unitWidth: (width + keySpacing) / KeypadModel.unitCount(keyLayer)

  signal tapped()
  signal typed(string text)
  signal erased()
  signal submitted()

  LayoutMirroring.enabled: false
  LayoutMirroring.childrenInherit: true

  implicitHeight: KeypadModel.ROW_COUNT * keyHeight + (KeypadModel.ROW_COUNT - 1) * keySpacing

  function press(key) {
    var result = KeypadModel.press(key, shifted)
    tapped()
    shifted = result.shifted
    if (result.layer) keyLayer = result.layer
    if (result.insert) typed(result.insert)
    else if (result.erase) erased()
    else if (result.submit) submitted()
  }

  onVisibleChanged: {
    keyLayer = "digits"
    shifted = false
  }

  Column {
    width: parent.width
    spacing: root.keySpacing

    Repeater {
      model: KeypadModel.rows(root.keyLayer)

      Row {
        id: keyRow
        required property var modelData
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: root.keySpacing

        Repeater {
          model: keyRow.modelData

          Rectangle {
            id: key
            required property string modelData
            width: KeypadModel.weight(modelData, root.keyLayer) * root.unitWidth - root.keySpacing
            height: root.keyHeight
            radius: Style.cornerRadius
            color: Commons.Color.lock.background
            border.color: Commons.Color.lock.placeholder
            border.width: 1

            Text {
              anchors.centerIn: parent
              textFormat: Text.PlainText
              text: KeypadModel.label(key.modelData, root.shifted)
              color: Commons.Color.lock.text
              font.family: Style.font.family
              font.pixelSize: root.fontSize
            }

            MouseArea {
              anchors.fill: parent
              onClicked: root.press(key.modelData)
            }
          }
        }
      }
    }
  }
}
