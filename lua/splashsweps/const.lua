
-- Constant values

---@class ss
local ss = SplashSWEPs
if not ss then return end

local Girl1   = Model "models/drlilrobot/splatoon/ply/inkling_girl.mdl"
local Boy1    = Model "models/drlilrobot/splatoon/ply/inkling_boy.mdl"
local AltGirl = Model "models/drlilrobot/splatoon/ply/octoling.mdl"
local MsM1    = Model "models/drlilrobot/splatoon/ply/marie.mdl"
local MsC     = Model "models/drlilrobot/splatoon/ply/callie.mdl"
local Girl2   = Model "models/player/octoling.mdl"
local Boy2    = Model "models/player/octoling_male.mdl"
local MsP     = Model "models/egghead/splatoon_2/pearl_hime_pm.mdl"
local MsM2    = Model "models/egghead/splatoon_2/marina_ida_pm.mdl"

ss.sp = game.SinglePlayer()
ss.mp = not ss.sp
ss.Options           = include "splashsweps/constants/options.lua" ---@type {[string]: cvartree.CVarOption}
ss.WeaponClassNames  = include "splashsweps/constants/weaponclasses.lua" ---@type string[]
ss.TEXTUREFLAGS      = include "splashsweps/constants/textureflags.lua" ---@type table<string, integer>
ss.RenderTarget      = include "splashsweps/constants/rendertarget.lua" ---@type ss.RenderTarget
ss.Units             = include "splashsweps/constants/parameterunits.lua" ---@type table<string, string>
ss.InkTankModel      = Model "models/player/items/humans/top_hat.mdl"

---@enum PlayerType
ss.PLAYER = {
    NOCHANGE = 1,
    GIRL     = 2,
    BOY      = 3,
    MSM1     = 4,
    MSC      = 5,
    ALTGIRL  = 6,
    GIRL2    = 7,
    BOY2     = 8,
    MSP      = 9,
    MSM2     = 10,
}
---@enum TransformType
ss.TRANSFORM = {
    STANDARD = 1,
    BIGGER   = 2,
    ALT      = 3,
    ALT2     = 4,
}
---@type { [PlayerType]: string? }
ss.Playermodel = {
    [ss.PLAYER.NOCHANGE] = nil,
    [ss.PLAYER.GIRL]     = Girl1,
    [ss.PLAYER.BOY]      = Boy1,
    [ss.PLAYER.MSM1]     = MsM1,
    [ss.PLAYER.MSC]      = MsC,
    [ss.PLAYER.ALTGIRL]  = AltGirl,
    [ss.PLAYER.GIRL2]    = Girl2,
    [ss.PLAYER.BOY2]     = Boy2,
    [ss.PLAYER.MSP]      = MsP,
    [ss.PLAYER.MSM2]     = MsM2,
}
---@type { [string]: PlayerType }
ss.PlayermodelInv = {
    [Girl1]   = ss.PLAYER.GIRL,
    [Boy1]    = ss.PLAYER.BOY,
    [MsM1]    = ss.PLAYER.MSM1,
    [MsC]     = ss.PLAYER.MSC,
    [AltGirl] = ss.PLAYER.ALTGIRL,
    [Girl2]   = ss.PLAYER.GIRL2,
    [Boy2]    = ss.PLAYER.BOY2,
    [MsP]     = ss.PLAYER.MSP,
    [MsM2]    = ss.PLAYER.MSM2,
}
---@type { [TransformType]: string }
ss.TransformModel = {
}
---@type { [PlayerType]: TransformType? }
ss.TransformModelIndex = {
    [ss.PLAYER.NOCHANGE] = nil,
    [ss.PLAYER.GIRL]     = ss.TRANSFORM.STANDARD,
    [ss.PLAYER.BOY]      = ss.TRANSFORM.STANDARD,
    [ss.PLAYER.MSM1]     = ss.TRANSFORM.STANDARD,
    [ss.PLAYER.MSC]      = ss.TRANSFORM.STANDARD,
    [ss.PLAYER.ALTGIRL]  = ss.TRANSFORM.ALT,
    [ss.PLAYER.GIRL2]    = ss.TRANSFORM.ALT2,
    [ss.PLAYER.BOY2]     = ss.TRANSFORM.ALT2,
    [ss.PLAYER.MSP]      = ss.TRANSFORM.STANDARD,
    [ss.PLAYER.MSM2]     = ss.TRANSFORM.ALT2,
}
ss.VoiceSuffix = {
    [ss.PLAYER.GIRL]    = "Female1",
    [ss.PLAYER.BOY]     = "Male1",
    [ss.PLAYER.MSM1]    = "Female1",
    [ss.PLAYER.MSC]     = "Female1",
    [ss.PLAYER.ALTGIRL] = "Female2",
    [ss.PLAYER.GIRL2]   = "Female2",
    [ss.PLAYER.BOY2]    = "Male2",
    [ss.PLAYER.MSP]     = "Female1",
    [ss.PLAYER.MSM2]    = "Female2",
}
ss.ChargingEyeSkin = {
    [MsM1]    = 0,
    [MsC]     = 5,
    [Boy1]    = 4,
    [Girl1]   = 4,
    [AltGirl] = 4,
    [MsP]     = 5,
    [MsM2]    = 4,
}
ss.DrLilRobotPlayermodels = {
    [Girl1]   = true,
    [Boy1]    = true,
    [MsM1]    = true,
    [MsC]     = true,
    [AltGirl] = true,
}
ss.TwilightPlayermodels = {
    [Girl2] = true,
    [Boy2]  = true, -- Can't apply flex manipulation to this model.
}
ss.EggHeadPlayermodels = {
    [MsP]  = true,
    [MsM2] = true,
}
ss.Materials = {
    Crosshair = {
        Flash     = Material "color.vmt",
        Line      = Material "color.vmt",
        LineColor = Material "color.vmt",
    },
    Effects = {
        HitCritical = Material "particle/particle_glow_04_additive",
        Ink         = Material "splashsweps/effects/ink",
        Invisible   = Material "splashsweps/weapons/primaries/shared/weapon_hider",
    },
}
ss.Particles = {
}
---Counting turf inked uses this threshold index
ss.MASK_INDEX_INKED_POINTS = 4
---Pixels with alpha value greater than this threshold will be considered as paintable
ss.InkShotMaskThresholds = { 7, 21, 41, 74 }
---Index to InkShotMaskThresholds to define mask threshold for paint types
ss.InkShotMaskIndices = {
    drop = 2, explosion = 3, roller = 1, shot = 2, trail = 2,
}

