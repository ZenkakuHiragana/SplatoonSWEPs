
-- Clientside SplashSWEPs structure

if not SplashSWEPs then
---@class ss
SplashSWEPs = {
    ClassDefinitions        = {}, ---@type table<string, table>
    CrosshairColors         = {}, ---@type integer[]
    EntityFilters           = {}, ---@type table<integer, table<Entity, boolean>> [color][target] = true
    IMesh                   = {}, ---@type IMesh[]
    InkColors               = {}, ---@type Color[]
    InkShotMasks            = {}, ---@type ss.InkShotMask[][] Indexing order -> InkType, ThresholdIndex, x, y
    InkShotMaterials        = {}, ---@type IMaterial[][]
    InkShotNormals          = {}, ---@type IMaterial[][]
    InkShotTypes            = {}, ---@type table<string, integer[]> InkShotCategory (string: "drop", "shot", etc.)  InkShotTypes (integer[])
    InkShotTypeToCategory   = {}, ---@type string[] InkShotType (integer) to InkShotCategory (string: "drop", "shot", etc.)
    InkQueue                = {}, ---@type table<number, ss.InkQueue[]>
    InvincibleEntities      = {}, ---@type table<Entity, number> [target] = end time
    KnockbackVector         = {}, ---@type table<Entity, Vector> [target] = current knockback velocity
    LastHitID               = {}, ---@type table<Entity, integer> [target] = ink id
    Lightmap                = {}, ---@type ss.Lightmap
    MinimapAreaBounds       = {}, ---@type table<integer, { mins: Vector, maxs: Vector }>
    PlayerFilters           = {}, ---@type table<integer, table<Entity, boolean>> [color][player, npc, or nextbot] = true
    PaintQueue              = {}, ---@type table<integer, ss.PaintQueue>
    PaintSchedule           = {}, ---@type table<table, true>
    PlayerHullChanged       = {}, ---@type table<Player, boolean>
    PlayerShouldResetCamera = {}, ---@type table<Player, boolean>
    RenderTarget            = {}, ---@type ss.RenderTarget
    SurfaceArray            = {}, ---@type PaintableSurface[]
    WaterMesh               = {}, ---@type IMesh[]
    WaterSurfaces           = {}, ---@type PaintableSurface[]
    WeaponRecord            = {}, ---@type table<Entity, ss.WeaponRecord>
}
end

include "splashsweps/const.lua"
include "splashsweps/shared.lua"
include "drawui.lua"
include "inkrenderer.lua"
include "minimap.lua"
include "network.lua"
include "surfacebuilder.lua"
include "userinfo.lua"

---@class ss
local ss = SplashSWEPs
if not ss.GetOption "enabled" then
    for h, t in pairs(hook.GetTable() --[[@as table<string, {[string]: function}>]]) do
        for name in pairs(t) do
            if ss.ProtectedCall(name.find, name, "SplashSWEPs") then
                hook.Remove(h, name)
            end
        end
    end

    table.Empty(SplashSWEPs)
    ---@diagnostic disable-next-line: global-element
    SplashSWEPs = nil ---@type nil
    return
end

