
local ss = SplashSWEPs
if not ss then return end
AddCSLuaFile "shared.lua"
AddCSLuaFile "baseinfo.lua"
AddCSLuaFile "ai_translations.lua"
AddCSLuaFile "cl_draw.lua"
include "shared.lua"
include "baseinfo.lua"
include "ai_translations.lua"

---@class SWEP.BackupPlayerInfo
---@field Color            Color
---@field Flags            integer
---@field HullMaxs         Vector
---@field HullMins         Vector
---@field JumpPower        number
---@field Material         string
---@field Playermodel      SWEP.PlayerModelDefinition
---@field RenderMode       integer
---@field Speed            SWEP.BackupPlayerSpeed
---@field SubMaterial      string[]
---@field ViewOffsetDucked Vector

---@class SWEP.BackupPlayerSpeed
---@field Crouched number
---@field Duck     number
---@field Max      number
---@field Run      number
---@field UnDuck   number
---@field Walk     number

---@class SWEP.PlayerModelDefinition
---@field BodyGroups  BodyGroupData[]?
---@field Model       string
---@field PlayerColor Vector
---@field Skin        integer

local SWEP = SWEP
---@cast SWEP SplashWeaponBase
---@class SplashWeaponBase
---@field BackupHumanMaxHealth   integer
---@field BackupPlayerMaxHealth integer
---@field BackupPlayerInfo       SWEP.BackupPlayerInfo
---@field NPCDelay               number
---@field PMTable                SWEP.PlayerModelDefinition|nil
---@field Ragdoll                Entity
---@field SafeOwner              Entity
---@field BackupInfo             fun(self)
---@field ChangePlayermodel      fun(self, data: SWEP.PlayerModelDefinition)
---@field CreateRagdoll          fun(self)
---@field GetNPCBurstSettings    fun(self): number, number, number
---@field GetNPCRestTimes        fun(self): number, number
---@field RemoveRagdoll          fun(self)
---@field RestoreInfo            fun(self)

---Returns if the owner is invalid; it's a real player and is not ready to paint
---@param Owner Entity
---@return boolean result True if the owner is invalid
local function InvalidPlayer(Owner)
    if not IsValid(Owner) then return true end
    if not Owner:IsPlayer() then return false end
    ---@cast Owner Player
    return not Owner:IsBot() and not table.HasValue(ss.PlayersReady, Owner)
end

---Changes player model using given table
---@param data SWEP.PlayerModelDefinition
function SWEP:ChangePlayermodel(data)
    local Owner = self:GetOwner()
    if not Owner:IsPlayer() then return end
    ---@cast Owner Player
    Owner:SetModel(data.Model)
    Owner:SetSkin(data.Skin)
    local numgroups = Owner:GetNumBodyGroups()
    if isnumber(numgroups) then
        for k = 0, numgroups - 1 do
            local v = data.BodyGroups[k + 1]
            local n = istable(v) and isnumber(v.num) and v.num or 0
            Owner:SetBodygroup(k, n)
        end
    end

    ss.SetSubMaterial_Workaround(Owner)
    Owner:SetPlayerColor(data.PlayerColor)
    if self:GetNWInt "playermodel" <= ss.PLAYER.BOY then
        ss.ProtectedCall(Owner.SplatColors, Owner)
    end

    local hands = Owner:GetHands()
    if not IsValid(hands) then return end
    local mdl = player_manager.TranslateToPlayerModelName(data.Model)
    ---@type { model: string?, skin: number?, body: string? }
    local info = player_manager.TranslatePlayerHands(mdl)
    if not info then return end
    hands:SetModel(info.model)
    hands:SetSkin(info.skin)
    hands:SetBodyGroups(info.body)
end

