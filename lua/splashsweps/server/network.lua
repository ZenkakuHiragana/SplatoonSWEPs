
-- util.AddNetworkString's

---@class ss
local ss = SplashSWEPs
if not ss then return end

util.AddNetworkString "SplashSWEPs: Change throwing"
util.AddNetworkString "SplashSWEPs: Register knockback"
util.AddNetworkString "SplashSWEPs: Play damage sound"
util.AddNetworkString "SplashSWEPs: Ready to splat"
util.AddNetworkString "SplashSWEPs: Redownload ink data"
util.AddNetworkString "SplashSWEPs: Send a sound"
util.AddNetworkString "SplashSWEPs: Send an error message"
util.AddNetworkString "SplashSWEPs: Send an ink queue"
util.AddNetworkString "SplashSWEPs: Send ink cleanup"
util.AddNetworkString "SplashSWEPs: Send player data"
util.AddNetworkString "SplashSWEPs: Send turf inked"
util.AddNetworkString "SplashSWEPs: Strip weapon"
util.AddNetworkString "SplashSWEPs: Sync entity filter"
util.AddNetworkString "SplashSWEPs: Sync invincible entity state"
util.AddNetworkString "SplashSWEPs: Sync player filter"
net.Receive("SplashSWEPs: Ready to splat", function(_, ply)
    ss.PlayersReady[#ss.PlayersReady + 1] = ply
    ss.InitializeMoveEmulation(ply)
    ss.SynchronizePlayerStats(ply)
end)

local RedownloadProgress = {} ---@type table<Player, integer>
net.Receive("SplashSWEPs: Redownload ink data", function(_, ply)
    local data = file.Read(string.format("splashsweps/%s.txt", game.GetMap()))
    local startpos = RedownloadProgress[ply] or 1
    local header, bool, uint, float = 3, 1, 2, 4
    local bps = 65536 - header - bool - uint - float
    local chunk = data:sub(startpos, startpos + bps - 1)
    local size = chunk:len()
    local current = math.floor(startpos / bps)
    local total = math.floor(data:len() / bps)
    RedownloadProgress[ply] = startpos + size
    net.Start "SplashSWEPs: Redownload ink data"
    net.WriteBool(size < bps or data:len() < startpos + bps)
    net.WriteUInt(size, 16)
    net.WriteData(chunk, size)
    net.WriteFloat(current / total)
    net.Send(ply)
    print(string.format("Redownloading ink data to %s (%d/%d)", tostring(ply), current, total))
end)

net.Receive("SplashSWEPs: Send ink cleanup", function(_, ply)
    if not ply:IsAdmin() then return end
    ss.ClearAllInk()
end)

net.Receive("SplashSWEPs: Strip weapon", function(_, ply)
    local weaponID = net.ReadUInt(ss.WEAPON_CLASSNAMES_BITS)
    local weaponClass = ss.WeaponClassNames[weaponID]
    if not weaponClass then return end
    local weapon = ply:GetWeapon(weaponClass)
    if not IsValid(weapon) then return end
    ply:StripWeapon(weaponClass)
end)
