doSimple = (input) ->
  selectDefault = false
  if input.slice(0, 1) == 's'
    selectDefault = true
  action = input.slice(1, 2)
  count = parseInt(input.slice(2), 10)
  func = null
  if action == '!'
    func = nextWordStart
  else if action == '@'
    func = backWordEnd
  else if action == '#'
    func = nextWordEnd
  else if action == '$'
    func = backWordStart
  else if action == '%'
    func = endOfLine
  else if action == '^'
    func = firstCharacterOfLine
  else if action == '&'
    func = beginningOfLine
  if func != null
    (func(selectDefault) for i in [count..1])
  else
    if action == 'h'
      left(count, selectDefault)
    else if action == 'j'
      down(count, selectDefault)
    if action == 'k'
      up(count, selectDefault)
    else if action == 'l'
      right(count, selectDefault)

nextWordStart = (selectDefault) ->
  editor = atom.workspace.getActiveTextEditor()
  if editor.getSelectedText().length == 0 and not selectDefault
    forwardFunc = -> editor.moveToEndOfWord()
    backFunc = -> editor.moveToBeginningOfWord()
  else
    forwardFunc = -> editor.selectToEndOfWord()
    backFunc = -> editor.selectToBeginningOfWord()
  start = editor.getCursorBufferPosition()
  forwardFunc()
  if editor.getCursorBufferPosition().column == 0
    return
  backFunc()
  end = editor.getCursorBufferPosition()
  if end.isLessThanOrEqual(start)
    forwardFunc()
    forwardFunc()
    if editor.getCursorBufferPosition().column == 0
      return
    backFunc()

backWordEnd = (selectDefault) ->
  editor = atom.workspace.getActiveTextEditor()
  if editor.getSelectedText().length == 0 and not selectDefault
    forwardFunc = -> editor.moveToEndOfWord()
    backFunc = -> editor.moveToBeginningOfWord()
  else
    forwardFunc = -> editor.selectToEndOfWord()
    backFunc = -> editor.selectToBeginningOfWord()
  start = editor.getCursorBufferPosition()
  backFunc()
  forwardFunc()
  end = editor.getCursorBufferPosition()
  if end.isGreaterThanOrEqual(start)
    backFunc()
    backFunc()
    if editor.getCursorBufferPosition().column == 0
      return
    forwardFunc()

nextWordEnd = (selectDefault) ->
  editor = atom.workspace.getActiveTextEditor()
  if editor.getSelectedText().length == 0
    editor.moveToEndOfWord()
  else
    editor.selectToEndOfWord()

backWordStart = (selectDefault) ->
  editor = atom.workspace.getActiveTextEditor()
  if editor.getSelectedText().length == 0
    editor.moveToBeginningOfWord()
  else
    editor.selectToBeginningOfWord()

endOfLine = (selectDefault) ->
  editor = atom.workspace.getActiveTextEditor()
  if editor.getSelectedText().length == 0
    editor.moveToEndOfLine()
  else
    editor.selectToEndOfLine()

firstCharacterOfLine = (selectDefault) ->
  editor = atom.workspace.getActiveTextEditor()
  if editor.getSelectedText().length == 0
    editor.moveToFirstCharacterOfLine()
  else
    editor.selectToFirstCharacterOfLine()

beginningOfLine = (selectDefault) ->
  editor = atom.workspace.getActiveTextEditor()
  if editor.getSelectedText().length == 0 and not selectDefault
    editor.moveToBeginningOfLine()
  else
    editor.selectToBeginningOfLine()

left = (count, selectDefault) ->
  editor = atom.workspace.getActiveTextEditor()
  if editor.getSelectedText().length == 0 and not selectDefault
    editor.moveLeft(count)
  else
    editor.selectLeft(count)

down = (count, selectDefault) ->
  editor = atom.workspace.getActiveTextEditor()
  if editor.getSelectedText().length == 0 and not selectDefault
    editor.moveDown(count)
  else
    editor.selectDown(count)

up = (count, selectDefault) ->
  editor = atom.workspace.getActiveTextEditor()
  if editor.getSelectedText().length == 0 and not selectDefault
    editor.moveUp(count)
  else
    editor.selectUp(count)

right = (count, selectDefault) ->
  editor = atom.workspace.getActiveTextEditor()
  if editor.getSelectedText().length == 0 and not selectDefault
    editor.moveRight(count)
  else
    editor.selectRight(count)

module.exports = {
    doSimple
}
