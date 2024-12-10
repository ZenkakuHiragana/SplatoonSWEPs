
-- Shared library

---@class ss
local ss = SplashSWEPs
if not ss then return end

-- The function names of EffectData() don't make sense, renaming.
do local e = EffectData()
    ss.GetEffectSplash         = e.GetAngles -- Angle(SplashColRadius, SplashDrawRadius, SplashLength)
    ss.SetEffectSplash         = e.SetAngles
    ss.GetEffectColor          = e.GetColor
    ss.SetEffectColor          = e.SetColor
    ss.GetEffectColRadius      = e.GetRadius
    ss.SetEffectColRadius      = e.SetRadius
    ss.GetEffectDrawRadius     = e.GetMagnitude
    ss.SetEffectDrawRadius     = e.SetMagnitude
    ss.GetEffectEntity         = e.GetEntity
    ss.SetEffectEntity         = e.SetEntity
    ss.GetEffectInitPos        = e.GetOrigin
    ss.SetEffectInitPos        = e.SetOrigin
    ss.GetEffectInitVel        = e.GetStart
    ss.SetEffectInitVel        = e.SetStart
    ss.GetEffectSplashInitRate = e.GetNormal
    ss.SetEffectSplashInitRate = e.SetNormal
    ss.GetEffectSplashNum      = e.GetSurfaceProp
    ss.SetEffectSplashNum      = e.SetSurfaceProp
    ss.GetEffectStraightFrame  = e.GetScale
    ss.SetEffectStraightFrame  = e.SetScale
    ss.GetEffectFlags = e.GetFlags
    ---@param eff CEffectData
    ---@param weapon integer|SplashWeaponBase?
    ---@param flags integer?
    function ss.SetEffectFlags(eff, weapon, flags)
        if isnumber(weapon) and not flags then ---@cast weapon integer
            flags, weapon = weapon, nil
        end

        flags = flags or 0 ---@cast flags integer
        if IsValid(weapon) then ---@cast weapon SplashWeaponBase
            local IsLP = CLIENT and weapon:IsCarriedByLocalPlayer()
            flags = flags + (IsLP and 128 or 0)
        end

        eff:SetFlags(flags)
    end

    ---Dispatch an effect properly in a weapon predicted hook.
    ---@param ply Entity? The owner of the weapon
    ---@param ... any     Arguments of util.Effect()
    function ss.UtilEffectPredicted(ply, ...)
        ss.SuppressHostEventsMP(ply)
        util.Effect(...)
        ss.EndSuppressHostEventsMP(ply)
    end
end

include "util.lua"
include "debug.lua"
include "bsploader.lua"
include "explosion.lua"
include "fixings.lua"
include "text.lua"
include "convars.lua"
include "hash.lua"
include "inkcolorgrid.lua"
include "movement.lua"
include "packer.lua"
include "painttexture.lua"
include "projectile.lua"
include "structure.lua"
include "weapons.lua"
include "weaponregistration.lua"

for _, filename in ipairs(file.Find("splashsweps/subs/*.lua", "LUA") or {}) do
    include("splashsweps/subs/" .. filename)
end
for _, filename in ipairs(file.Find("splashsweps/specials/*.lua", "LUA") or {}) do
    include("splashsweps/specials/" .. filename)
end

local CrouchMask = bit.bnot(IN_DUCK)
local WALLCLIMB_KEYS = bit.bor(IN_JUMP, IN_FORWARD, IN_BACK)

