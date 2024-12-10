
-- Weapon names, descriptions, and other texts.

---@class ss
local ss = SplashSWEPs
local gl = require "greatzenkakuman/localization" or greatzenkakuman.localization

---@param t string|string[]
---@return string
local function TableToString(t)
    if isstring(t) then return t --[[@as string]] end
    local str = "" ---@cast t string[]
    for i, v in ipairs(t) do
        if i > 1 then str = str .. "\n" end
        str = str .. tostring(i) .. ":\t" .. tostring(v)
    end

    return str
end

if not ss then return end
ss.Text = gl.IncludeTexts "splashsweps/constants/texts"
ss.Text.CVars.InkColor = ss.Text.CVars.InkColor .. TableToString(ss.Text.ColorNames)
ss.Text.CVars.Playermodel = ss.Text.CVars.Playermodel .. TableToString(ss.Text.PlayermodelNames)

if SERVER then return end
language.Add("Cleanup_" .. ss.CleanupTypeInk, ss.Text.CleanupInk --[[@as string]])
language.Add("Cleaned_" .. ss.CleanupTypeInk, ss.Text.CleanupInkMessage --[[@as string]])
steamworks.RequestPlayerInfo("76561198013738310", function(name) ss.Text.Author = name end)
