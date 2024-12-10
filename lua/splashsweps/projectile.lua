
---@class ss
local ss = SplashSWEPs
if not ss then return end

---@param ink ss.InkQueue
local function DoScatterSplash(ink)
    local data, p = ink.Data, ink.Parameters
    if CurTime() < data.ScatterSplashTime then return end
    if data.ScatterSplashCount >= p.mScatterSplashMaxNum then return end
    local t = ink.Trace.LifeTime
    local tmin = p.mScatterSplashMinSpanBulletCounter
    local tmax = p.mScatterSplashMaxSpanBulletCounter
    local tfrac = math.TimeFraction(tmin, tmax, t)
    local delaymin = p.mScatterSplashMinSpanFrame
    local delaymax = p.mScatterSplashMaxSpanFrame
    local delay = Lerp(tfrac, delaymin, delaymax)
    local dropdata = ss.MakeProjectileStructure()
    data.ScatterSplashTime = CurTime() + delay
    data.ScatterSplashCount = data.ScatterSplashCount + 1
    table.Merge(dropdata, {
        AirResist = 1e-8,
        Color = data.Color,
        ColRadiusEntity = p.mScatterSplashColRadius,
        ColRadiusWorld = p.mScatterSplashColRadius,
        DoDamage = false,
        Gravity = ss.InkDropGravity,
        InitPos = ink.Trace.endpos,
        PaintFarRadius = p.mScatterSplashPaintRadius,
        PaintFarRatio = 1,
        PaintNearRadius = p.mScatterSplashPaintRadius,
        PaintNearRatio = 1,
        StraightFrame = ss.FrameToSec,
        Type = ss.GetDropType(),
        Weapon = data.Weapon,
        Yaw = data.Yaw,
    })

    local rand = "SplashSWEPs: Scatter offset"
    local ang = data.InitDir:Angle()
    local offsetdir = ang:Right()
    local offsetmin = p.mScatterSplashInitPosMinOffset
    local offsetmax = p.mScatterSplashInitPosMaxOffset
    local offsetsign = math.Round(util.SharedRandom(rand, 0, 1, CurTime())) * 2 - 1
    local offsetamount = util.SharedRandom(rand, offsetmin, offsetmax, CurTime() * 2)
    local offsetvec = offsetdir * offsetsign * offsetamount

    local initspeed = p.mScatterSplashInitSpeed
    local initang = Angle(ang)
    local rotmax = util.SharedRandom(rand, 0, 1, CurTime() * 3) > 0.5
        and -p.mScatterSplashUpDegree or p.mScatterSplashDownDegree
    local bias = p.mScatterSplashDegreeBias
    local selectbias = bias > util.SharedRandom(rand, 0, 1, CurTime() * 4)
    local frac = util.SharedRandom(rand,
        selectbias and bias or 0, selectbias and 1 or bias, CurTime() * 5)

    initang:RotateAroundAxis(initang:Forward(), frac * rotmax * offsetsign)
    dropdata.InitPos = dropdata.InitPos + offsetvec
    dropdata.InitVel = initang:Right() * offsetsign * initspeed
    ss.AddInk(p, dropdata)
    ss.CreateDropEffect(dropdata, p.mScatterSplashPaintRadius, ink.Owner)
end

---@param ink ss.InkQueue
local function Simulate(ink)
    if IsFirstTimePredicted() then ss.DoDropSplashes(ink) end
    ink.CurrentSpeed = ink.Trace.start:Distance(ink.Trace.endpos) / FrameTime()
    ss.AdvanceBullet(ink)

    if not IsFirstTimePredicted() then return end
    if ink.Data.ScatterSplashCount then DoScatterSplash(ink) end
    if not ink.Data.Weapon.IsBlaster then return end
    if not ink.Data.DoDamage then return end

    local tr, p = ink.Trace, ink.Parameters
    if tr.LifeTime <= p.mExplosionFrame then return end
    if ink.Exploded then return end
    ink.BlasterRemoval = p.mExplosionSleep
    ink.Exploded = true
    tr.collisiongroup = COLLISION_GROUP_DEBRIS
    ss.MakeBlasterExplosion(ink)
end