---@param w SplashWeaponBase
---@param ply Player
---@param mv CMoveData
function ss.PredictedThinkMoveHook(w, ply, mv)
    ss.ProtectedCall(w.Move, w, ply, mv)

    -- Check if it should forcibly stand up
    local crouching = ply:Crouching()
    if w:CheckCanStandup() and w:GetKey() ~= 0 and w:GetKey() ~= IN_DUCK
    or w:GetSpecialActivated() and w.SuppressCrouchingSpecial
    or CurTime() > w:GetEnemyInkTouchTime() + ss.EnemyInkCrouchEndurance and ply:KeyDown(IN_DUCK)
    or CurTime() < w:GetCooldown() then
        mv:SetButtons(bit.band(mv:GetButtons(), CrouchMask))
        crouching = false
    end

    -- Player speed clip
    local maxspeed = math.min(mv:GetMaxSpeed(), w.PlayerSpeed * 1.1)
    if ply:OnGround() then
        maxspeed = ss.ProtectedCall(w.CustomMoveSpeed, w) or w.PlayerSpeed
        if crouching         then maxspeed = maxspeed * ss.CrouchedSpeedOutofInk   end
        if w:GetInInk()      then maxspeed = w.CrouchedSpeed                       end
        if w:GetOnEnemyInk() then maxspeed = w.OnEnemyInkSpeed                     end
        if w:GetThrowing()   then maxspeed = maxspeed * ss.PlayerSpeedMulSubWeapon end
        ply:SetWalkSpeed(maxspeed)
        if w:GetNWBool "allowsprint" and not (crouching or w:GetInInk() or w:GetOnEnemyInk()) then
            maxspeed = Lerp(0.5, maxspeed, w.CrouchedSpeed) -- Sprint speed
        end

        mv:SetMaxSpeed(maxspeed)
        ply:SetRunSpeed(maxspeed)
    end

    -- Pad support: reset third person camera key input
    if ss.PlayerShouldResetCamera[ply] then
        local a = ply:GetAimVector():Angle()
        a.p = math.NormalizeAngle(a.p) / 2
        ply:SetEyeAngles(a)
        ss.PlayerShouldResetCamera[ply] = math.abs(a.p) > 1
    end

    local jumppower = w.JumpPower
    if w:GetOnEnemyInk() then jumppower = jumppower * ss.JumpPowerMulOnEnemyInk end
    ply:SetJumpPower(jumppower)
    if CLIENT and w:GetNWInt "inkcolor" > 0 then w:UpdateInkState() end -- Ink state prediction

    -- Swimming on the wall
    ss.PerformWallClimb(w, ply, mv, crouching, maxspeed)

    -- Send viewmodel animation.
    if crouching then
        -- w.LoopSounds.SwimSound.SoundPatch:ChangeVolume(math.Clamp(mv:GetVelocity():Length() / w.CrouchedSpeed * (w:GetInInk() and 1 or 0), 0, 1))
        if not w:GetOldCrouching() then
            w:SetWeaponAnim(ss.ViewModel.Crouching)
            if w:GetNWInt "playermodel" ~= ss.PLAYER.NOCHANGE then
                ply:RemoveAllDecals()
            end

            if IsFirstTimePredicted() then
                ss.EmitSoundPredicted(ply, w, "SplashSWEPs_Player.ToCrouched")
            end
        end
    elseif w:GetOldCrouching() then
        -- w.LoopSounds.SwimSound.SoundPatch:ChangeVolume(0)
        w:SetWeaponAnim(w:GetThrowing() and ss.ViewModel.Throwing or ss.ViewModel.Standing)
        if IsFirstTimePredicted() then
            ss.EmitSoundPredicted(ply, w, "SplashSWEPs_Player.ToStand")
        end
    end

    -- Apply knockback
    if (ss.sp or IsFirstTimePredicted()) and ss.KnockbackVector[ply] then
        mv:SetVelocity(mv:GetVelocity() + ss.KnockbackVector[ply])
        ss.KnockbackVector[ply]:Div(2)
        if ss.KnockbackVector[ply]:IsEqualTol(vector_origin, 10) then
            ss.KnockbackVector[ply] = nil
        end
    end

    w.OnOutofInk = w:GetInWallInk()
    w:SetOldCrouching(crouching)
end

