
-- Functions for weapon settings.

---@class ss
local ss = SplashSWEPs
if not ss then return end

---@class ss.InkQueue
---@field Data                   Projectile
---@field InitTime               number
---@field IsCarriedByLocalPlayer boolean
---@field Owner                  Entity?
---@field Parameters             Parameters
---@field Trace                  ss.InkQueueTrace
---@field CurrentSpeed           number
---@field BlasterRemoval         boolean
---@field BlasterHitWall         boolean
---@field Exploded               boolean

---@class ss.InkQueueTrace : Trace, HullTrace
---@field LengthSum number
---@field LifeTime  number

---@class Projectile
---@field AirResist              number   Air resistance.  Horizontal velocity at next frame = Current horizontal velocity * AirResist
---@field Color                  number   Ink color ID
---@field ColRadiusEntity        number   Collision radius against entities
---@field ColRadiusWorld         number   Collision radius against the world
---@field DoDamage               boolean  Whether or not the ink deals damage
---@field DamageMax              number   Maximum damage
---@field DamageMaxDistance      number   Ink travel distance to start decaying damage
---@field DamageMin              number   Minimum damage
---@field DamageMinDistance      number   Ink travel distance to end decaying damage
---@field Gravity                number   Gravity acceleration
---@field ID                     number   Ink identifier to avoid multiple damages at once
---@field Inflictor              Entity?  The entity that actually spawned this ink (e.g. a Sprinkler)
---@field InitDir                Vector   (Auto set) Initial direction of velocity
---@field InitPos                Vector   Initial position
---@field InitSpeed              number   (Auto set) Initial speed
---@field InitVel                Vector   Initial velocity
---@field IsCritical             boolean  Whether or not the ink is critical (true to change the hit effect)
---@field PaintFarDistance       number   Ink travel distance to end shrinking paint radius
---@field PaintFarRadius         number   Painting radius when hit
---@field PaintFarRatio          number   Painting aspect ratio at the end
---@field PaintNearDistance      number   Ink travel distance to start shrinking paint radius
---@field PaintNearRadius        number   Painting radius when hit
---@field PaintNearRatio         number   Painting aspect ratio at the beginning
---@field PaintRatioFarDistance  number   Ink travel distance to end changing paint aspect ratio
---@field PaintRatioNearDistance number   Ink travel distance to start changing paint aspect ratio
---@field SplashColRadius        number   Collision radius against entities/world for splashes created from the ink
---@field SplashDrawRadius       number?  Draw radius for splashes created from the ink
---@field SplashCount            number   (Variable) Current number of splashes the ink has dropped so far
---@field SplashInitRate         number   Determines the position of the first splash the ink drops = SplashLength * SplashInitRate
---@field SplashLength           number   Length between two splashes from the ink
---@field SplashNum              number   Number of total splashes the ink will drop
---@field SplashPaintRadius      number   Painting radius splashes will paint
---@field SplashRatio            number   Painting aspect ratio for splashes
---@field StraightFrame          number   The ink travels without affecting gravity for this frames
---@field Type                   number   The shape of the paintings
---@field Weapon                 SplashWeaponBase The weapon entity which created the ink
---@field Yaw                    number   Determines the angle of the paintings in degrees

---@param initvel       number Initial speed
---@param straightframe number Go straight without gravity for this seconds
---@param guideframe    number
---@param airresist     number
---@return number
function ss.GetRange(initvel, straightframe, guideframe, airresist)
    return ss.GetBulletPos(Vector(initvel), straightframe, airresist, 0, guideframe).x
end

---@param self SplashWeaponBase
function ss.SetChargingEye(self)
    local ply = self:GetOwner()
    local mdl = ply:GetModel()
    local skin = ss.ChargingEyeSkin[mdl]
    if skin and ply:GetSkin() ~= skin then
        ply:SetSkin(skin)
    elseif ss.TwilightPlayermodels[mdl] then
        -- Eye animation for Twilight's playermodel
        local l = ply:GetFlexIDByName "Blink_L"
        local r = ply:GetFlexIDByName "Blink_R"
        if l then ply:SetFlexWeight(l, .3) end
        if r then ply:SetFlexWeight(r, 1) end
    end
end

