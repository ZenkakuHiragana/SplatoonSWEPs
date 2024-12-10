
include "sh_anim.lua"

local ss = SplashSWEPs
if not ss then return end

---@class ss.WeaponRecord
---@field Recent   table<string, number>
---@field Duration table<string, number>?
---@field Inked    table<string, number>?

---@class Entity.Colorable : Entity
---@field GetInkColorProxy fun(self): Vector

---@class SWEP.ActivityTranslationTable
---@field [string] table<integer, integer>

---@class SWEP.Variation
---@field ClassName     string?
---@field Bodygroup     integer[]?
---@field Skin          integer?
---@field ShootSound    string?
---@field Sub           string?
---@field Special       string?
---@field Suffix        string?

---@class ISubWeapon
---@field CanSecondaryAttack        fun(self): boolean
---@field GetSubWeaponCost    fun(self): number
---@field GetSubWeaponInitVelocity (fun(self): Vector)?
---@field ServerSecondaryAttack     fun(self)?
---@field ClientSecondaryAttack     fun(self)?
---@field SharedSecondaryAttack     fun(self)?
---@field DrawOnSubTriggerDown      fun(self)?

---@class ISpecialWeapon
---@field ShouldFireOnEnd                boolean?
---@field SuppressPrimaryAttackSpecial   boolean?
---@field SuppressSecondaryAttackSpecial boolean?
---@field SuppressCrouchingSpecial           boolean?
---@field SwitchWeaponOnSpecial          boolean?
---@field SwitchSpecialWeaponTo          string?
---@field GetSpecialDuration             fun(self): number
---@field CanSpecialAttack               fun(self): boolean? Return true if it is suitable to start special at the moment
---@field OnSpecialStart                 fun(self)
---@field OnSpecialEnd                   fun(self, switchTo: Entity?)

---Overridable functions implemented in inherited classes
---@class IMainWeapon
---@field ClientDeploy          fun(self)
---@field ClientHolster         fun(self)
---@field ClientInit            fun(self)
---@field ClientOnRemove        fun(self)
---@field ClientPrimaryAttack   fun(self, able: boolean?, auto: boolean?)
---@field ClientThink           fun(self)
---@field CustomActivity        fun(self): string?
---@field CustomDataTables      fun(self)
---@field CustomDrawCrosshair   fun(self, x: number, y: number): boolean?
---@field CustomMoveSpeed       fun(self): number?
---@field InitNetworkSlots      fun(self)
---@field KeyPress              fun(self, ply: Player, key: integer)
---@field KeyRelease            fun(self, ply: Player, key: integer)
---@field Move                  fun(self, ply: Entity, mv: CMoveData)
---@field NPCBurstSettings      fun(self): number?, number?, number?
---@field NPCRestTimes          fun(self): number?, number?
---@field NPCShoot_Primary      fun(self, ShootPos: Vector, ShootDir: Vector)
---@field ServerDeploy          fun(self)
---@field ServerHolster         fun(self)
---@field ServerInit            fun(self)
---@field ServerOnRemove        fun(self)
---@field ServerPrimaryAttack   fun(self, able: boolean?, auto: boolean?)
---@field ServerSecondaryAttack fun(self, able: boolean?)
---@field ServerThink           fun(self)
---@field SharedDeploy          fun(self)
---@field SharedHolster         fun(self): boolean?
---@field SharedInit            fun(self)
---@field SharedOnRemove        fun(self)
---@field SharedPrimaryAttack   fun(self, able: boolean?, auto: boolean?)
---@field SharedSecondaryAttack fun(self, able: boolean?)
---@field SharedThink           fun(self)
---@field UpdateAnimation       fun(self, ply: Player, velocity: Vector, maxSeqGroundSpeed: number)

