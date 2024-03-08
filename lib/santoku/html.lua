-- TODO: Match the most general xml spec possible
-- TODO: Allow adding text in chunks (perhaps final generator value is the
-- unprocessed text?)

local find = string.find
local html = require("santoku.html.capi")
local parse = html.parse
local step = html.step
local destroy = html.destroy

return function (text, ...)
  local state = parse(text, (find(text, "%S")), ...)
  return function ()
    if not state then
      return nil
    end
    local m, n, v = step(state)
    if not m then
      destroy(state)
      state = nil
      return nil
    end
    return m, n, v
  end
end