---@param w SplashWeaponBase
---@param ply Player
---@param mv CMoveData
---@param crouching boolean
---@param maxspeed number
function ss.PerformWallClimb(w, ply, mv, crouching, maxspeed)
    for v, i in pairs {
        [mv:GetVelocity()] = true, -- Current velocity
        [ss.MoveEmulation.m_vecVelocity[ply] or false] = false,
    } do
        if not v then continue end
        local speed, vz = v:Length2D(), v.z -- Horizontal speed, Z component
        if w:GetInWallInk() and mv:KeyDown(WALLCLIMB_KEYS) then -- Wall climbing
            local sp = ply:GetShootPos()
            local t = {
                start = sp, endpos = sp + ply:GetForward() * 32768,
                mask = ss.CrouchingSolidMask,
                collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT,
                filter = ply,
            }
            local fw = util.TraceLine(t)
            t.endpos = sp - ply:GetForward() * 32768
            local bk = util.TraceLine(t)
            if fw.Fraction < bk.Fraction == mv:KeyDown(IN_FORWARD) then
                vz = math.max(math.abs(vz) * -.75,
                vz + math.min(12 + (mv:KeyPressed(IN_JUMP) and maxspeed or 0), maxspeed))
                if ply:OnGround() then
                    t.endpos = sp + ply:GetRight() * 32768
                    local r = util.TraceLine(t)
                    t.endpos = sp - ply:GetRight() * 32768
                    local l = util.TraceLine(t)
                    if math.min(fw.Fraction, bk.Fraction) < math.min(r.Fraction, l.Fraction) then
                        mv:AddKey(IN_JUMP)
                    end
                end
            end

            t.start = mv:GetOrigin()
            t.endpos = t.start + vector_up * ss.WALLCLIMB_STEP_CHECK_LENGTH
            t.mins, t.maxs = ply:GetCollisionBounds()
            local tr = util.TraceHull(t)
            if tr.HitWorld then
                t.start = t.endpos + w:GetWallNormal() * ss.MAX_WALLCLIMB_STEP
                tr = util.TraceHull(t)
                if not tr.StartSolid and math.abs(tr.HitNormal.z) < ss.MAX_COS_DIFF then
                    mv:SetOrigin(tr.HitPos)
                end
            end
        end

        if not (crouching and ply:OnGround()) and speed > maxspeed then -- Limits horizontal speed
            v:Mul(maxspeed / speed)
            speed = math.min(speed, maxspeed)
        end

        v.z = math.min(vz, ply:GetJumpPower())
        if i then mv:SetVelocity(v) end
    end
end

---Short for Entity:NetworkVar()
---A new function Entity:AddNetworkVar() is created to the given entity
---@param ent Entity The entity to add to
function ss.AddNetworkVar(ent)
    ---@class INetworkVar
    ---@field NetworkSlot table<string, integer>
    ---@field AddNetworkVar      fun(self, type: string, name: string): integer
    ---@field GetLastSlot        fun(self, typeof: string): integer
    ---@field InitNetworkSlots   fun(self)

    ---@class _NetworkVarImplemented : Entity, INetworkVar
    ---@cast ent _NetworkVarImplemented
    if ent.NetworkSlot then return end
    function ent:InitNetworkSlots()
        self.NetworkSlot = {
            String = -1, Bool = -1, Float = -1, Int = -1,
            Vector = -1, Angle = -1, Entity = -1,
        }
    end
    ent:InitNetworkSlots()

    ---Returns how many network slots the entity uses
    ---@param typeof string Type to inspect
    ---@return integer # The number of slots it uses
    function ent:GetLastSlot(typeof)
        return self.NetworkSlot[typeof]
    end

    ---Adds a new network variable to the entity
    ---@param typeof string Type of the variable, same as Entity:NetworkVar()
    ---@param name   string Name of the variable
    ---@return integer # New assigned slot
    function ent:AddNetworkVar(typeof, name)
        assert(self.NetworkSlot[typeof] < 31, "SplashSWEPs: Tried to use too many network variables!")
        self.NetworkSlot[typeof] = self.NetworkSlot[typeof] + 1
        self:NetworkVar(typeof, self.NetworkSlot[typeof], name)
        return self.NetworkSlot[typeof]
    end
end

