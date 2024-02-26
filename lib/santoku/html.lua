-- TODO: Match the most general xml spec possible
-- TODO: Allow adding text in chunks (perhaps final generator value is the
-- unprocessed text?)

local L = require("lpeg")
local P = L.P
local S = L.S
local Cg = L.Cg
local Ct = L.Ct
local Cp = L.Cp

L.locale(L)

-- TODO: convert to grammar notation
local closing_tag = P("</") * L.space^0 * Cg((P(1) - (P(">") + L.space))^0, "close") * L.space^0 * P(">")
local opening_tag_open = ((P("<") * P("?")^-1) - closing_tag) *
  Cg((P(1) - (P(">") + P("/>") + L.space))^0, "open") * L.space^0
local opening_tag_close = Cg(P(">"), "open_close")
local opening_tag_self_close = Cg((P("?>") + P("/>")) / function () return true end, "close")
local text = Cg((P(1) - (opening_tag_open + closing_tag))^1, "text")
local value = P("=") * ((Cg(P('"'), "quote") * Cg((P('\\"') + (P(1) - P('"')))^0, "value") * P('"')) +
                    (Cg(P("'"), "quote") * Cg((P("\\'") + (P(1) - P("'")))^0, "value") * P("'")))

-- TODO: Attribute names are defined here as alnum/_/- but this is not accurate
-- per the spec
local attribute = Cg(Ct(Cg((L.alnum + S(":_-"))^1, "name") * value^0^-1), "attribute") * L.space^0

-- Matches text, opening tags, or closing tags. If an open tag is matched, state
-- moves to attributes
local state_default = Ct((text + opening_tag_open + closing_tag) * Cg(Cp(), "position"))

-- Matches attributes or tag close
local state_attributes = Ct((attribute + opening_tag_close + opening_tag_self_close) * Cg(Cp(), "position"))

return function (text)
  local state = state_default
  local max = #text
  local start = 1
  return function ()
    while start <= max do
      local m = state:match(text, start)
      if not m then
        start = max + 1
        return
      end
      m.start = start
      start = m.position
      if m.open then
        state = state_attributes
        return m
      elseif m.open_close then
        state = state_default
      elseif m.attribute then
        -- TODO: Ugly hack.
        -- How can we just modify the capture so that \\" becomes "?
        if m.attribute.value and m.attribute.quote then
          m.attribute.value = m.attribute.value:gsub("\\" .. m.attribute.quote, m.attribute.quote)
        end
        m.attribute.quote = nil
        return m
      elseif m.close then
        state = state_default
        return m
      else
        return m
      end
    end
  end
end
