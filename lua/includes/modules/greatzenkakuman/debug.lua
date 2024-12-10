
-- Debugging code
AddCSLuaFile()
module("greatzenkakuman.debug", package.seeall)
local debug = greatzenkakuman.debug or {}
local t = 5 -- Debugoverlay time
local csv = Color(0, 255, 255)
local ccl = Color(255, 255, 0) -- Debugoverlay color
local igz = true -- Debugoverlay ignoreZ
local sp = game.SinglePlayer()
local d = sp or CLIENT
local dcolor = "greatzenkakuman.debug.DColor(%s,%s,%s,%s,1)"
local daxis = "greatzenkakuman.debug.DAxis(Vector(%f,%f,%f),Angle(%f,%f,%f),%s,%f)"
local dline = "greatzenkakuman.debug.DLine(Vector(%f,%f,%f),Vector(%f,%f,%f),%s,1)"
local dtext = "greatzenkakuman.debug.DText(Vector(%f,%f,%f),\"%s\",%s)"
local dtri = "greatzenkakuman.debug.DTri(Vector(%f,%f,%f),Vector(%f,%f,%f),Vector(%f,%f,%f),%s,1)"
local dplane = "greatzenkakuman.debug.DPlane(Vector(%f,%f,%f),Vector(%f,%f,%f),%s,1)"
local dpoint = "greatzenkakuman.debug.DPoint(Vector(%f,%f,%f),%s,1)"
local dstext = "greatzenkakuman.debug.DSText(%d,%d,%s,1)"
local dsphere = "greatzenkakuman.debug.DSphere(Vector(%f,%f,%f),%f,%s,1)"
local dvector = "greatzenkakuman.debug.DVector(Vector(%f,%f,%f),Vector(%f,%f,%f),%s,1)"
local dbox = "greatzenkakuman.debug.DBox(Vector(%f,%f,%f),Vector(%f,%f,%f),1)"
local dsbox = "greatzenkakuman.debug.DSBox(Vector(%f,%f,%f),Vector(%f,%f,%f),Vector(%f,%f,%f),Vector(%f,%f,%f),Angle(%f,%f,%f),1)"
local dabox = "greatzenkakuman.debug.DABox(Vector(%f,%f,%f),Vector(%f,%f,%f),Vector(%f,%f,%f),Angle(%f,%f,%f),1)"
if SERVER then
    util.AddNetworkString "greatzenkakuman.debug.DPoly"
else
    net.Receive("greatzenkakuman.debug.DPoly", function() debug.DPoly(net.ReadTable(), net.ReadBool(), true) end)
end

---Display debug overlay for very short time (80 ms)
function debug.DTick() if d then t = .08 else BroadcastLua "greatzenkakuman.debug.DTick()" end end
---Display debug overlay for short time (5 sec.)
function debug.DShort() if d then t = 5 else BroadcastLua "greatzenkakuman.debug.DShort()" end end
---Display debug overlay for long time (10 sec.)
function debug.DLong() if d then t = 10 else BroadcastLua "greatzenkakuman.debug.DLong()" end end
---Changes color of debug overlay
---@param r  integer?
---@param g  integer?
---@param b  integer?
---@param a  integer?
---@param sv boolean? True to change color for serverside
function debug.DColor(r, g, b, a, sv)
    if d then
        r = r or sv and 0 or 255
        g = g or 255
        b = b or sv and 255 or 0
        a = a or 255
        local c = Color(r, g, b, a)
        if sv then csv = c else ccl = c end
    else
        BroadcastLua(dcolor:format(r, g, b, a))
    end
end

---Runs debugoverlay.Axis
---@param v Vector   Origin position
---@param a Angle    Axis angle
---@param z boolean? Ignore Z
---@param l number   Axis length
function debug.DAxis(v, a, z, l)
    a, z, l = a or angle_zero, Either(z ~= nil, z, igz), l or 20
    if d then
        debugoverlay.Axis(v, a, l, t, z)
    else
        BroadcastLua(daxis:format(v.x, v.y, v.z, a.p, a.y, a.r, tostring(z), t, l))
    end
end

---Runs debugoverlay.Line
---@param x  Vector
---@param y  Vector
---@param z  boolean? Ignore Z
---@param sv boolean? True to display serverside color
function debug.DLine(x, y, z, sv)
    z = Either(z ~= nil, z, igz)
    if d then
        debugoverlay.Line(x, y, t, sv and csv or ccl, z)
    else
        BroadcastLua(dline:format(x.x, x.y, x.z, y.x, y.y, y.z, tostring(z)))
    end
end

---Runs debugoverlay.Text
---@param v Vector   Position of text
---@param x any      Text
---@param z boolean? Ignore Z
function debug.DText(v, x, z)
    z = Either(z ~= nil, z, igz)
    x = tostring(x)
    if d then
        debugoverlay.Text(v, x, t, not z)
    else
        BroadcastLua(dtext:format(v.x, v.y, v.z, x, tostring(z)))
    end
end

---Runs debugoverlay.Triangle
---@param a  Vector
---@param b  Vector
---@param c  Vector
---@param z  boolean? Ignore Z
---@param sv boolean? True to display serverside color
function debug.DTri(a, b, c, z, sv)
    z = Either(z ~= nil, z, igz)
    if d then
        debugoverlay.Triangle(a, b, c, t, sv and csv or ccl, z)
    else
        BroadcastLua(dtri:format(a.x, a.y, a.z, b.x, b.y, b.z, c.x, c.y, c.z, tostring(z)))
    end
end

