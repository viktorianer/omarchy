import QtQuick 2.15
import SddmComponents 2.0

Rectangle {
  id: root
  width: 640
  height: 480
  color: "#1a1b26"

  property string currentUser: userModel.lastUser
  property bool loginFailed: false
  property bool keypadShown: false
  property string keypadLayer: "digits"
  property bool keypadShifted: false
  readonly property int keyHeight: 56
  readonly property int keySpacing: 8
  readonly property var keypadRows: ({
    digits: [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], ["letters", "0", "backspace"], ["enter"]],
    letters: [["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"], ["a", "s", "d", "f", "g", "h", "j", "k", "l"], ["shift", "z", "x", "c", "v", "b", "n", "m", "backspace"], ["digits", "symbols", "space", "enter"]],
    symbols: [["!", "@", "#", "$", "%", "^", "&", "*", "(", ")"], ["-", "_", "=", "+", "[", "]", "{", "}", "\\", "|"], [";", ":", "'", "\"", ",", ".", "/", "?", "<", ">"], ["letters", "`", "~", "space", "backspace", "enter"]]
  })
  readonly property var keypadWeights: ({
    digits: { enter: 3 },
    letters: { shift: 1.5, backspace: 1.5, digits: 1.5, symbols: 1.5, space: 5, enter: 2 },
    symbols: { letters: 1.5, space: 3, backspace: 1.5, enter: 2 }
  })
  readonly property var keypadLabels: ({ letters: "ABC", digits: "123", symbols: "#+=", backspace: "\u{F0B5C}", enter: "\u{F0311}", shift: "\u{F0636}", space: "" })
  property int sessionIndex: {
    for (var i = 0; i < sessionModel.rowCount(); i++) {
      var name = (sessionModel.data(sessionModel.index(i, 0), Qt.DisplayRole) || "").toString()
      if (name.indexOf("uwsm") !== -1)
        return i
    }
    return sessionModel.lastIndex
  }

  function login() {
    sddm.login(root.currentUser, password.text, root.sessionIndex)
  }

  function keyWeight(key) {
    return root.keypadWeights[root.keypadLayer][key] || 1
  }

  function keyUnits() {
    var widest = 0
    var rows = root.keypadRows[root.keypadLayer]
    for (var r = 0; r < rows.length; r++) {
      var total = 0
      for (var k = 0; k < rows[r].length; k++) total += root.keyWeight(rows[r][k])
      widest = Math.max(widest, total)
    }
    return widest
  }

  function keyLabel(key) {
    if (root.keypadLabels.hasOwnProperty(key)) return root.keypadLabels[key]
    return root.keypadShifted ? key.toUpperCase() : key
  }

  function pressKey(key) {
    if (key === "backspace") {
      if (password.selectedText.length > 0) password.remove(password.selectionStart, password.selectionEnd)
      else if (password.cursorPosition > 0) password.remove(password.cursorPosition - 1, password.cursorPosition)
    } else if (key === "enter") {
      root.keypadShifted = false
      root.login()
    } else if (key === "shift") {
      root.keypadShifted = !root.keypadShifted
    } else if (key === "letters" || key === "digits" || key === "symbols") {
      root.keypadLayer = key
      root.keypadShifted = false
    } else {
      if (password.selectedText.length > 0) password.remove(password.selectionStart, password.selectionEnd)
      password.insert(password.cursorPosition, key === "space" ? " " : root.keyLabel(key))
      root.keypadShifted = false
    }
  }

  Connections {
    target: sddm
    function onLoginFailed() {
      root.loginFailed = true
      password.text = ""
      password.focus = true
    }
    function onLoginSucceeded() {
      root.loginFailed = false
    }
  }

  TapHandler {
    acceptedDevices: PointerDevice.TouchScreen
    onTapped: root.keypadShown = true
  }

  Column {
    anchors.centerIn: parent
    spacing: 40

    Image {
      id: logo
      readonly property real roomHeight: root.keypadShown ? root.height - entryRow.height - keypad.height - 3 * parent.spacing : Infinity
      source: "logo.png"
      width: Math.min(sourceSize.width, root.width * 0.8, sourceSize.height > 0 ? Math.max(0, roomHeight) * sourceSize.width / sourceSize.height : 0)
      height: sourceSize.width > 0 ? Math.round(width * sourceSize.height / sourceSize.width) : 0
      fillMode: Image.PreserveAspectFit
      anchors.horizontalCenter: parent.horizontalCenter
    }

    Row {
      id: entryRow
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 15

      Image {
        source: root.loginFailed ? "lock-failed.png" : "lock.png"
        width: 34
        height: 38
        fillMode: Image.PreserveAspectFit
        anchors.verticalCenter: parent.verticalCenter
      }

      Item {
        width: entry.width
        height: entry.height

        Image {
          id: entry
          source: root.loginFailed ? "entry-failed.png" : "entry.png"
          anchors.centerIn: parent
        }

        Row {
          anchors.left: parent.left
          anchors.leftMargin: 20
          anchors.verticalCenter: parent.verticalCenter
          spacing: 5

          Repeater {
            model: Math.min(password.text.length, 21)

            Image {
              source: "bullet.png"
              width: 7
              height: 7
            }
          }
        }

        TextInput {
          id: password
          anchors.fill: parent
          anchors.leftMargin: 20
          anchors.rightMargin: 20
          verticalAlignment: TextInput.AlignVCenter
          echoMode: TextInput.Password
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 24
          font.letterSpacing: 5
          passwordCharacter: "\u2022"
          color: "transparent"
          selectionColor: "transparent"
          selectedTextColor: "transparent"
          cursorDelegate: Item {}
          focus: true

          onTextChanged: root.loginFailed = false

          Keys.onPressed: {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
              root.login()
              event.accepted = true
            }
          }
        }
      }
    }

    Item {
      id: keypad
      objectName: "loginKeypad"
      visible: root.keypadShown
      width: Math.min(root.width - 48, root.keypadLayer !== "digits" ? 560 : entryRow.width)
      height: 5 * root.keyHeight + 4 * root.keySpacing
      anchors.horizontalCenter: parent.horizontalCenter
      LayoutMirroring.enabled: false
      LayoutMirroring.childrenInherit: true

      readonly property real unitWidth: (width + root.keySpacing) / root.keyUnits()

      Column {
        width: parent.width
        spacing: root.keySpacing

        Repeater {
          model: root.keypadRows[root.keypadLayer]

          Row {
            id: keyRow
            property var keys: modelData
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.keySpacing

            Repeater {
              model: keyRow.keys

              Item {
                id: key
                property string name: modelData
                width: root.keyWeight(name) * keypad.unitWidth - root.keySpacing
                height: root.keyHeight

                Rectangle {
                  anchors.fill: parent
                  color: "transparent"
                  border.color: "#ffffff"
                  border.width: 1
                  opacity: 0.35
                }

                Text {
                  anchors.centerIn: parent
                  textFormat: Text.PlainText
                  text: root.keyLabel(key.name)
                  color: "#ffffff"
                  font.family: "JetBrainsMono Nerd Font"
                  font.pixelSize: 22
                }

                MouseArea {
                  anchors.fill: parent
                  onClicked: root.pressKey(key.name)
                }
              }
            }
          }
        }
      }
    }
  }

  Component.onCompleted: password.forceActiveFocus()
}
