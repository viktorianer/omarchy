import QtQuick
import Quickshell
import qs.Commons

ShellRoot {
  id: root

  readonly property string resultPath: Quickshell.env("OMARCHY_QML_TEST_RESULT")
  readonly property string rootPath: Quickshell.env("OMARCHY_PATH")
  property var failures: []

  function fail(message) {
    failures.push(String(message))
  }

  function assertTrue(condition, message) {
    if (!condition) fail(message)
  }

  function assertEqual(actual, expected, message) {
    if (actual !== expected) fail(message + ": expected " + JSON.stringify(expected) + ", got " + JSON.stringify(actual))
  }

  function shellQuote(value) {
    return "'" + String(value).replace(/'/g, "'\\''") + "'"
  }

  function writeResult() {
    var payload = JSON.stringify({
      ok: failures.length === 0,
      failures: failures
    })

    if (resultPath) {
      Quickshell.execDetached(["bash", "-lc", "printf '%s' " + shellQuote(payload) + " > " + shellQuote(resultPath)])
    }
  }

  function findByObjectName(node, name) {
    if (!node) return null
    if (node.objectName === name) return node
    var kids = node.children || []
    for (var i = 0; i < kids.length; i++) {
      var found = findByObjectName(kids[i], name)
      if (found) return found
    }
    return null
  }

  function pressAll(keypad, keys) {
    for (var i = 0; i < keys.length; i++) keypad.press(keys[i])
  }

  Item { id: host; width: 800; height: 600 }

  Timer {
    interval: 1
    running: true
    repeat: false
    onTriggered: {
      try {
        var component = Qt.createComponent("file://" + root.rootPath + "/shell/plugins/lock/LockView.qml", Component.PreferSynchronous)
        if (component.status !== Component.Ready) {
          root.fail("LockView failed to load: " + component.errorString())
          return
        }

        var view = component.createObject(host, { width: 800, height: 600, loadBackground: false })
        if (!view) {
          root.fail("LockView failed to instantiate: " + component.errorString())
          return
        }

        var keypad = root.findByObjectName(view, "lockKeypad")
        root.assertTrue(keypad !== null, "the lock view holds a keypad")
        if (!keypad) return

        root.assertTrue(!keypad.visible, "the keypad stays hidden unless shell.json turns it on")

        var submitted = []
        var wakes = 0
        view.passwordTextEdited.connect(function(password) { view.passwordText = password })
        view.submitPassword.connect(function(password) { submitted.push(password) })
        view.wakeRequested.connect(function() { wakes++ })

        view.keypadEnabled = true
        root.assertTrue(keypad.visible, "the keypad shows once shell.json turns it on")
        root.assertTrue(keypad.enabled, "the keypad takes taps while the lock waits for a password")

        root.pressAll(keypad, ["1", "2", "3", "backspace", "4"])
        root.assertEqual(view.passwordText, "124", "digits type into the password field and backspace erases one")
        root.assertTrue(wakes >= 5, "every tap wakes the display, got " + wakes)

        root.pressAll(keypad, ["letters", "shift", "a", "b", "space", "digits", "9"])
        root.assertEqual(view.passwordText, "124Ab 9", "shift capitalises one letter and the layers switch back")

        view.passwordText = ""
        root.pressAll(keypad, ["letters", "symbols", "!", "\\", "\"", "letters", "x"])
        root.assertEqual(view.passwordText, "!\\\"x", "the symbols layer types punctuation and switches back to letters")

        var input = root.findByObjectName(view, "lockPasswordInput")
        root.assertTrue(input !== null, "the lock view holds its password field")
        if (input) {
          input.selectAll()
          keypad.press("7")
          root.assertEqual(view.passwordText, "7", "a tap replaces selected text, as a typed key does")
          view.passwordText = "78"
          input.selectAll()
          keypad.press("backspace")
          root.assertEqual(view.passwordText, "", "backspace erases selected text, as the key does")
        }

        var clears = 0
        view.clearFailureRequested.connect(function() { clears++ })
        view.failureMessage = "Wrong password"
        view.passwordText = ""
        keypad.press("5")
        root.assertEqual(view.passwordText, "5", "a tap after a failure starts a new password")
        root.assertEqual(clears, 1, "the first tap after a failure clears the failure message")

        keypad.press("enter")
        root.assertEqual(submitted.length, 1, "enter submits once")
        root.assertEqual(submitted[0], "5", "enter submits the typed password")
        root.assertEqual(view.passwordText, "", "submitting clears the field")

        keypad.press("enter")
        root.assertEqual(submitted.length, 1, "enter on an empty field submits nothing")

        view.authenticatingPassword = true
        root.assertTrue(!keypad.enabled, "the keypad ignores taps while a password is checked")
        view.authenticatingPassword = false

        view.inputEnabled = false
        root.assertTrue(!keypad.enabled, "the keypad ignores taps while the lock takes no input")

        view.destroy()
      } catch (error) {
        root.fail("lock keypad fixture threw: " + error)
      } finally {
        root.writeResult()
      }
    }
  }
}
