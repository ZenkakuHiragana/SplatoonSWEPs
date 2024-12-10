
-- SplashSWEPs.DTabPlus
local PANEL = {}
---@cast PANEL PANEL.DTabPlus
---@class PANEL.DTabPlus : DTab, PANEL
---@field Image DImage
---@field GetTabHeight     fun(self, Active: boolean?): number
---@field GetPropertySheet fun(self): Panel # Undocumented DTab method
---@field SetPanel         fun(self, value: Panel) # Undocumented DTab method
---@field SetPropertySheet fun(self, value: Panel) # Undocumented DTab method
---@field Setup            fun(self, label: string, pPropertySheet: PANEL.DPropertySheetPlus, pPanel: Panel, strMaterial: string)
---@field PaintActiveTab   fun(self, skin: table, w: integer, h: integer)

function PANEL:GetTabHeight(Active)
    local fix = self.Image and 4 or 8
    local h = self.Image and self.Image:GetTall() or select(2, self:GetContentSize())
    if Either(Active ~= nil, Active, self:IsActive()) then
        return fix + h + 8
    else
        return fix + h
    end
end

function PANEL:Setup(label, pPropertySheet, pPanel, strMaterial)
    self:SetText(label)
    self:SetPropertySheet(pPropertySheet)
    self:SetPanel(pPanel)
    if strMaterial then
        self.Image = vgui.Create("DImage", self) --[[@as DImage]]
        self.Image:SetImage(strMaterial)
        self.Image:SizeToContents()
        self:InvalidateLayout(true)
    end
end

function PANEL:PerformLayout()
    self:ApplySchemeSettings()
    if not self.Image then return end
    local y = 3
    local PropertySheet = self:GetPropertySheet() --[[@as PANEL.DPropertySheetPlus]]
    local Max = PropertySheet:GetMaxTabSize()
    local Min = PropertySheet:GetMinTabSize()
    local Width = math.Clamp(self.Image:GetWide(), Min, Max > 0 and Max or 32768)
    local Height = math.Clamp(self.Image:GetTall(), Min, Max > 0 and Max or 32768)
    if PropertySheet:GetTabDock() == BOTTOM then
        y = 1 + (self:IsActive() and PropertySheet:GetPadding() or 0)
    end

    self.Image:SetPos(7, y)
    self.Image:SetSize(Width, Height)

    if self:GetText():len() == 0 then
        self.Image:CenterHorizontal()
    end

    if self:IsActive() then
        self.Image:SetImageColor(color_white)
    else
        self.Image:SetImageColor(ColorAlpha(color_white, 155))
    end
end

function PANEL:ApplySchemeSettings()
    local PropertySheet = self:GetPropertySheet() --[[@as PANEL.DPropertySheetPlus]]
    local TabHeight = PropertySheet:GetTabHeight()
    local Padding = PropertySheet:GetPadding()
    local ExtraInset = 10
    local InsetY = -4
    if self.Image then
        ExtraInset = ExtraInset + self.Image:GetWide()
    end

    if PropertySheet:GetTabDock() == TOP and self:IsActive() then
        InsetY = InsetY - Padding
    end

    self:SetTextInset(ExtraInset, InsetY)
    self:SetSize(self:GetContentSize() + 10, self:GetTabHeight())
    self:SetContentAlignment(1)

    if TabHeight then
        local y = TabHeight - self:GetTabHeight(true)
        if PropertySheet:GetTabDock() == BOTTOM then
            y = self:IsActive() and 0 or Padding
        end

        self:SetPos(self:GetPos(), y)
    end

    -- DLabel.ApplySchemeSettings(self)
end

function PANEL:Paint(w, h)
    local skin = derma.GetDefaultSkin()
    local PropertySheet = self:GetPropertySheet() --[[@as PANEL.DPropertySheetPlus]]
    local dock = PropertySheet:GetTabDock()
    local y = 0
    local func = {
        [TOP] = {
            [true] = {skin.tex.TabT_Active, 0, h},
            [false] = {skin.tex.TabT_Inactive, 0, h},
        },
        [BOTTOM] = {
            [true] = {skin.tex.TabB_Active, 0, h},
            [false] = {skin.tex.TabB_Inactive, 0, h},
        },
        [LEFT] = {
            [true] = {skin.tex.TabL_Active, 0, h},
            [false] = {skin.tex.TabL_Inactive, 0, h},
        },
        [RIGHT] = {
            [true] = {skin.tex.TabR_Active, 0, h},
            [false] = {skin.tex.TabR_Inactive, 0, h},
        },
    }

    local paint = (func[dock] or {})[self:IsActive()]
    paint, y, h = unpack(paint or {})
    if not isfunction(paint) then return false end
    paint(0, y, w, h)
    return false
end

function PANEL:PaintActiveTab(skin, w, h)
    skin.tex.TabT_Active(0, 0, w, h)
end

derma.DefineControl("SplashSWEPs.DTabPlus", "", PANEL, "DTab")