---@param self SplashWeaponBase
function ss.SetNormalEye(self)
    local ply = self:GetOwner()
    local mdl = ply:GetModel()
    local f = ply:GetFlexIDByName "Blink_R"
    local IsTwilightModel = ss.TwilightPlayermodels[mdl]
    local skin = ss.ChargingEyeSkin[mdl]
    if skin and ply:GetSkin() == skin then
        local s = 0
        if self:GetNWInt "playermodel" == ss.PLAYER.NOCHANGE then
            if CLIENT then
                s = GetConVar "cl_playerskin":GetInt()
            else
                s = self.BackupPlayerInfo.Playermodel.Skin
            end
        end

        if ply:GetSkin() == s then return end
        ply:SetSkin(s)
    elseif IsTwilightModel and f and ply:GetFlexWeight(f) == 1 then
        local l = ply:GetFlexIDByName "Blink_L"
        local r = ply:GetFlexIDByName "Blink_R"
        if l then ply:SetFlexWeight(l, 0) end
        if r then ply:SetFlexWeight(r, 0) end
    end
end

---@return Projectile
function ss.MakeProjectileStructure()
    local PRFarD  = 100 * ss.ToHammerUnits
    local PRNearD =  50 * ss.ToHammerUnits
    return { -- Used in ss.AddInk(), describes how a projectile is.
        AirResist = 0,                    -- Air resistance.  Horizontal velocity at next frame = Current horizontal velocity * AirResist
        Color = 1,                        -- Ink color ID
        ColRadiusEntity = 1,              -- Collision radius against entities
        ColRadiusWorld = 1,               -- Collision radius against the world
        DoDamage = true,                  -- Whether or not the ink deals damage
        DamageMax = 0,                    -- Maximum damage
        DamageMaxDistance = 0,            -- Ink travel distance to start decaying damage
        DamageMin = 0,                    -- Minimum damage
        DamageMinDistance = 0,            -- Ink travel distance to end decaying damage
        Gravity = 0,                      -- Gravity acceleration
        ID = CurTime(),                   -- Ink identifier to avoid multiple damages at once
        Inflictor = nil,                  -- The entity that actually spawned this ink
        InitDir = Vector(),               -- (Auto set) Initial direction of velocity
        InitPos = Vector(),               -- Initial position
        InitSpeed = 0,                    -- (Auto set) Initial speed
        InitVel = Vector(),               -- Initial velocity
        IsCritical = false,               -- Whether or not the ink is critical (true to change the hit effect)
        PaintFarDistance = 0,             -- Ink travel distance to end shrinking paint radius
        PaintFarRadius = 0,               -- Painting radius when hit
        PaintFarRatio = 3,                -- Painting aspect ratio at the end
        PaintNearDistance = 0,            -- Ink travel distance to start shrinking paint radius
        PaintNearRadius = 0,              -- Painting radius when hit
        PaintNearRatio = 1,               -- Painting aspect ratio at the beginning
        PaintRatioFarDistance = PRFarD,   -- Ink travel distance to end changing paint aspect ratio
        PaintRatioNearDistance = PRNearD, -- Ink travel distance to start changing paint aspect ratio
        SplashColRadius = 0,              -- Collision radius against entities/world for splashes created from the ink
        SplashCount = 0,                  -- (Variable) Current number of splashes the ink has dropped so far
        SplashInitRate = 0,               -- Determines the position of the first splash the ink drops = SplashLength * SplashInitRate
        SplashLength = 0,                 -- Length between two splashes from the ink
        SplashNum = 0,                    -- Number of total splashes the ink will drop
        SplashPaintRadius = 0,            -- Painting radius splashes will paint
        SplashRatio = 1,                  -- Painting aspect ratio for splashes
        StraightFrame = 0,                -- The ink travels without affecting gravity for this frames
        Type = 1,                         -- The shape of the paintings
        Weapon = NULL,                    -- The weapon entity which created the ink
        Yaw = 0,                          -- Determines the angle of the paintings in degrees
    }
end

---@return ss.InkQueueTrace
function ss.MakeInkQueueTraceStructure()
    return {
        collisiongroup = COLLISION_GROUP_NONE,
        endpos = Vector(),
        filter = NULL,
        LengthSum = 0,
        LifeTime = 0,
        mask = ss.CrouchingSolidMask,
        maxs = ss.vector_one * 1,
        mins = ss.vector_one * -1,
        start = Vector(),
    }
