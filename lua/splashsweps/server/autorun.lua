
-- Serverside SplashSWEPs structure

---@class ss.Transferrable
---@field MapCRC              string
---@field Revision            integer
---@field MinimapAreaBounds   table<integer, { mins: Vector, maxs: Vector }>
---@field SurfaceArrayLDR     PaintableSurface[]
---@field SurfaceArrayHDR     PaintableSurface[]
---@field SurfaceArrayDetails PaintableSurface[]
---@field WaterSurfaces       PaintableSurface[]
---@field Lightmap            ss.Lightmap

---@class ss.InkShotMask
---@field width     integer
---@field height    integer
---@field [integer] boolean[]

if not SplashSWEPs then
---@class ss
SplashSWEPs = {
    ClassDefinitions        = {}, ---@type table<string, table>
    CrosshairColors         = {}, ---@type integer[]
    EntityFilters           = {}, ---@type table<integer, table<Entity, boolean>> [color][target] = true
    InkColors               = {}, ---@type Color[]
    InkQueue                = {}, ---@type table<number, ss.InkQueue[]>
    InkShotMasks            = {}, ---@type ss.InkShotMask[][] Indexing order -> InkType, ThresholdIndex, x, y
    InkShotTypes            = {}, ---@type table<string, integer[]> InkShotCategory (string: "drop", "shot", etc.)  InkShotTypes (integer[])
    InkShotTypeToCategory   = {}, ---@type string[] InkShotType (integer) to InkShotCategory (string: "drop", "shot", etc.)
    InvincibleEntities      = {}, ---@type table<Entity, number> [target] = end time
    KnockbackVector         = {}, ---@type table<Entity, Vector> [target] = current knockback velocity
    LastHitID               = {}, ---@type table<Entity, integer> [target] = ink id
    Lightmap                = {}, ---@type ss.Lightmap
    MinimapAreaBounds       = {}, ---@type table<integer, { mins: Vector, maxs: Vector }>
    PaintSchedule           = {}, ---@type table<table, true>
    PlayerFilters           = {}, ---@type table<integer, table<Entity, boolean>> [color][player, npc, or nextbot] = true
    PlayerHullChanged       = {}, ---@type table<Player, boolean>
    PlayerID                = {}, ---@type table<Player, string>
    PlayerShouldResetCamera = {}, ---@type table<Player, boolean>
    PlayersReady            = {}, ---@type Player[]
    SurfaceArray            = {}, ---@type PaintableSurface[]
    SurfaceArrayLDR         = {}, ---@type PaintableSurface[]
    SurfaceArrayHDR         = {}, ---@type PaintableSurface[]
    SurfaceArrayDetails     = {}, ---@type PaintableSurface[]
    WeaponRecord            = {}, ---@type table<Entity, ss.WeaponRecord>
    WaterSurfaces           = {}, ---@type PaintableSurface[]
}
end

include "splashsweps/const.lua"
include "splashsweps/shared.lua"
include "lightmap.lua"
include "network.lua"
include "surfacebuilder.lua"

---@class ss
local ss = SplashSWEPs
if not ss.GetOption "enabled" then
    for h, t in pairs(hook.GetTable() --[[@as table<string, table<string, function>>]]) do
        for name in pairs(t) do
            if ss.ProtectedCall(name.find, name, "SplashSWEPs") then
                hook.Remove(h, name)
            end
        end
    end

    table.Empty(SplashSWEPs)
    ---@diagnostic disable-next-line: global-element
    SplashSWEPs = nil ---@type nil
    return
end

concommand.Add("sv_splashsweps_clear", function(ply, _, _, _)
    if not IsValid(ply) and game.IsDedicated() or IsValid(ply) and ply:IsAdmin() then
        ss.ClearAllInk()
    end
end, nil, ss.Text.CVars.Clear --[[@as string]], FCVAR_SERVER_CAN_EXECUTE)

---Clears all ink in the world.
---Sends a net message to clear ink on clientside.
---@diagnostic disable-next-line: duplicate-set-field
function ss.ClearAllInk()
    if #ss.PlayersReady > 0 then
        net.Start "SplashSWEPs: Send ink cleanup"
        net.Send(ss.PlayersReady)
    end

    table.Empty(ss.InkQueue)
    table.Empty(ss.PaintSchedule)
    if not ss.SurfaceArray then return end -- Workaround for changelevel
    for _, s in ipairs(ss.SurfaceArray) do
        table.Empty(s.InkColorGrid)
    end

    collectgarbage "collect"
end