local SWEP = SWEP
---@cast SWEP SplashWeaponBase
---@class SplashWeaponBase : IMainWeapon, ISubWeapon, ISpecialWeapon, INetworkVar, INetworkSchedule, SWEP, ENT
---@field BaseClass SWEP
---@field ActivityTranslate        table<integer, integer>
---@field ActivityTranslateAI      SWEP.ActivityTranslationTable
---@field Bodygroup                integer[]
---@field BotInkColor              integer
---@field Buttons                  integer
---@field ExistingSprinkler        Entity?
---@field HealSchedule             EntityNetworkSchedule
---@field HoldType                 string
---@field IgnorePrediction         boolean
---@field PlayerSpeed             number
---@field IsBlaster                boolean?
---@field IsBrush                  boolean?
---@field IsCharger                boolean?
---@field IsRoller                 boolean?
---@field IsShooter                boolean?
---@field IsSpecial                boolean?
---@field IsSubWeaponThrowable     boolean
---@field JumpPower                number
---@field KeyPressedOrder          integer[]
---@field LoopSounds               {[string]: { SoundName: string, SoundPatch: CSoundPatch? }}
---@field ModelPath                string
---@field NextEnemyInkDamage       number
---@field OldButtons               integer
---@field OnEnemyInkSpeed          number
---@field OnOutofInk               boolean?
---@field Parameters               Parameters
---@field Projectile               Projectile
---@field Range                    number
---@field ReloadSchedule           EntityNetworkSchedule
---@field RestrictedFieldsToCopy   {[string]: boolean}
---@field SeekerPreviousTarget     Entity?
---@field SeekerTargetSearched     number?
---@field Skin                     integer
---@field Special                  string
---@field SpecialPointsNeeded      number Points needed for special weapon that can be overriden by per weapon definition
---@field CrouchedSpeed               number
---@field Sub                      string
---@field Translate                SWEP.ActivityTranslationTable
---@field Variations               SWEP.Variation[]
---@field ApplySkinAndBodygroups   fun(self)
---@field ChangeThrowing           fun(self, name: string, old: boolean, new: boolean)
---@field CheckCanStandup          fun(self): boolean
---@field ConsumeInk               fun(self, amount: number)
---@field Crouching                fun(self): boolean
---@field DisplayAmmo              fun(self): number
---@field EndRecording             fun(self)
---@field GetBase                  fun(self, BaseClassName: string?): SWEP|SplashWeaponBase
---@field GetFOV                   fun(self): number
---@field GetHandPos               fun(self): Vector
---@field GetInkColor              fun(self): Color
---@field GetPlayerSpeed          fun(self): number
---@field GetTurfInkedThisTime     fun(self): integer
---@field GetTurfInkedSoFar        fun(self): integer
---@field GetOptions               fun(self)
---@field GetSpecialPointProgress  fun(self): number
---@field GetCrouchedSpeed            fun(self): number
---@field GetSubWeaponInitVelocity fun(self): Vector
---@field GetViewModel             fun(self, index: number?): Entity
---@field IsFirstTimePredicted     fun(self): boolean
---@field IsMine                   fun(self): boolean
---@field Ping                     fun(self): number
---@field PlayLoopSound            fun(self)
---@field PrimaryAttackEntryPoint  fun(self, auto: boolean?)
---@field ResetSpecialState        fun(self)
---@field SetReloadDelay           fun(self, delay: number)
---@field SetWeaponAnim            fun(self, act: number, index: number?)
---@field SharedDeployBase         fun(self): boolean
---@field SharedHolsterBase        fun(self, switchTo: Entity): boolean
---@field SharedInitBase           fun(self)
---@field SharedThinkBase          fun(self)
---@field StartRecording           fun(self)
---@field StopLoopSound            fun(self)
---@field UpdateInkState           fun(self)

ss.AddTimerFramework(SWEP)
SWEP.SpecialPointsNeeded = -1
SWEP.RestrictedFieldsToCopy = {
    FunctionQueue  = true,
    NetworkSlot    = true,
    Projectile     = true,
    HealSchedule   = true,
    ReloadSchedule = true,
}
SWEP.LoopSounds = {
    -- SwimSound     = { SoundName = ss.SwimSound },
    -- EnemyInkSound = { SoundName = ss.EnemyInkSound },
}

---Starts playing registered loop sounds
function SWEP:PlayLoopSound()
    for _, s in pairs(self.LoopSounds) do
        if not s.SoundPatch then
            s.SoundPatch = CreateSound(self, s.SoundName)
        end

        s.SoundPatch:PlayEx(0, 100)
    end
end

---Stops playing registered loop sounds
function SWEP:StopLoopSound()
    for _, s in pairs(self.LoopSounds) do
        if not s.SoundPatch then
            s.SoundPatch = CreateSound(self, s.SoundName)
        end

        s.SoundPatch:Stop()
    end
end

---Starts recording statistics for this weapon
function SWEP:StartRecording()
    local Owner = self:GetOwner()
    if not Owner:IsPlayer() then return end
    local record = ss.WeaponRecord[Owner]
    if not record then return end
    if not record.Inked[self.ClassName] then
        record.Inked[self.ClassName] = 0
    end
    if not record.Duration[self.ClassName] then
        record.Duration[self.ClassName] = 0
    end

    self:SetNWEntity("Owner", Owner)
    record.Recent[self.ClassName] = -os.time()
    if self:GetNWInt "TurfInkedAtStart" >= 0 then
        self:SetNWInt("TurfInkedAtStart", record.Inked[self.ClassName])
        self:SetNWInt("SpecialBasePoints", record.Inked[self.ClassName])
    end
end

---Stops recording statistics for this weapon
function SWEP:EndRecording()
    local Owner = IsValid(self:GetOwner()) and self:GetOwner() or self:GetNWEntity "Owner"
    if not Owner:IsPlayer() then return end
    local record = ss.WeaponRecord[Owner]
    if not record then return end
    local classname = self.ClassName
    local time = os.time()
    record.Duration[classname] = record.Duration[classname] or 0
    record.Recent[classname]   = record.Recent[classname  ] or -os.time()
    record.Duration[classname] = record.Duration[classname] - (time + record.Recent[classname])
end

---Basically shared version of IsCarriedByLocalPlayer
---@return boolean result True if this is carried by local player
function SWEP:IsMine()
    return SERVER or self:IsCarriedByLocalPlayer()
