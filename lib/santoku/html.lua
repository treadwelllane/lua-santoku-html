-- TODO: Match the most general xml spec possible
-- TODO: Allow adding text in chunks (perhaps final generator value is the
-- unprocessed text?)

local err = require("santoku.error")
local error = err.error

local L = require("lpeg")

L.locale(L)

local re = require("re")
local compile = re.compile
local match = re.match

local defs = {}
defs.quoted = compile([[ (('"' {} ('\"' / [^"])* {} '"') / ("'" {} ("\'" / [^'])* {} "'")) {} ]], defs)
defs.ident = compile([[ {} (!["'/<>=]([%w]/[%p]))+ {} ]], defs)
defs.closing = compile([[ {} -> "close" "</" %ident ">" {} ]], defs)
defs.comment = compile([[ {} -> "comment" "<!--" {} (!"-->" .)+ {} "-->" {} ]], defs)
defs.doctype = compile([[ {} -> "doctype" !%comment "<!" {} (%quoted -> 0 / (!">" .))+ {} ">" {} ]], defs)
defs.opening = compile([[ {} -> "open" !%comment !%closing !%doctype "<" "?"? [%s]* %ident ]], defs)
defs.opening_close = compile([[ {} -> "open_close" ">" {} ]], defs)
defs.opening_close_self = compile([[ {} -> "close_self" {} ("?>" / "/>") {} ]], defs)
defs.text = compile([[ {} -> "text" {} (!%opening !%closing .)+ {} ]], defs)
defs.attibute = compile([[ {} -> "attribute" [%s]* %ident ("=" %quoted)? ]], defs)

local state_default = defs.doctype + defs.comment + defs.text + defs.opening + defs.closing
local state_attributes = defs.attibute + defs.opening_close + defs.opening_close_self

return function (text)
  local state = state_default
  local max = #text
  local start = 1
  return function ()
    while start <= max do
      local m, s0, e0, s1, e1, f1 = match(text, state, start)
      if not m then
        start = max + 1
        return
      end
      if m == "open" then
        state = state_attributes
        start = e0
        return m, text, s0, e0 - 1
      elseif m == "open_close" then
        state = state_default
        start = s0
      elseif m == "attribute" then
        start = f1 or e1 or e0
        return m, text, s0, e0 - 1, s1, e1 and e1 - 1 or nil
      elseif m == "close" then
        state = state_default
        start = s1
        return m, text, s0, e0 - 1
      elseif m == "close_self" then
        state = state_default
        start = e0
        return "close"
      elseif m == "text" then
        start = f1 or e1 or e0
        return m, text, s0, e0 - 1
      elseif m == "comment" then
        start = s1
        return "comment", text, s0, e0 -1
      elseif m == "doctype" then
        start = s1
        return "doctype", text, s0, e0 - 1
      else
        error("unexpected parsing state", m, s0, s1, e0, e1, f1)
      end
    end
  end
end
