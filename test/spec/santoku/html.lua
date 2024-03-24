local test = require("santoku.test")
local serialize = require("santoku.serialize") -- luacheck: ignore

local parsehtml = require("santoku.html")

local it = require("santoku.iter")
local collect = it.collect
local map = it.map
local take = it.take

local arr = require("santoku.array")
local pack = arr.pack

local err = require("santoku.error")
local assert = err.assert

local tbl = require("santoku.table")
local teq = tbl.equals

test("simple", function ()

  local text = "testing, <em a=\"b\" c=\"d\">testing...</em>" -- luacheck: ignore
  local tokens = collect(map(pack, parsehtml(text, true)))

  assert(teq({
    { "open", "p" },
    { "text", "testing, " },
    { "open", "em" },
    { "attribute", "a", "b" },
    { "attribute", "c", "d" },
    { "text", "testing..." },
    { "close", "em" },
    { "close", "p" },
  }, tokens))

end)

test("html", function ()

  local text = [[this is a test of <span class="thing" id='"hi"'>something</span>]] -- luacheck: ignore
  local tokens = collect(map(pack, parsehtml(text, true)))

  assert(teq({
    { "open", "p" },
    { "text", "this is a test of " },
    { "open", "span" },
    { "attribute", "class", "thing" },
    { "attribute", "id", "\"hi\"" },
    { "text", "something" },
    { "close", "span" },
    { "close", "p" },
  }, tokens))

end)

test("xml", function ()

  local text = [[
    <?xml version="1.0"?>
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
    { "open", "w:p" },
    { "open", "w:pPr" },
    { "open", "w:pStyle" },
    { "attribute", "w:val", "text-indented" },
    { "close" },
    { "close", "w:pPr" },
    { "open", "w:r" },
    { "open", "w:t" },
    { "attribute", "space", "preserve" },
    { "text", "some text" },
    { "close", "w:t" },
    { "close", "w:r" },
    { "close", "w:p" }
  }, tokens))

end)

test("xml empty self-closing", function ()

  local text = "<w:p/>"
  local tokens = collect(map(pack, parsehtml(text)))
  assert(teq({
    { "open", "w:p" },
    { "close" },
  }, tokens))

end)

test("xml comments", function ()

  local text = "<span><!-- testing --></span>"
  local tokens = collect(map(pack, parsehtml(text)))
  assert(teq({
    { "open", "span" },
    { "comment", " testing " },
    { "close", "span" },
  }, tokens))

end)

test("doctype", function ()
  local text = [[<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict."   ><span a="b">test</span>]] -- luacheck: ignore
  local tokens = collect(map(pack, parsehtml(text)))
  assert(teq({
    { "open", "span" },
    { "attribute", "a", "b" },
    { "text", "test" },
    { "close", "span" }
  }, tokens))
end)

test("doctype with quoted closer", function ()
  local text = [[<!DOCTYPE html><span a="b">test</span>]] -- luacheck: ignore
  local tokens = collect(map(pack, parsehtml(text, true)))
  assert(teq({
    { "open", "span" },
    { "attribute", "a", "b" },
    { "text", "test" },
    { "close", "span" }
  }, tokens))
end)

test("ampersand", function ()
  local text = [[<p>&</p>]]
  local tokens = collect(take(10, map(pack, parsehtml(text, true))))
  assert(teq({
    { "open", "p" },
    { "text", "&" },
    { "close", "p" }
  }, tokens))
end)