ss.KeyMask                     = {IN_ATTACK, IN_DUCK, IN_ATTACK2}
ss.KeyMaskFind                 = {[IN_ATTACK] = true, [IN_DUCK] = true, [IN_ATTACK2] = true}
ss.CleanupTypeInk              = "SplashSWEPs Ink"
ss.GrayScaleFactor             = Vector(.298912, .586611, .114478)
ss.ShooterGravityMul           = 1
ss.RollerGravityMul            = 0.15
ss.PLAYER_BITS                 = 3   -- unsigned enum
ss.SEND_ERROR_DURATION_BITS    = 4   -- unsgined
ss.SEND_ERROR_NOTIFY_BITS      = 3   -- unsigned NOTIFY_ enum 0 to 4
ss.TRANSFORM_BITS                  = 2   -- unsigned enum
-- ss.SURFACE_ID_BITS          = nil -- For surface ID, determined in InitPostEntity
ss.WEAPON_CLASSNAMES_BITS      = 8   -- unsigned, number of weapon classname array
ss.MAPCACHE_REVISION           = 0   -- Map cache file version (force to redownload on addon update)
ss.MAX_DEGREES_DIFFERENCE      = 60  -- Maximum angle difference between two surfaces to paint
ss.MAX_COS_DIFF                = math.cos(math.rad(ss.MAX_DEGREES_DIFFERENCE)) -- Used by filtering process
ss.MAX_WALLCLIMB_STEP          = 10  -- Wall climb: step size for getting over obstacles
ss.WALLCLIMB_STEP_CHECK_LENGTH = 3   -- Wall climb: look ahead distance for getting over obstacles
ss.ViewModel = { -- Viewmodel animations
    Standing  = ACT_VM_IDLE,
    Crouching = ACT_VM_IDLE_LOWERED,
    Throwing  = ACT_VM_PULLPIN,      -- About to throw sub weapon
    Throw     = ACT_VM_THROW,        -- Actual throw animation
}