---Represents a plane in the 3D space
---@param v  Vector   Origin
---@param n  Vector   Normal
---@param z  boolean? Ignore Z
---@param sv boolean? True to display serverside color
function debug.DPlane(v, n, z, sv)
    z = Either(z ~= nil, z, igz)
    if d then
        local l = 50
        local a = n:Angle()
        local x, y = a:Right() * l, a:Up() * l
        debug.DPoly({v + x + y, v + x - y, v - x - y, v - x + y}, z, sv)
        debug.DLine(v + x + y, v - x - y, z, sv)
        debug.DLine(v + x - y, v - x + y, z, sv)
        debug.DVector(v, n * l, z, sv)
    else
        BroadcastLua(dplane:format(v.x, v.y, v.z, n.x, n.y, n.z, tostring(z)))
    end
end

---Runs debugoverlay.Cross
---@param v  Vector          Position
---@param s  number|boolean? Size (= 10)
---@param z  boolean?        Ignore Z
---@param sv boolean?        True to display serverside color
function debug.DPoint(v, s, z, sv)
    if s == nil or isbool(s) then s, z, sv = 10, s --[[@as boolean]], z end ---@cast s number
    z = Either(z ~= nil, z, igz)
    if d then
        debugoverlay.Cross(v, s, t, sv and csv or ccl, z)
    else
        BroadcastLua(dpoint:format(v.x, v.y, v.z, tostring(z)))
    end
end

---Runs debugoverlay.ScreenText
---@param u  number   X-coordinate
---@param v  number   Y-coordinate
---@param x  any      Text
---@param sv boolean? True to display serverside color
function debug.DSText(u, v, x, sv)
    if d then
        debugoverlay.ScreenText(u, v, x, t, sv and csv or ccl)
    else
        BroadcastLua(dstext:format(u, v, x))
    end
end

---Runs debugoverlay.Sphere
---@param v  Vector   Center position
---@param r  number   Radius
---@param z  boolean? Ignore Z
---@param sv boolean? True to display serverside color
function debug.DSphere(v, r, z, sv)
    z = Either(z ~= nil, z, igz)
    if d then
        debugoverlay.Sphere(v, r, t, sv and csv or ccl, z)
    else
        BroadcastLua(dsphere:format(v.x, v.y, v.z, r, tostring(z)))
    end
end

---Runs debugoverlay.Line but using origin and direction like util.QuickTrace
---@param v  Vector   Origin
---@param n  Vector   Direction
---@param z  boolean? Ignore Z
---@param sv boolean? True to display serverside color
function debug.DVector(v, n, z, sv)
    z = Either(z ~= nil, z, igz)
    if d then
        debugoverlay.Line(v, v + n, t, sv and csv or ccl, z)
    else
        BroadcastLua(dvector:format(v.x, v.y, v.z, n.x, n.y, n.z, tostring(z)))
    end
end

---Runs debugoverlay.Line to form a polygon
---@param v  Vector[] The vertices
---@param z  boolean? Ignore Z
---@param sv boolean? True to display serverside color
function debug.DPoly(v, z, sv)
    if d then
        local n = #v
        for k = 1, n do
            local a, b = v[k], v[k % n + 1]
            debug.DLine(a, b, z, sv)
        end
    else ---@cast z -?
        net.Start "greatzenkakuman.debug.DPoly"
        net.WriteTable(v)
        net.WriteBool(z)
        net.Broadcast()
    end
end

---Runs debugoverlay.Box
---@param a  Vector   Minimum
---@param b  Vector   Maximum
---@param sv boolean? True to display serverside color
function debug.DBox(a, b, sv)
    if d then
        local c = sv and csv or ccl
        debugoverlay.Box(vector_origin, a, b, t, ColorAlpha(c, math.min(c.a, 64)))
    else
        BroadcastLua(dbox:format(a.x, a.y, a.z, b.x, b.y, b.z))
    end
end

---Runs debugoverlay.SweptBox
---@param a  Vector   Start
---@param b  Vector   End
---@param x  Vector   Minimum
---@param y  Vector   Maximum
---@param o  Angle?   Orientation
---@param sv boolean? True to display serverside color
function debug.DSBox(a, b, x, y, o, sv)
    o = o or angle_zero
    if d then
        debugoverlay.SweptBox(x, y, a, b, o, t, sv and csv or ccl)
    else
        BroadcastLua(dsbox:format(a.x, a.y, a.z, b.x, b.y, b.z, x.x, x.y, x.z, y.x, y.y, y.z, o.p, o.y, o.r))
    end
end

---Runs debugoverlay.BoxAngles
---@param v  Vector   Position
---@param a  Vector   Minimum
---@param b  Vector   Maximum
---@param o  Angle?   Orientation
---@param sv boolean? True to display serverside color
function debug.DABox(v, a, b, o, sv)
    o = o or angle_zero
    if d then
        local c = sv and csv or ccl
        debugoverlay.BoxAngles(v, a, b, o, t, ColorAlpha(c, math.min(c.a, 64)))
    else
        BroadcastLua(dabox:format(v.x, v.y, v.z, a.x, a.y, a.z, b.x, b.y, b.z, o.p, o.y, o.r))
    end
end

---Draws a swept box for HullTrace, a line for Trace structure
---@param v  HullTrace|Trace|TraceResult
---@param z  boolean? Ignore Z
---@param sv boolean? True to display serverside color
function debug.DTrace(v, z, sv)
    if v.mins and v.maxs then
        debug.DSBox(v.mins, v.maxs, v.start, v.endpos, nil, SERVER)
    else
        z = Either(z ~= nil, z, igz)
        debug.DLine(v.StartPos or v.start, v.HitPos or v.endpos, z)
    end
end

hook.Add("Think", "greatzenkakuman.debug.DLoop", function()
    sp = game.SinglePlayer()
    d = sp or CLIENT
    if debug.DLoop then debug.DLoop() end
end)

return debug
