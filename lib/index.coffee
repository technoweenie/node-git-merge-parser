module.exports =
  parse: (diff) ->
    if diff.toString
      diff = diff.toString()
    lines = diff.split "\n"
    parser = header
    context = {files: {}}
    for line in lines
      parser = parser context, line
    finishFile context
    context

finishFile = (context) ->
  if context.currentFile?
    file = context.currentFile
    finishHunk file
    context.files[file.name] = file
    delete file.name
  delete context.currentFile

finishHunk = (file) ->
  if file.currentHunk?
    file.debug.hunks.push(file.currentHunk)
  delete file.currentHunk

header = (context, line) ->
  finishFile context
  context.currentFile =
    conflictedLines: []
    debug:
      header: {}
      hunks: []
  headerLine

headerLine = (context, line) ->
  file = context.currentFile

  if isMarker line
    file.name = file.debug.header.base.filename
    return diffMarker(context, line)

  pieces = line.trim().split WHITESPACE_RE
  file.debug.header[pieces[0]] =
    mode: pieces[1]
    oid: pieces[2]
    filename: pieces[3]

  headerLine

diffMarker = (context, line) ->
  match = line.match DIFF_MARKER_LINES

  file = context.currentFile
  finishHunk file

  file.currentHunk =
    start: parseInt(match[1])
    length: parseInt(match[3] || 1)
    pos: 0

  content

content = (context, line) ->
  file = context.currentFile
  hunk = file.currentHunk

  if isLeft line
    leftSide
  else if isMarker line
    diffMarker(context, line)
  else
    hunk.pos += 1
    content

leftSide = (context, line) ->
  file = context.currentFile
  hunk = file.currentHunk

  if isMiddle line
    rightSide
  else
    file.conflictedLines.push(hunk.start + hunk.pos)
    hunk.pos += 1
    leftSide

rightSide = (context, line) ->
  if isRight line
    content
  else
    rightSide

isMarker = (line) ->
  line.indexOf(DIFF_MARKER) == 0

isLeft = (line) ->
  line.indexOf(LEFT_MARKER) == 1

isRight = (line) ->
  line.indexOf(RIGHT_MARKER) == 1

isMiddle = (line) ->
  line.indexOf(MIDDLE_MARKER) == 1

WHITESPACE_RE = /\s+/
DIFF_MARKER_LINES = /\-(\d+)(\,(\d+))?/
DIFF_MARKER = "@@"
LEFT_MARKER = "<<<<<<<"
RIGHT_MARKER = ">>>>>>>"
MIDDLE_MARKER = "======="
