
-- do return end -- Uncomment this to disable debugging

AddCSLuaFile()

---@class ss
local ss = SplashSWEPs
if not ss then return end

ss.Debug = {}
local d = require "greatzenkakuman/debug" or greatzenkakuman.debug
local sd = ss.Debug

function d.DLoop() end
if CLIENT then hook.Remove("CreateMove", "Test") end
local ShowInkChecked     = false -- Draws ink boundary.
local ShowInkDrawn       = false -- When ink hits, show ink surface painted by it.
local DrawInkUVMap       = false -- Press Shift to draw ink UV map.
local DrawInkUVBounds    = false -- Also draws UV boundary.
local ShowInkSurface     = false -- Press E for serverside, Shift for clientside, draws ink surface nearby player #1.
local ShowInkStateMesh   = false -- Shows the mesh to determine ink color of surface.
local ShowInkChecked_ServerTime = CurTime()
function sd.ShowInkChecked(r, s)
    if not ShowInkChecked then return end
    local debugv = {Vector(-r.ratio, -1), Vector(r.ratio, -1), Vector(r.ratio, 1), Vector(-r.ratio, 1)}
    for _, v in ipairs(debugv) do v:Rotate(Angle(0, -r.angle)) v:Mul(r.radius) v:Add(r.pos) end
    if CLIENT then d.DTick() end
    if SERVER then
        if CurTime() < ShowInkChecked_ServerTime then return end
        ShowInkChecked_ServerTime = CurTime() + 1
        d.DShort()
    end

    local c = ss.GetColor(r.color)
    d.DColor()
    d.DPoly {
        ss.To3D(debugv[1], s.Origin, s.Angles),
        ss.To3D(debugv[2], s.Origin, s.Angles),
        ss.To3D(debugv[3], s.Origin, s.Angles),
        ss.To3D(debugv[4], s.Origin, s.Angles),
    }
    d.DColor(c.r, c.g, c.b)
    for b in pairs(r.bounds) do
        local b1, b2, b3, b4 = unpack(b)
        local v1 = ss.To3D(Vector(b1, b2), s.Origin, s.Angles)
        local v2 = ss.To3D(Vector(b1, b4), s.Origin, s.Angles)
        local v3 = ss.To3D(Vector(b3, b4), s.Origin, s.Angles)
        local v4 = ss.To3D(Vector(b3, b2), s.Origin, s.Angles)
        d.DText(v1, string.format("(%d, %d)", b1, b2))
        d.DText(v3, string.format("(%d, %d)", b3, b4))
        d.DPoly {v1, v2, v3, v4}
    end
end

function sd.ShowInkDrawn(s, c, b, surf)
    if not ShowInkDrawn then return end
    d.DShort()
    d.DColor()
    d.DBox(s * ss.PixelsToUV * 500, b * ss.PixelsToUV * 500)
    d.DPoint(c * ss.PixelsToUV * 500)
    d.DPoly(surf.Vertices3D)
end

local gridsize = ss.InkGridSize -- [Hammer Units]
local ShowInkStatePos = Vector()
local ShowInkStateID = 0
local ShowInkStateSurf = {}
---@param pos Vector
---@param id integer
---@param surf PaintableSurface
function sd.ShowInkStateMesh(pos, id, surf)
    if not ShowInkStateMesh then return end
    ShowInkStatePos = pos
    ShowInkStateID = id
    ShowInkStateSurf = surf
    if SERVER ~= player.GetByID(1):KeyDown(IN_ATTACK2) then return end
    local ink = surf.InkColorGrid
    if not ink then return end
    local colorid = ink[pos.x * 32768 + pos.y]
    local c = ss.GetColor(colorid) or color_white
    local p = ss.To3D(pos * gridsize, surf.Origin, surf.Angles)
    d.DTick()
    d.DColor(c.r, c.g, c.b, colorid and 64 or 16)
    d.DABox(p, vector_origin, Vector(0, gridsize, gridsize), surf.Angles)
end