end

---Shared version of IsFirstTimePredicted, also considers singleplayer
---@return boolean result True if this tick is first time predicted
function SWEP:IsFirstTimePredicted()
    return SERVER or ss.sp or IsFirstTimePredicted() or not self:IsCarriedByLocalPlayer()
end

---Get base entity with given class name recursively
---@param BaseClassName string? The class name to find
---@return SWEP|SplashWeaponBase # The associated base class table
function SWEP:GetBase(BaseClassName)
    BaseClassName = BaseClassName or "weapon_splashsweps_base"
    local base = self.BaseClass --[[@as SWEP|SplashWeaponBase]]
    while base and base.Base ~= BaseClassName do
        base = base.BaseClass
    end

    return base
end

---Speed on humanoid form = base speed * ability factor
---@return number speed The walking speed in Hammer Units per second
function SWEP:GetPlayerSpeed()
    return ss.PlayerBaseSpeed
end

---Speed on transformed form = base speed * ability factor
---@return number speed The swimming speed in Hammer Units per second
function SWEP:GetCrouchedSpeed()
    return ss.CrouchedBaseSpeed
end

---Returns the points of turf inked with this instance
---@return integer
function SWEP:GetTurfInkedThisTime()
    local record = ss.WeaponRecord[self:GetOwner()]
    if not record then return 0 end
    local raw = record.Inked[self.ClassName]
    if not raw then return 0 end
    raw = math.min(raw - self:GetNWInt "TurfInkedAtStart", 0)
    return math.Round(ss.GetTurfInkedInPoints(raw))
end

---Returns the points of turf this owner has inked so far
---@return integer
function SWEP:GetTurfInkedSoFar()
    local record = ss.WeaponRecord[self:GetOwner()]
    if not record then return 0 end
    local raw = record.Inked[self.ClassName]
    if not raw then return 0 end
    return math.Round(ss.GetTurfInkedInPoints(raw))
end

---Returns progress of special points = points earned / points needed
---@return number
function SWEP:GetSpecialPointProgress()
    local record = ss.WeaponRecord[self:GetOwner()]
    if not record then return 0 end
    local raw = record.Inked[self.ClassName]
    if not raw then return 0 end
    raw = math.min(raw - self:GetNWInt "SpecialBasePoints", 0)
    return math.Clamp(math.Round(ss.GetTurfInkedInPoints(raw)) / self.SpecialPointsNeeded, 0, 1)
end

function SWEP:ResetSpecialState()
    local record = ss.WeaponRecord[self:GetOwner()]
    if not record then return end
    local raw = record.Inked[self.ClassName]
    self:SetNWInt("SpecialBasePoints", raw)
    self:SetSpecialActivated(false)
end

---Get actual color of current ink
---@return Color color 
function SWEP:GetInkColor()
    return ss.GetColor(self:GetNWInt "inkcolor")
end

---Returns the owner ping in seconds, 0 if the owner is invalid or an NPC.
---@return number seconds Ping in seconds
function SWEP:Ping()
    local Owner = self:GetOwner()
    if not IsValid(Owner) then return 0 end
    if not Owner:IsPlayer() then return 0 end
    ---@cast Owner Player
    return Owner:Ping() / 1000
end

---Returns if the owner is crouching
---@return boolean result True if the owner is crouching
function SWEP:Crouching()
    local Owner = self:GetOwner()
    if not IsValid(Owner) then return false end
    if Owner:IsPlayer() then
        ---@cast Owner Player
        return ss.ProtectedCall(Owner.Crouching, self:GetOwner())
    else
        return Owner:IsFlagSet(FL_DUCKING)
    end
end

---Get current FOV
---@return number fov FOV in degrees
function SWEP:GetFOV()
    local Owner = self:GetOwner()
    if not IsValid(Owner) then return 0 end
    if not Owner:IsPlayer() then return 90 end
    ---@cast Owner Player
    return Owner:GetFOV()
end

---Retrieves various options for the weapon owner and stores them to NW var
---@param self SplashWeaponBase The weapon entity
---@param name string             Name of the preference
---@param pt   cvartree.CVarItem  Definition of the preference
local function RetrieveOption(self, name, pt)
    if pt.options and (pt.options.serverside or pt.options.clientside) then return end
    if #pt.location > 1 then
        if pt.location[2] ~= self.Base then return end
        if #pt.location > 2 and pt.location[3] ~= self.ClassName then return end
    end

    local Owner = self:GetOwner()
    local cvartree = require "greatzenkakuman/cvartree" or greatzenkakuman.cvartree
    local value = cvartree.GetValue(pt, Owner)
    if isbool(value) and self:GetNWBool(name) ~= value then ---@cast value boolean
        self:SetNWBool(name, value)
    end

    if isnumber(value) and self:GetNWInt(name) ~= value then ---@cast value number
        if name == "inkcolor" then
            if Owner:IsNPC() then return end
            if Owner:IsPlayer() then ---@cast Owner Player
                if Owner:IsBot() then return end
                if ss.sp then -- NWVarProxy won't be called serverside in singleplayer
                    ss.SetPlayerFilter(Owner, self:GetNWInt(name, -1), false)
                    ss.SetPlayerFilter(Owner, value, true)
                end
            end
        end

        self:SetNWInt(name, value)
    end