---Lets the given entity use CurTime() based timer library
---Call this in the header, and put SplashSWEPs.ProcessSchedules() in ENT:Think()
---@param ent Entity The entity to be able to use timer library
function ss.AddTimerFramework(ent)
    ---@class ISchedule
    ---@field delay           string|number
    ---@field done            string|integer
    ---@field func            fun(self: Entity, schedule: ISchedule): boolean?
    ---@field numcall         string|integer
    ---@field time            string|number
    ---@field prevtime        string|number
    ---@field weapon          SplashWeaponBase
    ---@field SetDone         fun(self, done: integer)
    ---@field GetDone         fun(self): integer
    ---@field SetDelay        fun(self, newdelay: number)
    ---@field GetDelay        fun(self): number
    ---@field SetLastCalled   fun(self, newtime: number)
    ---@field SinceLastCalled fun(self): number

    ---@class EntityNetworkSchedule : ISchedule
    ---@field delay    string
    ---@field done     string
    ---@field func     fun(self: Entity, schedule: ISchedule): boolean?
    ---@field numcall  string
    ---@field time     string
    ---@field prevtime string
    ---@field weapon   SplashWeaponBase

    ---@class EntitySchedule : ISchedule
    ---@field delay    number
    ---@field done     integer
    ---@field func     fun(self: Entity, schedule: ISchedule): boolean?
    ---@field numcall  integer
    ---@field time     number
    ---@field prevtime number
    ---@field weapon   SplashWeaponBase

    ---@alias _AddScheduleSignetures
    ---| fun(self, delay: number, repitition: integer, hook: fun(self: Entity, schedule: ISchedule): boolean?): EntitySchedule
    ---| fun(self, delay: number, hook: fun(self: Entity, schedule: ISchedule): boolean?): EntitySchedule
    ---@class INetworkSchedule
    ---@field FunctionQueue      ISchedule[]
    ---@field AddNetworkSchedule fun(self, repitition: integer, hook: fun(self: Entity, schedule: ISchedule)): EntityNetworkSchedule
    ---@field AddSchedule        _AddScheduleSignetures
    ---@field ProcessSchedules   fun(self)

    ---@class _NetworkScheduleImplemented : INetworkVar, INetworkSchedule, Entity
    ---@cast ent _NetworkScheduleImplemented
    if ent.FunctionQueue then return end

    ss.AddNetworkVar(ent) -- Required to use Entity:AddNetworkSchedule()
    ent.FunctionQueue = {}

    ---@class ISchedule
    local ScheduleFunc = {}
    local ScheduleMeta = {__index = ScheduleFunc}

    ---Sets how many this schedule has done
    ---@param done integer The new amount
    function ScheduleFunc:SetDone(done)
        if isstring(self.done) then
            self.weapon["Set" .. self.done](self.weapon, done)
        else
            self.done = done
        end
    end

    ---Returns the current counter value.
    ---@return integer
    function ScheduleFunc:GetDone()
        if isstring(self.done) then
            return self.weapon["Get" .. self.done](self.weapon)
        else
            return self.done --[[@as integer]]
        end
    end

    ---Resets the interval of the schedule
    ---@param newdelay number The new interval in seconds
    function ScheduleFunc:SetDelay(newdelay)
        if isstring(self.delay) then
            self.weapon["Set" .. self.delay](self.weapon, newdelay)
        else
            self.delay = newdelay
        end

        if isstring(self.prevtime) then
            self.weapon["Set" .. self.prevtime](self.weapon, CurTime())
        else
            self.prevtime = CurTime()
        end

        if isstring(self.time) then
            self.weapon["Set" .. self.time](self.weapon, CurTime() + newdelay)
        else
            self.time = CurTime() + newdelay
        end
    end

    ---Returns the current interval of the schedule
    ---@return number
    function ScheduleFunc:GetDelay()
        if isstring(self.delay) then
            return self.weapon["Get" .. self.delay](self.weapon)
        else
            return self.delay --[[@as number]]
        end
    end

    ---Sets a time for SinceLastCalled()
    ---@param newtime number Relative to CurTime()
    function ScheduleFunc:SetLastCalled(newtime)
        if isstring(self.prevtime) then
            self.weapon["Set" .. self.prevtime](self.weapon, CurTime() - newtime)
        else
            self.prevtime = CurTime() - newtime
        end
    end

    ---Returns the time since the schedule has been last called
    ---@return number
    function ScheduleFunc:SinceLastCalled()
        if isstring(self.prevtime) then
            return CurTime() - self.weapon["Get" .. self.prevtime](self.weapon)
        else
            return CurTime() - self.prevtime
        end
    end

    ---Adds a schedule that is synchronized between server and clients
    ---@param delay number How long the function should be ran in seconds. Use 0 to have the function run every time ENT:Think() called
    ---@param func fun(self: Entity, schedule: ISchedule) The function to run after the specified delay
    ---@return EntityNetworkSchedule # Created schedule object
    function ent:AddNetworkSchedule(delay, func)
        ---@type EntityNetworkSchedule
        local schedule = setmetatable({
            func = func,
            weapon = self,
        }, ScheduleMeta --[[@as EntityNetworkSchedule]])
        schedule.delay = "TimerDelay" .. tostring(self:GetLastSlot "Float")
        self:AddNetworkVar("Float", schedule.delay)
        self["Set" .. schedule.delay](self, delay)
        schedule.prevtime = "TimerPrevious" .. tostring(self:GetLastSlot "Float")
        self:AddNetworkVar("Float", schedule.prevtime)
        self["Set" .. schedule.prevtime](self, CurTime())
        schedule.time = "Timer" .. tostring(self:GetLastSlot "Float")
        self:AddNetworkVar("Float", schedule.time)
        self["Set" .. schedule.time](self, CurTime())
        schedule.done = "Done" .. tostring(self:GetLastSlot "Int")
        self:AddNetworkVar("Int", schedule.done)
        self["Set" .. schedule.done](self, 0)
        self.FunctionQueue[#self.FunctionQueue + 1] = schedule
        return schedule
    end

    ---Adds a schedule similar to timer.Create()
    ---@param delay   number   How long the function should be ran in seconds. Use 0 to have the function run every time ENT:Think() called
    ---@param numcall integer? The number of times to repeat.  Set to nil or 0 for infinite schedule
    ---@param func   (fun(self: Entity, schedule: ISchedule): boolean?)? The function to run.  Returning true in it to have the schedule stop
    ---@return EntitySchedule # Created schedule object
    function ent:AddSchedule(delay, numcall, func)
        ---@type EntitySchedule
        local schedule = setmetatable({
            delay = delay,
            done = 0,
            func = func or numcall,
            numcall = func and numcall or 0,
            time = CurTime() + delay,
            prevtime = CurTime(),
            weapon = self,
        }, ScheduleMeta --[[@as EntitySchedule]])
        self.FunctionQueue[#self.FunctionQueue + 1] = schedule
        return schedule
    end

    ---Makes the registered functions run.  Put this in ENT:Think() for desired use
    function ent:ProcessSchedules()
        for i, s in pairs(self.FunctionQueue) do
            if isstring(s.time) then
                local get = self["Get" .. s.time] ---@type fun(self: Entity): number
                if not (isfunction(s.func) and isfunction(get) and isnumber(get(self))) then
                    self.FunctionQueue[i] = nil
                elseif CurTime() > get(self) then
                    local remove = s.func(self, s)
                    self["Set" .. s.prevtime](self, CurTime())
                    self["Set" .. s.time](self, CurTime() + self["Get" .. s.delay](self))
                    self["Set" .. s.done](self, self["Get" .. s.done](self) + 1)
                    if remove then self["Set" .. s.done](self, 2^16 - 1) end
                end
            elseif CurTime() > s.time then
                local remove = not isfunction(s.func) or s.func(self, s)
                s.prevtime = CurTime()
                s.time = CurTime() + s.delay
                if s.numcall > 0 then
                    s.done = s.done + 1
                    remove = remove or s.done >= s.numcall
                end

                if remove then self.FunctionQueue[i] = nil end
            end
        end
    end
end

local gain = ss.GetOption "gain"

---Get player's desired maximum health
---@return number
function ss.GetMaxHealth() return gain "maxhealth" --[[@as number]] end

---Get the maximum amount of an ink tank
---@return number
function ss.GetMaxInkAmount() return gain "inkamount" --[[@as number]] end

---@return number
function ss.GetDamageScale() return gain "damagescale" / 100 end

---Get the area of turf inked in points from internal value
---@param raw number
---@return integer
function ss.GetTurfInkedInPoints(raw)
    local convertedUnits = -raw / ss.ToHammerUnits2
    return math.floor(convertedUnits / 330)
end

---Get the area of turf inked in raw value from apparent points
---@param pts number the apparent points
---@return number
function ss.GetTurfInkedInRaw(pts)
    return -pts * 330 * ss.ToHammerUnits2
end

---@param ply Entity
---@param force Vector
function ss.ApplyKnockback(ply, force)
    ss.KnockbackVector[ply] = force
    if CLIENT or ss.sp or not ply:IsPlayer() then return end ---@cast ply Player
    net.Start "SplashSWEPs: Register knockback"
    net.WriteVector(force)
    net.Send(ply)
end

---@param pt cvartree.CVarItem
---@return any
function ss.GetBotOption(pt) return (pt.cl or pt.sv):GetDefault() end

---@param key string
---@param id PlayerType | SplashWeaponBase
---@return string?
function ss.GetVoiceName(key, id)
    if not isnumber(id) then ---@cast id SplashWeaponBase
        id = id:GetNWInt "playermodel" ---@type PlayerType
    end ---@cast id PlayerType
    local suffix = ss.VoiceSuffix[id]
    if not suffix then return end
    return "SplashSWEPs_Voice." .. key .. "_" .. suffix
end

---Adds invincible time to the given entity for duration seconds
---@param ent Entity
---@param duration number
function ss.SetInvincibleDuration(ent, duration)
    if duration < 0 then
        ss.InvincibleEntities[ent] = nil
    else
        ss.InvincibleEntities[ent] = CurTime() + duration
    end
    if CLIENT then return end
    if #ss.PlayersReady == 0 then return end
    net.Start "SplashSWEPs: Sync invincible entity state"
    net.WriteEntity(ent)
    net.WriteFloat(duration)
    net.Send(ss.PlayersReady)
end

---Checks if the given entity is invincible from ink
---@param ent Entity
---@return boolean
function ss.IsInvincible(ent)
    if not IsValid(ent) then return false end
    return ss.InvincibleEntities[ent] and CurTime() < ss.InvincibleEntities[ent]
end

---Play footstep sound of ink
---@param w SplashWeaponBase
---@param ply Player
---@param pos Vector
---@param foot number
---@param soundName string
---@param volume number
---@param filter CRecipientFilter
---@return boolean?
function ss.PlayerFootstep(w, ply, pos, foot, soundName, volume, filter)
    if SERVER and ss.mp then return end
    if ply:Crouching() and w:GetNWBool "transformoncrouch" and w:GetGroundColor() < 0
    or not ply:Crouching() and w:GetGroundColor() >= 0 then
        ply:EmitSound "SplashSWEPs_Player.InkFootstep"
        return true
    end

    if not ply:Crouching() then return end
    return soundName:find "chainlink" and true or nil
end

---@param w SplashWeaponBase
---@param ply Player
---@param velocity Vector
---@param maxseqspeed number
function ss.UpdateAnimation(w, ply, velocity, maxseqspeed)
    ss.ProtectedCall(w.UpdateAnimation, w, ply, velocity, maxseqspeed)

    if not w:GetThrowing() then return end

    ply:AnimSetGestureWeight(GESTURE_SLOT_ATTACK_AND_RELOAD, 1)

    local f = (CurTime() - w:GetThrowAnimTime()) / ss.SubWeaponThrowTime
    if CLIENT and w:IsCarriedByLocalPlayer() then
        f = f + LocalPlayer():Ping() / 1000 / ss.SubWeaponThrowTime
    end

    if 0 <= f and f <= 1 then
        local seq = ply:LookupSequence "range_grenade"
        if seq < 0 then seq = ply:SelectWeightedSequenceSeeded(ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE, 0) end
        ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_ATTACK_AND_RELOAD, seq, f * .55, true)
    end
end

---@param self SplashWeaponBase
---@param ply Player
---@param ucmd CUserCmd
function ss.StartCommand(self, ply, ucmd)
    if self.IsSpecial then ---@cast self SWEP.Special If player is holding a special weapon
        local activator = self:GetNWEntity "Activator" ---@cast activator SplashWeaponBase
        if not IsValid(activator) then return end
        local elapsed = CurTime() - activator:GetSpecialStartTime()
        if activator:GetSpecialActivated() and elapsed < activator:GetSpecialDuration() then return end
        if self.ShouldFireOnEnd and elapsed >= activator:GetSpecialDuration() then self:SharedPrimaryAttack() end
        if SERVER and self:Ammo1() <= 0 then SafeRemoveEntity(self) end
        self:SetNWEntity("Activator", NULL)
        self:SetSubWeaponName("")
        ucmd:SelectWeapon(activator)
    else
        if not self.SwitchWeaponOnSpecial then return end
        if not self:GetSpecialActivated() then return end
        local elapsed = CurTime() - self:GetSpecialStartTime()
        if elapsed > self:GetSpecialDuration() then return end
        local special = ply:GetWeapon(self.SwitchSpecialWeaponTo) ---@cast special SWEP.Special
        if SERVER and not IsValid(special) then
            special = ply:Give(self.SwitchSpecialWeaponTo, true)
        end

        if not IsValid(special) then return end
        special:SetClip1(special.Primary and special.Primary.ClipSize or 0)
        special:SetNWEntity("Activator", self)
        special:SetSubWeaponName(self.Sub)
        ucmd:SelectWeapon(special)
    end
end

---@param self SplashWeaponBase
---@param ply Player
---@param key integer
function ss.KeyPress(self, ply, key)
    if ss.KeyMaskFind[key] then
        self:SetKey(key)
        table.RemoveByValue(self.KeyPressedOrder, key)
        self.KeyPressedOrder[#self.KeyPressedOrder + 1] = key
    end

    ss.ProtectedCall(self.KeyPress, self, ply, key)
    if CLIENT and (ss.sp or IsFirstTimePredicted())
    and key == IN_SPEED and not ss.IsOpeningMinimap then
        ss.OpenMiniMap()
    end

    local transformed = self:GetNWEntity "TransformModel"
    if key == IN_JUMP and ply:OnGround() and IsValid(transformed)
    and transformed:LookupSequence "jump_start" >= 0 then
        transformed:SetSequence "jump_start"
    end
end

---@param self SplashWeaponBase
---@param ply Player
---@param key integer
function ss.KeyRelease(self, ply, key)
    table.RemoveByValue(self.KeyPressedOrder, key)
    if #self.KeyPressedOrder > 0 then
        ss.KeyPress(self, ply, self.KeyPressedOrder[#self.KeyPressedOrder])
    else
        self:SetKey(0)
    end

    ss.ProtectedCall(self.KeyRelease, self, ply, key)
    if not ss.KeyMaskFind[key] then return end
    if CurTime() < self:GetNextSecondaryFire() then return end
    if not (self:GetThrowing() and key == IN_ATTACK2) then return end
    self:AddSchedule(ss.SubWeaponThrowTime, 1, function() self:SetThrowing(false) end)
    if self:Crouching() then return end

    local time = CurTime() + ss.SubWeaponThrowTime
    self:SetCooldown(time)
    self:SetNextPrimaryFire(time)
    self:SetNextSecondaryFire(time)

    local able = self:GetInk() > 0 and self:CheckCanStandup() and self:CanSecondaryAttack()
    if not able then return end
    self:SetThrowAnimTime(CurTime())
    self:SetWeaponAnim(ss.ViewModel.Throw)
    ss.ProtectedCall(self.SharedSecondaryAttack, self, able)
    ss.ProtectedCall(Either(SERVER, self.ServerSecondaryAttack, self.ClientSecondaryAttack), self, able)
end

---@param self SplashWeaponBase
---@param ply Player
---@param inWater boolean
---@param onFloater boolean
---@param speed number
function ss.OnPlayerHitGround(self, ply, inWater, onFloater, speed)
    if not self:GetInInk() or self:GetInWallInk() then return end
    if not self:IsFirstTimePredicted() then return end
    local e = EffectData()
    local f = (speed - 100) / 600
    local t = util.QuickTrace(ply:GetPos(), -vector_up * 16384, {self, ply})
    e:SetAngles(t.HitNormal:Angle())
    e:SetAttachment(10)
    e:SetColor(self:GetNWInt "inkcolor")
    e:SetEntity(self)
    e:SetFlags((f > .5 and (64 + 32 + 16) or (32 + 16))
    + (CLIENT and self:IsCarriedByLocalPlayer() and 128 or 0))
    e:SetOrigin(t.HitPos)
    e:SetRadius(Lerp(f, 25, 50))
    e:SetScale(.5)
    util.Effect("SplashSWEPsMuzzleSplash", e, true)
end

cvars.AddChangeCallback("gmod_language", function(convar, old, new)
    CompileFile "splashsweps/text.lua" ()
end, "SplashSWEPs: OnLanguageChanged")

if ss.GetOption "enabled" then
    cleanup.Register(ss.CleanupTypeInk)
end

local nest = nil
for hookname in pairs {CalcMainActivity = true, TranslateActivity = true} do
    hook.Add(hookname, "SplashSWEPs: Crouch anim in fence", ss.hook(function(w, ply, ...)
        if nest then nest = nil return end
        if not ply:Crouching() then return end
        if not w:GetInFence() then return end
        nest = true
        ply:SetMoveType(MOVETYPE_WALK)
        local res1, res2 = gamemode.Call(hookname, ply, ...)
        ply:AnimResetGestureSlot(GESTURE_SLOT_CUSTOM)
        ply:SetMoveType(MOVETYPE_NOCLIP)
        return res1, res2
    end))
end

concommand.Add("-splashsweps_reset_camera", function(ply) end, nil, ss.Text.CVars.ResetCamera --[[@as string]])
concommand.Add("+splashsweps_reset_camera", function(ply --[[@as Player]])
    ss.PlayerShouldResetCamera[ply] = true
end, nil, ss.Text.CVars.ResetCamera --[[@as string]])

---@param pos Vector
---@return { mins: Vector, maxs: Vector }?
function ss.GetMinimapAreaBounds(pos)
    for _, t in ipairs(ss.MinimapAreaBounds) do
        if pos:WithinAABox(t.mins, t.maxs) then
            return t
        end
    end
end

hook.Add("PlayerFootstep", "SplashSWEPs: Ink footstep", ss.hook "PlayerFootstep")
hook.Add("UpdateAnimation", "SplashSWEPs: Adjust TPS animation speed", ss.hook "UpdateAnimation")
hook.Add("StartCommand", "SplashSWEPs: Switch weapon on special", ss.hook "StartCommand")
hook.Add("KeyPress", "SplashSWEPs: Check a valid key", ss.hook "KeyPress")
hook.Add("KeyRelease", "SplashSWEPs: Throw sub weapon", ss.hook "KeyRelease")
hook.Add("OnPlayerHitGround", "SplashSWEPs: Play diving sound", ss.hook "OnPlayerHitGround")
hook.Add("Initialize", "SplashSWEPs: Add ammo type of ink", function()
    game.AddAmmoType {
        dmgtype = bit.bor(DMG_AIRBOAT, DMG_REMOVENORAGDOLL),
        force = 1,
        maxsplash = 0,
        minsplash = 0,
        name = "Ink",
        npcdmg = -1,
        plydmg = -1,
        tracer = TRACER_NONE,
        flags = 0,
    }
end)
