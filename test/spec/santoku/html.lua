local test = require("santoku.test")
local serialize = require("santoku.serialize") -- luacheck: ignore

local parsehtml = require("santoku.html")

local iter = require("santoku.iter")
local collect = iter.collect

local err = require("santoku.error")
local assert = err.assert

local tbl = require("santoku.table")
local teq = tbl.equals


test("html", function ()

  local text = "this is a test of <span class=\"thing\" id='\"hi\"' failme=\"test: \\\"blah\\\": it's bound to fail\">something</span>" -- luacheck: ignore

  local tokens = collect(parsehtml(text))

  assert(teq({
    { start = 1,   position = 19,   text = "this is a test of " },
    { start = 19,  position = 25,   open = "span" },
    { start = 25,  position = 39,   attribute = { name = "class", value = "thing" } },
    { start = 39,  position = 49,   attribute = { name = "id", value = "\"hi\"" } },
    { start = 49,  position = 92,   attribute = { name = "failme", value = "test: \"blah\": it's bound to fail" } },
    { start = 93,  position = 102,  text = "something" },
    { start = 102, position = 109,  close = "span" },
  }, tokens))

end)