local crashpath = "splashsweps/crashdump.txt" -- Existing this means the client crashed before.
hook.Add("InitPostEntity", "SplashSWEPs: Clientside initialization", function()
    gameevent.Listen "entity_killed"
    local rt = ss.RenderTarget
    local wascrashedbefore = file.Exists(crashpath, "DATA")
    if not file.Exists("splashsweps", "DATA") then file.CreateDir "splashsweps" end
    if wascrashedbefore then -- If the client has crashed before, RT shrinks.
        ss.SetOption("rtresolution", rt.RESOLUTION.MINIMUM)
        notification.AddLegacy(ss.Text.Error.CrashDetected --[[@as string]], NOTIFY_GENERIC, 15)
    end

    file.Write(crashpath, "")
    local rtsizeindex = ss.GetOption "rtresolution"
    if wascrashedbefore or not rt.Size[rtsizeindex] then
        rtsizeindex = rt.RESOLUTION.MINIMUM
    end

    local rtsize = math.min(rt.Size[rtsizeindex], render.MaxTextureWidth(), render.MaxTextureHeight())
    rt.BaseTexture = GetRenderTargetEx(
        rt.Name.BaseTexture,
        rtsize, rtsize,
        RT_SIZE_LITERAL,
        MATERIAL_RT_DEPTH_NONE,
        rt.Flags.BaseTexture,
        CREATERENDERTARGETFLAGS_HDR,
        IMAGE_FORMAT_RGBA8888 -- 8192x8192, 256MB
    )
    rt.Bumpmap = GetRenderTargetEx(
        rt.Name.Bumpmap,
        rtsize, rtsize,
        RT_SIZE_LITERAL,
        MATERIAL_RT_DEPTH_NONE,
        rt.Flags.Bumpmap,
        CREATERENDERTARGETFLAGS_HDR,
        IMAGE_FORMAT_RGBA8888 -- 8192x8192, 256MB
    )
    rtsize = math.min(rt.BaseTexture:Width(), rt.BaseTexture:Height())
    rt.Material = CreateMaterial(
        rt.Name.RenderTarget,
        "LightmappedGeneric", {
            ["$basetexture"]                 = rt.Name.BaseTexture,
            ["$bumpmap"]                     = rt.Name.Bumpmap,
            ["$vertexcolor"]                 = "1",
            ["$nolod"]                       = "1",
            ["$alpha"]                       = "0.99609375", -- = 255 / 256,
            ["$alphatest"]                   = "1",
            ["$alphatestreference"]          = "0.0625",
            ["$phong"]                       = "1",
            ["$phongexponent"]               = "128",
            ["$phongamount"]                 = "[1 1 1 1]",
            ["$phongmaskcontrastbrightness"] = "[2 .7]",
            ["$envmap"]                      = "shadertest/shadertest_env",
            ["$envmaptint"]                  = "[1 1 1]",
            ["$color"]                       = "[1 1 1]",
            -- ["$detail"]                      = rt.BaseTexture,
            -- ["$detailscale"]                 = 1,
            -- ["$detailblendmode"]             = 5,
            -- ["$detailblendfactor"]           = 1, -- Increase this for bright ink in night maps
        }
    )

    file.Delete(crashpath) -- Succeeded to make RTs and remove crash detection

    -- Checking ink map in data/
    local bspPath = string.format("maps/%s.bsp", game.GetMap())
    local txtPath = string.format("splashsweps/%s.txt", game.GetMap())
    local mapCRC = util.CRC(file.Read(bspPath, true))
    local dataJSON = file.Read("data/" .. txtPath, "DOWNLOAD") or ""
    local dataCRC = util.CRC(dataJSON) or ""
    local dataCRCServer = GetGlobalString "SplashSWEPs: Ink map CRC"
    if dataCRC ~= dataCRCServer then
        dataJSON = file.Read(txtPath, "DATA") or ""
        dataCRC = util.CRC(dataJSON) or ""
    end

    local dataTable = util.JSONToTable(util.Decompress(dataJSON) or "", true) or {}
    local isvalid = dataJSON ~= ""
        and dataTable.MapCRC == mapCRC
        and (ss.sp or dataCRC == dataCRCServer)
        and dataTable.Revision == ss.MAPCACHE_REVISION

    if not isvalid then -- Local ink cache ~= Ink cache from server
        net.Start "SplashSWEPs: Redownload ink data"
        net.SendToServer()
        notification.AddProgress("SplashSWEPs: Redownload ink data", "Downloading ink map...")
        return
    end

    ss.PrepareInkSurface(dataTable)
end)

---Local player isn't considered by Trace.  This is a poor workaround.
---@param start Vector
---@param dir Vector
---@return Vector?
function ss.TraceLocalPlayer(start, dir)
    local lp = LocalPlayer()
    local pos = util.IntersectRayWithOBB(start, dir, lp:GetPos(), lp:GetRenderAngles(), lp:OBBMins(), lp:OBBMaxs())
    return pos
end

---Address the issue of detaching ClientsideModel on leaving PVS
---https://github.com/Facepunch/garrysmod-issues/issues/861
---@param w SplashWeaponBase
---@param ent Entity
---@param shouldTransmit boolean
function ss.NotifyShouldTransmit(w, ent, shouldTransmit)
    if not IsValid(w.InkTankModel) then return end
    if shouldTransmit then w.InkTankModel:SetParent(ent) end
end

local Water80 = Material "effects/flicker_128"
local Water90 = Material "effects/water_warp01"
---@return IMaterial
function ss.GetWaterMaterial()
    return render.GetDXLevel() < 90 and Water80 or Water90
end
---@param w SplashWeaponBase
---@param ply Player
---@return boolean
local function ShouldHidePlayer(w, ply)
    return Either(w:GetNWBool "transformoncrouch" and IsValid(w:GetNWEntity "TransformModel"), ply:Crouching(), w:GetInInk())
end
---@param w SplashWeaponBase
---@param ply Player
---@return boolean
local function ShouldChangePlayerAlpha(w, ply)
    return w:IsCarriedByLocalPlayer() and not (vrmod and vrmod.IsPlayerInVR(ply))
end
---@param w SplashWeaponBase
---@param ply Player
---@param flags number
function ss.PostPlayerDraw(w, ply, flags)
    if flags == 0 then return end
    if ShouldHidePlayer(w, ply) then return end
    if ShouldChangePlayerAlpha(w, ply) then
        render.SetBlend(1)
    end