local UseRagdoll = {
}
---Creates a ragdoll for the weapon physics when no owner is there.
function SWEP:CreateRagdoll()
    if not UseRagdoll[self.Base] then return end
    local ragdoll = self.Ragdoll
    if IsValid(ragdoll) then ragdoll:Remove() end
    ragdoll = ents.Create "prop_ragdoll" --[[@as ENT]]
    ragdoll:SetModel(self.WorldModel)
    ragdoll:SetPos(self:GetPos())
    ragdoll:SetAngles(self:GetAngles())
    ragdoll:SetMaterial(ss.Materials.Effects.Invisible:GetName())
    ragdoll:DeleteOnRemove(self)
    ragdoll:Spawn()
    ragdoll:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    function ragdoll.OnEntityCopyTableFinish(_, data)
        table.Empty(data)
        table.Merge(data, duplicator.CopyEntTable(self))
    end
    for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
        local ph = ragdoll:GetPhysicsObjectNum(i)
        if IsValid(ph) then
            ph:Wake()
            ph:ApplyForceCenter(ph:GetMass() * self:GetVelocity())
        end
    end

    self:DrawShadow(false)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetParent(ragdoll)
    self:AddEffects(EF_BONEMERGE)
    self:DeleteOnRemove(ragdoll)
    self.Ragdoll = ragdoll
    local n = "SplashSWEPs: RagdollCollisionCheck" .. self:EntIndex()
    timer.Create(n, 0.5, 0, function()
        timer.Adjust(n, 0)
        if not (IsValid(self) and IsValid(ragdoll)) then timer.Remove(n) return end
        local nearest, ply = self:BoundingRadius() ^ 2, NULL
        for _, p in ipairs(ss.PlayersReady) do
            local d = p:GetPos():DistToSqr(ragdoll:GetPos())
            if d < nearest then nearest, ply = d, p end
        end
        if not IsValid(ply) then return end
        self:RemoveRagdoll()
        timer.Remove(n)
    end)
end

---Removes ragdoll for weapons with multiple PhysObj
function SWEP:RemoveRagdoll()
    if not UseRagdoll[self.Base] then return end
    local n = "SplashSWEPs: RagdollCollisionCheck" .. self:EntIndex()
    timer.Remove(n)

    local ragdoll = self.Ragdoll
    self.Ragdoll = nil
    if not IsValid(ragdoll) then return end
    self:DrawShadow(true)
    self:DontDeleteOnRemove(ragdoll)
    ragdoll:DontDeleteOnRemove(self)
    ragdoll:Remove()
end

---Returns fire rates for NPCs
---@return number min   Minimum rest time between burst-shots
---@return number max   Maximum rest time between burst-shots
---@return number delay Interval between shots
function SWEP:GetNPCBurstSettings()
    ---@type number?, number?, number?
    local min, max, delay = ss.ProtectedCall(self.NPCBurstSettings, self)
    return min or 3, max or 8, delay or self.NPCDelay
end

---Returns rest times between burst shots for NPCs
---@return number min Minimum rest time
---@return number max Maximum rest time
function SWEP:GetNPCRestTimes()
    ---@type number?, number?
    local min, max = ss.ProtectedCall(self.NPCRestTimes, self)
    return min or self.NPCDelay, max or self.NPCDelay * 3
end

function SWEP:CanBePickedUpByNPCs()
    return true
end

function SWEP:Initialize()
    self:SetHolstering(true)
    self:SetInInk(false)
    self:SetOnEnemyInk(false)
    self:SetInk(ss.GetMaxInkAmount())
    self:SetInkColorProxy(ss.vector_one)
    self:SharedInitBase()
    self.NextEnemyInkDamage = CurTime()
    timer.Simple(0, function()
        if not IsValid(self) then return end
        if IsValid(self:GetOwner()) then return end
        self:CreateRagdoll()
    end)

    ss.ProtectedCall(self.ServerInit, self)
end