---@param ink ss.InkQueue
---@param t   TraceResult
local function HitSmoke(ink, t) -- FIXME: Don't emit it twice
    local data, weapon = ink.Data, ink.Data.Weapon
    if not t.HitWorld or CurTime() - ink.InitTime > data.StraightFrame then return end
    local e = EffectData()
    e:SetAttachment(0)
    e:SetColor(data.Color)
    e:SetEntity(game.GetWorld())
    e:SetFlags(PATTACH_ABSORIGIN)
    e:SetOrigin(t.HitPos + t.HitNormal * 10)
    e:SetScale(6)
    e:SetStart(data.InitPos)
    util.Effect("SplashSWEPsMuzzleMist", e, true, weapon.IgnorePrediction)
end

---@param ink ss.InkQueue
---@param t   TraceResult
local function HitPaint(ink, t)
    local data, tr, weapon = ink.Data, ink.Trace, ink.Data.Weapon
    local g_dir = ss.GetGravityDirection()
    local hitfloor = -t.HitNormal:Dot(g_dir) > ss.MAX_COS_DIFF
    local lmin = data.PaintNearDistance
    local lmin_ratio = data.PaintRatioNearDistance
    local lmax = data.PaintFarDistance
    local lmax_ratio = data.PaintRatioFarDistance
    local rmin = data.PaintNearRadius
    local rmax = data.PaintFarRadius
    local ratio_min = data.PaintNearRatio
    local ratio_max = data.PaintFarRatio
    local length = math.Clamp(tr.LengthSum, lmin, lmax)
    local length2d = math.Clamp((t.HitPos - data.InitPos):Length2D(), lmin_ratio, lmax_ratio)
    local radius = math.Remap(length, lmin, lmax, rmin, rmax)
    local ratio = math.Remap(length2d, lmin_ratio, lmax_ratio, ratio_min, ratio_max)
    if length == lmin and lmin == lmax then radius = rmax end -- Avoid NaN
    if length2d == lmin_ratio and lmin_ratio == lmax_ratio then ratio = ratio_max end
    if length2d == lmin_ratio then data.Type = ss.GetDropType() end
    if data.DoDamage then
        if weapon.IsCharger then
            HitSmoke(ink, t) -- TODO: Add smoke if the surface is not paintable
            local radiusmul = ink.Parameters.mPaintRateLastSplash or 1
            if not hitfloor then radius = radius * Lerp(data.Charge or 0, radiusmul, 1) end
            if tr.LengthSum < (data.Range or 0) then
                local cos = math.Clamp(-data.InitDir.z, ss.MAX_COS_DIFF, 1)
                ratio = math.Remap(cos, ss.MAX_COS_DIFF, 1, ratio, 1)
            elseif hitfloor then
                radius = radius * radiusmul
            end
        elseif weapon.IsBlaster then
            data.DoDamage = false
            data.Type = ss.GetDropType()
            if not ink.Exploded then
                ink.BlasterHitWall = true
                tr.endpos:Set(t.HitPos)
                ss.MakeBlasterExplosion(ink)
            end
        end
    end

    if not hitfloor then
        ratio = 1
        data.Type = ss.GetDropType()
    end

    if (ss.sp or CLIENT and IsFirstTimePredicted()) and t.Hit and data.DoDamage then
        sound.Play("SplashSWEPs_Ink.HitWorld", t.HitPos)
    end

    ss.Paint(t.HitPos, t.HitNormal, radius * ratio, data.Color,
    data.Yaw, data.Type, 1 / ratio, ink.Owner, weapon.ClassName)

    if not data.DoDamage then return end
    if hitfloor then return end

    local n = data.WallPaintMaxNum or 0
    if data.WallPaintUseSplashNum then n = data.SplashNum - data.SplashCount end
    for i = 1, n do
        local pos = t.HitPos + g_dir * data.WallPaintFirstLength
        if i > 1 then pos:Add(g_dir * (i - 1) * data.WallPaintLength) end
        local tn = util.TraceLine {
            collisiongroup = COLLISION_GROUP_INTERACTIVE_DEBRIS,
            endpos = pos - t.HitNormal,
            filter = tr.filter,
            mask = ss.CrouchingSolidMask,
            start = data.InitPos,
        }

        if math.abs(tn.HitNormal:Dot(g_dir)) < ss.MAX_COS_DIFF
        and not tn.StartSolid and tn.HitWorld then
            ss.PaintSchedule[{
                pos = tn.HitPos,
                normal = tn.HitNormal,
                radius = data.WallPaintRadius,
                color = data.Color,
                angle = data.Yaw,
                inktype = ss.GetDropType(),
                ratio = 1,
                Time = CurTime() + i * data.WallPaintRadius / ink.CurrentSpeed,
                filter = tr.filter,
                ClassName = data.Weapon.ClassName,
                Owner = ink.Owner,
            }] = true
        end
    end
