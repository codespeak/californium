utils = require './utils'
{Disposable, CompositeDisposable, Point, Range} = require 'atom'

disposables = new CompositeDisposable()

class ActionHandler

  constructor: (@editor, num, action, arg) ->
    @num = parseInt(num)
    @action = action
    @arg = arg
    @start = @editor.getCursorBufferPosition()
    @lastPos = utils.getLastPos(@editor).toArray()

  doFunction: (func) ->
    @func = FUNCS[func]
    if @func.regexStr is not null
      @argRegex = new RegExp(@func.regexStr)
    else
      if @func.type == 'surroundObject'
        @argRegex = new RegExp('\\' + @arg[0] + '|\\' + @arg[1])
      else
        esc = utils.escapeRegexStr(@arg)
        @argRegex = new RegExp(esc)
    funcResult = this[@func.funcName].apply(this, @func.args)
    if funcResult == null
      return
    backwards = func in ['T', 'F']
    doAction(funcResult, @action, @editor, @func.type, backwards)

  searchAhead: (back, start=@start, lastPos=@lastPos, num=@num) ->
    count = 0
    end = start
    while count < num
      result = @scanForwardsThroughRegex [end, lastPos], @argRegex
      if result == null
        break
      end = result.range.end
      lastLength = result.matchText.length
      count++
    if end == start
      return null
    if back is true
      end = utils.moveBackwards end, lastLength
    return new Range(start, end)

   searchBehind: (back, start=@start, lastPos=@lastPos, num=@num) ->
    limit = [0, 0]
    count = 0
    end = null
    while count < num
      result = @scanBackwardsThroughRegex [start, limit], @argRegex
      if result == null
        return
      end = result.range.start
      lastLength = result.matchText.length
      start = end
      count++
    if end == null
      return null
    if back is true
      end = utils.moveForwards end, lastLength
    return new Range(@editor.getCursorBufferPosition(), end)

  modifyLine: () ->
    start = @start.toArray()
    start[1] = 0
    count = 0
    endRow = Math.min(start[0] + @num - 1, @lastPos[0])
    endCol = @editor.lineTextForBufferRow(endRow).length
    return new Range(start, [endRow, endCol])

  modifyTextObject: (outer) ->
    start = @start.toArray()
    end = @start.toArray()
    start[1] = 0
    end[1] = @editor.lineTextForBufferRow(end[0]).length
    behind = @scanBackwardsThroughRegex([@start, start], @argRegex)
    ahead = @scanForwardsThroughRegex([@start, end], @argRegex)
    try
      if ahead != null and behind != null
        if outer
          return new Range(behind.range.start, ahead.range.end)
        else
          return new Range(behind.range.end, ahead.range.start)
      else if ahead != null
        range = @searchAhead(!outer, ahead.range.end, end)
        if !outer
          return new Range(range.start, range.end)
        startPoint = utils.moveBackwards(range.start, ahead.matchText.length)
        return new Range(startPoint, range.end)
      else if behind != null
        range = @searchAhead(!outer, behind.range.start, start)
        if !outer
          startPoint = utils.moveForwards(range.start, behind.matchText.length)
          return new Range(startPoint, range.end)
        startPoint = utils.moveBackwards(range.start, behind.matchText.length)
        endPoint = utils.moveForwards(range.end, behind.matchText.length)
        return new Range(startPoint, endPoint)
      else
        return null
    catch
      return null

  getSurroundRange: () ->
    start = @start
    end = @start
    pos1 = null
    pos2 = null
    oppoCharCount = 0
    while pos1 == null
      result = @scanBackwardsThroughRegex [start, [0, 0]], @argRegex
      if result == null
        return null
      start = result.range.start
      if result.matchText == @arg[1]
        oppoCharCount++
      else
        if oppoCharCount > 0
          oppoCharCount--
        else
          pos1 = result.range.start
    oppoCharCount = 0
    while pos2 == null
      result = @scanForwardsThroughRegex [end, @lastPos], @argRegex
      if result == null
        return null
      end = result.range.end
      if result.matchText == @arg[0]
        oppoCharCount++
      else
        if oppoCharCount > 0
          oppoCharCount--
        else
          pos2 = result.range.end
    if null not in [pos1, pos2] and @arg.length == 3
      @arg = @arg[0] + @arg[1]
      return new Range(utils.moveForwards(start, 1), utils.moveBackwards(end, 1))
    return new Range(pos1, pos2)

  scanForwardsThroughRegex: (searchRange, regex) =>
    result = null
    @editor.scanInBufferRange regex, searchRange, (hit) =>
      hit.stop()
      if hit.matchText != ''
        result = hit
    result

  scanBackwardsThroughRegex: (searchRange, regex) ->
    result = null
    @editor.backwardsScanInBufferRange regex, searchRange, (hit) =>
      hit.stop()
      if hit.matchText != ''
        result = hit
    result

FUNCS =
  'f':
    'funcName': 'searchAhead'
    'regexStr': null
    'num': null
    'type': 'motion'
    'args': [false]
  'F':
    'funcName': 'searchBehind'
    'regexStr': null
    'num': null
    'type': 'motion'
    'args': [false]
  't':
    'funcName': 'searchAhead'
    'regexStr': null
    'num': null
    'type': 'motion'
    'args': [true]
  'T':
    'funcName': 'searchBehind'
    'regexStr': null
    'num': null
    'type': 'motion'
    'args': [true]
  'l':
    'funcName': 'modifyLine'
    'regexStr': '\\n'
    'num': null
    'type': 'motion'
    'args': []
  's':
    'funcName': 'getSurroundRange'
    'regexStr': null
    'num': null
    'type': 'surroundObject'
    'args': []
  'i':
    'funcName': 'modifyTextObject'
    'regexStr': null
    'num': null
    'type': 'textObject'
    'args': [false]
  'a':
    'funcName': 'modifyTextObject'
    'regexStr': null
    'num': null
    'type': 'textObject'
    'args': [true]
  '':
    'funcName': 'modifyTextObject'
    'regexStr': null
    'num': null
    'type': 'textObject'
    'args': [true]


doAction = (range, action, editor, type, backwards) ->
  if action in ['y', 'c']
    atom.clipboard.write(editor.getTextInBufferRange(range))
  if action == 'm'
    if type == 'motion'
      pos = range.end
      if backwards is true
        pos = range.start
      if editor.getSelectedText().length == 0
        editor.setCursorBufferPosition(pos)
      else
        editor.selectToBufferPosition(pos)
  else if action in ['d', 'c']
    editor.setTextInBufferRange range, ''
  else if action == 's'
    editor.setSelectedBufferRange(range)
  else if action == 'p'
    editor.setTextInBufferRange range, atom.clipboard.read()

module.exports = {
    ActionHandler
}