if CLIENT and DrawInkUVMap then
    local c = 500
    function d.DLoop() -- Draw ink UV map
        -- setpos 0 250 500; setang 90 -90 0
        local ply = LocalPlayer()
        if not ply:KeyPressed(IN_SPEED) then return end
        d.DShort()
        d.DColor(255, 255, 255)
        d.DPoly {Vector(0, 0), Vector(0, c), Vector(c, c), Vector(c, 0)}
        d.DColor(255, 0, 0)
        d.DVector(Vector(c, 0), Vector(c, 0))
        d.DColor(0, 255, 0)
        d.DVector(Vector(0, c), Vector(0, c))
        for _, s in ipairs(ss.SurfaceArray) do
            local t = {} ---@type Vector[]
            for i, v in ipairs(s.Vertices2D or {}) do t[i] = v * c end

            d.DColor()
            for i = 1, #s.Triangles, 3 do
                local v1 = t[s.Triangles[i]]
                local v2 = t[s.Triangles[i + 1]]
                local v3 = t[s.Triangles[i + 2]]
                d.DLine(v1, v2, true)
                d.DLine(v2, v3, true)
                d.DLine(v3, v1, true)
            end

            if DrawInkUVBounds then
                d.DColor(255, 255, 255)
                local org = Vector(s.OffsetUV.x, s.OffsetUV.y) * c + vector_up
                local u, v = s.BoundaryUV.x, s.BoundaryUV.y
                d.DPoly {
                    org,
                    org + Vector(u, 0) * c,
                    org + Vector(u, v) * c,
                    org + Vector(0, v) * c,
                }
            end
        end
    end
end

if ShowInkSurface then
    local key = SERVER and IN_USE or IN_SPEED
    function d.DLoop()
        local ply = player.GetByID(1)
        if not IsValid(ply) then return end
        if not ply:KeyPressed(key) then return end
        d.DShort()
        d.DColor()
        local p = ply:GetPos()
        local mins, maxs = p - ss.vector_one, p + ss.vector_one
        for s in ss.CollectSurfaces(mins, maxs, vector_up) do
            if s.IsDisplacement then
                for i = 1, #s.Triangles, 3 do
                    local v1 = s.Vertices3D[s.Triangles[i]]
                    local v2 = s.Vertices3D[s.Triangles[i + 1]]
                    local v3 = s.Vertices3D[s.Triangles[i + 2]]
                    d.DLine(v1, v2, true)
                    d.DLine(v2, v3, true)
                    d.DLine(v3, v1, true)
                end
            else
                d.DPoly(s.Vertices3D)
            end
            d.DPoint(s.Origin)
        end
    end
end

if ShowInkStateMesh then
    local key = SERVER and IN_USE or IN_SPEED
    function d.DLoop()
        local ply = SERVER and player.GetByID(1) or LocalPlayer()
        if not IsValid(ply) then return end
        if not ply:KeyPressed(key) then return end
        if not ShowInkStatePos then return end
        local pos = ShowInkStatePos
        local id = ShowInkStateID
        local surf = ShowInkStateSurf ---@type PaintableSurface
        local ink = surf.InkColorGrid
        if not ink then return end
        local colorid = ink[pos.x * 32768 + pos.y]
        local color = ss.GetColor(colorid) or color_white
        local sw, sh = surf.width, surf.height
        local gw, gh = math.floor(sw / gridsize), math.floor(sh / gridsize)
        d.DShort()
        d.DColor(color.r, color.g, color.b, colorid and 64 or 16)
        d.DPoint(surf.Origin)
        d.DText(surf.Origin, tostring(id))
        for x = 0, gw do
            for y = 0, gh do
                local p = Vector(x, y) * gridsize
                local org = ss.To3D(p, surf.Origin, surf.Angles)
                local cid = ink[x * 32768 + y]
                local c = ss.GetColor(cid) or color_white
                d.DColor(c.r, c.g, c.b, cid and 64 or 0)
                d.DABox(org, vector_origin, Vector(0, gridsize, gridsize), surf.Angles)
            end
        end
    end
end
