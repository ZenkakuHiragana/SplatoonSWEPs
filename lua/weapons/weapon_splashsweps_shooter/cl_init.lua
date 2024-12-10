
local ss = SplashSWEPs
if not ss then return end
include "shared.lua"

local SWEP = SWEP
---@cast SWEP SWEP.Shooter
---@class SWEP.Shooter : SplashWeaponBase
---@field SwayTime              number
---@field IronSightsAng         Angle[]
---@field IronSightsPos         Vector[]
---@field IronSightsFlip        boolean[]
---@field ArmPos                integer
---@field ArmBegin              number
---@field BasePos               Vector
---@field BaseAng               Angle
---@field OldPos                Vector
---@field OldAng                Angle
---@field OldArmPos             integer
---@field TransitFlip           boolean
---@field ADSAngOffset          Angle
---@field ADSOffset             Vector
---@field GetMuzzlePosition     fun(self): Vector, Angle
---@field GetCrosshairTrace     fun(self, t: SWEP.CrosshairData)
---@field DrawFourLines         fun(self, t: SWEP.CrosshairData, degx: number, degy: number)
---@field DrawCenterCircleNoHit fun(self, t: SWEP.CrosshairData)
---@field DrawHitCrossBG        fun(self, t: SWEP.CrosshairData)
---@field DrawHitCross          fun(self, t: SWEP.CrosshairData)
---@field DrawOuterCircleBG     fun(self, t: SWEP.CrosshairData)
---@field DrawOuterCircle       fun(self, t: SWEP.CrosshairData)
---@field DrawInnerCircle       fun(self, t: SWEP.CrosshairData)
---@field DrawCenterDot         fun(self, t: SWEP.CrosshairData)
---@field GetArmPos             fun(self): number?
---@field GetIronSights        (fun(self): boolean)?
---@field GetScopedSize        (fun(self): number)?
---@field SetupDrawCrosshair    fun(self): SWEP.CrosshairData

---@class SWEP.CrosshairData
---@field CrosshairColor       Color?
---@field CrosshairDarkColor   Color?
---@field CrosshairBrightColor Color?
---@field pos                  Vector
---@field dir                  Vector
---@field IsNewStyle          boolean
---@field Trace                TraceResult?
---@field EndPosScreen         { x: number, y: number }?
---@field HitPosScreen         { x: number, y: number }?
---@field HitEntity            boolean?
---@field Distance             number?

---Custom functions executed before weapon model is drawn.  
---When the weapon is fired, it slightly expands.  This is maximum time to get back to normal size.
---@param self   SWEP.Shooter
---@param vm     Entity
---@param weapon SWEP.Shooter
---@param ply    Player
local function ExpandModel(self, vm, weapon, ply)
    local FireWeaponCooldown = 6 * ss.FrameToSec
    local FireWeaponMultiplier = 1
    local fraction = FireWeaponCooldown - SysTime() + self.ModifyWeaponSize
    fraction = math.max(1, fraction * FireWeaponMultiplier + 1)
    local s = ss.vector_one * fraction
    local bone = self:LookupBone "root_1" or self:LookupBone "root"
    if bone then self:ManipulateBoneScale(bone, s) end
    if not IsValid(vm) then return end
    if self.ViewModelFlip then s.y = -s.y end
    ---@cast vm Entity.Colorable
    local vmbone = vm:LookupBone "root_1" or vm:LookupBone "root" or 0
    if vmbone then vm:ManipulateBoneScale(vmbone, s) end
    function vm.GetInkColorProxy()
        return ss.ProtectedCall(self.GetInkColorProxy, self) or ss.vector_one
    end
end