end

---Retrieves all preferences for the weapon
function SWEP:GetOptions()
    if ss.mp and CLIENT and not IsFirstTimePredicted() then return end
    if not self:IsMine() then return end
    local cvartree = require "greatzenkakuman/cvartree" or greatzenkakuman.cvartree
    for name, pt in cvartree.IteratePreferences "splashsweps" do
        RetrieveOption(self, name, pt)
    end

    local inkcolor ---@type integer
    local Owner = self:GetOwner()
    if Owner:IsPlayer() then ---@cast Owner Player
        if not Owner:IsBot() then return end
        inkcolor = ss.GetBotInkColor(self)
    else
        inkcolor = ss.GetNPCInkColor(Owner)
    end

    if self:GetNWInt "inkcolor" == inkcolor then return end
    self:SetNWInt("inkcolor", inkcolor)
end

---Applies skin and bodygroups for this weapon
function SWEP:ApplySkinAndBodygroups()
    self:SetSkin(self.Skin or 0)
    for k, v in pairs(self.Bodygroup or {}) do
        self:SetBodygroup(k, v)
    end

    local Owner = self:GetOwner()
    if not IsValid(Owner) or not Owner:IsPlayer() then return end
    for i = 0, 2 do ---@cast Owner Player
        local vm = Owner:GetViewModel(i)
        if IsValid(vm) then
            vm:SetSkin(self.Skin or 0)
            for k, v in pairs(self.Bodygroup or {}) do
                vm:SetBodygroup(k, v)
            end
        end
    end
end

local InkTraceLength = 30
local InkTraceDepth = 20
---Set if player is in ink
function SWEP:UpdateInkState()
    local Owner = self:GetOwner()
    if not IsValid(Owner) then return end
    local ang = Angle(0, Owner:GetAngles().yaw)
    local c = self:GetNWInt "inkcolor"
    local org = Owner:GetPos()
    local fw, right = ang:Forward() * InkTraceLength, ang:Right() * InkTraceLength
    local gtrace = util.QuickTrace(org, -vector_up * InkTraceDepth, Owner)
    local gcolor = gtrace.Hit and ss.GetSurfaceColor(gtrace.HitPos, gtrace.HitNormal) or -1
    local onink = gcolor >= 0
    local onourink = gcolor == c
    local onenemyink = onink and not onourink

    local center = Owner:WorldSpaceCenter()
    local normal, onwallink = Vector(), false
    for _, p in ipairs { fw + right, fw - right, -fw + right, -fw - right } do
        local tr = util.QuickTrace(center, p, Owner)
        if not tr.Hit or tr.HitNormal.z > ss.MAX_COS_DIFF then continue end
        if ss.GetSurfaceColor(tr.HitPos, tr.HitNormal) == c then
            normal = tr.HitNormal
            onwallink = true
            break
        end
    end

    local inwallink = self:Crouching() and onwallink
    local inink = self:Crouching() and (onink and onourink or self:GetInWallInk())
    -- if onenemyink and not self:GetOnEnemyInk() then
    --     self.LoopSounds.EnemyInkSound.SoundPatch:ChangeVolume(1, .5)
    -- end
    -- if not onenemyink and self:GetOnEnemyInk() then
    --     self.LoopSounds.EnemyInkSound.SoundPatch:ChangeVolume(0, .5)
    -- end

    if Owner:IsPlayer() then
        ---@cast Owner Player
        if inink and not self:GetInInk() then Owner:SetDSP(14, false) end
        if not inink and self:GetInInk() then Owner:SetDSP(1, false) end
        if not (self:GetOnEnemyInk() and Owner:KeyDown(IN_DUCK)) then
            self:SetEnemyInkTouchTime(CurTime())
        end
    end

    self:SetGroundColor(gcolor)
    self:SetInWallInk(inwallink)
    self:SetInInk(inink)
    self:SetOnEnemyInk(onenemyink)
    self:SetWallNormal(normal)

    self:GetOptions()
    if not self:GetInkColor() then return end
    self:SetInkColorProxy(self:GetInkColor():ToVector())
end

---Returns the position of the right hand of the owner
---@return Vector pos The hand position
function SWEP:GetHandPos()
    local Owner = self:GetOwner()
    if not (IsValid(Owner) and Owner:IsPlayer()) then return self:GetShootPos() end

    ---@cast Owner Player
    local e = (SERVER or self:IsTPS()) and Owner or self:GetViewModel()
    local boneid = e:LookupBone "ValveBiped.Bip01_R_Hand"
    or e:LookupBone "ValveBiped.Weapon_bone" or 0
    return e:GetBoneMatrix(boneid):GetTranslation()
end

