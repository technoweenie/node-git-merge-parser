fs = require "fs"
path = require "path"
assert = require "assert"
util = require "util"
diffParser = require path.join(__dirname, "..", "lib")

assertDiff = (dir) ->
  diff = fs.readFileSync path.join(dir, "diff.txt")
  json = fs.readFileSync path.join(dir, "expected.json")
  expected = JSON.parse json
  actual = diffParser.parse diff
  for filename, file of actual.files
    expectedFile = expected.files[filename]
    assert.ok expectedFile, "unexpected file: #{filename}"

    delete expected.files[filename]
    assert.deepEqual expectedFile.conflictedLines, file.conflictedLines,
      "ERROR: #{filename}\n" +
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
  assertDiff dir

console.log "OK"
