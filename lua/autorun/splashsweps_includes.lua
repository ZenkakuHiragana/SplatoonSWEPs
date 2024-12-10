
-- SplashSWEPs library inclusions

local SharedDirectory = "splashsweps/"
local ServerDirectory = SharedDirectory .. "server/"
local ClientDirectory = SharedDirectory .. "client/"
if SERVER then -- Finds all Lua files used on client and AddCSLuaFile() them.
    local shared = file.Find(SharedDirectory .. "*.lua", "LUA") --[=[@as string[]]=]
    local client = file.Find(ClientDirectory .. "*.lua", "LUA") --[=[@as string[]]=]
    for i, filename in ipairs(shared) do
        shared[i] = SharedDirectory .. filename
    end

    for i, filename in ipairs(client) do
        client[i] = ClientDirectory .. filename
    end

    local merged = table.Add(shared, client) --[=[@as string[]]=]
    for _, filepath in ipairs(merged) do
        AddCSLuaFile(filepath)
    end

    include(ServerDirectory .. "autorun.lua")
else
    include(ClientDirectory .. "autorun.lua")
end