SWEP.PreViewModelDrawn = ExpandModel
SWEP.PreDrawWorldModel = ExpandModel
SWEP.SwayTime = 12 * ss.FrameToSec
SWEP.IronSightsAng = {
    Angle(), -- right
    Angle(), -- left
    Angle(0, 0, -60), -- top-right
    Angle(0, 0, -60), -- top-left
    Angle(), -- center
}
SWEP.IronSightsPos = {
    Vector(), -- right
    Vector(), -- left
    Vector(), -- top-right
    Vector(), -- top-left
    Vector(0, 6, -2), -- center
}
SWEP.IronSightsFlip = {
    false,
    true,
    false,
    true,
    false,
}

function SWEP:ClientInit()
    self.ArmPos, self.ArmBegin = nil, nil
    self.BasePos, self.BaseAng = nil, nil
    self.OldPos, self.OldAng = nil, nil
    self.OldArmPos = 1
    self.TransitFlip = false
    self.ModifyWeaponSize = SysTime() - 1
    self.ViewPunch = Angle()
    self.ViewPunchVel = Angle()
    if not (self.ADSAngOffset and self.ADSOffset) then return end
    self.IronSightsAng[6] = self.IronSightsAng[5] + self.ADSAngOffset
    self.IronSightsPos[6] = self.IronSightsPos[5] + self.ADSOffset

    local ent = ClientsideModel(self.ViewModel)
    if not IsValid(ent) then return end
    local bone = ent:LookupBone "ValveBiped.Bip01_Spine4"
    local seq0 = ent:LookupSequence "idle_ref"
    local seq1 = ent:LookupSequence "idle_ads"
    local seq2 = ent:LookupSequence "idle_center"
    if not (seq0 and seq1 and seq2) or seq0 < 0 or seq1 < 0 or seq2 < 0 then
        ent:Remove()
        return
    end

    ent:SetSequence(seq0)
    ent:SetupBones()
    local ref = ent:GetBoneMatrix(bone)

    ent:SetSequence(seq1)
    ent:SetupBones()
    local matads = ent:GetBoneMatrix(bone)

    ent:SetSequence(seq2)
    ent:SetupBones()
    local matcenter = ent:GetBoneMatrix(bone)

    ent:Remove()
    -- WorldToLocal(
    --    vector_origin, angle_zero,
    --    ref:GetTranslation(), ref:GetAngles())
    local refinv = ref:GetInverse()

    -- LocalToWorld(
    --     refinv:GetTranslation(), refinv:GetAngles(),
    --     matads:GetTranslation(), matads:GetAngles())
    local ads = matads * refinv
    self.IronSightsAng[6] = ads:GetAngles()
    self.IronSightsPos[6] = ads:GetTranslation()

    local center = matcenter * refinv
    self.IronSightsAng[5] = center:GetAngles()
    self.IronSightsPos[5] = center:GetTranslation()
end

function SWEP:GetMuzzlePosition()
    local ent = self:IsTPS() and self or self:GetViewModel()
    local a = ent:GetAttachment(ent:LookupAttachment "muzzle")
    if not a then return self:WorldSpaceCenter(), self:GetAngles() end
    return a.Pos, a.Ang
end

---@param t SWEP.CrosshairData
function SWEP:GetCrosshairTrace(t)
    local colradius = self:GetColRadius()
    local range = self:GetRange(true) - colradius
    local tr = ss.MakeInkQueueTraceStructure()
    tr.start, tr.endpos = t.pos, t.pos + t.dir * range
    tr.filter = ss.MakeAllyFilter(self)
    tr.maxs = ss.vector_one * colradius
    tr.mins = -tr.maxs

    t.Trace = util.TraceHull(tr)
    t.EndPosScreen = (self:GetShootPos() + self:GetAimVector() * range):ToScreen()
    t.HitPosScreen = t.Trace.HitPos:ToScreen()
    t.HitEntity = IsValid(t.Trace.Entity) and t.Trace.Entity:Health() > 0
    t.Distance = t.Trace.HitPos:Distance(t.pos)
    if t.HitEntity then
        local w = ss.IsValid(t.Trace.Entity)
        t.HitEntity = not (ss.IsAlly(t.Trace.Entity, self) or w and ss.IsAlly(w, self))
    end
