fs = require "fs"
path = require "path"
assert = require "assert"
util = require "util"
diffParser = require path.join(__dirname, "..", "lib")

assertDiff = (expected, parseType, cb) ->
  actual = cb()
  for filename, file of actual.files
    expectedFile = expected.files[filename]
    assert.ok expectedFile, "unexpected file from #{parseType}: #{filename}"

    delete expected.files[filename]
    assert.deepEqual expectedFile.conflictedLines, file.conflictedLines,
      "#{parseType} error: #{filename}\n" +
      "expected: #{expectedFile.conflictedLines}\n" +
      "received: #{file.conflictedLines}\n" +
      util.inspect(file.debug)

  assert.deepEqual [], Object.keys(expected.files),
    "expected all files from expected.json to be checked\n" +
    util.inspect(expected.files)

fixturesDir = path.join(__dirname, "fixtures")
dirs = fs.readdirSync fixturesDir
for name in dirs
  dir = path.join fixturesDir, name
  diffFile = path.join(dir, "diff.txt")
  expected = fs.readFileSync path.join(dir, "expected.json")

  assertDiff JSON.parse(expected), "parse", ->
    diffParser.parse fs.readFileSync(diffFile)

  assertDiff JSON.parse(expected), "parseFile", ->
    diffParser.parseFileSync diffFile

console.log "OK"
