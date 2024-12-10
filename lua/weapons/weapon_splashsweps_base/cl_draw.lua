
-- The way to draw ink tank comes from SWEP Construction Kit.
local ss = SplashSWEPs
if not ss then return end

---@class SplashWeaponBase
---@field CustomCalcView               fun(self, ply: Player, pos: Vector, ang: Angle, fov: number): number?
---@field PreDrawWorldModel            fun(self): boolean?
---@field PreDrawWorldModelTranslucent fun(self): boolean?
---@field PreViewModelDrawn            fun(self, vm: Entity, weapon: Weapon, ply: Player)
---@field AmmoDisplay                  { Draw: boolean, PrimaryClip: number, PrimaryAmmo: number, SecondaryAmmo: number? }
---@field Cursor                       { x: number, y: number }
---@field EnoughSubWeapon              boolean
---@field InkTankModel                 CSEnt.ModelEnt?
---@field InkTankLight                 CNewParticleEffect?
---@field PreviousInk                  boolean
---@field ViewPunch                    Angle
---@field ViewPunchVel                 Angle
---@field SpriteSizeChangeSpeed        number
---@field SpriteCurrentSize            number
local SWEP = SWEP

---@class CSEnt.ModelEnt : CSEnt
---@field GetInkColorProxy fun(self): Vector
---@field RenderOverride?  fun(self, flags: number)

---Resets bone manipulations of given view model
---@param vm Entity The view model to reset
function SWEP:ResetBonePositions(vm)
    if not (IsValid(vm) and vm:GetBoneCount()) then return end
    for i = 0, vm:GetBoneCount() do
        vm:ManipulateBoneScale(i, ss.vector_one)
        vm:ManipulateBonePosition(i, vector_origin)
        vm:ManipulateBoneAngles(i, angle_zero)
    end
end

local mat = Material "sprites/orangeflare1.vmt"
function SWEP:CreateModels()
    if not IsValid(self.InkTankModel) then
        local mdl = ClientsideModel(ss.InkTankModel, RENDERGROUP_TRANSLUCENT)
        mdl:SetNoDraw(true)
        mdl:SetParent(self:GetOwner())
        mdl:AddEffects(EF_BONEMERGE)
        mdl:SetRenderMode(RENDERMODE_TRANSCOLOR)
        mdl:SetColor(Color(255, 255, 255, 128))
        ---@cast mdl CSEnt.ModelEnt
        function mdl.GetInkColorProxy()
            if IsValid(self) then
                return self:GetInkColorProxy()
            else
                return ss.vector_one
            end
        end
        function mdl.RenderOverride(_, flags)
            if not IsValid(self) then return end
            local cameradistance = self:IsCarriedByLocalPlayer() and self:GetCameraFade() or 1
            render.SetBlend(cameradistance)
            mdl:DrawModel(flags)
            render.SetBlend(1)
            local size = self.SpriteCurrentSize
            local subweaponcost = ss.ProtectedCall(self.GetSubWeaponCost, self) or 0
            if self:GetInk() < subweaponcost then return end
            local att = mdl:LookupAttachment "cap"
            if att <= 0 then return end
            local pos = mdl:GetAttachment(att).Pos
            render.SetMaterial(mat)
            render.DrawSprite(pos, size, size)
        end

        self.InkTankModel = mdl
    end
end

---@param vm Entity
---@param weapon SplashWeaponBase
---@param ply Player
function SWEP:PreDrawViewModel(vm, weapon, ply)
    ss.ProtectedCall(self.PreViewModelDrawn, self, vm, weapon, ply)
    vm:SetupBones()
end

---@param vm Entity
function SWEP:ViewModelDrawn(vm)
    if self:GetHolstering() or not (IsValid(self) and IsValid(self:GetOwner())) then return end
    if self:GetThrowing() and CurTime() > self:GetNextSecondaryFire() then
        ss.ProtectedCall(self.DrawOnSubTriggerDown, self)
    end
end