end
---@param w SplashWeaponBase
---@param ply Player
---@param flags number
---@return boolean?
function ss.PrePlayerDraw(w, ply, flags)
    if flags == 0 then return end
    if ShouldHidePlayer(w, ply) then return true end
    if ShouldChangePlayerAlpha(w, ply) then
        render.SetBlend(Lerp(w:GetCameraFade(), 0, ply:GetColor().a / 255))
    end
end

---@param w SWEP.Charger
function ss.RenderScreenspaceEffects(w)
    ss.ProtectedCall(w.RenderScreenspaceEffects, w)
    if not w:GetInInk() or LocalPlayer():ShouldDrawLocalPlayer() or not ss.GetOption "drawinkoverlay" then return end
    local color = w:GetInkColorProxy()
    DrawMaterialOverlay(render.GetDXLevel() < 90 and "effects/flicker_128" or "effects/water_warp01", .1)
    surface.SetDrawColor(ColorAlpha(color:ToColor(),
    48 * (1.1 - math.sqrt(ss.GrayScaleFactor:Dot(color))) / ss.GrayScaleFactor:Dot(render.GetToneMappingScaleLinear())))
    surface.DrawRect(0, 0, ScrW(), ScrH())
end

---@param w SWEP.Charger
function ss.PostRender(w)
    if ss.RenderingRTScope then return end
    if not (w.Scoped and w.RTScope) then return end
    local vm = w:GetViewModel()
    if not IsValid(vm) then return end
    if not w:GetNWBool "usertscope" then
        ss.SetSubMaterial_Workaround(vm, w.RTScopeNum - 1)
        return
    end

    w.RTName = w.RTName or vm:GetMaterials()[w.RTScopeNum] .. "rt"
    w.RTMaterial = w.RTMaterial or Material(w.RTName)
    w.RTMaterial:SetTexture("$basetexture", w.RTScope)
    w.RTAttachment = w.RTAttachment or vm:LookupAttachment "scope_end"
    ss.SetSubMaterial_Workaround(vm, w.RTScopeNum - 1, w.RTName)
    ss.RenderingRTScope = ss.sp
    local alpha = 1 - w:GetScopedProgress(true)
    local a = vm:GetAttachment(w.RTAttachment)
    if a then
        render.PushRenderTarget(w.RTScope)
        render.RenderView {
            origin = w.ScopeOrigin or a.Pos, angles = a.Ang,
            x = 0, y = 0, w = 512, h = 512, aspectratio = 1,
            fov = w.Parameters.mSniperCameraFovy_RTScope,
            drawviewmodel = false,
        }
        ss.ProtectedCall(w.HideRTScope, w, alpha)
        render.PopRenderTarget()
    end
    ss.RenderingRTScope = nil
end

local EaseInOut = math.EaseInOut
local duration = 72 * ss.FrameToSec
local max = math.max
local mat = Material "debug/debugtranslucentvertexcolor"
local Remap = math.Remap
local vector_one = ss.vector_one

---Draws V-shaped crosshair
---The weapon needs these fields:
---table self.Crosshair ... a table of CurTime()-based times
---number self.Parameters.mTargetEffectScale -- a scale for width
---number self.Parameters.mTargetEffectVelRate -- a scale for depth
---@param self SWEP.Roller
---@param dodraw boolean
---@param isfirstperson boolean?
function ss.DrawVCrosshair(self, dodraw, isfirstperson)
    local aim = self:GetAimVector()
    local ang = aim:Angle()
    local alphastart = 0.8
    local colorstart = 0.25
    local degstart = isfirstperson and 0 or 0.4
    local inkcolor = self:GetInkColorProxy()
    local rot = ang:Up()
    local degbase = isfirstperson and 6 or 14
    local deg = degbase * self.Parameters.mTargetEffectScale
    local degmulstart = isfirstperson and 0.6 or 1
    local dz = 8
    local width = isfirstperson and 0.25 or 0.5
    ang:RotateAroundAxis(ang:Right(), 4)
    render.SetMaterial(mat)

    local org = self:GetShootPos() - rot * dz
    for i, v in ipairs(self.Crosshair) do
        local linearfrac = (CurTime() - v) / duration
        local alphafrac = EaseInOut(Remap(max(linearfrac, alphastart), alphastart, 1, 0, 1), 0, 1)
        local colorfrac = EaseInOut(Remap(max(linearfrac, colorstart), colorstart, 1, 0, 1), 0, 1)
        local degfrac = EaseInOut(Remap(max(linearfrac, degstart), degstart, 1, 0, 1), 0, 1)
        local movefrac = EaseInOut(linearfrac, 0, 1)
        local radius = Lerp(movefrac, 40, 100 * self.Parameters.mTargetEffectVelRate)
        local radiusside = radius * 0.85
        local color = ColorAlpha(LerpVector(colorfrac, vector_one, inkcolor):ToColor(), Lerp(alphafrac, 255, 0))
        local angleft = Angle(ang)
        local angright = Angle(ang)
        local degside = deg * Lerp(degfrac, degmulstart, 1.1)
        angleft:RotateAroundAxis(rot, degside)
        angright:RotateAroundAxis(rot, -degside)
        local start = org + ang:Forward() * radius
        local endleft = org + angleft:Forward() * radiusside
        local endright = org + angright:Forward() * radiusside
        if linearfrac > 1 then self.Crosshair[i] = nil end
        if dodraw then
            render.DrawBeam(start, endleft, width, 0, 1, color)
            render.DrawBeam(start, endright, width, 0, 1, color)
        end
    end