end

---Called when ink collides with an entity
---@param ink ss.InkQueue
---@param t TraceResult
local function HitEntity(ink, t)
    local data, tr, weapon = ink.Data, ink.Trace, ink.Data.Weapon
    local d, e, o = DamageInfo(), t.Entity, weapon:GetOwner() ---@cast e -?
    if weapon.IsCharger and data.Range and tr.LengthSum > data.Range then return end
    if ss.LastHitID[e] == data.ID then return end
    ss.LastHitID[e] = data.ID -- Avoid multiple damages at once

    local decay_start = data.DamageMaxDistance
    local decay_end = data.DamageMinDistance
    local damage_max = data.DamageMax
    local damage_min = data.DamageMin
    local damage = damage_max
    if not weapon.IsCharger then
        local value = tr.LengthSum
        if weapon.IsShooter then
            value = math.max(CurTime() - ink.InitTime, 0)
        end

        local frac = math.Remap(value, decay_start, decay_end, 0, 1)
        damage = Lerp(frac, damage_max, damage_min)
    end

    local flags = 0
    local te = util.TraceLine { start = t.HitPos, endpos = e:WorldSpaceCenter() }
    if data.IsCritical            then flags = flags + 1 end
    if ss.IsInvincible(e)         then flags = flags + 8 end
    if ink.IsCarriedByLocalPlayer then flags = flags + 128 end
    ss.CreateHitEffect(data.Color, flags, te.HitPos, te.HitNormal, weapon)
    if ss.mp and CLIENT then return end

    local dt = bit.bor(DMG_AIRBOAT, DMG_REMOVENORAGDOLL)
    if not e:IsPlayer() then dt = bit.bor(dt, DMG_DISSOLVE) end
    d:SetDamage(damage)
    d:SetDamageForce(-t.HitNormal * 100)
    d:SetDamagePosition(t.HitPos)
    d:SetDamageType(dt)
    d:SetMaxDamage(damage_max)
    d:SetReportedPosition(t.StartPos)
    d:SetAttacker(IsValid(o) and o or game.GetWorld())
    d:SetInflictor(IsValid(weapon) and weapon or game.GetWorld())
    d:ScaleDamage(ss.ToHammerHealth * ss.GetDamageScale())
    ss.ProtectedCall(e.TakeDamageInfo, e, d)
end

---@param ink ss.InkQueue
---@param ply Entity?
---@return boolean
local function ProcessInkQueue(ink, ply)
    if not ink then return true end
    local data, tr, weapon = ink.Data, ink.Trace, ink.Data.Weapon
    local removal = not IsValid(ink.Owner)
    or not IsValid(weapon)
    or not IsValid(weapon:GetOwner())

    if not removal and Either(not ply, IsValid(ink.Owner)
    and not ink.Owner:IsPlayer() or data.Inflictor, ink.Owner == ply) then
        tr.filter = ss.MakeAllyFilter(weapon)
        Simulate(ink)
        if tr.start:DistToSqr(tr.endpos) > 0 then
            tr.maxs = ss.vector_one * data.ColRadiusWorld
            tr.mins = -tr.maxs
            tr.mask = ss.CrouchingSolidMaskBrushOnly
            local trworld = util.TraceHull(tr)
            tr.maxs = ss.vector_one * data.ColRadiusEntity
            tr.mins = -tr.maxs
            tr.mask = ss.CrouchingSolidMask
            local trent = util.TraceHull(tr)
            tr.LengthSum = tr.LengthSum + tr.start:Distance(trent.HitPos)
            if ink.BlasterRemoval or not (trworld.Hit or ss.IsInWorld(trworld.HitPos)) then
                removal = true
            elseif data.DoDamage and IsValid(trent.Entity) and trent.Entity:Health() > 0 then
                local w = ss.IsValid(trent.Entity) -- If ink hits someone
                if not (ss.IsAlly(trent.Entity, data.Color) or w and ss.IsAlly(w, data.Color)) then
                    HitEntity(ink, trent)
                end
                removal = true
            elseif trworld.Hit then
                if trworld.StartSolid and tr.LifeTime < ss.FrameToSec then trworld = util.TraceLine(tr) end
                if trworld.Hit and not (trworld.StartSolid and tr.LifeTime < ss.FrameToSec) then
                    tr.endpos = trworld.HitPos - trworld.HitNormal * data.ColRadiusWorld * 2
                    HitPaint(ink, util.TraceLine(tr))
                    removal = true
                end
            end
        end
    end

    return removal
