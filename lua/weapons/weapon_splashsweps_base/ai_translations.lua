
---@class SplashWeaponBase
local SWEP = SWEP

---Sets up ACT translation table for given hold type t.
---@param t string The hold type to construct.
function SWEP:SetupWeaponHoldTypeForAI(t)
    self.ActivityTranslateAI    = self.ActivityTranslateAI    or {}
    self.ActivityTranslateAI[t] = self.ActivityTranslateAI[t] or {}
    local a = self.ActivityTranslateAI[t]
    if t == "smg" then

        a[ ACT_IDLE ]                  = ACT_IDLE_SMG1
        a[ ACT_IDLE_ANGRY ]            = ACT_IDLE_ANGRY_SMG1
        a[ ACT_IDLE_RELAXED ]          = ACT_IDLE_SMG1_RELAXED
        a[ ACT_IDLE_STIMULATED ]       = ACT_IDLE_SMG1_STIMULATED
        a[ ACT_IDLE_AGITATED ]         = ACT_IDLE_ANGRY_SMG1
        a[ ACT_MP_RUN ]                = ACT_HL2MP_RUN_SMG1
        a[ ACT_MP_CROUCHWALK ]         = ACT_HL2MP_WALK_CROUCH_SMG1
        a[ ACT_RANGE_ATTACK1 ]         = ACT_RANGE_ATTACK_SMG1
        a[ ACT_RANGE_ATTACK1_LOW ]     = ACT_RANGE_ATTACK_SMG1_LOW
        a[ ACT_RELOAD ]                = ACT_RELOAD_SMG1
        a[ ACT_RELOAD_LOW ]            = ACT_RELOAD_SMG1_LOW
        a[ ACT_WALK_AIM_RELAXED ]      = ACT_WALK_RIFLE_RELAXED
        a[ ACT_WALK_AIM_STIMULATED ]   = ACT_WALK_AIM_RIFLE_STIMULATED
        a[ ACT_WALK_AIM_AGITATED ]     = ACT_WALK_AIM_RIFLE
        a[ ACT_RUN_AIM_RELAXED ]       = ACT_RUN_RIFLE_RELAXED
        a[ ACT_RUN_AIM_STIMULATED ]    = ACT_RUN_AIM_RIFLE_STIMULATED
        a[ ACT_RUN_AIM_AGITATED ]      = ACT_RUN_AIM_RIFLE
        a[ ACT_WALK_AIM ]              = ACT_WALK_AIM_RIFLE
        a[ ACT_WALK_CROUCH ]           = ACT_WALK_CROUCH_RIFLE
        a[ ACT_WALK_CROUCH_AIM ]       = ACT_WALK_CROUCH_AIM_RIFLE
        a[ ACT_RUN ]                   = ACT_RUN_RIFLE
        a[ ACT_RUN_AIM ]               = ACT_RUN_AIM_RIFLE
        a[ ACT_WALK_RELAXED ]          = ACT_WALK_RIFLE_RELAXED
        a[ ACT_WALK_STIMULATED ]       = ACT_WALK_RIFLE_STIMULATED
        a[ ACT_WALK_AGITATED ]         = ACT_WALK_AIM_RIFLE
        a[ ACT_RUN_RELAXED ]           = ACT_RUN_RIFLE_RELAXED
        a[ ACT_RUN_STIMULATED ]        = ACT_RUN_RIFLE_STIMULATED
        a[ ACT_RUN_AGITATED ]          = ACT_RUN_AIM_RIFLE

    elseif t == "ar2" then

        a[ ACT_RANGE_ATTACK1 ]         = ACT_RANGE_ATTACK_AR2
        a[ ACT_RELOAD ]                = ACT_RELOAD_SMG1
        a[ ACT_IDLE ]                  = ACT_IDLE_SMG1
        a[ ACT_IDLE_ANGRY ]            = ACT_IDLE_ANGRY_SMG1
        a[ ACT_WALK ]                  = ACT_WALK_RIFLE
        a[ ACT_IDLE_RELAXED ]          = ACT_IDLE_SMG1_RELAXED
        a[ ACT_IDLE_STIMULATED ]       = ACT_IDLE_SMG1_STIMULATED
        a[ ACT_IDLE_AGITATED ]         = ACT_IDLE_ANGRY_SMG1
        a[ ACT_WALK_RELAXED ]          = ACT_WALK_RIFLE_RELAXED
        a[ ACT_WALK_STIMULATED ]       = ACT_WALK_RIFLE_STIMULATED
        a[ ACT_WALK_AGITATED ]         = ACT_WALK_AIM_RIFLE
        a[ ACT_RUN_RELAXED ]           = ACT_RUN_RIFLE_RELAXED
        a[ ACT_RUN_STIMULATED ]        = ACT_RUN_RIFLE_STIMULATED
        a[ ACT_RUN_AGITATED ]          = ACT_RUN_AIM_RIFLE
        a[ ACT_IDLE_AIM_RELAXED ]      = ACT_IDLE_SMG1_RELAXED
        a[ ACT_IDLE_AIM_STIMULATED ]   = ACT_IDLE_AIM_RIFLE_STIMULATED
        a[ ACT_IDLE_AIM_AGITATED ]     = ACT_IDLE_ANGRY_SMG1
        a[ ACT_WALK_AIM_RELAXED ]      = ACT_WALK_RIFLE_RELAXED
        a[ ACT_WALK_AIM_STIMULATED ]   = ACT_WALK_AIM_RIFLE_STIMULATED
        a[ ACT_WALK_AIM_AGITATED ]     = ACT_WALK_AIM_RIFLE
        a[ ACT_RUN_AIM_RELAXED ]       = ACT_RUN_RIFLE_RELAXED
        a[ ACT_RUN_AIM_STIMULATED ]    = ACT_RUN_AIM_RIFLE_STIMULATED
        a[ ACT_RUN_AIM_AGITATED ]      = ACT_RUN_AIM_RIFLE
        a[ ACT_WALK_AIM ]              = ACT_WALK_AIM_RIFLE
        a[ ACT_WALK_CROUCH ]           = ACT_WALK_CROUCH_RIFLE
        a[ ACT_WALK_CROUCH_AIM ]       = ACT_WALK_CROUCH_AIM_RIFLE
        a[ ACT_RUN ]                   = ACT_RUN_RIFLE
        a[ ACT_RUN_AIM ]               = ACT_RUN_AIM_RIFLE
        a[ ACT_RUN_CROUCH ]            = ACT_RUN_CROUCH_RIFLE
        a[ ACT_RUN_CROUCH_AIM ]        = ACT_RUN_CROUCH_AIM_RIFLE
        a[ ACT_GESTURE_RANGE_ATTACK1 ] = ACT_GESTURE_RANGE_ATTACK_AR2
        a[ ACT_COVER_LOW ]             = ACT_COVER_SMG1_LOW
        a[ ACT_RANGE_AIM_LOW ]         = ACT_RANGE_AIM_AR2_LOW
        a[ ACT_RANGE_ATTACK1_LOW ]     = ACT_RANGE_ATTACK_SMG1_LOW
        a[ ACT_RELOAD_LOW ]            = ACT_RELOAD_SMG1_LOW
        a[ ACT_GESTURE_RELOAD ]        = ACT_GESTURE_RELOAD_SMG1

    elseif t == "pistol" then

        a[ ACT_RANGE_ATTACK1 ]         = ACT_RANGE_ATTACK_AR2
        a[ ACT_MELEE_ATTACK1 ]         = ACT_IDLE_ANGRY_SMG1
        a[ ACT_RELOAD ]                = ACT_RELOAD_SMG1
        a[ ACT_IDLE ]                  = ACT_IDLE_SMG1
        a[ ACT_IDLE_ANGRY ]            = ACT_IDLE_ANGRY_SMG1
        a[ ACT_WALK ]                  = ACT_WALK_RIFLE
        a[ ACT_IDLE_RELAXED ]          = ACT_IDLE_SMG1_RELAXED
        a[ ACT_IDLE_STIMULATED ]       = ACT_IDLE_SMG1_STIMULATED
        a[ ACT_IDLE_AGITATED ]         = ACT_IDLE_ANGRY_SMG1
        a[ ACT_WALK_RELAXED ]          = ACT_WALK_RIFLE_RELAXED
        a[ ACT_WALK_STIMULATED ]       = ACT_WALK_RIFLE_STIMULATED
        a[ ACT_WALK_AGITATED ]         = ACT_WALK_AIM_RIFLE
        a[ ACT_RUN_RELAXED ]           = ACT_RUN_RIFLE_RELAXED
        a[ ACT_RUN_STIMULATED ]        = ACT_RUN_RIFLE_STIMULATED
        a[ ACT_RUN_AGITATED ]          = ACT_RUN_AIM_RIFLE
        a[ ACT_IDLE_AIM_RELAXED ]      = ACT_IDLE_SMG1_RELAXED
        a[ ACT_IDLE_AIM_STIMULATED ]   = ACT_IDLE_AIM_RIFLE_STIMULATED
        a[ ACT_IDLE_AIM_AGITATED ]     = ACT_IDLE_ANGRY_SMG1
        a[ ACT_WALK_AIM_RELAXED ]      = ACT_WALK_RIFLE_RELAXED
        a[ ACT_WALK_AIM_STIMULATED ]   = ACT_WALK_AIM_RIFLE_STIMULATED
        a[ ACT_WALK_AIM_AGITATED ]     = ACT_WALK_AIM_RIFLE
        a[ ACT_RUN_AIM_RELAXED ]       = ACT_RUN_RIFLE_RELAXED
        a[ ACT_RUN_AIM_STIMULATED ]    = ACT_RUN_AIM_RIFLE_STIMULATED
        a[ ACT_RUN_AIM_AGITATED ]      = ACT_RUN_AIM_RIFLE
        a[ ACT_WALK_AIM ]              = ACT_WALK_AIM_RIFLE
        a[ ACT_WALK_CROUCH ]           = ACT_WALK_RIFLE_RELAXED
        a[ ACT_WALK_CROUCH_AIM ]       = ACT_WALK_AIM_RIFLE
        a[ ACT_RUN ]                   = ACT_RUN_RIFLE
        a[ ACT_RUN_AIM ]               = ACT_RUN_AIM_RIFLE
        a[ ACT_RUN_CROUCH ]            = ACT_RUN_RIFLE
        a[ ACT_RUN_CROUCH_AIM ]        = ACT_RUN_AIM_RIFLE
        a[ ACT_GESTURE_RANGE_ATTACK1 ] = ACT_GESTURE_RANGE_ATTACK_AR2
        a[ ACT_CROUCH ]                = ACT_IDLE_ANGRY_SMG1
        a[ ACT_CROUCHIDLE ]            = ACT_IDLE_ANGRY_SMG1
        a[ ACT_COVER_LOW ]             = ACT_IDLE_ANGRY_SMG1
        a[ ACT_RANGE_AIM_LOW ]         = ACT_IDLE_ANGRY_SMG1
        a[ ACT_RANGE_ATTACK1_LOW ]     = ACT_RANGE_ATTACK_SMG1
        a[ ACT_RELOAD_LOW ]            = ACT_RELOAD_SMG1
        a[ ACT_GESTURE_RELOAD ]        = ACT_GESTURE_RELOAD_SMG1

    elseif t == "shotgun" then

        a[ ACT_RANGE_ATTACK1 ]         = ACT_RANGE_ATTACK_SHOTGUN
        a[ ACT_MELEE_ATTACK1 ]         = ACT_IDLE_ANGRY_SHOTGUN
        a[ ACT_RELOAD ]                = ACT_RELOAD_SHOTGUN
        a[ ACT_IDLE ]                  = ACT_IDLE_RIFLE
        a[ ACT_IDLE_ANGRY ]            = ACT_IDLE_ANGRY_SHOTGUN
        a[ ACT_WALK ]                  = ACT_WALK_RIFLE
        a[ ACT_IDLE_RELAXED ]          = ACT_IDLE_SMG1_RELAXED
        a[ ACT_IDLE_STIMULATED ]       = ACT_IDLE_SMG1_STIMULATED
        a[ ACT_IDLE_AGITATED ]         = ACT_IDLE_ANGRY_SHOTGUN
        a[ ACT_WALK_RELAXED ]          = ACT_WALK_RIFLE_RELAXED
        a[ ACT_WALK_STIMULATED ]       = ACT_WALK_RIFLE_STIMULATED
        a[ ACT_WALK_AGITATED ]         = ACT_WALK_AIM_RIFLE
        a[ ACT_RUN_RELAXED ]           = ACT_RUN_RIFLE_RELAXED
        a[ ACT_RUN_STIMULATED ]        = ACT_RUN_RIFLE_STIMULATED
        a[ ACT_RUN_AGITATED ]          = ACT_RUN_AIM_RIFLE
        a[ ACT_IDLE_AIM_RELAXED ]      = ACT_IDLE_SHOTGUN_RELAXED
        a[ ACT_IDLE_AIM_STIMULATED ]   = ACT_IDLE_AIM_RIFLE_STIMULATED
        a[ ACT_IDLE_AIM_AGITATED ]     = ACT_IDLE_ANGRY_SHOTGUN
        a[ ACT_WALK_AIM_RELAXED ]      = ACT_WALK_RIFLE_RELAXED
        a[ ACT_WALK_AIM_STIMULATED ]   = ACT_WALK_AIM_RIFLE_STIMULATED
        a[ ACT_WALK_AIM_AGITATED ]     = ACT_WALK_AIM_RIFLE
        a[ ACT_RUN_AIM_RELAXED ]       = ACT_RUN_RIFLE_RELAXED
        a[ ACT_RUN_AIM_STIMULATED ]    = ACT_RUN_AIM_RIFLE_STIMULATED
        a[ ACT_RUN_AIM_AGITATED ]      = ACT_RUN_AIM_RIFLE
        a[ ACT_WALK_AIM ]              = ACT_WALK_AIM_RIFLE
        a[ ACT_WALK_CROUCH ]           = ACT_WALK_RIFLE_RELAXED
        a[ ACT_WALK_CROUCH_AIM ]       = ACT_WALK_AIM_RIFLE
        a[ ACT_RUN ]                   = ACT_RUN_RIFLE
        a[ ACT_RUN_AIM ]               = ACT_RUN_AIM_RIFLE
        a[ ACT_RUN_CROUCH ]            = ACT_RUN_RIFLE
        a[ ACT_RUN_CROUCH_AIM ]        = ACT_RUN_AIM_RIFLE
        a[ ACT_GESTURE_RANGE_ATTACK1 ] = ACT_GESTURE_RANGE_ATTACK_SHOTGUN
        a[ ACT_CROUCH ]                = ACT_IDLE_ANGRY_SHOTGUN
        a[ ACT_CROUCHIDLE ]            = ACT_IDLE_ANGRY_SHOTGUN
        a[ ACT_COVER_LOW ]             = ACT_IDLE_ANGRY_SHOTGUN
        a[ ACT_RANGE_AIM_LOW ]         = ACT_IDLE_ANGRY_SHOTGUN
        a[ ACT_RANGE_ATTACK1_LOW ]     = ACT_RANGE_ATTACK_SHOTGUN_LOW
        a[ ACT_RELOAD_LOW ]            = ACT_RELOAD_SHOTGUN_LOW
        a[ ACT_GESTURE_RELOAD ]        = ACT_GESTURE_RELOAD_SHOTGUN

    elseif t == "melee" then

        a[ ACT_RANGE_ATTACK1 ]         = ACT_MELEE_ATTACK_SWING
        a[ ACT_MELEE_ATTACK1 ]         = ACT_MELEE_ATTACK1
        a[ ACT_RELOAD ]                = ACT_IDLE_ANGRY_MELEE
        a[ ACT_IDLE ]                  = ACT_IDLE_ANGRY_MELEE
        a[ ACT_IDLE_ANGRY ]            = ACT_IDLE_ANGRY_MELEE
        a[ ACT_WALK ]                  = ACT_WALK
        a[ ACT_IDLE_RELAXED ]          = ACT_IDLE_RELAXED
        a[ ACT_IDLE_STIMULATED ]       = ACT_IDLE_STIMULATED
        a[ ACT_IDLE_AGITATED ]         = ACT_IDLE_AGITATED
        a[ ACT_WALK_RELAXED ]          = ACT_WALK_RELAXED
        a[ ACT_WALK_STIMULATED ]       = ACT_WALK_STIMULATED
        a[ ACT_WALK_AGITATED ]         = ACT_WALK_AGITATED
        a[ ACT_RUN_RELAXED ]           = ACT_RUN
        a[ ACT_RUN_STIMULATED ]        = ACT_RUN_STIMULATED
        a[ ACT_RUN_AGITATED ]          = ACT_RUN_AGITATED
        a[ ACT_IDLE_AIM_RELAXED ]      = ACT_IDLE_AIM_RELAXED
        a[ ACT_IDLE_AIM_STIMULATED ]   = ACT_IDLE_AIM_STIMULATED
        a[ ACT_IDLE_AIM_AGITATED ]     = ACT_IDLE_AIM_AGITATED
        a[ ACT_WALK_AIM_RELAXED ]      = ACT_WALK_AIM_RELAXED
        a[ ACT_WALK_AIM_STIMULATED ]   = ACT_WALK_AIM_STIMULATED
        a[ ACT_WALK_AIM_AGITATED ]     = ACT_WALK_AIM_AGITATED
        a[ ACT_RUN_AIM_RELAXED ]       = ACT_RUN_AIM_RELAXED
        a[ ACT_RUN_AIM_STIMULATED ]    = ACT_RUN_AIM_STIMULATED
        a[ ACT_RUN_AIM_AGITATED ]      = ACT_RUN_AIM_AGITATED
        a[ ACT_WALK_AIM ]              = ACT_WALK_AIM
        a[ ACT_WALK_CROUCH ]           = ACT_WALK_CROUCH
        a[ ACT_WALK_CROUCH_AIM ]       = ACT_WALK_CROUCH_AIM
        a[ ACT_RUN ]                   = ACT_RUN
        a[ ACT_RUN_AIM ]               = ACT_RUN_AIM
        a[ ACT_RUN_CROUCH ]            = ACT_RUN_CROUCH
        a[ ACT_RUN_CROUCH_AIM ]        = ACT_RUN_CROUCH_AIM
        a[ ACT_GESTURE_RANGE_ATTACK1 ] = ACT_GESTURE_MELEE_ATTACK_SWING
        a[ ACT_GESTURE_MELEE_ATTACK1 ] = ACT_GESTURE_MELEE_ATTACK_SWING
        a[ ACT_CROUCH ]                = ACT_IDLE_ANGRY_MELEE
        a[ ACT_CROUCHIDLE ]            = ACT_IDLE_ANGRY_MELEE
        a[ ACT_COVER_LOW ]             = ACT_IDLE_ANGRY_MELEE
        a[ ACT_RANGE_AIM_LOW ]         = ACT_IDLE_ANGRY_MELEE
        a[ ACT_RANGE_ATTACK1_LOW ]     = ACT_GESTURE_MELEE_ATTACK_SWING
        a[ ACT_RELOAD_LOW ]            = ACT_GESTURE_MELEE_ATTACK_SWING
        a[ ACT_GESTURE_RELOAD ]        = ACT_GESTURE_MELEE_ATTACK_SWING

    end
end

