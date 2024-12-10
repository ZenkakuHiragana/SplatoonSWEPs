
local ss = SplashSWEPs
if not ss then return end
AddCSLuaFile "shared.lua"
include "shared.lua"

local SWEP = SWEP
---@cast SWEP SWEP.Shooter
---@class SWEP.Shooter : SplashWeaponBase

function SWEP:NPCBurstSettings()
    local span = self.Parameters.mTripleShotSpan or 0
    if span > 0 then return 1, 1, self.NPCDelay end
end

function SWEP:NPCRestTimes()
    local span = self.Parameters.mTripleShotSpan or 0
    if span > 0 then return span, span end
end

function SWEP:NPCShoot_Primary(ShootPos, ShootDir)
    self:PrimaryAttackEntryPoint()
    if self.IsBlaster then return end
    local interval = self.Parameters.mRepeatFrame
    if not interval then return end
    self:AddSchedule(interval, 2, function(_, schedule)
        self:PrimaryAttackEntryPoint()
    end)
end