---Stores player info for later use
function SWEP:BackupInfo()
    local Owner = self:GetOwner()
    self.BackupPlayerMaxHealth = ss.GetMaxHealth()
    self.BackupHumanMaxHealth = Owner:GetMaxHealth()
    self:SetNWInt("BackupPlayerMaxHealth", self.BackupPlayerMaxHealth)
    self:SetNWInt("BackupHumanMaxHealth", self.BackupHumanMaxHealth)
    if not Owner:IsPlayer() then return end
    ---@cast Owner Player
    local mins, maxs = Owner:GetHullDuck()
    self.BackupPlayerInfo = {
        Color      = Owner:GetColor(),
        Flags      = Owner:GetFlags(),
        JumpPower  = Owner:GetJumpPower(),
        Material   = Owner:GetMaterial(),
        RenderMode = Owner:GetRenderMode(),
        Speed = {
            Crouched = Owner:GetCrouchedWalkSpeed(),
            Duck     = Owner:GetDuckSpeed(),
            Max      = Owner:GetMaxSpeed(),
            Run      = Owner:GetRunSpeed(),
            Walk     = Owner:GetWalkSpeed(),
            UnDuck   = Owner:GetUnDuckSpeed(),
        },
        SubMaterial = {},
        Playermodel = {
            Model       = Owner:GetModel(),
            Skin        = Owner:GetSkin(),
            BodyGroups  = Owner:GetBodyGroups(),
            PlayerColor = Owner:GetPlayerColor(),
        },
        ViewOffsetDucked = Owner:GetViewOffsetDucked(),
        HullMins = mins,
        HullMaxs = maxs,
    }
    for _, v in pairs(self.BackupPlayerInfo.Playermodel.BodyGroups) do
        v.num = Owner:GetBodygroup(v.id)
        v.submodels = nil
    end

    for i = 0, 31 do
        local submat = self:GetOwner():GetSubMaterial(i)
        self.BackupPlayerInfo.SubMaterial[i] = submat
    end
end

---Restores player info on holster
function SWEP:RestoreInfo()
    local Owner = self:GetOwner()
    Owner:SetMaxHealth(self.BackupHumanMaxHealth)
    Owner:SetHealth(Owner:Health() * self.BackupHumanMaxHealth / self.BackupPlayerMaxHealth)

    if not (IsValid(Owner) and Owner:IsPlayer()) then return end
    ---@cast Owner Player
    Owner:SetDSP(1, false)
    if istable(self.BackupPlayerInfo) then -- Restores owner's information.
        self:ChangePlayermodel(self.BackupPlayerInfo.Playermodel)
        Owner:SetColor(self.BackupPlayerInfo.Color)
        -- Owner:RemoveFlags(self:GetOwner():GetFlags()) -- Restores no target flag and something.
        -- Owner:AddFlags(self.BackupPlayerInfo.Flags)
        Owner:SetJumpPower(self.BackupPlayerInfo.JumpPower)
        Owner:SetRenderMode(self.BackupPlayerInfo.RenderMode)
        Owner:SetCrouchedWalkSpeed(self.BackupPlayerInfo.Speed.Crouched)
        Owner:SetDuckSpeed(self.BackupPlayerInfo.Speed.Duck)
        Owner:SetMaxSpeed(self.BackupPlayerInfo.Speed.Max)
        Owner:SetRunSpeed(self.BackupPlayerInfo.Speed.Run)
        Owner:SetWalkSpeed(self.BackupPlayerInfo.Speed.Walk)
        Owner:SetUnDuckSpeed(self.BackupPlayerInfo.Speed.UnDuck)
        Owner:SetHullDuck(self.BackupPlayerInfo.HullMins, self.BackupPlayerInfo.HullMaxs)
        Owner:SetViewOffsetDucked(self.BackupPlayerInfo.ViewOffsetDucked)
        Owner:SetMaterial(self.BackupPlayerInfo.Material)
        for i = 0, 31 do
            ss.SetSubMaterial_Workaround(Owner, i, self.BackupPlayerInfo.SubMaterial[i])
        end
    end
end