---Returns the index-th view model entity
---@param index integer? The index that should range from 0 to 3
---@return Entity # The view model entity if available
function SWEP:GetViewModel(index)
    local Owner = self:GetOwner() --[[@as Player]]
    if not (IsValid(Owner) and Owner:IsPlayer()) then return NULL end
    return Owner:GetViewModel(index)
end

---Set sequence for the weapon
---@param act   integer  ACT_ enum
---@param index integer? View model index that should range from 0 to 3
function SWEP:SetWeaponAnim(act, index)
    if not index then self:SendWeaponAnim(act) end
    if index == 0 then self:SendWeaponAnim(act) return end
    if not self:IsFirstTimePredicted() then return end
    local Owner = self:GetOwner() --[[@as Player]]
    if not (IsValid(Owner) and Owner:IsPlayer()) then return end
    for i = 1, 2 do
        if not (index and i ~= index) then
            -- Entity:GetSequenceCount() returns nil on an invalid viewmodel
            local vm = Owner:GetViewModel(i)
            if IsValid(vm) and (vm:GetSequenceCount() or 0) > 0 then
                local seq = vm:SelectWeightedSequence(act)
                if seq > -1 then
                    vm:SendViewModelMatchingSequence(seq)
                    vm:SetPlaybackRate(1)
                end
            end
        end
    end
end

---Consumes given ink
---@param amount number the amount of ink to consume
function SWEP:ConsumeInk(amount)
    if not isnumber(amount) then return end
    self:SetInk(math.max(self:GetInk() - amount, 0))
end

---Base function of Initialize hook for both realms
function SWEP:SharedInitBase()
    self:SetCooldown(CurTime())
    self:ApplySkinAndBodygroups()
    self:SetSpecialActivated(false)
    self:SetRenderMode(RENDERMODE_TRANSCOLOR)
    self:SetNWInt("TurfInkedAtStart", 0)
    self:SetNWInt("SpecialBasePoints", 0)
    self.KeyPressedOrder = {} -- Pressed keys are added here, most recent key will go last

    local translate = {} ---@type SWEP.ActivityTranslationTable
    for _, t in ipairs {
        "ar2",
        "crossbow",
        "duel",
        "grenade",
        "melee",
        "melee2",
        "passive",
        "physgun",
        "revolver",
        "rpg",
        "shotgun",
        "smg",
    } do ---@cast t string
        self:SetWeaponHoldType(t)
        translate[t] = self.ActivityTranslate
    end

    self:SetNWVarProxy("inkcolor", function(ent, name, old, new)
        if not IsValid(ent) then return end
        if old == new then return end
        local Owner = ent:GetOwner()
        if not IsValid(Owner) then return end
        ss.SetPlayerFilter(Owner, old, false)
        ss.SetPlayerFilter(Owner, new, true)
    end)

    if ss.sp then self.Buttons, self.OldButtons = 0, 0 end
    if ss[self.Sub] then table.Merge(self, ss[self.Sub].Merge) end
    if ss[self.Special] then
        table.Merge(self, ss[self.Special].Merge)
        if self.SpecialPointsNeeded < 0 then
            self.SpecialPointsNeeded = ss[self.Special].PointsNeeded
        end
    end

    self.Translate = translate
    self.Projectile = ss.MakeProjectileStructure()
    self.Projectile.Weapon = self
    ss.ProtectedCall(self.SharedInit, self)
end

-- Predicted hooks

---Base function of Deploy hook for both realms
---@return boolean allowSwitch True to allow switching away from this weapon using lastinv command
function SWEP:SharedDeployBase()
    local Owner = self:GetOwner()
    self:PlayLoopSound()
    self:SetHolstering(false)
    self:SetThrowing(false)
    self:StartRecording()
    self:SetKey(0)
    self:MakeTransformedModel()
    self.KeyPressedOrder = {}
    self.PlayerSpeed = self:GetPlayerSpeed()
    self.CrouchedSpeed = self:GetCrouchedSpeed()
    self.OnEnemyInkSpeed = ss.OnEnemyInkSpeed
    self.JumpPower = ss.PlayerJumpPower
    self.IgnorePrediction = SERVER and ss.mp and not Owner:IsPlayer()
    Owner:SetHealth(Owner:Health() * self:GetNWInt "BackupPlayerMaxHealth" / self:GetNWInt "BackupHumanMaxHealth")
    if Owner:IsPlayer() then
        ---@cast Owner Player
        Owner:SetJumpPower(self.JumpPower)
        Owner:SetCrouchedWalkSpeed(.5)
        for _, k in ipairs(ss.KeyMask) do
            if Owner:KeyDown(k) then
                ss.KeyPress(self, Owner, k)
            end
        end
    end

    ss.ProtectedCall(self.SharedDeploy, self)
    ss.SetPlayerFilter(Owner, self:GetNWInt("inkcolor", -1), true)
    return true
end

---Base function of Holster hook for both realms
---@param switchTo Entity
---@return boolean allowHolster True to allow weapon to holster
function SWEP:SharedHolsterBase(switchTo)
    if ss.ProtectedCall(self.SharedHolster, self, switchTo) == false then return false end
    self:SetHolstering(true)
    ss.SetPlayerFilter(self:GetOwner(), self:GetNWInt("inkcolor", -1), false)
    if self:GetSpecialActivated() then self:OnSpecialEnd(switchTo) end
    self:StopLoopSound()
    self:EndRecording()
    return true