function SWEP:DrawWorldModel(flags)
    if not IsValid(self:GetOwner()) then return self:DrawModel(flags) end
    if self:GetHolstering() then return end
    if self:ShouldDrawTransformedModel() then return end
    if self:GetInInk() then return end
    if ss.ProtectedCall(self.PreDrawWorldModel, self) then return end
    if not self:IsCarriedByLocalPlayer() then self:Think() end
    if self:GetThrowing() and CurTime() > self:GetNextSecondaryFire() then
        ss.ProtectedCall(self.DrawOnSubTriggerDown, self)
    end

    local cameradistance = self:IsCarriedByLocalPlayer() and self:GetCameraFade() or 1
    if cameradistance == 1 then
        self:SetupBones()
        self:DrawModel(flags)
    end
end

function SWEP:DrawWorldModelTranslucent(flags)
    if IsValid(self:GetOwner()) and self:GetHolstering() then return end
    if ss.ProtectedCall(self.PreDrawWorldModelTranslucent, self) then return end

    local usingbombrush = self:GetSpecialActivated() and self.Special == "bombrush"
    local refsize = usingbombrush and 36 or self.EnoughSubWeapon and 24 or 0
    local diff = refsize - self.SpriteCurrentSize
    self.SpriteSizeChangeSpeed = self.SpriteSizeChangeSpeed * 0.92 + diff * 2 * FrameTime()
    self.SpriteCurrentSize = self.SpriteCurrentSize + self.SpriteSizeChangeSpeed

    if self:GetThrowing() and CurTime() > self:GetNextSecondaryFire() then
        ss.ProtectedCall(self.DrawOnSubTriggerDown, self)
    end

    if not (self:ShouldDrawTransformedModel() or self:GetInInk()) then
        local subweaponcost = ss.ProtectedCall(self.GetSubWeaponCost, self) or 0
        local cameradistance = self:IsCarriedByLocalPlayer() and self:GetCameraFade() or 1
        if cameradistance < 1 then
            render.SetBlend(cameradistance)
            self:DrawModel(flags)
            render.SetBlend(1)
        end
        if not IsValid(self.InkTankModel) then
            self:CreateModels()
        end

        local model = self.InkTankModel
        if IsValid(model) then ---@cast model -?
            -- Manipulate sub weapon usable meter
            local pos_bombmeter = Vector(math.min(-11.9 + subweaponcost * 17 / ss.GetMaxInkAmount(), 5.1))
            local bone_bombmeter = model:LookupBone "bip_inktank_bombmeter"
            local bone_ink = model:LookupBone "bip_inktank_ink_core"
            local bg_ink = model:FindBodygroupByName "Ink"
            if bone_bombmeter then
                model:ManipulateBonePosition(bone_bombmeter, pos_bombmeter)
            end

            -- Ink remaining
            local ink = -17 + .17 * self:GetInk() * ss.MaxInkAmount / ss.GetMaxInkAmount()
            if bone_ink then
                model:ManipulateBonePosition(bone_ink, Vector(ink, 0, 0))
            end

            -- Ink visiblity
            if bg_ink >= 0 then
                model:SetBodygroup(bg_ink, ink < -16.5 and 1 or 0)
            end

            -- Ink wave
            for i = 1, 19 do
                if i == 10 or i == 11 then continue end
                local number = tostring(i)
                if i < 10 then number = "0" .. tostring(i) end
                local bone = model:LookupBone("bip_inktank_ink_" .. number)
                if bone then
                    local delta = model:GetManipulateBonePosition(bone).y
                    local write = math.Clamp(delta + math.sin(CurTime() + math.pi / 17 * i) / 100, -0.25, 0.25)
                    model:ManipulateBonePosition(bone, Vector(0, write, 0))
                end
            end

            model:SetupBones()
            model:DrawModel()
        end
    end
end

-- Show remaining amount of ink tank
function SWEP:CustomAmmoDisplay()
    local specialProgress = math.Clamp(math.Round(self:GetSpecialPointProgress() * 100), 0, 100)
    if self:GetSpecialActivated() then
        local dt = CurTime() - self:GetSpecialStartTime()
        local duration = self:GetSpecialDuration()
        specialProgress = math.Clamp(100 - math.Round(dt / duration * 100), 0, 100)
    end
    return {
        Draw = true,
        PrimaryClip = math.Round(self:GetInk()),
        PrimaryAmmo = specialProgress,
        SecondaryAmmo = self:DisplayAmmo(),
    }
