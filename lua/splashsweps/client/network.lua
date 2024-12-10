
-- net.Receive()

---@class ss
local ss = SplashSWEPs
if not ss then return end
net.Receive("SplashSWEPs: Change throwing", function()
    local w = net.ReadEntity() --[[@as SplashWeaponBase]]
    if not (IsValid(w) and w.IsSplashWeapon) then return end
    w.WorldModel = w.ModelPath .. (net.ReadBool() and "w_left.mdl" or "w_right.mdl")
end)

net.Receive("SplashSWEPs: Play damage sound", function()
    sound.Play("SplashSWEPs.TakeDamage", Vector())
end)

local buffer = ""
net.Receive("SplashSWEPs: Redownload ink data", function()
    local finished = net.ReadBool()
    local size = net.ReadUInt(16)
    local data = net.ReadData(size)
    local prog = net.ReadFloat()
    buffer = buffer .. data
    if not finished then
        net.Start "SplashSWEPs: Redownload ink data"
        net.SendToServer()
        notification.AddProgress("SplashSWEPs: Redownload ink data",
            "Downloading ink map... " .. math.Round(prog * 100) .. "%", prog)
        return
    end

    if not file.Exists("splashsweps", "DATA") then file.CreateDir "splashsweps" end
    file.Write(string.format("splashsweps/%s.txt", game.GetMap()), buffer)
    notification.Kill "SplashSWEPs: Redownload ink data"
    ss.PrepareInkSurface(util.JSONToTable(util.Decompress(buffer)))
    notification.AddLegacy(ss.Text.LateReadyToSplat --[[@as string]], NOTIFY_HINT, 8)
end)

net.Receive("SplashSWEPs: Send a sound", function()
    local soundName = net.ReadString()
    local soundLevel = net.ReadUInt(9)
    local pitchPercent = net.ReadUInt(8)
    local volume = net.ReadFloat()
    local channel = net.ReadUInt(8) - 1
    LocalPlayer():EmitSound(soundName, soundLevel, pitchPercent, volume, channel)
end)

net.Receive("SplashSWEPs: Send an error message", function()
    local icon = net.ReadUInt(ss.SEND_ERROR_NOTIFY_BITS)
    local duration = net.ReadUInt(ss.SEND_ERROR_DURATION_BITS)
    local msg = ss.Text.Error[net.ReadString()] --[[@as string?]]
    if not msg then return end
    notification.AddLegacy(msg, icon, duration)
end)

net.Receive("SplashSWEPs: Send ink cleanup", function()
    ss.ClearAllInk() -- Wrap function for auto-refresh
end)

net.Receive("SplashSWEPs: Send player data", function()
    local size = net.ReadUInt(16)
    local record = util.Decompress(net.ReadData(size))
    ss.WeaponRecord[LocalPlayer()] = util.JSONToTable(record) or ss.WeaponRecord[LocalPlayer()]
end)

net.Receive("SplashSWEPs: Send turf inked", function()
    local inked = net.ReadFloat()
    local classname = ss.WeaponClassNames[net.ReadUInt(8)]
    assert(classname, "SplashSWEPs: Invalid classname!")
    ss.WeaponRecord[LocalPlayer()].Inked[classname] = inked
end)

net.Receive("SplashSWEPs: Send an ink queue", function()
    local color = net.ReadUInt(ss.COLOR_BITS)
    local inktype = net.ReadUInt(ss.INK_TYPE_BITS)
    local radius = net.ReadUInt(8)
    local ratio = net.ReadFloat()
    local normal = net.ReadNormal()
    local ang = net.ReadInt(7) * 4
    local x = net.ReadInt(15)
    local y = net.ReadInt(15)
    local z = net.ReadInt(15)
    local order = net.ReadUInt(9)
    local time = net.ReadUInt(5)
    local pos = Vector(x, y, z) * 2
    if color == 0 or inktype == 0 then return end
    ss.ReceiveInkQueue(radius, ang, normal, ratio, color, inktype, pos, order, time)
end)

net.Receive("SplashSWEPs: Sync entity filter", function()
    local ent = net.ReadEntity()
    if not IsValid(ent) then return end
    local color = net.ReadUInt(ss.COLOR_BITS)
    local state = net.ReadBool()
    ss.SetEntityFilter(ent, color, state)
end)

net.Receive("SplashSWEPs: Sync invincible entity state", function()
    local ent = net.ReadEntity()
    local duration = net.ReadFloat()
    ss.SetInvincibleDuration(ent, duration)
end)

net.Receive("SplashSWEPs: Sync player filter", function()
    local ent = net.ReadEntity()
    if not IsValid(ent) then return end
    local color = net.ReadUInt(ss.COLOR_BITS)
    local state = net.ReadBool()
    ss.SetPlayerFilter(ent, color, state)
end)

net.Receive("SplashSWEPs: Register knockback", function()
    ss.KnockbackVector[LocalPlayer()] = net.ReadVector()
end)