end

---Returns amount for displaying ammo HUD
---@return number? ammo The amount for displaying
function SWEP:DisplayAmmo() return nil end

---Base function of Think hook for both realms
function SWEP:SharedThinkBase()
    local vm = self:GetViewModel()
    if IsValid(vm) and vm:IsSequenceFinished()
    and vm:GetSequenceActivity(vm:GetSequence()) == ACT_VM_DRAW then
        self:SetWeaponAnim(ACT_VM_IDLE)
    end

    local Owner = self:GetOwner()
    local ShouldNoDraw = Either(self:GetNWBool "transformoncrouch", self:Crouching(), self:GetInInk())
    if not self.IsSpecial and IsValid(Owner) then
        Owner:DrawShadow(not ShouldNoDraw)
        if Owner:IsPlayer() then ---@cast Owner Player
            self:SetClip1(math.Round(self:GetInk()))
            Owner:SetAmmo(self:GetTurfInkedThisTime(), self:GetPrimaryAmmoType())
        end
    end

    self:DrawShadow(not (ShouldNoDraw or CLIENT and ss.ProtectedCall(self.PreDrawWorldModel, self)))
    self:ApplySkinAndBodygroups()
    ss.ProtectedCall(self.SharedThink, self)
end

---Reload hook begins special weapon
function SWEP:Reload()
    if self:GetHolstering() then return end
    if not ss[self.Special] then return end -- Remove after all specials are implemented
    if self:GetSpecialPointProgress() < 1 then return end
    if self:GetSpecialActivated() then return end
    if ss.ProtectedCall(self.CanSpecialAttack, self) == false then return end
    local voice = ss.GetVoiceName("SpecialStart", self)
    if voice and self:IsFirstTimePredicted() then
        ss.EmitSoundPredicted(self:GetOwner(), self, voice)
    end
    self:SetInk(ss.GetMaxInkAmount())
    self:SetSpecialStartTime(CurTime())
    self:SetSpecialActivated(true)
    ss.ProtectedCall(self.OnSpecialStart, self)
end

---Returns if the owner can stand up at current position
---@return boolean result True if the owner can stand up
function SWEP:CheckCanStandup()
    local Owner = self:GetOwner()
    if self:GetInFence() then return false end
    if not IsValid(Owner) then return true end
    if not Owner:IsPlayer() then return true end ---@cast Owner Player
    if Owner:Crouching() then return ss.CanUnduck(Owner) end
    return true
end

---Sets cooldown time of reloading ink
---@param delay number The cooldown time in seconds
function SWEP:SetReloadDelay(delay)
    local reloadtime = delay / ss.GetTimeScale(self:GetOwner())
    if self.ReloadSchedule:SinceLastCalled() < -reloadtime then return end
    self.ReloadSchedule:SetDelay(reloadtime) -- Stop reloading ink
    self.ReloadSchedule:SetLastCalled(-reloadtime)
end

---The Primary Attack hook for both realms
---@param auto boolean? True if this is called from a timer instead of predicted hook
function SWEP:PrimaryAttackEntryPoint(auto)
    if self:GetHolstering() then return end
    if self:GetSpecialActivated() and self.SuppressPrimaryAttackSpecial then return end

    local Owner = self:GetOwner()
    if self:GetThrowing() then return end
    if CurTime() < self:GetNextPrimaryFire() then return end
    if not self:CheckCanStandup() then return end
    if auto and ss.sp and CLIENT then return end
    if not auto and Owner:IsPlayer() and self:GetKey() ~= IN_ATTACK then return end
    local able = self:GetInk() > 0 and self:CheckCanStandup()
    ss.SuppressHostEventsMP(Owner)
    ss.ProtectedCall(self.SharedPrimaryAttack, self, able, auto)
    ss.ProtectedCall(Either(SERVER, self.ServerPrimaryAttack, self.ClientPrimaryAttack), self, able, auto)
    ss.EndSuppressHostEventsMP(Owner)
end

function SWEP:PrimaryAttack()
    self:PrimaryAttackEntryPoint()
end