end

---This hook draws the selection icon in the weapon selection menu.
---@param x number
---@param y number
---@param wide number
---@param tall number
---@param alpha number
function SWEP:DrawWeaponSelection(x, y, wide, tall, alpha)
    -- Set us up the texture
    surface.SetDrawColor(255, 255, 255, alpha)
    surface.SetTexture(self.WepSelectIcon)

    -- Lets get a sin wave to make it bounce
    local fsin = math.sin(CurTime() * 10) * (self.BounceWeaponIcon and 5 or 0)

    -- Borders
    x, y, wide = x + 10, y + 10, wide - 20

    -- Draw that mother
    surface.DrawTexturedRect(x + fsin, y - fsin, wide - fsin * 2, tall + fsin * 2)

    -- Draw weapon info box
    self:PrintWeaponInfo(x + wide + 20, y + tall, alpha)
end

---Called when the crosshair is about to get drawn, and allows you to override it.
---@param x number
---@param y number
---@return boolean?
function SWEP:DoDrawCrosshair(x, y)
    local Owner = self:GetOwner()
    if not (IsValid(Owner) and Owner:IsPlayer()) then return false end ---@cast Owner Player
    self.Cursor = Owner:GetEyeTrace().HitPos:ToScreen()
    if not ss.GetOption "drawcrosshair" then return false end
    if self:GetThrowing() then return false end
    x, y = self.Cursor.x, self.Cursor.y

    return ss.ProtectedCall(self.CustomDrawCrosshair, self, x, y)
end

local PUNCH_DAMPING = 9.0
local PUNCH_SPRING_CONSTANT = 65.0
---Allows you to adjust player view while this weapon in use.
---@param ply Player
---@param pos Vector
---@param ang Angle
---@param fov number
---@return Vector
---@return Angle
---@return number
function SWEP:CalcView(ply, pos, ang, fov)
    local f = ss.ProtectedCall(self.CustomCalcView, self, ply, pos, ang, fov) ---@type number?
    if ply:ShouldDrawLocalPlayer() then return pos, ang, f or fov end
    if not isangle(self.ViewPunch) then return pos, ang, f or fov end
    if math.abs(self.ViewPunch.p + self.ViewPunch.y + self.ViewPunch.r) > 0.001
    or math.abs(self.ViewPunchVel.p + self.ViewPunchVel.y + self.ViewPunchVel.r) > 0.001 then
        self.ViewPunch:Add(self.ViewPunchVel * FrameTime())
        self.ViewPunchVel:Mul(math.max(0, 1 - PUNCH_DAMPING * FrameTime()))
        self.ViewPunchVel:Sub(self.ViewPunch * math.Clamp(
            PUNCH_SPRING_CONSTANT * FrameTime(), 0, 2))
        self.ViewPunch:Set(Angle(
            math.Clamp(self.ViewPunch.p, -89, 89),
            math.Clamp(self.ViewPunch.y, -179, 179),
            math.Clamp(self.ViewPunch.r, -89, 89)))
    else
        self.ViewPunch:Zero()
    end

    return pos, ang + self.ViewPunch, f or fov
end

---Returns transparency of the player in case the camera is too close
---@return number The transparency from 0 to 1
function SWEP:GetCameraFade()
    if not ss.GetOption "translucentnearbylocalplayer" then return 1 end
    return math.Clamp(self:GetPos():DistToSqr(EyePos()) / ss.CameraFadeDistance, 0, 1)
end

---Returns if the transformed model should be drawn
---@return boolean True # if the transformed model should be drawn
function SWEP:ShouldDrawTransformedModel()
    if not IsValid(self:GetOwner()) then return false end
    if not self:Crouching() then return false end
    if not self:GetNWBool "transformoncrouch" then return false end
    if not IsValid(self:GetNWEntity "TransformModel") then return false end
    return not self:GetInInk()
end
