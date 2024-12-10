
---@class ss
local ss = SplashSWEPs
if not ss then return end

local GLOBAL_DELTA_Z = 32768 -- How far the orthogonal camera will be placed above
local abs, cos, sin, rad = math.abs, math.cos, math.sin, math.rad
function ss.OpenMiniMap()
    local bb = ss.GetMinimapAreaBounds(LocalPlayer():WorldSpaceCenter())
    if not bb then return end
    local inclined       = true
    local bbmins, bbmaxs = bb.mins, bb.maxs
    local bbsize         = bbmaxs - bbmins
    local vertical       = bbsize.x > bbsize.y -- Indicates if the map is vertically long
    local renderOrigin   = Vector(bbmins.x, vertical and bbmins.y or bbmaxs.y, bbmaxs.z + GLOBAL_DELTA_Z)
    local transitionTime = 0.5
    local inclinedPitch  = 60
    local upPitch        = 90
    local inclinedYaw    = vertical and 60 or -30
    local upYaw          = vertical and 90 or 0
    local inclinedAngle  = Angle(inclinedPitch, inclinedYaw, 0)
    local upAngle        = Angle(upPitch, upYaw, 0)
    local desiredAngle   = Angle(inclinedAngle)
    local currentAngle   = Angle(desiredAngle)
    local angularRate    = Angle(abs(inclinedPitch - upPitch), abs(inclinedYaw - upYaw), 0) / transitionTime
    local panMultiplier  = bbsize:Length2D() / 1000
    local zoomMultiplier = panMultiplier * 10
    local maxzoom        = bbsize:Length() -- FIXME: Find the correct maximum zoom
    local cameraInfo = {
        mousePos       = Vector(), -- Mouse position stored on right click
        panOnMouseDown = Vector(), -- X/Y offset backup
        pan            = Vector(), -- X/Y offset
        zoom           = 0,        -- Wheel delta value
    }
    local cameraInfoUp = { -- Camera info for looking straight down
        mousePos       = Vector(),
        panOnMouseDown = Vector(),
        pan            = Vector(),
        zoom           = 0,
    }

    -- Minimap window margin taken from spawnmenu.lua
    local spawnmenu_border = GetConVar "spawnmenu_border"
    local border = spawnmenu_border and spawnmenu_border:GetFloat() or 0.1
    local windowMarginX = math.Clamp((ScrW() - 1024) * border, 25, 256 )
    local windowMarginY = math.Clamp((ScrH() - 768)  * border, 25, 256 )
    if ScrW() < 1024 or ScrH() < 768 then
        windowMarginX = 0
        windowMarginY = 0
    end

    local frame = vgui.Create("DFrame")
    local panel = vgui.Create("DButton", frame) ---@cast panel +PANEL
    frame:SetSizable(true)
    frame:SetPos(windowMarginX, windowMarginY)
    frame:SetSize(ScrW() - windowMarginX * 2, ScrH() - windowMarginY * 2)
    frame:MakePopup()
    frame:SetKeyboardInputEnabled(false)
    frame:SetMouseInputEnabled(true)
    frame:SetTitle("Splash SWEPs: Minimap")
    panel:Dock(FILL)
    panel:SetText("")

    local function UpdateCameraAngles()
        currentAngle.pitch = math.ApproachAngle(
            currentAngle.pitch, desiredAngle.pitch,
            angularRate.pitch * RealFrameTime())
        currentAngle.yaw = math.ApproachAngle(
            currentAngle.yaw, desiredAngle.yaw,
            angularRate.yaw * RealFrameTime())
    end

    ---@return number
    ---@return number
    local function GetPanOffset()
        local frac = math.Remap(currentAngle.yaw, inclinedYaw, upYaw, 0, 1)
        local dx = Lerp(frac, cameraInfo.pan.x, cameraInfoUp.pan.x)
        local dy = Lerp(frac, cameraInfo.pan.y, cameraInfoUp.pan.y)
        return dx, dy
    end

    ---@param windowWidth number
    ---@param windowHeight number
    ---@return Vector
    ---@return table
    local function GetOrthoTable(windowWidth, windowHeight)
        -- +--------------=====------------------------------+
        -- |             /     ^^^^^-----_____  H = bbsize.y |
        -- |            /                     ^^^^^-----_____|
        -- |           /                                    /|
        -- |          /                                    / |
        -- |         /                                    /  |
        -- |        /                         x1 = W - x /   |
        -- |       / W = bbsize.x                       /    |
        -- |      /                                    /     |
        -- |     /                                    /      |
        -- |    /            renderOrigin            /       |
        -- |   /                  (X)^^^^^-----_____/        |
        -- |  /                   /                /         |
        -- | /                   /                /          |
        -- |/    x1 = H - y     /             x0 /           |
        -- |^^^^^-----_____    /      y0        /            |
        -- |       yaw (   ^^^^^-----_____     /             |
        -- +------------`-----------------====---------------+
        local px, py = GetPanOffset()
        local pitch  = rad(currentAngle.pitch)
        local yaw    = rad(currentAngle.yaw)
        local x0, y0 = renderOrigin.x - bbmins.x, renderOrigin.y - bbmins.y
        local x1, y1 = bbmaxs.x - renderOrigin.x, bbmaxs.y - renderOrigin.y
        local left   =  -y1 * cos(yaw) - math.max( x0 * sin(yaw), -x1 * sin(yaw))
        local right  =   y0 * cos(yaw) + math.max(-x0 * sin(yaw),  x1 * sin(yaw))
        local top    = -(x0 * cos(yaw) + math.max( y0 * sin(yaw), -y1 * sin(yaw))) * sin(pitch) - bbsize.z * cos(pitch)
        local bottom =  (x1 * cos(yaw) + math.max(-y0 * sin(yaw),  y1 * sin(yaw))) * sin(pitch)
        local deltaz =  GLOBAL_DELTA_Z * cos(pitch)

        local width  = right - left
        local height = bottom - top
        local aspect = width / height
        local frac   = math.Remap(currentAngle.yaw, inclinedYaw, upYaw, 0, 1)
        local zoom   = Lerp(frac, cameraInfo.zoom,  cameraInfoUp.zoom)
        left   = left   + zoom * zoomMultiplier * aspect - px
        right  = right  - zoom * zoomMultiplier * aspect - px
        top    = top    + zoom * zoomMultiplier - deltaz + py
        bottom = bottom - zoom * zoomMultiplier - deltaz + py

        local Lx  = (right - left) / 2
        local Ly  = (bottom - top) / 2
        local dx  = (right + left) / 2
        local dy  = (top + bottom) / 2
        local org = renderOrigin + currentAngle:Right() * dx + currentAngle:Up() * dy

        local marginx, marginy = 0, 0
        if windowWidth / windowHeight < Lx / Ly then -- Add margin vertically
            marginy = Lx * windowHeight / windowWidth - Ly
        else
            marginx = Ly * windowWidth / windowHeight - Lx
        end

        return org, {
            left   = -Lx - marginx,
            right  =  Lx + marginx,
            top    = -Ly - marginy,
            bottom =  Ly + marginy,
        }
    end

    ---@param x number
    ---@param y number
    ---@param w number
    ---@param h number
    local function DrawMap(x, y, w, h)
        local origin, ortho = GetOrthoTable(w, h)
        ss.IsDrawingMinimap = true
        local old = render.EnableClipping(true)
        render.PushCustomClipPlane(Vector( 0,  0, -1), -bbmaxs.z - 0.5)
        render.PushCustomClipPlane(Vector( 0,  0,  1),  bbmins.z - 0.5)
        render.PushCustomClipPlane(Vector(-1,  0,  0), -bbmaxs.x - 0.5)
        render.PushCustomClipPlane(Vector( 1,  0,  0),  bbmins.x - 0.5)
        render.PushCustomClipPlane(Vector( 0, -1,  0), -bbmaxs.y - 0.5)
        render.PushCustomClipPlane(Vector( 0,  1,  0),  bbmins.y - 0.5)
        render.RenderView {
            drawviewmodel = false,
            origin = origin,
            angles = currentAngle,
            x = x, y = y,
            w = w, h = h,
            ortho = ortho,
            znear = 1,
            zfar  = 56756 + GLOBAL_DELTA_Z,
        }
        render.PopCustomClipPlane()
        render.PopCustomClipPlane()
        render.PopCustomClipPlane()
        render.PopCustomClipPlane()
        render.PopCustomClipPlane()
        render.PopCustomClipPlane()
        render.EnableClipping(old)
        ss.IsDrawingMinimap = false
    end

    ---@param pos Vector
    ---@param w number
    ---@param h number
    ---@param ortho { left: number, right: number, top: number, bottom: number }
    ---@param origin Vector
    ---@return number
    ---@return number
    local function TransformPosition(pos, w, h, ortho, origin)
        local localpos = WorldToLocal(pos, angle_zero, origin, currentAngle)
        local x = math.Remap(localpos.y, ortho.left, ortho.right,  w, 0)
        local y = math.Remap(localpos.z, ortho.top,  ortho.bottom, h, 0)
        return x, y
    end

    local keydown = input.IsShiftDown()
    local mousedown = input.IsMouseDown(MOUSE_RIGHT)
    function panel:Think()
        local k = input.IsShiftDown()
        local m = input.IsMouseDown(MOUSE_RIGHT)
        local x, y = input.GetCursorPos()
        if not keydown and k then frame:Close() end
        keydown = k

        local t = inclined and cameraInfo or cameraInfoUp
        if not mousedown and m then
            t.mousePos.x, t.mousePos.y = x, y
            t.panOnMouseDown.x, t.panOnMouseDown.y = t.pan.x, t.pan.y
        elseif m then
            t.pan.x = t.panOnMouseDown.x + (x - t.mousePos.x) * panMultiplier
            t.pan.y = t.panOnMouseDown.y + (y - t.mousePos.y) * panMultiplier
        end
        mousedown = m

        if input.IsKeyDown(input.GetKeyCode(input.LookupBinding "reload")) then
            t.pan.x, t.pan.y, t.zoom = 0, 0, 0
        end
    end

    function panel:DoDoubleClick()
        inclined = not inclined
        desiredAngle = inclined and inclinedAngle or upAngle
    end

    function panel:DoClick()
        local weapon = ss.IsValid(LocalPlayer())
        if not weapon then return end
        local x, y = self:ScreenToLocal(input.GetCursorPos())
        local w, h = panel:GetSize()
        local origin, ortho = GetOrthoTable(w, h)
        local pc = weapon:GetNWInt "inkcolor"
        local s = math.min(w, h) * 0.025 -- beacon icon size
        for _, b in ipairs(ents.FindByClass "ent_splashsweps_beacon") do ---@cast b ENT.Beacon
            local c = b:GetNWInt "inkcolor"
            if c ~= pc then continue end
            local pos = b:WorldSpaceCenter()
            local bx, by = TransformPosition(pos, w, h, ortho, origin)
            if math.Distance(x, y, bx, by) < s then
                frame:Close()
                return
            end
        end
    end

    function panel:OnMouseWheeled(scrollDelta)
        local t = inclined and cameraInfo or cameraInfoUp
        t.zoom = math.min(t.zoom + scrollDelta, maxzoom)
        return false
    end

    function panel:Paint(w, h)
        local x, y = self:LocalToScreen(0, 0)
        UpdateCameraAngles()
        DrawMap(x, y, w, h)
    end

    ss.IsOpeningMinimap = true
    function frame:OnClose()
        timer.Simple(0, function()
            ss.IsOpeningMinimap = nil
        end)
    end
end

local WaterMaterial = Material "gm_construct/water_13_beneath"
hook.Add("PreDrawTranslucentRenderables", "SplashSWEPs: Draw water surfaces", function(bDrawingDepth, bDrawingSkybox)
    if not ss.IsDrawingMinimap then return end
    render.SetMaterial(WaterMaterial)
    for _, m in ipairs(ss.WaterMesh) do m:Draw() end
    render.OverrideDepthEnable(true, true)
    render.UpdateRefractTexture()
    render.SetMaterial(ss.GetWaterMaterial())
    for _, m in ipairs(ss.WaterMesh) do m:Draw() end
    render.OverrideDepthEnable(false)
end)

hook.Add("PreDrawSkyBox", "SplashSWEPs: Disable rendering skybox in a minimap", function()
    if ss.IsDrawingMinimap then return true end
end)