end

---@param t SWEP.CrosshairData
---@param degx number
---@param degy number
function SWEP:DrawFourLines(t, degx, degy)
    degx = math.max(degx, degy) -- Stupid workaround for Blasters' crosshair
    local frac = t.Trace.Fraction
    local bgcolor = t.IsNewStyle and t.Trace.Hit and ss.CrosshairBaseColor or color_white
    local forecolor = t.HitEntity and ss.GetColor(self:GetNWInt "inkcolor") or nil
    local dir = self:GetAimVector() * t.Distance
    local org = self:GetShootPos()
    local right = EyeAngles():Right()
    local range = self:GetRange()
    local adjust = not t.IsNewStyle and t.HitEntity
    local dx, dy = 0, 0
    if not t.IsNewStyle then
        local SPREAD_HITWALL = 5
        dx = t.HitPosScreen.x - t.EndPosScreen.x
        dy = t.HitPosScreen.y - t.EndPosScreen.y
        degx = Lerp(1 - frac, degx, SPREAD_HITWALL)
        degy = Lerp(1 - frac, degy, SPREAD_HITWALL)
    end

    ss.DrawCrosshair.FourLinesAround(
    org, right, dir, range, degx, degy, dx, dy, adjust, bgcolor, forecolor)
end

---@param t SWEP.CrosshairData
function SWEP:DrawCenterCircleNoHit(t)
    if not t.IsNewStyle and t.Trace.Hit then return end
    ss.DrawCrosshair.CircleNoHit(t.EndPosScreen.x, t.EndPosScreen.y)
end

---@param t SWEP.CrosshairData
function SWEP:DrawHitCrossBG(t) -- Hit cross pattern, background
    if not t.HitEntity then return end
    local mul = ss.ProtectedCall(self.GetScopedSize, self) or 1
    local frac = 1 - (t.Distance / self:GetRange()) / 2
    ss.DrawCrosshair.LinesHitBG(t.HitPosScreen.x, t.HitPosScreen.y, frac, mul)
end

---@param t SWEP.CrosshairData
function SWEP:DrawHitCross(t) -- Hit cross pattern, foreground
    if not t.HitEntity then return end
    local c = ss.GetColor(self:GetNWInt "inkcolor")
    local frac = 1 - (t.Distance / self:GetRange()) / 2
    ss.DrawCrosshair.LinesHit(t.HitPosScreen.x, t.HitPosScreen.y, c, frac, 1)
end

function SWEP:DrawOuterCircleBG(t)
    if not (t.Trace.Hit and t.HitEntity) then return end
    ss.DrawCrosshair.OuterCircleBG(t.HitPosScreen.x, t.HitPosScreen.y)
end

function SWEP:DrawOuterCircle(t)
    if not t.Trace.Hit then return end
    ss.DrawCrosshair.OuterCircle(t.HitPosScreen.x, t.HitPosScreen.y, t.CrosshairColor)
end

function SWEP:DrawInnerCircle(t)
    if not t.Trace.Hit then return end
    ss.DrawCrosshair.InnerCircle(t.HitPosScreen.x, t.HitPosScreen.y)
end

function SWEP:DrawCenterDot(t) -- Center circle
    ss.DrawCrosshair.CenterDot(t.HitPosScreen.x, t.HitPosScreen.y)
    if not (t.IsNewStyle and t.Trace.Hit) then return end
    ss.DrawCrosshair.CenterDot(t.EndPosScreen.x, t.EndPosScreen.y, ss.CrosshairBaseColor)
end

function SWEP:GetArmPos()
    if self:GetADS() then
        self.IronSightsFlip[6] = self.ViewModelFlip
        return 6
    end
end

-- Patch for Viewmodel Lagger
function SWEP:GetIronSights()
    return self:GetADS()
end