end

---@return ss.InkQueue
function ss.MakeInkQueueStructure()
    return {
        Data = {},
        InitTime = CurTime(),
        IsCarriedByLocalPlayer = false,
        Parameters = {},
        Trace = ss.MakeInkQueueTraceStructure(),
    }
end

---@param weapon SplashWeaponBase
---@param parameters Parameters
function ss.SetPrimary(weapon, parameters)
    local maxink = ss.GetMaxInkAmount()
    ss.ProtectedCall(ss.DefaultParams[weapon.Base], weapon)
    weapon.Primary = {
        Ammo = "Ink",
        Automatic = true,
        ClipSize = maxink,
        DefaultClip = 0,
    }

    table.Merge(weapon.Parameters, parameters or {})
    ss.ConvertUnits(weapon.Parameters, ss.Units)
    ss.ProtectedCall(ss.CustomPrimary[weapon.Base], weapon)
end

ss.DefaultParams = {}
ss.CustomPrimary = {}
---@param weapon SWEP.Shooter
function ss.DefaultParams.weapon_splashsweps_shooter(weapon)
    weapon.Parameters = {
        mRepeatFrame = 6, ---The repeat frame
        mTripleShotSpan = 0,
        mInitVel = 22,
        mDegRandom = 6,
        mDegJumpRandom = 15,
        mSplashSplitNum = 5,
        mKnockBack = 0,
        mInkConsume = 0.009,
        mInkRecoverStop = 20,
        mMoveSpeed = 0.72,
        mDamageMax = 0.35,
        mDamageMin = 0.175,
        mDamageMinFrame = 15,
        mStraightFrame = 4,
        mGuideCheckCollisionFrame = 8,
        mCreateSplashNum = 2,
        mCreateSplashLength = 75,
        mDrawRadius = 2.5,
        mColRadius = 2,
        mPaintNearDistance = 11,
        mPaintFarDistance = 200,
        mPaintNearRadius = 19.2,
        mPaintFarRadius = 18,
        mSplashDrawRadius = 3,
        mSplashColRadius = 1.5,
        mSplashPaintRadius = 13,
        mArmorTypeGachihokoDamageRate = 1,
        mDegBias = 0.25,
        mDegBiasKf = 0.02,
        mDegJumpBias = 0.4,
        mDegJumpBiasFrame = 60,
    }
end

---@param weapon SWEP.Shooter
function ss.CustomPrimary.weapon_splashsweps_shooter(weapon)
    local p = weapon.Parameters
    weapon.NPCDelay = p.mRepeatFrame
    weapon.Primary.Automatic = p.mTripleShotSpan == 0
    weapon.Range = ss.GetRange(p.mInitVel, p.mStraightFrame,
    p.mGuideCheckCollisionFrame, ss.ShooterAirResist)
end

---event = 5xyy, x = option index, yy = effect type
--- - yy = 0 : SplashSWEPsMuzzleSplash
---   - x = 0 : Attach to muzzle
---   - x = 1 : Go backward (for charger)
---@param self SplashWeaponBase
---@param pos Vector
---@param ang Angle
---@param event integer
---@param options string
---@return boolean
function ss.FireAnimationEvent(self, pos, ang, event, options)
    if 5000 <= event and event < 6000 then
        event = event - 5000
        local vararg = options:Split " "
        ss.tablepush(vararg, math.floor(event / 100))
        ss.ProtectedCall(ss.DispatchEffect[event % 100], self, vararg, pos, ang)
    end

    return true
end

---@type (fun(self: SplashWeaponBase, options: table, pos: Vector, ang: Angle))[]
ss.DispatchEffect = {}
local SplashSWEPsMuzzleSplash = 0
local sd, e = ss.DispatchEffect, EffectData()
sd[SplashSWEPsMuzzleSplash] = function(self, options, pos, ang)
    local tpslag = 0
    if self.IsSplashWeapon and self:IsCarriedByLocalPlayer()
    and self:GetOwner() --[[@as Player]]:ShouldDrawLocalPlayer() then
        tpslag = 128
    end

    local attachment = options[2] or "muzzle"
    local attindex = self:LookupAttachment(attachment)
    if attindex <= 0 then attindex = 1 end
end
