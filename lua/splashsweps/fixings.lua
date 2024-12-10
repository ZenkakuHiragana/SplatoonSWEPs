
---@class ss
local ss = SplashSWEPs
if not ss then return end

------------------------------------------
--           !!!WORKAROUND!!!           --
--  This should be removed after        --
--  Adv. Colour Tool fixed the bug!!    --
------------------------------------------
local AdvancedColourToolLoaded
= file.Exists("weapons/gmod_tool/stools/adv_colour.lua", "LUA")
local AdvancedColourToolReplacedSetSubMaterial
= AdvancedColourToolLoaded and FindMetaTable "Entity"._OldSetSubMaterial
if AdvancedColourToolReplacedSetSubMaterial then
    function ss.SetSubMaterial_Workaround(ent, ...)
        ent:_OldSetSubMaterial(...)
    end
else
    function ss.SetSubMaterial_Workaround(ent, ...)
        ent:SetSubMaterial(...)
    end
end
------------------------------------------
--           !!!WORKAROUND!!!           --
------------------------------------------


-- Playermodels hull change fix
if isfunction(FindMetaTable "Player".SplatoonOffsets) then
    ---@class Player
    ---@field SplatColors               fun(self)
    ---@field DefaultOffsets            fun(self)
    ---@field IsKilledBySplashSWEPs boolean?

    local cvarflags = {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE}
    CreateConVar("splt_Colors", "1", cvarflags, "Toggles skin/eye colors on Splatoon playermodels.")
    if SERVER then
        hook.Remove("KeyPress", "splt_KeyPress")
        hook.Remove("PlayerSpawn", "splt_Spawn")
        hook.Remove("PlayerDeath", "splt_OnDeath")
        hook.Add("PlayerSpawn", "SplashSWEPs: Fix PM change", function(ply)
            ss.SetSubMaterial_Workaround(ply)
        end)
    else
        hook.Remove("Tick", "splt_Offsets_cl")
    end

    local width = 16
    local splt_EditScale = GetConVar "splt_EditScale"
    local ViewOffset = Vector(0, 0, 42)
    local ViewOffsetDucked = Vector(0, 0, 28)
    local HullMins, HullMaxs = Vector(-width, -width, 0), Vector(width, width, 53)
    hook.Add("Tick", "SplashSWEPs: Fix playermodel hull change", function()
        for _, p in ipairs(player.GetAll()) do
            local m = p:GetModel()
            local is = ss.DrLilRobotPlayermodels[m] or ss.EggHeadPlayermodels[m]
            if not p:Alive() then
                ss.PlayerHullChanged[p] = nil
            elseif is and splt_EditScale:GetInt() ~= 0 and ss.PlayerHullChanged[p] ~= true then
                p:SetViewOffset(ViewOffset)
                p:SetViewOffsetDucked(ViewOffsetDucked)
                p:SetHull(HullMins, HullMaxs)
                p:SetHullDuck(HullMins, HullMaxs)
                ss.PlayerHullChanged[p] = true
            elseif not is and ss.PlayerHullChanged[p] ~= false then
                p:DefaultOffsets()
                ss.PlayerHullChanged[p] = false
            end
        end
    end)
end

-- View Extension disables FOV changes so "fix" it
local ht = hook.GetTable()
if CLIENT and ht.CalcView and ht.CalcView["ViewExtension:CalcView"] then
    ---@type fun(ply: Player, origin: Vector, angles: Angle, fov: number, znear: number, zfar: number): CamData?
    ss.ViewExtensionCalcView = ss.ViewExtensionCalcView or hook.GetTable().CalcView["ViewExtension:CalcView"]
    hook.Remove("CalcView", "ViewExtension:CalcView")
    hook.Add("CalcView", "ViewExtension:CalcView",
    ---@param ply Player
    ---@param org Vector
    ---@param ang Angle
    ---@param fov number
    ---@param zn number
    ---@param zf number
    ---@return table?
    function( ply, org, ang, fov, zn, zf)
        local w = ss.IsValid(ply)
        local t = ss.ViewExtensionCalcView(ply, org, ang, fov, zn, zf)
        if not t then return end
        if not w then return t end

        -- This is really ugly, but I have to because
        -- Player:ShouldDrawLocalPlayer() returns false at here for some reason
        local mt = FindMetaTable "Player"
        local g = mt.ShouldDrawLocalPlayer
        function mt:ShouldDrawLocalPlayer() return t.drawviewer end

        local p, a, f = w:CalcView(ply, Vector(t.origin), Angle(t.angles), t.fov)
        mt.ShouldDrawLocalPlayer = g -- Then restore it
        t.origin, t.angles, t.fov = p, a, f
        return t
    end)
end