-- HACKHACK
-- This is a list of Splatoon maps available in Garry's Mod.
-- They seem unusual and hide our ink.
ss.SplatoonMapPorts = {
    gm_arena_octostomp                  = true,
    gm_blackbelly_skatepark             = true,
    gm_blackbelly_skatepark_night       = true,
    gm_bluefin_depot                    = true,
    gm_bluefin_depot_night              = true,
    gm_bluefin_depot_oct                = true,
    gm_bluefin_depot_rvl                = true,
    gm_camp_triggerfish_day_closegate   = true,
    gm_camp_triggerfish_day_opengate    = true,
    gm_camp_triggerfish_night_closegate = true,
    gm_camp_triggerfish_night_opengate  = true,
    gm_flounder_heights_day             = true,
    gm_flounder_heights_night           = true,
    gm_hammerhead_bridge                = true,
    gm_hammerhead_bridge_night          = true,
    gm_inkopolis_b1                     = true,
    gm_inkopolis_plaza_day              = true,
    gm_inkopolis_plaza_fes_day          = true,
    gm_inkopolis_plaza_fes_night        = true,
    gm_inkopolis_plaza_night            = true,
    gm_inkopolis_square                 = true,
    gm_kelp_dome                        = true,
    gm_kelp_dome_fes                    = true,
    gm_mako_mart                        = true,
    gm_mako_mart_night                  = true,
    gm_mc_princess_diaries              = true,
    gm_moray_towers                     = true,
    gm_new_albacore_hotel_day           = true,
    gm_new_albacore_hotel_night         = true,
    gm_octo_showdown                    = true,
    gm_octo_valley_hubworld             = true,
    gm_octo_valley_hubworld_night       = true,
    gm_port_mackerel_day                = true,
    gm_port_mackerel_night              = true,
    gm_skipper_pavilion_day             = true,
    gm_skipper_pavilion_night           = true,
    gm_shootingrange_splat1             = true,
    gm_shootingrange_splat1_night       = true,
    gm_snapper_canal                    = true,
    gm_snapper_canal_night              = true,
    gm_spawning_grounds_fog_high        = true,
    gm_spawning_grounds_fog_low         = true,
    gm_spawning_grounds_fog_normal      = true,
    gm_spawning_grounds_high            = true,
    gm_spawning_grounds_low             = true,
    gm_spawning_grounds_night_high      = true,
    gm_spawning_grounds_night_low       = true,
    gm_spawning_grounds_night_normal    = true,
    gm_spawning_grounds_normal          = true,
    gm_the_reef_day                     = true,
    gm_the_reef_night                   = true,
    gm_tutorial                         = true,
    gm_tutorial_night                   = true,
    humpback_pump_track_day             = true,
    humpback_pump_track_night           = true,
}

do -- Color tables
    ---@type table<integer, {[1]: integer, [2]: number, [3]: number, [4]: integer}>
    local inkcolors = include "splashsweps/constants/inkcolors.lua"
    for i, t in ipairs(inkcolors) do
        local c = HSVToColor(t[1], t[2], t[3])
        ss.InkColors[i]       = ColorAlpha(c, c.a)
        ss.CrosshairColors[i] = t[4]
        ss.MAX_COLORS         = #ss.InkColors
    end

    ss.COLOR_BITS = select(2, math.frexp(ss.MAX_COLORS)) ---@type integer
end

game.AddParticles "particles/splashsweps.pcf"
timer.Simple(0.25, function() -- Trying to avoid "Attempt to precache unknown particle system" errors
    if not (ss and ss.Particles) then return end
    for _, p in pairs(ss.Particles) do
        if p:find "%%" then continue end
        PrecacheParticleSystem(p)
    end
end)

---Gets actual color from color ID
---@param colorid integer|string
---@return Color
function ss.GetColor(colorid)
    return ss.InkColors[tonumber(colorid)]
end

if game.GetMap() == "gm_inkopolis_b1" then
    ss.CrouchingSolidMask          = bit.band(MASK_PLAYERSOLID, bit.bnot(CONTENTS_PLAYERCLIP))
    ss.CrouchingSolidMaskBrushOnly = bit.band(MASK_PLAYERSOLID_BRUSHONLY, bit.bnot(CONTENTS_PLAYERCLIP))
    ss.MASK_GRATE              = CONTENTS_PLAYERCLIP
else
    ss.CrouchingSolidMask          = MASK_SHOT
    ss.CrouchingSolidMaskBrushOnly = MASK_SHOT_PORTAL
    ss.MASK_GRATE              = bit.bor(CONTENTS_GRATE, CONTENTS_MONSTER)
end

local fps = 60
local playerspeed = .96 * fps -- Distance units per second

---1 meter = 39.3701 inches
local meterToInch = 39.3701

---1 for entity scale, 16 / 12 for map scale
---I don't know why but using reciprocal of this fits the shooting range map
---(gm_shootingrange_splat1)
local inchToHammerUnits = 1 and 1 / (16 / 12)

---Height of the girl in Hammer units
local playermodelHeight = 53
local playermodelHeightInMeters = playermodelHeight / meterToInch

---The real height of the player ripped from the reference game in distance units
local playerRealHeight = 13.5641
local playerRealHeightInMeters = playerRealHeight * 0.1
local unitConversionFix = playermodelHeightInMeters / playerRealHeightInMeters

---DU to HU, Distance units used internally to Hammer units
---Distance between two lines in the shooting range = 50 DU = 5 meters
--- -> 1 DU = 0.1 meters = 0.1 * 39.3701 [inches = Hammer units (entity scale)]
--- = 2.9305 [Hammer units / distance unit]
local dutohu = 0.1 * meterToInch * inchToHammerUnits * unitConversionFix