local LeftHandAlt = { 2, 1, 4, 3, 5, 6 }
function SWEP:GetViewModelPosition(pos, ang)
    local vm = self:GetViewModel()
    if not IsValid(vm) then return pos, ang end

    local ping = IsFirstTimePredicted() and self:Ping() or 0
    local ct = CurTime() - ping
    if not self.OldPos then
        self.ArmPos, self.ArmBegin = 1, ct
        self.BasePos, self.BaseAng = Vector(), Angle()
        self.OldPos, self.OldAng = self.BasePos, self.BaseAng
        return pos, ang
    end

    local armpos = self.OldArmPos
    if self:IsFirstTimePredicted() then
        self.OldArmPos = ss.ProtectedCall(self.GetArmPos, self)
        if self:GetHolstering() or self:GetThrowing()
        or vm:GetSequenceActivityName(vm:GetSequence()) == "ACT_VM_DRAW" then
            self.OldArmPos = 1
        elseif not self.OldArmPos then
            if ss.GetOption "doomstyle" then
                self.OldArmPos = 5
            elseif ss.GetOption "moveviewmodel" and not self:Crouching() then
                if not self.Cursor then return pos, ang end
                self.OldArmPos = select(3, self:GetFirePosition())
            else
                self.OldArmPos = 1
            end
        end
    end

    if self:GetNWBool "lefthand" then armpos = LeftHandAlt[armpos] or armpos end
    if not isangle(self.IronSightsAng[armpos]) then return pos, ang end
    if not isvector(self.IronSightsPos[armpos]) then return pos, ang end

    local DesiredFlip = self.IronSightsFlip[armpos]
    local SwayTime = self.SwayTime / ss.GetTimeScale(self:GetOwner())
    if self:IsFirstTimePredicted() and armpos ~= self.ArmPos then
        self.ArmPos, self.ArmBegin = armpos, ct
        self.BasePos, self.BaseAng = self.OldPos, self.OldAng
        self.TransitFlip = self.ViewModelFlip ~= DesiredFlip
    else
        armpos = self.ArmPos
    end

    local dt = ct - self.ArmBegin
    local f = math.Clamp(dt / SwayTime, 0, 1)
    if self.TransitFlip then
        f, armpos = f * 2, 5
        if self:IsFirstTimePredicted() and f >= 1 then
            f, self.ArmPos = 1, 5
            self.ViewModelFlip = DesiredFlip
            self.ViewModelFlip1 = DesiredFlip
            self.ViewModelFlip2 = DesiredFlip
        end
    end

    local newpos = LerpVector(f, self.BasePos, self.IronSightsPos[armpos])
    local newang = LerpAngle(f, self.BaseAng, self.IronSightsAng[armpos])
    if self:IsFirstTimePredicted() then
        self.OldPos, self.OldAng = newpos, newang
    end

    return LocalToWorld(self.OldPos, self.OldAng, pos, ang)
end

---@return SWEP.CrosshairData
function SWEP:SetupDrawCrosshair()
    local pos, dir = self:GetFirePosition(true)
    local t = { ---@type SWEP.CrosshairData
        pos = pos, dir = dir,
        CrosshairColor = ss.GetColor(ss.CrosshairColors[self:GetNWInt "inkcolor"]),
        IsNewStyle = ss.GetOption "newstylecrosshair" --[[@as boolean]],
    }
    self:GetCrosshairTrace(t)
    return t
end

function SWEP:CustomDrawCrosshair(x, y)
    local t = self:SetupDrawCrosshair()
    if not t.CrosshairColor then return end
    self:DrawFourLines(t, self:GetSpreadAmount())
    self:DrawCenterCircleNoHit(t)
    self:DrawHitCrossBG(t)
    self:DrawOuterCircleBG(t)
    self:DrawOuterCircle(t)
    self:DrawHitCross(t)
    self:DrawInnerCircle(t)
    self:DrawCenterDot(t)

    return true
end
