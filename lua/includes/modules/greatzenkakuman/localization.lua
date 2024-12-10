AddCSLuaFile()
module("greatzenkakuman.localization", package.seeall)
local localization = greatzenkakuman.localization or {}

---@alias localization.RecursiveText string|string[]|{[string]: localization.RecursiveText}
---@alias localization.RecursiveTextRoot table<string, localization.RecursiveText>

localization.Texts = {} ---@type localization.RecursiveTextRoot
local FileList     = {} ---@type string[]
local Workspace    = ""
local cvarlang = GetConVar "gmod_language"
---@param folder string
local function LoadText(folder)
    local language = cvarlang:GetString()
    local path = folder .. "en.lua"
    if file.Exists(path, "LUA") then
        table.Merge(localization.Texts, include(path))
    end
    path = folder .. language .. ".lua"
    if file.Exists(path, "LUA") then
        table.Merge(localization.Texts, include(path))
    end
end

---@param convar string
---@param old string
---@param new string
local function RefreshTexts(convar, old, new)
    table.Empty(localization.Texts)
    for _, f in ipairs(FileList) do LoadText(f) end
end

cvars.AddChangeCallback("gmod_language", RefreshTexts, "GreatZenkakuMan's Module: OnLanguageChanged")

function localization.ClearTexts()
    table.Empty(FileList)
    table.Empty(localization.Texts)
end

---@param folder string
---@return localization.RecursiveTextRoot
function localization.IncludeTexts(folder)
    Workspace = folder .. "/"
    local _, directories = file.Find(Workspace .. "*", "LUA")
    for _, d in ipairs(directories or {}) do
        if SERVER then -- We need to run AddCSLuaFile() for all languages.
            local path = Workspace .. d .. "/"
            local files = file.Find(path .. "*.lua", "LUA") or {}
            for _, f in ipairs(files) do
                AddCSLuaFile(path .. f)
            end
        end

        local path = Workspace .. d .. "/"
        FileList[#FileList + 1] = path
        LoadText(path)
    end

    return localization.Texts
end

---@param texttable string[]
local function DoChatPrint(texttable)
    if SERVER then return end
    ---@type localization.RecursiveText
    local text = localization.Texts
    for _, t in ipairs(texttable) do
        if not istable(text) then break end
        text = text[t] --[[@as string]]
    end

    LocalPlayer():ChatPrint(text)
end

if SERVER then
    util.AddNetworkString "greatzenkakuman.localization.chatprint"
else
    net.Receive("greatzenkakuman.localization.chatprint", function()
        DoChatPrint(net.ReadTable())
    end)
end

---@param texttable string|string[]
---@param ply Player
---@return nil
function localization.ChatPrint(texttable, ply)
    if not istable(texttable) then texttable = { texttable --[[@as string]] } end ---@cast texttable -string
    if CLIENT then return DoChatPrint(texttable) end
    if not (IsValid(ply) and ply:IsPlayer()) then return end
    net.Start "greatzenkakuman.localization.chatprint"
    net.WriteTable(texttable)
    net.Send(ply)
end

return localization