function SWEP:SecondaryAttack()
    if not (self.Sub and ss[self.Sub]) then return end
    if self:GetHolstering() then return end
    if self:GetSpecialActivated() and self.SuppressSecondaryAttackSpecial then return end
    if self:GetKey() ~= IN_ATTACK2 then self:SetThrowing(false) return end
    if self:GetThrowing() then return end
    if CurTime() < self:GetCooldown() then return end
    if not self:CheckCanStandup() then return end
    local Owner = self:GetOwner()
    if IsValid(Owner) and Owner:IsPlayer() then
        ---@cast Owner Player
        self:SetThrowing(true)
        self:SetWeaponAnim(ss.ViewModel.Throwing)

        if self.IsSubWeaponThrowable then
            local filter = self.IgnorePrediction ---@type boolean|CRecipientFilter
            if SERVER and ss.mp then
                filter = RecipientFilter()
                filter:AddPlayer(Owner)
            end

            local e = EffectData()
            e:SetEntity(self)
            e:SetScale(1.5)
            ss.UtilEffectPredicted(Owner, "SplashSWEPsLandingPoint", e, true, filter)
        end

        if not self:IsFirstTimePredicted() then return end
        if self.HoldType ~= "grenade" then
            Owner:AnimResetGestureSlot(GESTURE_SLOT_ATTACK_AND_RELOAD)
        end
    else
        local able = self:GetInk() > 0 and self:CheckCanStandup() and self:CanSecondaryAttack()
        ss.ProtectedCall(self.SharedSecondaryAttack, self, able)
        ss.ProtectedCall(self.ServerSecondaryAttack, self, able)
    end
end
-- End of predicted hooks

---Set up by NetworkVarNotify.  Called when SetThrowing() is executed.
---@param name string Name of the variable
---@param old boolean The old value
---@param new boolean The new value
function SWEP:ChangeThrowing(name, old, new)
    if old == new then return end
    if self:GetHolstering() then return end
    local start, stop = not old and new, old and not new

    -- Changes the world model on serverside and local player
    self.WorldModel = self.ModelPath .. (start and "w_left.mdl" or "w_right.mdl")
    if stop then self:SetWeaponAnim(ss.ViewModel.Standing) end
    if CLIENT then return end
    if #ss.PlayersReady == 0 then return end
    net.Start "SplashSWEPs: Change throwing"
    net.WriteEntity(self)
    net.WriteBool(start)
    net.Send(ss.PlayersReady) -- Properly changes it on other clients
end

---Called when the weapon entity is reloaded from a Source Engine
function SWEP:OnRestore()
    self:PlayLoopSound()
    self.NextEnemyInkDamage = CurTime()
    if ss[self.Sub] then table.Merge(self, ss[self.Sub].Merge) end
    if ss[self.Special] then
        table.Merge(self, ss[self.Special].Merge)
        if self.SpecialPointsNeeded < 0 then
            self.SpecialPointsNeeded = ss[self.Special].PointsNeeded
        end
    end
end