---Calls notification.AddLegacy serverside
---@param msg      string  Message to display
---@param user     Player? The receiver
---@param icon     number? Notification icon. Note that NOTIFY_Enums are only in clientside
---@param duration number? Duration of the notification in seconds
function ss.SendError(msg, user, icon, duration)
    if IsValid(user) and not user--[[@as Player]]:IsPlayer() then return end
    if not user and #ss.PlayersReady == 0 then return end
    net.Start "SplashSWEPs: Send an error message"
    net.WriteUInt(icon or 1, ss.SEND_ERROR_NOTIFY_BITS)
    net.WriteUInt(duration or 8, ss.SEND_ERROR_DURATION_BITS)
    net.WriteString(msg)
    if user then
        net.Send(user)
    else
        net.Send(ss.PlayersReady)
    end
end

local NPCFactions = {
    [CLASS_NONE]              = "others",
    [CLASS_PLAYER]            = "player",
    [CLASS_PLAYER_ALLY]       = "citizen",
    [CLASS_PLAYER_ALLY_VITAL] = "citizen",
    [CLASS_ANTLION]           = "antlion",
    [CLASS_BARNACLE]          = "barnacle",
    [CLASS_BULLSEYE]          = "others",
    [CLASS_CITIZEN_PASSIVE]   = "citizen",
    [CLASS_CITIZEN_REBEL]     = "citizen",
    [CLASS_COMBINE]           = "combine",
    [CLASS_COMBINE_GUNSHIP]   = "combine",
    [CLASS_CONSCRIPT]         = "others",
    [CLASS_HEADCRAB]          = "zombie",
    [CLASS_MANHACK]           = "combine",
    [CLASS_METROPOLICE]       = "combine",
    [CLASS_MILITARY]          = "military",
    [CLASS_SCANNER]           = "combine",
    [CLASS_STALKER]           = "combine",
    [CLASS_VORTIGAUNT]        = "citizen",
    [CLASS_ZOMBIE]            = "zombie",
    [CLASS_PROTOSNIPER]       = "combine",
    [CLASS_MISSILE]           = "others",
    [CLASS_FLARE]             = "others",
    [CLASS_EARTH_FAUNA]       = "others",
    [CLASS_HACKED_ROLLERMINE] = "citizen",
    [CLASS_COMBINE_HUNTER]    = "combine",
    [CLASS_MACHINE]           = "military",
    [CLASS_HUMAN_PASSIVE]     = "citizen",
    [CLASS_HUMAN_MILITARY]    = "military",
    [CLASS_ALIEN_MILITARY]    = "alien",
    [CLASS_ALIEN_MONSTER]     = "alien",
    [CLASS_ALIEN_PREY]        = "zombie",
    [CLASS_ALIEN_PREDATOR]    = "alien",
    [CLASS_INSECT]            = "others",
    [CLASS_PLAYER_BIOWEAPON]  = "player",
    [CLASS_ALIEN_BIOWEAPON]   = "alien",
}
---Gets an ink color for the given NPC, considering its faction.
---@param n Entity?
---@return integer # Ink color for the NPC
function ss.GetNPCInkColor(n)
    if not IsValid(n) then return 1 end ---@cast n NPC
    if not isfunction(n.Classify) then
        return n.SplashSWEPsInkColor --[[@as integer?]] or 1
    end

    local class = n:Classify()
    local cvar = ss.GetOption "npcinkcolor"
    local colors = {
        citizen  = cvar "citizen"          --[[@as integer]],
        combine  = cvar "combine"          --[[@as integer]],
        military = cvar "military"         --[[@as integer]],
        zombie   = cvar "zombie"           --[[@as integer]],
        antlion  = cvar "antlion"          --[[@as integer]],
        alien    = cvar "alien"            --[[@as integer]],
        barnacle = cvar "barnacle"         --[[@as integer]],
        player   = ss.GetOption "inkcolor" --[[@as integer]],
        others   = cvar "others"           --[[@as integer]],
    }
    return colors[NPCFactions[class]] or colors.others or 1
end

---@param weapon SplashWeaponBase
---@return integer
function ss.GetBotInkColor(weapon)
    local color = math.random(1, ss.MAX_COLORS)
    weapon.BotInkColor = weapon.BotInkColor or color
    return weapon.BotInkColor
end

---@param self SplashWeaponBase
---@param ply Player The player
---@param speed number The fall speed
---@return integer?
function ss.GetFallDamage(self, ply, speed)
    if ss.IsInvincible(ply) then return 0 end
    if ss.GetOption "takefalldamage" then return end
    return 0
