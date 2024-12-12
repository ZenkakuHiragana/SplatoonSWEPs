
-- SplashSWEPs.DPropertySheetPlus
local PANEL = {}
AccessorFunc(PANEL, "m_iTabDock", "TabDock", FORCE_NUMBER)
AccessorFunc(PANEL, "m_iTabHeight", "TabHeight", FORCE_NUMBER)
AccessorFunc(PANEL, "m_iMaxTabSize", "MaxTabSize", FORCE_NUMBER)
AccessorFunc(PANEL, "m_iMinTabSize", "MinTabSize", FORCE_NUMBER)

---@cast PANEL PANEL.DPropertySheetPlus
---@class PANEL.DPropertySheetPlus : DPropertySheet, PANEL
---@field SetMaxTabSize fun(self, value: number)
---@field SetMinTabSize fun(self, value: number)
---@field SetTabHeight  fun(self, value: number)
---@field SetTabDock    fun(self, value: number)
---@field GetMaxTabSize fun(self): number
---@field GetMinTabSize fun(self): number
---@field GetTabHeight  fun(self): number
---@field GetTabDock    fun(self): number
---@field tabScroller   DHorizontalScroller
---@field Items         { Name: string, Tab: PANEL.DTabPlus, Panel: DPanel.DPropertySheetPlus }[]
---@field animFade      table
---@field Weapon        { Panel: DPanel, List: ContentContainer, Tab: PANEL.DTabPlus }
---@field Preference    table

function PANEL:Init()
    self:SetMaxTabSize(-1)
    self:SetMinTabSize(0)
    self:SetTabHeight(self:GetPadding())
    self:SetTabDock(BOTTOM)
    self.tabScroller:Dock(self:GetTabDock())
end

function PANEL:AddSheet(label, panel, material, NoStretchX, NoStretchY, Tooltip)
    ---@cast panel DPanel.DPropertySheetPlus
    ---@class DPanel.DPropertySheetPlus : DPanel
    ---@field NoStretchX boolean?
    ---@field NoStretchY boolean?

    if not IsValid(panel) then
        ErrorNoHalt("SplashSWEPs.DPropertySheetPlus: AddSheet tried to add invalid panel!")
        debug.Trace()
        return {}
    end

    local Sheet = {}
    Sheet.Name = label

    Sheet.Tab = vgui.Create("SplashSWEPs.DTabPlus", self) --[[@as PANEL.DTabPlus]]
    Sheet.Tab:SetTooltip(Tooltip)
    Sheet.Tab:Setup(label, self, panel, material)

    Sheet.Panel = panel
    Sheet.Panel.NoStretchX = NoStretchX
    Sheet.Panel.NoStretchY = NoStretchY
    Sheet.Panel:SetPos(self:GetPadding(), self:GetPadding())
    Sheet.Panel:SetVisible(false)

    panel:SetParent(self)

    self.Items[#self.Items + 1] = Sheet
    self.tabScroller:AddPanel(Sheet.Tab)
    self:SetTabHeight(math.max(self:GetTabHeight(), Sheet.Tab:GetTabHeight(true)))

    if not self:GetActiveTab() then
        self:SetActiveTab(Sheet.Tab)
        Sheet.Panel:SetVisible(true)
    end

    return Sheet
end

function PANEL:PerformLayout()
    local ActiveTab = self:GetActiveTab()
    local Padding = self:GetPadding()
    if not IsValid(ActiveTab) then return end

    local ActivePanel = ActiveTab:GetPanel() --[[@as DPanel.DPropertySheetPlus]]
    local TabHeight = self:GetTabHeight()
    self.tabScroller:SetTall(TabHeight)

    for _, v in pairs(self.Items) do
        local y = TabHeight - v.Tab:GetTabHeight(true)
        if v.Tab:GetPanel() == ActivePanel then
            if IsValid(v.Tab:GetPanel()) then v.Tab:GetPanel():SetVisible(true) end
            v.Tab:SetZPos(2)
        else
            if self:GetTabDock() == BOTTOM then y = 0 end
            if IsValid(v.Tab:GetPanel()) then v.Tab:GetPanel():SetVisible(false) end
            v.Tab:SetZPos(1)
        end

        v.Tab:SetPos(v.Tab:GetPos(), y)
        v.Tab:ApplySchemeSettings()
    end

    if IsValid(ActivePanel) then
        if ActivePanel.NoStretchX then
            ActivePanel:CenterHorizontal()
        else
            ActivePanel:SetWide(self:GetWide() - Padding * 2)
        end

        if ActivePanel.NoStretchY then
            ActivePanel:CenterVertical()
        else
            local y = TabHeight
            if self:GetTabDock() == BOTTOM then y = Padding end
            ActivePanel:SetPos(ActivePanel:GetPos(), y)
            ActivePanel:SetTall(self:GetTall() - TabHeight - Padding)
        end

        ActivePanel:InvalidateLayout()
    end

    -- Give the animation a chance
    self.animFade:Run()
end

function PANEL:Paint(w, h)
    local skin = derma.GetDefaultSkin()
    local Offset = self:GetTabHeight() - self:GetPadding()
    local Pos = {
        [TOP] = {0, Offset, 0, Offset},
        [BOTTOM] = {0, 0, 0, Offset},
        [LEFT] = {Offset, 0, Offset, 0},
        [RIGHT] = {0, 0, Offset, 0},
    }

    local dx, dy, dw, dh = unpack(Pos[self:GetTabDock()] or {})
    skin.tex.Tab_Control(assert(dx), dy, w - dw, h - dh)
    return false
end

derma.DefineControl("SplashSWEPs.DPropertySheetPlus", "", PANEL, "DPropertySheet")
