
-- Clientside ink renderer

---@class ss
local ss = SplashSWEPs
if not ss then return end
local CVarWireframe = GetConVar "mat_wireframe"
local CVarMinecraft = GetConVar "mat_showlowresimage"
local rt = ss.RenderTarget
local MAX_QUEUE_TIME = ss.FrameToSec
local MAX_QUEUES_TOLERANCE = 5 -- Possible number of queues to be processed at once without losing FPS.
local grey = Material "grey":GetTexture "$basetexture"
local function DrawMeshes(bDrawingDepth, bDrawingSkybox)
    if ss.GetOption "hideink" then return end
    if not rt.Ready or bDrawingSkybox or CVarWireframe:GetBool() or CVarMinecraft:GetBool() then return end
    render.SetMaterial(rt.Material)                 -- Ink base texture
    render.SetLightmapTexture(rt.Lightmap or grey) -- Set custom lightmap
    render.DepthRange(0, 65534 / 65535)
    for _, m in ipairs(ss.IMesh) do m:Draw() end    -- Draw ink surface
    render.RenderFlashlights(function()
        render.SetMaterial(rt.Material)
        render.SetLightmapTexture(rt.Lightmap or grey)
        for _, m in ipairs(ss.IMesh) do m:Draw() end
    end)
    render.DepthRange(0, 1)
end

local ceil, floor = math.ceil, math.floor
local Round = math.Round
local To2D = ss.To2D
local Vector = Vector
local vector_one = ss.vector_one
local CollectSurfaces = ss.CollectSurfaces
local CollisionAABB2D = ss.CollisionAABB2D
local GetColor = ss.GetColor
local GetInkReferenceAABB = ss.GetInkReferenceAABB
---@param radius  number
---@param ang     number
---@param normal  Vector
---@param ratio   number
---@param color   integer
---@param inktype integer
---@param pos     Vector
---@param order   integer
---@param tick    integer
function ss.ReceiveInkQueue(radius, ang, normal, ratio, color, inktype, pos, order, tick)
    if color == 0 or inktype == 0 then return end
    local i = 0
    local mins, maxs = GetInkReferenceAABB(pos, normal, radius)
    for s in CollectSurfaces(mins, maxs, normal) do
        local pos2d = To2D(pos, s.OriginUV, s.AnglesUV) * ss.UnitsToPixels
        local b = s.BoundaryUV * ss.UVToPixels

        local start = s.OffsetUV * ss.UVToPixels
        local center = Vector(Round(pos2d.x + start.x), Round(pos2d.y + start.y))
        local endpos = Vector(ceil(start.x + b.x) + 1, ceil(start.y + b.y) + 1)
        start = Vector(floor(start.x) - 1, floor(start.y) - 1)
        local r = radius * ss.UnitsToPixels
        local vr = vector_one * r
        if CollisionAABB2D(start, endpos, center - vr, center + vr) then
            local lightmapoffset = r / 2
            i = i + 1
            ---@class ss.PaintQueue
            ---@field done integer
            ss.PaintQueue[tick * 16384 + order * 512 + i] = {
                angle = ang,
                center = center,
                color = GetColor(color),
                colorid = color,
                done = 1,
                endpos = endpos,
                height = 2 * r,
                lightmapradius = r,
                lightmapx = center.x - lightmapoffset,
                lightmapy = center.y - lightmapoffset,
                pos = pos,
                radius = radius,
                ratio = ratio,
                start = start,
                surf = s,
                t = inktype,
                width = 2 * r * ratio,
            }
        end
    end
end

