var LAYERS = {
  digits: [
    ["1", "2", "3"],
    ["4", "5", "6"],
    ["7", "8", "9"],
    ["letters", "0", "backspace"],
    ["enter"]
  ],
  letters: [
    ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
    ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
    ["shift", "z", "x", "c", "v", "b", "n", "m", "backspace"],
    ["digits", "symbols", "space", "enter"]
  ],
  symbols: [
    ["!", "@", "#", "$", "%", "^", "&", "*", "(", ")"],
    ["-", "_", "=", "+", "[", "]", "{", "}", "\\", "|"],
    [";", ":", "'", "\"", ",", ".", "/", "?", "<", ">"],
    ["letters", "`", "~", "space", "backspace", "enter"]
  ]
}

var LABELS = {
  letters: "ABC",
  digits: "123",
  symbols: "#+=",
  backspace: "\u{F0B5C}",
  enter: "\u{F0311}",
  shift: "\u{F0636}",
  space: ""
}

var WEIGHTS = {
  digits: { enter: 3 },
  letters: { shift: 1.5, backspace: 1.5, digits: 1.5, symbols: 1.5, space: 5, enter: 2 },
  symbols: { letters: 1.5, space: 3, backspace: 1.5, enter: 2 }
}

var ROW_COUNT = Math.max(LAYERS.digits.length, LAYERS.letters.length, LAYERS.symbols.length)

function enabledIn(shellConfig) {
  var lock = shellConfig && shellConfig.lock
  return !!lock && typeof lock === "object" && !Array.isArray(lock) && lock.keypad === true
}

function rows(layer) {
  return LAYERS[layer] || LAYERS.digits
}

function isLayerKey(key) {
  return key === "letters" || key === "digits" || key === "symbols"
}

function label(key, shifted) {
  if (Object.prototype.hasOwnProperty.call(LABELS, key)) return LABELS[key]
  return shifted ? key.toUpperCase() : key
}

function weight(key, layer) {
  var weights = WEIGHTS[layer] || WEIGHTS.digits
  return weights[key] || 1
}

function rowWeight(row, layer) {
  var total = 0
  for (var i = 0; i < row.length; i++) total += weight(row[i], layer)
  return total
}

function unitCount(layer) {
  var layerRows = rows(layer)
  var widest = 0
  for (var i = 0; i < layerRows.length; i++) widest = Math.max(widest, rowWeight(layerRows[i], layer))
  return widest
}

function press(key, shifted) {
  if (key === "backspace") return { erase: true, shifted: shifted }
  if (key === "enter") return { submit: true, shifted: false }
  if (key === "shift") return { shifted: !shifted }
  if (isLayerKey(key)) return { layer: key, shifted: false }
  if (key === "space") return { insert: " ", shifted: false }
  return { insert: shifted ? key.toUpperCase() : key, shifted: false }
}

if (typeof module !== "undefined") {
  module.exports = {
    ROW_COUNT: ROW_COUNT,
    enabledIn: enabledIn,
    rows: rows,
    isLayerKey: isLayerKey,
    label: label,
    weight: weight,
    unitCount: unitCount,
    press: press
  }
}