end

local PreventRecursive = false
local BlurX, BlurY, BlurStep = 0.08, 0.08, 0.16

---@param ent Entity
---@param color Color
function ss.DrawSolidHalo(ent, color)
    if PreventRecursive then return end
    render.SetStencilEnable(true)
    render.SetStencilWriteMask(3)
    render.SetStencilTestMask(3)
    render.SetStencilReferenceValue(3)
    render.ClearStencil()

    render.SetStencilCompareFunction(STENCIL_NEVER)
    render.SetStencilPassOperation(STENCIL_KEEP)
    render.SetStencilFailOperation(STENCIL_REPLACE)
    render.SetStencilZFailOperation(STENCIL_KEEP)

    PreventRecursive = true
    ent:DrawModel()

    render.SetStencilCompareFunction(STENCIL_NOTEQUAL)
    render.SetStencilPassOperation(STENCIL_REPLACE)
    render.SetStencilFailOperation(STENCIL_KEEP)
    render.SetStencilWriteMask(2)
    local org = ent:GetPos()
    local r, u = EyeAngles():Right(), EyeAngles():Up()
    for x = -BlurX, BlurX, BlurStep do
        for y = -BlurY, BlurY, BlurStep do
            local dxdy = r * x + u * y
            ent:SetPos(org + dxdy)
            ent:SetupBones()
            for _, e in ipairs(ent:GetChildren()) do e:SetupBones() end
            ent:DrawModel()
        end
    end

    ent:SetPos(org)
    ent:SetupBones()
    for _, e in ipairs(ent:GetChildren()) do e:SetupBones() end
    PreventRecursive = false

    render.SetStencilReferenceValue(2)
    render.SetStencilCompareFunction(STENCIL_EQUAL)
    render.SetStencilPassOperation(STENCIL_KEEP)

    cam.Start2D()
    surface.SetDrawColor(color)
    surface.DrawRect(0, 0, ScrW(), ScrH())
    cam.End2D()
    render.SetStencilEnable(false)
end

hook.Add("NotifyShouldTransmit", "SplashSWEPs: Address issue of detaching ink tank", ss.hook "NotifyShouldTransmit")
hook.Add("PostPlayerDraw", "SplashSWEPs: Thirdperson player fadeout", ss.hook "PostPlayerDraw")
hook.Add("PrePlayerDraw", "SplashSWEPs: Hide players on crouch", ss.hook "PrePlayerDraw")
hook.Add("PostRender", "SplashSWEPs: Render a RT scope", ss.hook "PostRender")
hook.Add("RenderScreenspaceEffects", "SplashSWEPs: First person ink overlay", ss.hook "RenderScreenspaceEffects")
hook.Add("OnCleanup", "SplashSWEPs: Cleanup all ink", function(t)
    if LocalPlayer():IsAdmin() and (t == "all" or t == ss.CleanupTypeInk) then
        net.Start "SplashSWEPs: Send ink cleanup"
        net.SendToServer()
    end
end)

hook.Add("entity_killed", "SplashSWEPs: Remove ragdolls on death", function(data)
    local attacker = Entity(data.entindex_attacker)
    local victim = Entity(data.entindex_killed)
    if not IsValid(victim) then return end
    if not victim:IsPlayer() then return end ---@cast victim Player
    local w = ss.IsValid(attacker)
    if not w then return end

    if IsValid(victim:GetRagdollEntity()) then
        victim:GetRagdollEntity():SetNoDraw(true)
        victim.IsKilledBySplashSWEPs = nil
    else
        victim.IsKilledBySplashSWEPs = true
    end
end)

hook.Add("CreateClientsideRagdoll", "SplashSWEPs: Remove ragdolls on death",
---@param ply Player
---@param rag Entity
function(ply, rag)
    if not ply.IsKilledBySplashSWEPs then return end
    rag:SetNoDraw(true)
    ply.IsKilledBySplashSWEPs = nil
end)
