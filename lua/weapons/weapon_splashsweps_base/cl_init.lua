
local ss = SplashSWEPs
if not ss then return end
include "shared.lua"
include "baseinfo.lua"
include "cl_draw.lua"
include "ai_translations.lua"

---@class SplashWeaponBase
---@field HullDuckMaxs             Vector
---@field HullDuckMins             Vector
---@field ViewOffsetDucked         Vector
local SWEP = SWEP

---Pops up error notification on the player's screen
---@param msg string
function SWEP:PopupError(msg)
    msg = ss.Text.Error[msg] --[[@as string]]
    if not msg then return end
    notification.AddLegacy(msg, NOTIFY_ERROR, 10)
end

function SWEP:Initialize()
    self:CreateModels()

    -- Our initialize code
    self.SpriteCurrentSize = 0
    self.SpriteSizeChangeSpeed = 0
    self.EnoughSubWeapon = true
    self.PreviousInk = true
    self.Cursor = { x = ScrW() / 2, y = ScrH() / 2 }
    self:MakeTransformedModel()
    self:SharedInitBase()
    ss.ProtectedCall(self.ClientInit, self)
    self:Deploy()
end

function SWEP:Deploy()
    local Owner = self:GetOwner()
    if not IsValid(Owner) then return true end
    if Owner:IsPlayer() then ---@cast Owner Player
        self.HullDuckMins, self.HullDuckMaxs = Owner:GetHullDuck()
        self.ViewOffsetDucked = Owner:GetViewOffsetDucked()
        self:ResetBonePositions(self:GetViewModel())
    end

    self:GetOptions()
    ss.ProtectedCall(self.ClientDeploy, self)
    return self:SharedDeployBase()
end

---@param switchTo Entity
---@return boolean
function SWEP:Holster(switchTo)
    if self:GetInFence() then return false end
    if ss.ProtectedCall(self.ClientHolster, self, switchTo) == false then return false end
    if self:SharedHolsterBase(switchTo) == false then return false end

    local Owner = self:GetOwner()
    if not IsValid(Owner) then return true end
    if Owner:IsPlayer() then ---@cast Owner Player
        local vm = self:GetViewModel()
        if IsValid(vm) then self:ResetBonePositions(vm) end
        if self:GetNWBool "transformoncrouch" and self.HullDuckMins then
            Owner:SetHullDuck(self.HullDuckMins, self.HullDuckMaxs)
            Owner:SetViewOffsetDucked(self.ViewOffsetDucked)
        end
    end

    Owner:SetHealth(Owner:Health() * self:GetNWInt "BackupHumanMaxHealth" / self:GetNWInt "BackupPlayerMaxHealth")
    return true
end

-- It's important to remove CSEnt with CSEnt:Remove() when it's no longer needed.
function SWEP:OnRemove()
    local vm = self:GetViewModel()
    if IsValid(vm) then self:ResetBonePositions(vm) end
    if IsValid(self.InkTankModel) then self.InkTankModel:Remove() end
    if IsValid(self.InkTankLight) then
        self.InkTankLight:StopEmissionAndDestroyImmediately()
    end

    self:StopLoopSound()
    self:EndRecording()
    ss.ProtectedCall(self.ClientOnRemove, self)
    ss.ProtectedCall(self.SharedOnRemove, self)
    ss.SetPlayerFilter(self:GetOwner(), self:GetNWInt("inkcolor", -1), false)
end

function SWEP:Think()
    if not IsValid(self:GetOwner()) or self:GetHolstering() then return end
    if self:IsFirstTimePredicted() then
        local enough = self:GetInk() > (ss.ProtectedCall(self.GetSubWeaponCost, self) or 0)
        if not self.EnoughSubWeapon and enough and self:IsCarriedByLocalPlayer() then
            surface.PlaySound(ss.BombAvailable)
        end
        self.EnoughSubWeapon = enough
    end

    self:ProcessSchedules()
    self:SharedThinkBase()
    ss.ProtectedCall(self.ClientThink, self)
end

---Returns if the owner is seeing third person view
---@return boolean # True if the camera is third person view
function SWEP:IsTPS()
    local Owner = self:GetOwner() --[[@as Player]]
    return not self:IsCarriedByLocalPlayer() or Owner:ShouldDrawLocalPlayer()
end

---Translates given world position to view model position
---@param pos Vector The world position
---@return Vector # Translated view model position
function SWEP:TranslateToViewmodelPos(pos)
    if self:IsTPS() then return pos end
    local dir = pos - EyePos() dir:Normalize()
    local aim = EyeAngles():Forward()
    dir = aim + (dir - aim) * self:GetFOV() / self.ViewModelFOV
    return EyePos() + dir * pos:Distance(EyePos())
end

---Translates given view model position to world position
---@param pos Vector The view model position
---@return Vector # Translated world position
function SWEP:TranslateToWorldmodelPos(pos)
    if self:IsTPS() then return pos end
    local dir = pos - EyePos() dir:Normalize()
    local aim = EyeAngles():Forward()
    dir = aim + (dir - aim) * self.ViewModelFOV / self:GetFOV()
    return EyePos() + dir * pos:Distance(EyePos())
end