local function ProcessPaintQueue()
    while not rt.Ready do coroutine.yield() end
    local Benchmark = 0
    local NumRepetition = 4
    local Painted = 0
    local BaseTexture = rt.BaseTexture
    local Bumpmap = rt.Bumpmap
    local Clamp = math.Clamp
    local InkShotMaterials = ss.InkShotMaterials
    local InkShotNormals = ss.InkShotNormals
    local Lerp = Lerp
    local PaintQueue = ss.PaintQueue
    local SortedPairs = SortedPairs
    local SysTime = SysTime
    local yield = coroutine.yield

    local Start2D = cam.Start2D
    local End2D = cam.End2D
    local OverrideBlend = render.OverrideBlend
    local PushRenderTarget = render.PushRenderTarget
    local PopRenderTarget = render.PopRenderTarget
    local SetScissorRect = render.SetScissorRect
    local DrawTexturedRectRotated = surface.DrawTexturedRectRotated
    local SetDrawColor = surface.SetDrawColor
    local SetMaterial = surface.SetMaterial
    while true do
        Benchmark = SysTime()
        NumRepetition = ceil(Lerp(Painted / MAX_QUEUES_TOLERANCE, 4, 0))
        for order, q in SortedPairs(PaintQueue) do
            local alpha = Clamp(q.done, 1, 4)
            local inkmaterial = InkShotMaterials[q.t][alpha]
            local inknormal = InkShotNormals[q.t][alpha]
            local angle = q.surf.AnglesUV.roll + q.surf.AnglesUV.yaw - q.angle

            PushRenderTarget(BaseTexture)
            Start2D()
            SetDrawColor(q.color)
            SetMaterial(inkmaterial)
            SetScissorRect(q.start.x, q.start.y, q.endpos.x, q.endpos.y, true)
            OverrideBlend(true, BLEND_ONE, BLEND_ZERO, BLENDFUNC_ADD, BLEND_ONE, BLEND_ONE, BLENDFUNC_ADD)
            DrawTexturedRectRotated(q.center.x, q.center.y, q.width, q.height, angle)
            OverrideBlend(false)
            SetScissorRect(0, 0, 0, 0, false)
            End2D()
            PopRenderTarget()

            PushRenderTarget(Bumpmap)
            Start2D()
            SetDrawColor(Color(255, 255, 255, 255))
            SetMaterial(inknormal)
            SetScissorRect(q.start.x, q.start.y, q.endpos.x, q.endpos.y, true)
            OverrideBlend(true, BLEND_ONE, BLEND_ZERO, BLENDFUNC_ADD, BLEND_ONE, BLEND_ZERO, BLENDFUNC_ADD)
            DrawTexturedRectRotated(q.center.x, q.center.y, q.width, q.height, angle)
            OverrideBlend(false)
            SetScissorRect(0, 0, 0, 0, false)
            End2D()
            PopRenderTarget()

            q.done = q.done + 1
            Painted = Painted + 1
            if q.done > NumRepetition or not InkShotMaterials[q.t][alpha + 1] then
                local localang = q.surf.Angles.roll + q.surf.Angles.yaw - q.angle
                ss.AddInkRectangle(q.colorid, q.t, localang, q.pos, q.radius, q.ratio, q.surf)
                PaintQueue[order] = nil
            end

            if ss.Debug then ss.Debug.ShowInkDrawn(q.start, q.center, q.endpos, q.surf, q) end
            if SysTime() - Benchmark > MAX_QUEUE_TIME then
                yield()
                Benchmark = SysTime()
            end
        end

        Painted = 0
        yield()
    end
end

local process = coroutine.create(ProcessPaintQueue)
---@diagnostic disable-next-line: duplicate-set-field
function ss.ClearAllInk()
    table.Empty(ss.InkQueue)
    table.Empty(ss.PaintSchedule)
    if rt.Ready then table.Empty(ss.PaintQueue) end
    for _, s in ipairs(ss.SurfaceArray) do table.Empty(s.InkColorGrid) end
    render.PushRenderTarget(rt.BaseTexture)
    render.OverrideAlphaWriteEnable(true, true)
    render.ClearDepth()
    render.ClearStencil()
    render.Clear(0, 0, 0, 0)
    render.OverrideAlphaWriteEnable(false)
    render.PopRenderTarget()

    render.PushRenderTarget(rt.Bumpmap)
    render.OverrideAlphaWriteEnable(true, true)
    render.ClearDepth()
    render.ClearStencil()
    render.Clear(128, 128, 255, 255)
    render.OverrideAlphaWriteEnable(false)
    render.PopRenderTarget()
end

local ErrorNoHalt = ErrorNoHalt
local resume, status = coroutine.resume, coroutine.status
hook.Add("Tick", "SplashSWEPs: Register ink clientside", function()
    if status(process) == "dead" then return end
    local ok, msg = resume(process)
    if not ok then ErrorNoHalt(msg) end
end)

hook.Add("PreDrawTranslucentRenderables", "SplashSWEPs: Draw ink", DrawMeshes)