function SWEP:Equip(newOwner)
    self:SetOwner(newOwner)
    if InvalidPlayer(self:GetOwner()) then return end
    self:RemoveRagdoll()
    self:PlayLoopSound()
    self.SafeOwner = self:GetOwner()
    if IsValid(self:GetOwner()) and not self:GetOwner():IsPlayer() then
        self:SetSaveValue("m_fMinRange1", 0)
        self:SetSaveValue("m_fMinRange2", 0)
        self:SetSaveValue("m_fMaxRange1", self.Range)
        self:SetSaveValue("m_fMaxRange2", self.Range)
        self:Deploy()
        local think = "SplashSWEPs: NPC Think function" .. self:EntIndex()
        timer.Create(think, 0, 0, function()
            if not (IsValid(self) and IsValid(self:GetOwner()) and not self:GetOwner():IsPlayer()) then
                return timer.Remove(think)
            end

            self:Think()
        end)

        local move = "SplashSWEPs: NPC Move function" .. self:EntIndex()
        timer.Create(move, 0, 0, function()
            if not (IsValid(self) and IsValid(self:GetOwner()) and not self:GetOwner():IsPlayer()) then
                return timer.Remove(move)
            end

            ss.ProtectedCall(self.Move, self, self:GetOwner())
        end)

        return
    end

    self:BackupInfo()
    ss.SetPlayerFilter(newOwner, self:GetNWInt("inkcolor", -1), true)
end

---Deploy hook
---@return boolean allowSwitch True to allow switching away from this weapon using lastinv command
---@diagnostic disable-next-line: duplicate-set-field
function SWEP:Deploy()
    local Owner = self:GetOwner()
    if not IsValid(Owner) then return true end
    if InvalidPlayer(Owner) then ---@cast Owner Player
        ss.SendError("LocalPlayerNotReadyToSplat", Owner)
        self:Remove()
        return true
    end

    self:GetOptions()
    self:SetInkColorProxy(self:GetInkColor():ToVector())
    self:SetInInk(false)
    self:SetOnEnemyInk(false)
    self:BackupInfo()
    self.SafeOwner = self:GetOwner()
    Owner:SetMaxHealth(self:GetNWInt "BackupPlayerMaxHealth") -- NPCs also have modified max health.
    if Owner:IsPlayer() then ---@cast Owner Player
        local PMPath = ss.Playermodel[self:GetNWInt "playermodel"]
        if PMPath then
            if file.Exists(PMPath, "GAME") then
                self.PMTable = {
                    BodyGroups  = {},
                    Model       = PMPath,
                    PlayerColor = self:GetInkColorProxy(),
                    Skin        = 0,
                }
                self:ChangePlayermodel(self.PMTable)
            else
                ss.SendError("WeaponPlayermodelNotFound", Owner)
            end
        else
            Owner:SetPlayerColor(self:GetInkColorProxy())
        end

        Owner:SetRenderMode(RENDERMODE_TRANSCOLOR)
        ss.ProtectedCall(Owner.SplatColors, Owner)
    end

    ss.ProtectedCall(self.ServerDeploy, self)
    return self:SharedDeployBase()
end

---Called on removing this weapon from the world
---@diagnostic disable-next-line: duplicate-set-field
function SWEP:OnRemove()
    self:RemoveRagdoll()
    self:StopLoopSound()
    self:EndRecording()
    ss.ProtectedCall(self.ServerOnRemove, self)
    ss.SetPlayerFilter(self:GetOwner(), self:GetNWInt("inkcolor", -1), false)
    if self:GetHolstering() then return end
    self:Holster(NULL)
end

---Called when weapon is dropped
function SWEP:OnDrop()
    self.PMTable = nil
    self:SetOwner(self.SafeOwner)
    local Owner = self:GetOwner()
    if IsValid(Owner) and Owner:IsPlayer() ---@cast Owner Player
    and Owner:GetActiveWeapon() == self then
        self:RestoreInfo()
    end

    ss.SetPlayerFilter(Owner, self:GetNWInt("inkcolor", -1), false)
    self:SetOwner(NULL)
    ss.ProtectedCall(self.ServerHolster, self)
    self:SharedHolsterBase(NULL)
    self:CreateRagdoll()
    self:SetNWInt("TurfInkedAtStart", 0)
