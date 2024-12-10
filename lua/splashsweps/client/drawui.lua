
---@class ss
local ss = SplashSWEPs
if not ss then return end

---@param cx        number
---@param cy        number
---@param radius    number
---@param thickness number?
---@param startang  number?
---@param endang    number?
---@param roughness number?
---@return { x: number, y: number, u: number, v: number }[][]
local function PrecacheArc(cx, cy, radius, thickness, startang, endang, roughness)
    local triarc = {} ---@type { x: number, y: number, u: number, v: number }[][]
    local inner  = {} ---@type { x: number, y: number, u: number, v: number }[]
    local outer  = {} ---@type { x: number, y: number, u: number, v: number }[]
    local step = math.max(roughness or 20, 1) -- Define step
    thickness = thickness or radius
    startang, endang = startang or 0, endang or 360 -- Correct start/end ang
    if startang > endang then endang = endang + 360 end

    -- Create the inner and outer circle's points.
    for t, r in pairs { [inner] = radius - thickness, [outer] = radius } do
        for deg = startang, endang, step do
            local rad = math.rad(deg)
            local rx, ry = math.cos(rad) * r, math.sin(rad) * r
            t[#t + 1] = {
                x = cx + rx, y = cy - ry,
                u = .5 + rx / radius,
                v = .5 - ry / radius,
            }
        end
    end

    -- Triangulate the points.
    for tri = 1, #inner * 2 do -- Twice as many triangles as there are degrees.
        local p1 = outer[math.floor(tri / 2) + 1]
        local p2 = (tri % 2 > 0 and inner or outer)[math.floor(tri / 2 + .5)]
        local p3 = inner[math.floor(tri / 2 + .5) + 1]
        triarc[#triarc + 1] = { p1, p2, p3 }
    end

    -- Return a table of triangles to draw.
    return triarc
end

---Draws an arc on your screen.
---startang and endang are in degrees,
---radius is the total radius of the outside edge to the center.
---cx, cy are the x, y coordinates of the center of the arc.
---roughness determines how many triangles are drawn. Number between 1-360; 2 or 3 is a good number.
---@param cx        number
---@param cy        number
---@param radius    number
---@param thickness number?
---@param startang  number?
---@param endang    number?
---@param roughness number?
function ss.DrawArc(cx, cy, radius, thickness, startang, endang, roughness)
    for _, v in ipairs(PrecacheArc(cx, cy, radius, thickness, startang, endang, roughness)) do
        -- Resetting stencil masks significantly reduces garrysmod-issues #2731 with multicore rendering enabled
        -- https://github.com/Facepunch/garrysmod-issues/issues/2731#issuecomment-1160688282
        render.SetStencilWriteMask(0xFF)
        render.SetStencilTestMask(0xFF)
        render.SetStencilReferenceValue(0)
        render.SetStencilCompareFunction(STENCIL_ALWAYS)
        render.SetStencilPassOperation(STENCIL_KEEP)
        render.SetStencilFailOperation(STENCIL_KEEP)
        render.SetStencilZFailOperation(STENCIL_KEEP)
        render.ClearStencil()
        surface.DrawPoly(v)
    end
end

ss.DrawCrosshair = {}
local SCRH_REF = 1080 -- Reference of screen height for crosshairs.

---@param x     number
---@param y     number
---@param color Color
---@param d1    number
---@param d2    number
---@param mul   number?
local function DrawCircle(x, y, color, d1, d2, mul)
    local r1, r2 = d1 / 2, d2 / 2
    local thickness = r1 - r2
    local scale = ScrH() / SCRH_REF * (mul or 1)
    draw.NoTexture()
    surface.SetDrawColor(color)
    ss.DrawArc(x, y, r1 * scale, thickness * scale)
end

local INNER_CIRCLE_INNER_DIAMETER = 34 + 2 -- in pixels
local INNER_CIRCLE_OUTER_DIAMETER = 46 - 1 -- in pixels
---Draws an inner circle of shooter's crosshair.
---I separate the circle into two functions
---as the four lines of the crosshair are placed between the inner one and the outer one.
---@param x number
---@param y number
function ss.DrawCrosshair.InnerCircle(x, y)
    DrawCircle(x, y, color_white,
    INNER_CIRCLE_OUTER_DIAMETER, INNER_CIRCLE_INNER_DIAMETER)
end

local OUTER_CIRCLE_OUTER_DIAMETER = 52 -- in pixels
local OUTER_CIRCLE_INNER_DIAMETER = 32 -- in pixels
---Draws an outer circle of shooter's crosshair.
---@param x     number
---@param y     number
---@param color Color
function ss.DrawCrosshair.OuterCircle(x, y, color)
    DrawCircle(x, y, color,
    OUTER_CIRCLE_OUTER_DIAMETER, OUTER_CIRCLE_INNER_DIAMETER)
end

local BG_CIRCLE_OUTER_DIAMETER = 56 -- in pixels
local BG_CIRCLE_INNER_DIAMETER = 52 -- in pixels
---Draws a black background circle of shooter's crosshair when it hits an enemy.
---@param x number
---@param y number
function ss.DrawCrosshair.OuterCircleBG(x, y)
    DrawCircle(x, y, color_black,
    BG_CIRCLE_OUTER_DIAMETER, BG_CIRCLE_INNER_DIAMETER)
end

---Draws a circle of shooter's crosshair when it doesn't hit anything.
---@param x number
---@param y number
function ss.DrawCrosshair.CircleNoHit(x, y)
    local OUTER_DARK   = 48 -- in pixels
    local INNER_DARK   = 32 -- in pixels
    local OUTER_BRIGHT = 44 -- in pixels
    local INNER_BRIGHT = 38 -- in pixels
    DrawCircle(x, y, ss.CrosshairDarkColor, OUTER_DARK, INNER_DARK)
    DrawCircle(x, y, ss.CrosshairBaseColor, OUTER_BRIGHT, INNER_BRIGHT)
end

local sin45 = math.sin(math.rad(45))
local LINEHIT_SIZE_BG = 41 -- in pixels
local LINEHIT_WIDTH_BG = 5
local LINEHIT_SIZE = 38
local LINEHIT_WIDTH = 3
---Draws shooter's four lines when they hit an enemy.
---@param x                 number
---@param y                 number
---@param distanceRatio     number
---@param distanceReference number
---@param mul               number
---@param size              number
---@param width             number
---@param t                 { [1]: string, [2]: Color }[]
local function DrawLinesHit(x, y, distanceRatio, distanceReference, mul, size, width, t)
    local scale = ScrH() / SCRH_REF
    local length = ((size - width) / sin45) * scale * mul
    size = size * scale -- = width + length
    width = (width / sin45) * scale * mul
    local diff = distanceReference * distanceRatio * mul
    for _, v in ipairs(t) do
        local mat = "Line" .. v[1]
        local c = v[2]
        surface.SetMaterial(ss.Materials.Crosshair[mat])
        surface.SetDrawColor(c)
        for i = 1, 4 do
            local dx = diff * (i > 2 and 1 or -1)
            local dy = diff * (bit.band(i, 3) > 1 and 1 or -1)
            surface.DrawTexturedRectRotated(x + dx, y + dy, length, width, 90 * i + 45)
        end
    end
end

---@param x             number
---@param y             number
---@param distanceRatio number
---@param mul           number
function ss.DrawCrosshair.LinesHitBG(x, y, distanceRatio, mul)
    DrawLinesHit(x, y, distanceRatio, LINEHIT_SIZE_BG, mul,
    LINEHIT_SIZE_BG, LINEHIT_WIDTH_BG, {{"", color_black}})
end

---@param x             number
---@param y             number
---@param color         Color
---@param distanceRatio number
---@param mul           number
function ss.DrawCrosshair.LinesHit(x, y, color, distanceRatio, mul)
    DrawLinesHit(x, y, distanceRatio, LINEHIT_SIZE_BG, mul,
    LINEHIT_SIZE, LINEHIT_WIDTH, {{"", color_white}, {"Color", color}})
end

---@param org      Vector
---@param right    Vector
---@param dir      Vector
---@param range    number
---@param degx     number
---@param degy     number
---@param dx       number
---@param dy       number
---@param drawfunc fun(x: number, y: number, sgnx: number, sgny: number, ang: number)
local function FourLinesAround(org, right, dir, range, degx, degy, dx, dy, drawfunc)
    local ndir = dir:GetNormalized()
    local up = right:Cross(ndir)
    for i = 1, 4 do
        local rot = dir:Angle()
        local sgnx = i > 2 and 1 or -1
        local sgny = bit.band(i, 3) > 1 and 1 or -1
        rot:RotateAroundAxis(up, degx * sgnx)
        rot:RotateAroundAxis(right, degy * sgny)

        local endpos = org + rot:Forward() * range
        local hit = endpos:ToScreen()
        if hit.visible then
            local ang = 90 * i - 45
            drawfunc(hit.x + dx, hit.y + dy, sgnx, sgny, ang)
        end
    end
end

---@param org       Vector
---@param right     Vector
---@param dir       Vector
---@param range     number
---@param degx      number
---@param degy      number
---@param dx        number
---@param dy        number
---@param adjust    boolean?
---@param bgcolor   Color
---@param forecolor Color?
function ss.DrawCrosshair.FourLinesAround(org, right, dir, range, degx, degy, dx, dy, adjust, bgcolor, forecolor)
    local SIZE_ORIGINAL = 18 -- in pixels
    local WIDTH_ORIGINAL = 4 -- in pixels
    local scale = ScrH() / SCRH_REF
    local width = (WIDTH_ORIGINAL / sin45) * scale
    local length = ((SIZE_ORIGINAL - WIDTH_ORIGINAL) / sin45) * scale
    local diff = OUTER_CIRCLE_OUTER_DIAMETER / 2 * scale
    if adjust then diff = diff - width * sin45 end
    FourLinesAround(org, right, dir, range, degx, degy, dx, dy,
    function(x, y, sx, sy, ang)
        x = x - diff * sx
        y = y - diff * sy
        surface.SetDrawColor(bgcolor)
        surface.SetMaterial(ss.Materials.Crosshair.Line)
        surface.DrawTexturedRectRotated(x, y, length, width, ang)

        if not forecolor then return end
        surface.SetDrawColor(forecolor)
        surface.SetMaterial(ss.Materials.Crosshair.LineColor)
        surface.DrawTexturedRectRotated(x, y, length, width, ang)
    end)
end

---Draws a center dot of shooter's crosshair
---@param x     number
---@param y     number
---@param color Color?
function ss.DrawCrosshair.CenterDot(x, y, color)
    local CENTER_DOT_SIZE = 3 -- Radius of the center dot in pixels
    color = color or color_white
    draw.NoTexture()
    surface.SetDrawColor(color)
    ss.DrawArc(x, y, CENTER_DOT_SIZE)
end

---Draws a center dot of charger's crosshair.
---@param x           number
---@param y           number
---@param mul         number?
---@param darkcolor   Color?
---@param brightcolor Color?
function ss.DrawCrosshair.ChargerCenterDot(x, y, mul, darkcolor, brightcolor)
    local DARK_DIAMETER = 10
    local BRIGHT_DIAMETER = 6
    local screenscale = ScrH() / SCRH_REF
    local scale = 0.5 * screenscale * (mul or 1)
    local dr = DARK_DIAMETER * scale
    local br = BRIGHT_DIAMETER * scale
    darkcolor = darkcolor or ss.CrosshairDarkColor
    brightcolor = brightcolor or ss.CrosshairBaseColor
    draw.NoTexture()
    surface.SetDrawColor(darkcolor)
    ss.DrawArc(x, y, dr)
    surface.SetDrawColor(brightcolor)
    ss.DrawArc(x, y, br)
end

---Draws a center circle of charger's crosshair.
---@param x   number
---@param y   number
---@param mul number?
function ss.DrawCrosshair.ChargerBaseCircle(x, y, mul)
    local OUTER_DIAMETER = 27
    local INNER_DIAMETER = 21
    DrawCircle(x, y, ss.CrosshairBaseColor, OUTER_DIAMETER, INNER_DIAMETER, mul)
end

local CHARGER_OUTER_DIAMETER = 40
local CHARGER_INNER_DIAMETER = 34 + 1
---@param x     number
---@param y     number
---@param mul   number?
---@param color Color
function ss.DrawCrosshair.ChargerColoredCircle(x, y, mul, color)
    DrawCircle(x, y, color, CHARGER_OUTER_DIAMETER, CHARGER_INNER_DIAMETER, mul)
end

---@param x      number
---@param y      number
---@param color  Color
---@param d1     number
---@param d2     number
---@param start  number?
---@param endang number?
---@param mul    number?
local function DrawArc(x, y, color, d1, d2, start, endang, mul)
    local scale = ScrH() / SCRH_REF * (mul or 1) * 0.5
    local r1, r2 = d1 * scale, d2 * scale
    local thickness = r1 - r2
    draw.NoTexture()
    surface.SetDrawColor(color)
    ss.DrawArc(x, y, r1, thickness, start, endang, 1)
end

local CHARGER_ALPHA = 96
---Draws the charger's crosshair. progress ranges from 0 to 360.
---@param x        number
---@param y        number
---@param mul      number?
---@param progress number
function ss.DrawCrosshair.ChargerProgress(x, y, mul, progress)
    -- Black part of the arc
    local OUTER_DIAMETER = 40
    local INNER_DIAMETER = 28
    local start = 90
    local endang = 450 - progress
    DrawArc(x, y, ColorAlpha(ss.CrosshairDarkColor, CHARGER_ALPHA),
    OUTER_DIAMETER, INNER_DIAMETER, start, endang, mul)

    -- White part of the arc
    OUTER_DIAMETER = 40
    INNER_DIAMETER = 24
    start = 450 - progress
    endang = 450
    DrawArc(x, y, ColorAlpha(ss.CrosshairBaseColor, CHARGER_ALPHA),
    OUTER_DIAMETER, INNER_DIAMETER, start, endang, mul)
end

---@param x             number
---@param y             number
---@param distanceRatio number
---@param mul           number
---@param darkcolor     Color
---@param brightcolor   Color
function ss.DrawCrosshair.ChargerFourLines(x, y, distanceRatio, mul, darkcolor, brightcolor)
    local SIZE_BG = 18 + 4
    local SIZE_FG = 14 + 2
    local WIDTH_BG = 7
    local WIDTH_FG = 3
    DrawLinesHit(x, y, distanceRatio, SIZE_BG, mul, SIZE_BG, WIDTH_BG, {{"", darkcolor}})
    DrawLinesHit(x, y, distanceRatio, SIZE_BG, mul, SIZE_FG, WIDTH_FG, {{"", brightcolor}})
end

---@param x        number
---@param y        number
---@param mul      number?
---@param color    Color
---@param frac     number
---@param diameter number
local function Flash(x, y, mul, color, frac, diameter)
    local ALPHA_MAX = 255
    local ALPHA_MIN = 0
    local scale = ScrH() / SCRH_REF * (mul or 1)
    local d = diameter * scale
    local radius = d / 2
    local alpha = Lerp(frac, ALPHA_MAX, ALPHA_MIN)
    surface.SetMaterial(ss.Materials.Crosshair.Flash)
    surface.SetDrawColor(ColorAlpha(color, alpha))
    surface.DrawTexturedRect(x - radius, y - radius, d, d)
end

---@param x     number
---@param y     number
---@param mul   number?
---@param color Color
---@param frac  number
function ss.DrawCrosshair.ChargerFlash(x, y, mul, color, frac)
    Flash(x, y, mul, color, frac, CHARGER_OUTER_DIAMETER)
end