end

local CurTime = CurTime
local IsFirstTimePredicted = IsFirstTimePredicted
local SortedPairs = SortedPairs
local SysTime = SysTime
local pairs = pairs
local yield = coroutine.yield
---@param ply Entity?
local function ProcessInkQueueAll(ply)
    local Benchmark = SysTime()
    while true do
        repeat yield() until IsFirstTimePredicted()
        Benchmark = SysTime()
        for inittime, inkgroup in SortedPairs(ss.InkQueue) do
            if not inkgroup then
                ss.InkQueue[inittime] = nil
                continue
            end
            local k = 1
            for i = 1, #inkgroup do
                local ink = inkgroup[i]
                if ProcessInkQueue(ink, ply) then
                    inkgroup[i] = nil
                else -- Move i's kept value to k's position, if it's not already there.
                    if i ~= k then inkgroup[k], inkgroup[i] = ink, nil end
                    k = k + 1 -- Increment position of where we'll place the next kept value.
                end

                if #inkgroup == 0 then
                    ss.InkQueue[inittime] = nil
                end

                if SysTime() - Benchmark > ss.FrameToSec then
                    yield()
                    Benchmark = SysTime()
                end
            end
        end

        for ink in pairs(ss.PaintSchedule) do
            if CurTime() > ink.Time then
                ss.Paint(ink.pos, ink.normal, ink.radius, ink.color,
                ink.angle, ink.inktype, ink.ratio, ink.Owner, ink.ClassName)
                ss.PaintSchedule[ink] = nil

                if SysTime() - Benchmark > ss.FrameToSec then
                    yield()
                    Benchmark = SysTime()
                end
            end
        end
    end
end

---@param color integer
---@param flags integer
---@param pos Vector
---@param normal Vector
---@param weapon SplashWeaponBase
function ss.CreateHitEffect(color, flags, pos, normal, weapon)
    local filter = nil
    local e = EffectData()
    local Owner = weapon:GetOwner()
    if IsValid(Owner) and Owner:IsPlayer() then ---@cast Owner Player
        if SERVER then
            filter = RecipientFilter()
            filter:AddPlayer(Owner)
        end
        e:SetColor(color)
        e:SetFlags(flags)
        e:SetOrigin(pos)
        util.Effect("SplashSWEPsOnHit", e, true, filter)
    end

    e:SetAngles(normal:Angle())
    e:SetAttachment(6)
    e:SetEntity(NULL)
    e:SetFlags(128 + 16)
    e:SetOrigin(pos)
    e:SetRadius(50)
    e:SetScale(.4)
    util.Effect("SplashSWEPsMuzzleSplash", e, true, SERVER)
end

---@param params      Parameters
---@param pos         Vector
---@param color       integer
---@param weapon      SplashWeaponBase
---@param colradius   number
---@param paintradius number
---@param paintratio  number
---@param yaw         number
function ss.CreateDrop(params, pos, color, weapon, colradius, paintradius, paintratio, yaw)
    local dropdata = ss.MakeProjectileStructure()
    table.Merge(dropdata, {
        Color = color,
        ColRadiusEntity = colradius,
        ColRadiusWorld = colradius,
        DoDamage = false,
        Gravity = ss.InkDropGravity,
        InitPos = pos,
        PaintFarRadius = paintradius,
        PaintFarRatio = paintratio or 1,
        PaintNearRadius = paintradius,
        PaintNearRatio = paintratio or 1,
        Range = 0,
        Type = ss.GetDropType(),
        Weapon = weapon,
        Yaw = yaw or 0,
    })

    ss.AddInk(params, dropdata)
