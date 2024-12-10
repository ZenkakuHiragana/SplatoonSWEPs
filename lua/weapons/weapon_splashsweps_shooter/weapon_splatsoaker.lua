
AddCSLuaFile()
local SWEP = SWEP ---@cast SWEP SWEP.Shooter
local ss = SplashSWEPs
if not (ss and SWEP) then return end
SWEP.ADSAngOffset = Angle(4, 0, -75)
SWEP.ADSOffset = Vector(-10, 8.75, -9)
SWEP.ShootSound = "Weapon_Pistol.Single"
SWEP.Special = "bombrush"
SWEP.Sub = "burstbomb"

ss.SetPrimary(SWEP, {
    mRepeatFrame = 6,
    mTripleShotSpan = 0,
    mInitVel = 22,
    mDegRandom = 6,
    mDegJumpRandom = 15,
    mSplashSplitNum = 5,
    mKnockBack = 0,
    mInkConsume = 0.009,
    mInkRecoverStop = 20,
    mMoveSpeed = 0.72,
    mDamageMax = 0.36,
    mDamageMin = 0.18,
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
    mDegBias = 0.25,
    mDegBiasKf = 0.02,
    mDegJumpBias = 0.4,
    mDegJumpBiasFrame = 60,
})