ss.eps                      = 1e-9 -- Epsilon, representing "close-to-zero"
ss.vector_one               = Vector(1, 1, 1)
ss.MaxInkAmount             = 100
ss.InkGridSize              = 12                          -- in Hammer Units
ss.PlayerJumpPower         = 250                          -- Base jump power
ss.PlayerSpeedMulSubWeapon = .75                          -- Speed multiplier when holding MOUSE2
ss.JumpPowerMulOnEnemyInk   = .75                         -- Jump power multiplier when on enemy ink
ss.ToHammerUnits            = dutohu                      -- = 3.53, distance units -> Hammer distance units
ss.ToHammerUnits2           = dutohu * dutohu             -- Square of distance units / Square of Hammer distance units
ss.ToHammerUnitsPerSec      = dutohu * fps                -- = 212, du/s -> Hammer du/s
ss.ToHammerUnitsPerSec2     = dutohu * fps * fps          -- = 12720, du/s^2 -> Hammer du/s^2
ss.ToHammerHealth           = 100                         -- Normalized health (0--1) to real health
ss.FrameToSec               = 1 / fps                     -- = 0.016667, Constants for time conversion
ss.SecToFrame               = fps                         -- = 60, Constants for time conversion
ss.mDegRandomY              = .5                          -- Shooter spread angle, yaw (need to be validated)
ss.CrouchedSpeedOutofInk    = .45                         -- Crouched speed coefficient when it goes out of ink.
ss.CameraFadeDistance       = 100^2                       -- Thirdperson model fade distance[Hammer units^2]
ss.InkDropGravity           = 1 * ss.ToHammerUnitsPerSec2 -- The gravity acceleration of ink drops[Hammer units/s^2]
ss.ShooterAirResist         = 0.25                        -- Air resistance of Shooter's ink.  The velocity will be multiplied by (1 - AirResist).
ss.RollerAirResist          = 0.1                         -- Air resistance of Roller's splash.
ss.CrosshairBaseAlpha       = 64
ss.CrosshairBaseColor       = ColorAlpha(color_white, ss.CrosshairBaseAlpha)
ss.CrosshairDarkColor       = ColorAlpha(color_black, ss.CrosshairBaseAlpha)
ss.CrouchedTrace = {
    start          = vector_origin,
    endpos         = vector_origin,
    filter         = {},
    mask           = ss.CrouchingSolidMask,
    collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT,
    mins           = -ss.vector_one,
    maxs           = ss.vector_one,
}

ss.PlayerBaseSpeed         = ss.ToHammerUnits * playerspeed      -- Walking speed [Distance units/60 frames]
ss.CrouchedBaseSpeed       = ss.ToHammerUnits * 1.923 * fps      -- Swimming speed [Distance units/60 frames]
ss.OnEnemyInkSpeed         = ss.ToHammerUnits * playerspeed / 4  -- On enemy ink speed[Distance units/60 frames]
ss.mColRadius              = ss.ToHammerUnits * 2                -- Shooter's ink collision radius[Distance units]
ss.mPaintNearDistance      = ss.ToHammerUnits * 11               -- Start decreasing distance[Distance units]
ss.mPaintFarDistance       = ss.ToHammerUnits * 200              -- Minimum radius distance[Distance units]
ss.mSplashDrawRadius       = ss.ToHammerUnits * 3                -- Ink drop position random spread value[Distance units]
ss.mSplashColRadius        = ss.ToHammerUnits * 1.5              -- Ink drop collision radius[Distance units]
ss.AimDuration             = ss.FrameToSec    * 20               -- Change hold type
ss.CrouchDelay             = ss.FrameToSec    * 10               -- Cannot crouch for some frames after firing.
ss.EnemyInkCrouchEndurance = ss.FrameToSec    * 20               -- Time to force players to stand up when they're on enemy ink.
ss.HealDelay               = ss.FrameToSec    * 60               -- Time to heal again after taking damage.
ss.RollerRunoverStopFrame  = ss.FrameToSec    * 30               -- Stopping time when player tries to run over.
ss.ShooterTrailDelay       = ss.FrameToSec    * 2                -- Time to start to move the latter half of shooter's ink.
ss.SubWeaponThrowTime      = ss.FrameToSec    * 25               -- Duration of TPS sub weapon throwing animation.

ss.UnitsConverter = {
    ["du"]     = ss.ToHammerUnits,
    ["du/f"]   = ss.ToHammerUnitsPerSec,
    ["du/f^2"] = ss.ToHammerUnitsPerSec2,
    ["f"]      = ss.FrameToSec,
    ["ink"]    = ss.MaxInkAmount,
}
