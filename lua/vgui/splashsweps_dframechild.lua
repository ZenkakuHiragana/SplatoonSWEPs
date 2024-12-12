
-- SplashSWEPs.DFrameChild
local PANEL = {}
---@cast PANEL PANEL.DFrameChild
---@class PANEL.DFrameChild : DFrame, EditablePanel, PANEL
---@field btnMaxim          DButton
---@field btnMinim          DButton
---@field Dragging          { [1]: number, [2]: number }
---@field Hovered           boolean
---@field InitialScreenLock boolean
---@field lblTitle          DLabel
---@field m_bSizable        boolean
---@field m_iMinHeight      integer
---@field m_iMinWidth       integer
---@field Restore           { x: number, y: number, w: number, h: number }
---@field Sizing            { [1]: number, [2]: number }
---@field Stat              string?
---@field x                 number
---@field y                 number

function PANEL:Init()
    self.btnMaxim:SetEnabled(true)
    self.btnMinim:SetEnabled(true)
    function self.btnMaxim.DoClick()
        if self.Stat ~= "Maximized" then
            self:SetPos(0, 0)
            self:SetSize(self:GetParent():GetSize())
            self.Stat = "Maximized"
        else
            self:SetPos(self.Restore.x, self.Restore.y)
            self:SetSize(self.Restore.w, self.Restore.h)
            self.Stat = nil
        end
    end

    function self.btnMinim.DoClick()
        if self.Stat ~= "Minimized" then
            local p = self:GetParent()
            local w, h = self.lblTitle:GetTextSize() + 110, 24
            self:SetPos(p:GetWide() - w, p:GetTall() - h)
            self:SetSize(w, h)
            self.Stat = "Minimized"
        else
            self:SetPos(self.Restore.x, self.Restore.y)
            self:SetSize(self.Restore.w, self.Restore.h)
            self.Stat = nil
        end
    end
end

function PANEL:Think()
    self:SetMinWidth(math.max(self:GetMinWidth(), self.lblTitle:GetTextSize() + 110))
    if not self.Stat then
        self.Restore = {
            x = self.x,
            y = self.y,
            w = self:GetWide(),
            h = self:GetTall(),
        }
    end

    local mousex, mousey = self:LocalCursorPos()
    if self.Dragging then
        local x = self.x + mousex - self.Dragging[1]
        local y = self.y + mousey - self.Dragging[2]

        -- Lock to screen bounds if screenlock is enabled
        if self:GetScreenLock() then
            x = math.Clamp(x, 0, self:GetParent():GetWide() - self:GetWide())
            y = math.Clamp(y, 0, self:GetParent():GetTall() - self:GetTall())
        end

        self.x, self.y = x, y
    end

    if self.Sizing then
        local x = mousex - self.Sizing[1]
        local y = mousey - self.Sizing[2]
        local px, py = self:GetPos()
        local pw, ph = self:GetParent():GetWide(), self:GetParent():GetTall()

        if x < self.m_iMinWidth then
            x = self.m_iMinWidth
        elseif x > pw - px and self:GetScreenLock() then
            x = pw - px
        end

        if y < self.m_iMinHeight then
            y = self.m_iMinHeight
        elseif y > ph - py and self:GetScreenLock() then
            y = ph - py
        end

        self:SetSize(x, y)
        self:SetCursor "sizenwse"
        return
    end

    if self.Hovered and self.m_bSizable
    and mousex > self:GetWide() - 20
    and mousey > self:GetTall() - 20 then
        self:SetCursor "sizenwse"
    elseif self.Hovered and self:GetDraggable() and mousey < 24 then
        self:SetCursor "sizeall"
    else
        self:SetCursor "arrow"
    end

    -- Don't allow the frame to go higher than 0
    local minw, maxw, maxh = self:GetWide(), 8, 8
    if self:GetScreenLock() or self.InitialScreenLock then
        minw, maxw, maxh = maxw --[[@as integer]], minw --[[@as integer]], self:GetTall()
        self.InitialScreenLock = nil
    end

    self.x = math.Clamp(self.x, 8 - minw, self:GetParent():GetWide() - maxw)
    self.y = math.Clamp(self.y, 0, self:GetParent():GetTall() - maxh)
    self:SetPos(self.x, self.y)
end

function PANEL:OnMousePressed()
    local mousex, mousey = self:LocalCursorPos()
    if self.m_bSizable and mousex > self:GetWide() - 20 and mousey > self:GetTall() - 20 then
        self.Sizing = {mousex - self:GetWide(), mousey - self:GetTall()}
        self:MouseCapture(true)
        return false
    end

    if self:GetDraggable() and mousey < 24 then
        self.Dragging = {mousex, mousey}
        self:MouseCapture(true)
        return false
    end

    return false
end

function PANEL:OnMouseReleased()
    if self.Sizing then self.Stat = nil end
    self.Dragging, self.Sizing = nil, nil
    self:MouseCapture(false)
    return false
end

derma.DefineControl("SplashSWEPs.DFrameChild", "", PANEL, "DFrame")