end

---Called after duplicator finishes saving the entity
---@param data EntityCopyData|table<string, any>
function SWEP:OnEntityCopyTableFinish(data)
    table.Empty(data.DT)
    for key, value in pairs(data) do
        if self.RestrictedFieldsToCopy[key] then data[key] = nil end
        if TypeID(value) == TYPE_SOUND      then data[key] = nil end
        if TypeID(value) == TYPE_ENTITY     then data[key] = nil end
    end
end

---Holster hook
---@param switchTo Entity
---@return boolean allowHolster True to allow weapon to holster
---@diagnostic disable-next-line: duplicate-set-field
function SWEP:Holster(switchTo)
    if self:GetInFence()              then return false end
    if not IsValid(self:GetOwner())   then return true end
    if InvalidPlayer(self:GetOwner()) then return true end
    if ss.ProtectedCall(self.ServerHolster, self, switchTo) == false then return false end
    if self:SharedHolsterBase(switchTo) == false then return false end
    self.PMTable = nil
    self:RestoreInfo()
    return true
end

---@diagnostic disable-next-line: duplicate-set-field
function SWEP:Think()
    local Owner = self:GetOwner()
    if not IsValid(Owner) or self:GetHolstering() then return end
    self:ProcessSchedules()
    self:UpdateInkState()
    self:SharedThinkBase()
    ss.ProtectedCall(self.ServerThink, self)
    if ss.GetOption "candrown" and Owner:WaterLevel() > 1 then
        local d = DamageInfo()
        d:SetAttacker(game.GetWorld())
        d:SetDamage(Owner:GetMaxHealth() * 10000)
        d:SetDamageForce(vector_origin)
        d:SetDamagePosition(Owner:GetPos())
        d:SetDamageType(DMG_DROWN)
        d:SetInflictor(game.GetWorld())
        d:SetMaxDamage(d:GetDamage())
        d:SetReportedPosition(Owner:GetPos())
        Owner:TakeDamageInfo(d)
    end

    if not Owner:IsPlayer() then
        if Owner:IsNPC() then ---@cast Owner NPC
            local target = Owner:GetTarget()
            if not IsValid(target) then target = Owner:GetEnemy() end
            if IsValid(target) then self:SetNPCTarget(target) end
            self:SetAimVector(Owner:GetAimVector())
            self:SetShootPos(Owner:GetShootPos())
        else
            self:SetAimVector(Owner:GetForward())
            self:SetShootPos(Owner:WorldSpaceCenter())
        end

        return
    end

    ---@cast Owner Player
    if not ss.IsInvincible(Owner) and self:GetOnEnemyInk() and CurTime() > self.NextEnemyInkDamage then
        local delay = 200 / ss.GetMaxHealth() * ss.FrameToSec
        self.NextEnemyInkDamage = CurTime() + delay
        self.HealSchedule:SetDelay(ss.HealDelay)
        if Owner:Health() > Owner:GetMaxHealth() / 2 then
            local d = DamageInfo()
            d:SetAttacker(game.GetWorld())
            d:SetDamage(1)
            d:SetInflictor(self)
            Owner:TakeDamageInfo(d) -- Enemy ink damage
        end
    end

    local PMPath = ss.Playermodel[self:GetNWInt "playermodel"]
    if PMPath then
        if (not self.PMTable or PMPath ~= Owner:GetModel()) and file.Exists(PMPath, "GAME") then
            self.PMTable = {
                BodyGroups  = {},
                Model       = PMPath,
                PlayerColor = self:GetInkColorProxy(),
                Skin        = 0,
            }
            self:ChangePlayermodel(self.PMTable)
        end
    else
        local mdl = self.BackupPlayerInfo.Playermodel
        if mdl.Model ~= Owner:GetModel() then
            self:ChangePlayermodel(mdl)
        end
    end

    if Owner:GetPlayerColor() ~= self:GetInkColorProxy() then
        Owner:SetPlayerColor(self:GetInkColorProxy())
    end
end