end

---@param data Projectile
---@param drawradius number
---@param owner Entity?
function ss.CreateDropEffect(data, drawradius, owner)
    local e = EffectData()
    ss.SetEffectColor(e, data.Color)
    ss.SetEffectColRadius(e, data.ColRadiusWorld)
    ss.SetEffectDrawRadius(e, drawradius)
    ss.SetEffectEntity(e, data.Weapon)
    ss.SetEffectFlags(e, data.Weapon, 8 + 4)
    ss.SetEffectInitPos(e, data.InitPos)
    ss.SetEffectInitVel(e, data.InitVel)
    ss.SetEffectSplash(e, Angle(data.AirResist * 180, data.Gravity / ss.InkDropGravity * 180))
    ss.SetEffectSplashInitRate(e, Vector(0))
    ss.SetEffectSplashNum(e, 0)
    ss.SetEffectStraightFrame(e, data.StraightFrame)
    if IsValid(owner) and --[[@cast owner -?]] owner:IsPlayer() then
        ss.UtilEffectPredicted(owner, "SplashSWEPsShooterInk", e)
    else
        util.Effect("SplashSWEPsShooterInk", e)
    end
end

---@param ink ss.InkQueue
---@param iseffect boolean?
function ss.DoDropSplashes(ink, iseffect)
    local data, tr, p = ink.Data, ink.Trace, ink.Parameters
    if not data.DoDamage then return end
    if data.SplashCount >= data.SplashNum then return end
    local IsBlaster = data.Weapon.IsBlaster
    local IsCharger = data.Weapon.IsCharger
    local DropDir = data.InitDir
    local Length = tr.endpos:Distance(data.InitPos)
    local NextLength = (data.SplashCount + data.SplashInitRate) * data.SplashLength
    if not IsCharger then
        Length = (tr.endpos - data.InitPos):Length2D()
        DropDir = Vector(data.InitDir.x, data.InitDir.y, 0):GetNormalized()
    end

    while Length >= NextLength and data.SplashCount < data.SplashNum do -- Creates ink drops
        local droppos = data.InitPos + DropDir * NextLength
        if not IsCharger then
            local frac = NextLength / Length
            if frac ~= frac then frac = 0 end -- In case of NaN
            droppos.z = Lerp(frac, data.InitPos.z, tr.endpos.z)
        end

        local hull = {
            collisiongroup = COLLISION_GROUP_INTERACTIVE_DEBRIS,
            start = data.InitPos,
            endpos = droppos,
            filter = tr.filter,
            mask = ss.CrouchingSolidMask,
            maxs = tr.maxs,
            mins = tr.mins,
        }
        local t = util.TraceHull(hull)
        if iseffect then
            local e = EffectData()
            if IsBlaster then
                e:SetColor(data.Color)
                e:SetNormal(data.InitDir)
                e:SetOrigin(t.HitPos)
                e:SetRadius(p.mCollisionRadiusNear / 2)
                ss.UtilEffectPredicted(ink.Owner, "SplashSWEPsBlasterTrail", e)
            end

            ss.SetEffectColor(e, data.Color)
            ss.SetEffectColRadius(e, data.SplashColRadius)
            ss.SetEffectDrawRadius(e, data.SplashDrawRadius)
            ss.SetEffectEntity(e, data.Weapon)
            ss.SetEffectFlags(e, 1)
            ss.SetEffectInitPos(e, droppos + ss.GetGravityDirection() * data.SplashDrawRadius)
            ss.SetEffectInitVel(e, Vector())
            ss.SetEffectSplash(e, Angle(0, 0, data.SplashLength / ss.ToHammerUnits))
            ss.SetEffectSplashInitRate(e, Vector(0))
            ss.SetEffectSplashNum(e, 0)
            ss.SetEffectStraightFrame(e, 0)
            if IsCharger then
                ss.SetEffectInitVel(e, tr.endpos - tr.start)
            end

            ss.UtilEffectPredicted(ink.Owner, "SplashSWEPsShooterInk", e)
        else
            hull.start = droppos
            hull.endpos = droppos + data.InitDir * data.SplashLength
            ss.CreateDrop(p, t.HitPos, data.Color, data.Weapon,
            data.SplashColRadius, data.SplashPaintRadius, data.SplashRatio, data.Yaw)
            if util.TraceHull(hull).Hit then break end
        end

        NextLength = NextLength + data.SplashLength
        data.SplashCount = data.SplashCount + 1
    end
