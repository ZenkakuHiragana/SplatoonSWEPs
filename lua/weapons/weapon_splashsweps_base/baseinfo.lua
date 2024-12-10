
-- Weapon information in default SWEP structure.
local ss = SplashSWEPs
if not ss then return end

---@class SplashWeaponBase
---@field ViewModel0    string?
---@field ViewModel1    string?
---@field ViewModel2    string?
---@field SpecialWeapon string
---@field SubWeapon     string
---@field ClassID       integer
local SWEP = SWEP
if CLIENT then
    SWEP.Author = ss.Text.Author
    SWEP.BobScale = 1
    SWEP.BounceWeaponIcon = true
    SWEP.DrawAmmo = true
    SWEP.DrawCrosshair = true
    SWEP.DrawWeaponInfoBox = true
    SWEP.Instructions = ss.Text.Instructions --[[@as string]]
    SWEP.Purpose = ss.Text.Purpose --[[@as string]]
    SWEP.RenderGroup = RENDERGROUP_BOTH
    SWEP.SpeechBubbleLid = surface.GetTextureID "gui/speech_lid"
    SWEP.SwayScale = 1
    SWEP.UseHands = true
    SWEP.ViewModelFOV = 62
else
    SWEP.AutoSwitchFrom = false
    SWEP.AutoSwitchTo = false
    SWEP.Weight = 1
end

SWEP.PrintName = "Splash Weapon Base"
SWEP.Spawnable = false
SWEP.HoldType = "crossbow"
SWEP.Slot = 1
SWEP.SlotPos = 2
SWEP.IsSplashWeapon = true
SWEP.m_WeaponDeploySpeed = 1

SWEP.Secondary = SWEP.Secondary or {}
SWEP.Secondary.Automatic = true
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Ammo = "Ink"