end

---@param ply Player
function ss.SynchronizePlayerStats(ply)
    ss.WeaponRecord[ply] = {
        Duration = {},
        Inked = {},
        Recent = {},
    }

    local id = ss.PlayerID[ply]
    if not id then return end
    local record = "data/splashsweps/record/" .. id:lower():gsub(":", "_") .. ".txt"
    if not file.Exists(record, "GAME") then return end
    local json = file.Read(record, "GAME")
    local cmpjson = util.Compress(json)
    ss.WeaponRecord[ply] = util.JSONToTable(json)
    net.Start "SplashSWEPs: Send player data"
    net.WriteUInt(cmpjson:len(), 16)
    net.WriteData(cmpjson, cmpjson:len())
    net.Send(ply)
end

---Parses the map and stores the result to a txt file, then sends it to the clients.
local function InitPostEntity()
    -- If the local server has crashed before, RT shrinks.
    if ss.sp and file.Exists("splashsweps/crashdump.txt", "DATA") then
        local res = ss.GetConVar "rtresolution"
        if res then res:SetInt(0) end
        ss.SendError(ss.Text.Error.CrashDetected --[[@as string]], nil, nil, 15)
    end

    local bspPath = string.format("maps/%s.bsp", game.GetMap())
    local txtPath = string.format("splashsweps/%s.txt", game.GetMap())
    ---@type ss.Transferrable
    local data = util.JSONToTable(util.Decompress(file.Read(txtPath) or "") or "", true) or {}
    local mapCRC = util.CRC(file.Read(bspPath, true))
    if not file.Exists("splashsweps", "DATA") then file.CreateDir "splashsweps" end
    if data.MapCRC ~= mapCRC or data.Revision ~= ss.MAPCACHE_REVISION then
        local t0 = SysTime()
        print("\n[Splash SWEPs] Building inkable surface structre...")
        ss.LoadBSP()
        ss.GenerateSurfaces()
        ss.BuildLightmap()
        data.MapCRC = mapCRC
        data.Revision = ss.MAPCACHE_REVISION
        data.Lightmap = ss.Lightmap
        data.MinimapAreaBounds = ss.MinimapAreaBounds
        data.SurfaceArrayLDR = ss.SurfaceArrayLDR
        data.SurfaceArrayHDR = ss.SurfaceArrayHDR
        data.SurfaceArrayDetails = ss.SurfaceArrayDetails
        data.WaterSurfaces = ss.WaterSurfaces
        file.Write(txtPath, util.Compress(util.TableToJSON(data)))
        local total = math.Round((SysTime() - t0) * 1000, 2)
        print("Finished!  Total construction time: " .. total .. " ms.\n")
    else
        ss.MinimapAreaBounds   = data.MinimapAreaBounds
        ss.SurfaceArrayLDR     = data.SurfaceArrayLDR
        ss.SurfaceArrayHDR     = data.SurfaceArrayHDR
        ss.SurfaceArrayDetails = data.SurfaceArrayDetails
    end

    if #ss.SurfaceArrayHDR > 0 then
        ss.SurfaceArray, ss.SurfaceArrayHDR = ss.SurfaceArrayHDR, nil
    else
        ss.SurfaceArray, ss.SurfaceArrayLDR = ss.SurfaceArrayLDR, nil
    end
    table.Add(ss.SurfaceArray, ss.SurfaceArrayDetails)
    ss.SurfaceArrayLDR = nil
    ss.SurfaceArrayHDR = nil
    ss.SurfaceArrayDetails = nil

    collectgarbage "collect"

    -- This is needed due to a really annoying bug (GitHub/garrysmod-issues #1495)
    SetGlobalBool("SplashSWEPs: IsDedicated", game.IsDedicated())

    -- CRC check clientside
    SetGlobalString("SplashSWEPs: Ink map CRC", util.CRC(file.Read(txtPath)))

    ss.SURFACE_ID_BITS = select(2, math.frexp(#ss.SurfaceArray))
    resource.AddSingleFile("data/" .. txtPath)

    ss.PrecachePaintTextures()
    ss.GenerateHashTable()
    ss.ClearAllInk()
end

---NOTE: PlayerInitialSpawn is called before InitPostEntity on changelevel
---@param ply Player
local function PlayerInitialSpawn(ply)
    ss.InitializeMoveEmulation(ply)
    ss.SynchronizePlayerStats(ply)
    if not ply:IsBot() then ss.ClearAllInk() end
end

---@param ply Player
---@param id string
local function OnPlayerAuthed(ply, id)
    if ss.IsGameInProgress --[[@as boolean?]] then
        ply:Kick "Splash SWEPs: The game is in progress"
        return
    end

    ss.PlayerID[ply] = id
end

---@param ply Player
local function SavePlayerData(ply)
    ---@param v Player
    ---@return boolean
    local function f(v) return v == ply end
    ss.tableremovefunc(ss.PlayersReady, f)
    if not ss.WeaponRecord[ply] then return end
    local id = ss.PlayerID[ply]
    if not id then return end
    local record = "splashsweps/record/" .. id:lower():gsub(":", "_") .. ".txt"
    if not file.Exists("data/splashsweps/record", "GAME") then
        file.CreateDir "splashsweps/record"
    end
    file.Write(record, util.TableToJSON(ss.WeaponRecord[ply], true))

    ss.PlayerID[ply] = nil
    ss.WeaponRecord[ply] = nil
end

local function OnShutdown()
    for _, v in ipairs(player.GetAll()) do
        SavePlayerData(v)
    end
end

---@param ent Entity
---@param dmg CTakeDamageInfo
---@return boolean?
local function OnEntityTakeDamage(ent, dmg)
    if ent:Health() <= 0 then return end
    local w = ss.IsValid(ent)
    local a = dmg:GetAttacker()
    local i = dmg:GetInflictor() --[[@as SplashWeaponBase]]
    if not w then return end
    if IsValid(a) and ss.IsInvincible(ent) then
        ss.ApplyKnockback(ent, dmg:GetDamageForce() * dmg:GetDamage())
        return true
    end
    w.HealSchedule:SetDelay(ss.HealDelay)
    if not (IsValid(a) and i.IsSplashWeapon) then return end
    if ss.IsAlly(w, i) then return true end
    if ss.IsAlly(ent, i) then return true end
    if not ent:IsPlayer() then return end ---@cast ent Player
    net.Start("SplashSWEPs: Play damage sound", true)
    net.Send(ent)
end

---@param ply Player|NPC
---@param attacker Entity
local function OnPlayerDeath(ply, attacker)
    local w = ss.IsValid(ply)
    local inflictor = ss.IsValid(attacker)
    if inflictor and (w or ss.GetOption "explodeeveryone") then
        ss.MakeDeathExplosion(ply:WorldSpaceCenter(), attacker, inflictor:GetNWInt "inkcolor")
    end
end

---@param _ Player
---@param dmg CTakeDamageInfo
---@return boolean?
local function OnDamagedByExplosion(_, dmg)
    local inflictor = dmg:GetInflictor() --[[@as SplashWeaponBase|ENT.Throwable]]
    return IsValid(inflictor) and (inflictor.IsSplashWeapon or inflictor.IsSplashSubWeapon) or nil
end

---@param ent Entity
local function OnEntityRemoved(ent)
    if ss.InvincibleEntities[ent] then
        ss.SetInvincibleDuration(ent, -1)
    end
    for color in pairs(ss.EntityFilters) do
        ss.SetEntityFilter(ent, color, false)
    end
    for color in pairs(ss.PlayerFilters) do
        ss.SetPlayerFilter(ent, color, false)
    end
end

hook.Add("PostCleanupMap", "SplashSWEPs: Cleanup all ink", ss.ClearAllInk)
hook.Add("InitPostEntity", "SplashSWEPs: Serverside Initialization", InitPostEntity)
hook.Add("PlayerInitialSpawn", "SplashSWEPs: Add a player", PlayerInitialSpawn)
hook.Add("PlayerAuthed", "SplashSWEPs: Store player ID", OnPlayerAuthed)
hook.Add("PlayerDisconnected", "SplashSWEPs: Reset player's readiness", SavePlayerData)
hook.Add("ShutDown", "SplashSWEPs: Save player data", OnShutdown)
hook.Add("GetFallDamage", "SplashSWEPs: Players don't take fall damage.", ss.hook "GetFallDamage")
hook.Add("EntityTakeDamage", "SplashSWEPs: Ink damage manager", OnEntityTakeDamage)
hook.Add("EntityRemoved", "SplashSWEPs: Remove regiestered entity", OnEntityRemoved)
hook.Add("DoPlayerDeath", "SplashSWEPs: Death explosion", OnPlayerDeath)
hook.Add("OnNPCKilled", "SplashSWEPs: Death explosion", OnPlayerDeath)
hook.Add("OnDamagedByExplosion", "SplashSWEPs: No sound effect needed", OnDamagedByExplosion)