end

---Make an ink bullet for shooter
---@param parameters Parameters|{} Table contains weapon parameters
---@param data       Projectile    Table contains ink bullet data
---@return ss.InkQueue
function ss.AddInk(parameters, data)
    local w = data.Weapon
    if not IsValid(w) then return {} end
    local ply = w:GetOwner()
    local t = ss.MakeInkQueueStructure()
    t.Data = table.Copy(data)
    t.IsCarriedByLocalPlayer = Either(SERVER, false, ss.ProtectedCall(w.IsCarriedByLocalPlayer, w))
    t.Owner = ply
    t.Parameters = parameters
    t.Trace.filter = ply
    t.Trace.endpos:Set(data.InitPos)
    t.Data.InitDir = t.Data.InitVel:GetNormalized()
    t.Data.InitSpeed = t.Data.InitVel:Length()
    t.CurrentSpeed = t.Data.InitSpeed

    local t0 = t.InitTime
    local dest = ss.InkQueue[t0] or {}
    ss.InkQueue[t0], dest[#dest + 1] = dest, t
    return t
end

local processes = {} ---@type table<Player|boolean, thread>
local ErrorNoHalt = ErrorNoHalt
local create = coroutine.create
local status = coroutine.status
local resume = coroutine.resume
local Empty = table.Empty
---@param ply Player?
local function RunCoroutines(ply)
    local p = processes[ply or true]
    if not p or status(p) == "dead" then
        processes[ply or true] = create(ProcessInkQueueAll)
        p = processes[ply or true]
        Empty(ss.InkQueue)
    end

    if ply then ply:LagCompensation(true) end
    local ok, msg = resume(p, ply)
    if ply then ply:LagCompensation(false) end
    if ok then return end
    ErrorNoHalt(msg)
end
hook.Add("Move", "SplashSWEPs: Simulate ink", RunCoroutines)
hook.Add("Tick", "SplashSWEPs: Simulate ink", RunCoroutines)

---Physics simulation for ink trajectory.
---The first some frames(1/60 sec.) ink flies without gravity.
---After that, ink decelerates horizontally and is affected by gravity.
---@param InitVel       Vector Initial velocity in Hammer units/s
---@param StraightFrame number Time to go straight in seconds
---@param AirResist     number Air resistance after it goes straight (0-1)
---@param Gravity       number Gravity acceleration in Hammer units/s^2
---@param t             number Time in seconds
---@return Vector
function ss.GetBulletPos(InitVel, StraightFrame, AirResist, Gravity, t)
    local tf = math.max(t - StraightFrame, 0) -- Time for being "free state"
    local tg = tf^2 / 2 -- Time for applying gravity
    local g = ss.GetGravityDirection() * Gravity -- Gravity accelerator
    local tlim = math.min(t, StraightFrame) -- Time limited to go straight
    local f = tf * ss.SecToFrame -- Frames for air resistance
    local ratio = 1 - AirResist
    local resist = (ratio^f - 1) / math.log(ratio) * ss.FrameToSec
    if resist ~= resist then resist = t - tlim end

    -- Additional pos = integral[ts -> t] InitVel * AirResist^u du (ts < t)
    return InitVel * (tlim + resist) + g * tg
end

---@param ink ss.InkQueue
function ss.AdvanceBullet(ink)
    local data, tr = ink.Data, ink.Trace
    local t = math.max(CurTime() - ink.InitTime, 0)
    tr.start:Set(tr.endpos)
    tr.endpos:Set(data.InitPos + ss.GetBulletPos(
        data.InitVel, data.StraightFrame, data.AirResist, data.Gravity, t))
    tr.LifeTime = t
end