---Called when the SWEP should set up its Data Tables.
function SWEP:SetupDataTables()
    ---@class SplashWeaponBase
    ---@field GetInInk              fun(self): boolean
    ---@field GetInFence            fun(self): boolean
    ---@field GetInWallInk          fun(self): boolean
    ---@field GetOldCrouching       fun(self): boolean
    ---@field GetOnEnemyInk         fun(self): boolean
    ---@field GetHolstering         fun(self): boolean
    ---@field GetSpecialActivated   fun(self): boolean
    ---@field GetThrowing           fun(self): boolean
    ---@field GetNPCTarget          fun(self): Entity
    ---@field GetCooldown           fun(self): number
    ---@field GetEnemyInkTouchTime  fun(self): number
    ---@field GetInk                fun(self): number
    ---@field GetOldSpeed           fun(self): number
    ---@field GetSpecialStartTime   fun(self): number
    ---@field GetThrowAnimTime      fun(self): number
    ---@field GetGroundColor        fun(self): integer
    ---@field GetKey                fun(self): integer
    ---@field GetInkColorProxy      fun(self): Vector
    ---@field GetAimVector          fun(self): Vector
    ---@field GetShootPos           fun(self): Vector
    ---@field GetWallNormal         fun(self): Vector
    ---@field SetInInk              fun(self, value: boolean)
    ---@field SetInFence            fun(self, value: boolean)
    ---@field SetInWallInk          fun(self, value: boolean)
    ---@field SetOldCrouching       fun(self, value: boolean)
    ---@field SetOnEnemyInk         fun(self, value: boolean)
    ---@field SetHolstering         fun(self, value: boolean)
    ---@field SetSpecialActivated   fun(self, value: boolean)
    ---@field SetThrowing           fun(self, value: boolean)
    ---@field SetNPCTarget          fun(self, value: Entity)
    ---@field SetCooldown           fun(self, value: number)
    ---@field SetEnemyInkTouchTime  fun(self, value: number)
    ---@field SetInk                fun(self, value: number)
    ---@field SetOldSpeed           fun(self, value: number)
    ---@field SetSpecialStartTime   fun(self, value: number)
    ---@field SetThrowAnimTime      fun(self, value: number)
    ---@field SetGroundColor        fun(self, value: integer)
    ---@field SetKey                fun(self, value: integer)
    ---@field SetInkColorProxy      fun(self, value: Vector)
    ---@field SetAimVector          fun(self, value: Vector)
    ---@field SetShootPos           fun(self, value: Vector)
    ---@field SetWallNormal         fun(self, value: Vector)

    local gain = ss.GetOption "gain"
    self:InitNetworkSlots()
    self:AddNetworkVar("Bool",   "InInk")             -- If owner is in ink.
    self:AddNetworkVar("Bool",   "InFence")           -- If owner is in fence.
    self:AddNetworkVar("Bool",   "InWallInk")         -- If owner is on wall.
    self:AddNetworkVar("Bool",   "OldCrouching")      -- If owner was crouching a tick ago.
    self:AddNetworkVar("Bool",   "OnEnemyInk")        -- If owner is on enemy ink.
    self:AddNetworkVar("Bool",   "Holstering")        -- The weapon is being holstered.
    self:AddNetworkVar("Bool",   "SpecialActivated")  -- The weapon is using its special weapon.
    self:AddNetworkVar("Bool",   "Throwing")          -- Is about to use sub weapon.
    self:AddNetworkVar("Entity", "NPCTarget")         -- Target entity for NPC.
    self:AddNetworkVar("Float",  "Cooldown")          -- Cannot crouch, fire, or use sub weapon.
    self:AddNetworkVar("Float",  "EnemyInkTouchTime") -- Delay timer to force to stand up.
    self:AddNetworkVar("Float",  "Ink")               -- Ink remainig. 0 to ss.GetMaxInkAmount()
    self:AddNetworkVar("Float",  "OldSpeed")          -- Old Z-velocity of the player.
    self:AddNetworkVar("Float",  "SpecialStartTime")
    self:AddNetworkVar("Float",  "ThrowAnimTime")     -- Time to adjust throw anim. speed.
    self:AddNetworkVar("Int",    "GroundColor")       -- Surface ink color.
    self:AddNetworkVar("Int",    "Key")               -- A valid key input.
    self:AddNetworkVar("Vector", "InkColorProxy")     -- For material proxy.
    self:AddNetworkVar("Vector", "AimVector")         -- NPC:GetAimVector() doesn't exist in clientside.
    self:AddNetworkVar("Vector", "ShootPos")          -- NPC:GetShootPos() doesn't, either.
    self:AddNetworkVar("Vector", "WallNormal")        -- The normal vector of a wall when climbing.
    local getaimvector = self.GetAimVector
    local getshootpos = self.GetShootPos

    ---Get aim direction vector
    ---@return Vector dir The aim vector
    function self:GetAimVector()
        local Owner = self:GetOwner()
        if not IsValid(Owner) then return self:GetForward() end
        if Owner:IsPlayer() then ---@cast Owner Player
            return Owner:GetAimVector()
        end
        return getaimvector(self)
    end

    ---Get muzzle position
    ---@return Vector pos The muzzle position
    function self:GetShootPos()
        local Owner = self:GetOwner()
        if not IsValid(Owner) then return self:GetPos() end
        if Owner:IsPlayer() then ---@cast Owner Player
            return Owner:GetShootPos()
        end
        return getshootpos(self)
    end

    self.HealSchedule = self:AddNetworkSchedule(0, function(_, schedule)
        local healink = self:GetNWBool "canhealink" and self:GetInInk() -- Gradually heals the owner
        local timescale = ss.GetTimeScale(self:GetOwner())
        local delay = 10 / timescale
        if healink then
            delay = delay / 8 / gain "healspeedink"
        else
            delay = delay / gain "healspeedstand"
        end

        if schedule:GetDelay() ~= delay then schedule:SetDelay(delay) end
        if not self:GetOnEnemyInk() and (self:GetNWBool "canhealstand" or healink) then
            local health = math.Clamp(self:GetOwner():Health() + 1, 0, self:GetOwner():GetMaxHealth())
            if self:GetOwner():Health() ~= health then self:GetOwner():SetHealth(health) end
        end
    end)

    self.ReloadSchedule = self:AddNetworkSchedule(0, function(_, schedule)
        local reloadamount = math.max(0, schedule:SinceLastCalled()) -- Recharging ink
        local reloadink = self:GetNWBool "canreloadink" and self:GetInInk()
        local timescale = ss.GetTimeScale(self:GetOwner())
        local mul = ss.GetMaxInkAmount() * timescale
        if reloadink then
            mul = mul / 3 * gain "reloadspeedink" / 100
        else
            mul = mul / 10 * gain "reloadspeedstand" / 100
        end

        if self:GetNWBool "canreloadstand" or reloadink then
            local ink = math.Clamp(self:GetInk() + reloadamount * mul, 0, ss.GetMaxInkAmount())
            if self:GetInk() ~= ink then self:SetInk(ink) end
        end

        if schedule:GetDelay() == 0 then return end
        schedule:SetDelay(0)
    end)

    ss.ProtectedCall(self.CustomDataTables, self)
    self:NetworkVarNotify("Throwing", self.ChangeThrowing)
    if pac then
        self:NetworkVarNotify("InInk", function(_, name, old, new)
            if tobool(old) == tobool(new) then return end
            pac.TogglePartDrawing(self:GetOwner(),
            not (new or self:GetOldCrouching() and self:GetNWBool "transformoncrouch"))
        end)
        self:NetworkVarNotify("OldCrouching", function(_, name, old, new)
            if tobool(old) == tobool(new) then return end
            if new and not self:GetNWBool "transformoncrouch" then return end
            pac.TogglePartDrawing(self:GetOwner(), not tobool(new))
        end)
    end
end
