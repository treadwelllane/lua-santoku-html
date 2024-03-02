local test = require("santoku.test")
local serialize = require("santoku.serialize") -- luacheck: ignore

local parsehtml = require("santoku.html")

local it = require("santoku.iter")
local collect = it.collect
local map = it.map

local arr = require("santoku.array")
local pack = arr.pack

local err = require("santoku.error")
local assert = err.assert

local tbl = require("santoku.table")
local teq = tbl.equals


test("html", function ()

  local text = "this is a test of <span class=\"thing\" id='\"hi\"' failme=\"test: \\\"blah\\\": it's bound to fail\">something</span>" -- luacheck: ignore

  local tokens = collect(map(pack, parsehtml(text)))

  assert(teq({
    { "text", text, 1, 18 },
    { "open", text, 20, 23 },
    { "attribute", text, 25, 29, 32, 36 },
    { "attribute", text, 39, 40, 43, 46 },
    { "attribute", text, 49, 54, 57, 90 },
    { "text", text, 93, 101 },
    { "close", text, 104, 107 }
  }, tokens))

end)

test("xml", function ()

  local text = [[
    <?xml abcd="efgh"?>
    <w:p>
      <w:pPr>
        <w:pStyle w:val="text-indented"/>
      </w:pPr>
      <w:r>
        <w:t xml:space="preserve">some text</w:t>
      </w:r>
    </w:p>
  ]]

  local tokens = collect(map(pack, parsehtml(text)))

  assert(teq({
    { "text", text, 1, 4 },
    { "open", text, 7, 9 },
    { "attribute", text, 11, 14, 17, 20 },
    { "attribute", text, 22, 22 },
    { "text", text, 24, 28 },
    { "open", text, 30, 32 },
    { "text", text, 34, 40 },
    { "open", text, 42, 46 },
    { "text", text, 48, 56 },
    { "open", text, 58, 65 },
    { "attribute", text, 67, 71, 74, 86 },
    { "close" },
    { "text", text, 90, 96 },
    { "close", text, 99, 103 },
    { "text", text, 105, 111 },
    { "open", text, 113, 115 },
    { "text", text, 117, 125 },
    { "open", text, 127, 129 },
    { "attribute", text, 131, 139, 142, 149 },
    { "text", text, 152, 160 },
    { "close", text, 163, 165 },
    { "text", text, 167, 173 },
    { "close", text, 176, 178 },
    { "text", text, 180, 184 },
    { "close", text, 187, 189 },
    { "text", text, 191, 193 },
  }, tokens))

end)

test("xml empty self-closing", function ()

  local text = "<w:p/>"
  local tokens = collect(map(pack, parsehtml(text)))
  assert(teq({
    { "open", text, 2, 4 },
    { "close" },
  }, tokens))

end)

test("xml comments", function ()

  local text = "<span><!-- testing --></span>"
  local tokens = collect(map(pack, parsehtml(text)))
  assert(teq({
    { "open", text, 2, 5 },
    { "comment", text, 11, 19 },
    { "close", text, 25, 28 },
  }, tokens))

end)
