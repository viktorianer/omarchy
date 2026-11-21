#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

run_node_test <<'JS'
const model = requireFromRoot('shell/plugins/lock/KeypadModel.js')

assert(model.enabledIn({ lock: { keypad: true } }), 'lock.keypad true turns the keypad on')
assert(!model.enabledIn({ lock: { keypad: 'true' } }), 'only a literal true turns the keypad on')
assert(!model.enabledIn({ lock: {} }), 'the keypad is off without lock.keypad')
assert(!model.enabledIn({ lock: [true] }), 'a lock array is no setting')
assert(!model.enabledIn(null), 'the keypad is off without a shell config')

assertDeepEqual(model.press('7', false), { insert: '7', shifted: false }, 'a digit types itself')
assertDeepEqual(model.press('q', true), { insert: 'Q', shifted: false }, 'shift capitalises the next letter and releases')
assertDeepEqual(model.press('space', false), { insert: ' ', shifted: false }, 'space types a space')
assertDeepEqual(model.press('shift', true), { shifted: false }, 'shift toggles off again')
assertDeepEqual(model.press('backspace', true), { erase: true, shifted: true }, 'backspace erases and keeps shift')
assertDeepEqual(model.press('enter', true), { submit: true, shifted: false }, 'enter submits and releases shift')
assertDeepEqual(model.press('letters', true), { layer: 'letters', shifted: false }, 'the layer key switches layers and releases shift')

assertEqual(model.rows('digits')[0].join(''), '123', 'digits come first, laid out as a phone keypad')
assert(model.rows('unknown') === model.rows('digits'), 'an unknown layer falls back to the digits')

const reached = ['digits']
const typed = new Set()
for (let i = 0; i < reached.length; i++) {
  const keys = [].concat(...model.rows(reached[i]))
  assert(keys.includes('backspace') && keys.includes('enter'), `the ${reached[i]} layer can erase and submit`)
  for (const key of keys) {
    if (model.isLayerKey(key)) {
      const next = model.press(key, false).layer
      if (!reached.includes(next)) reached.push(next)
    } else {
      for (const shifted of [false, true]) {
        const result = model.press(key, shifted)
        if (result.insert) typed.add(result.insert)
      }
    }
  }
}
const missing = []
for (let code = 0x20; code <= 0x7e; code++) {
  if (!typed.has(String.fromCharCode(code))) missing.push(String.fromCharCode(code))
}
assertEqual(missing.join(''), '', 'every printable ASCII character can be typed from the digits layer on')
JS

require_quickshell "lock keypad test"

run_qml_fixture lock-keypad "lock keypad types into the password field and submits through it" Ui Commons
