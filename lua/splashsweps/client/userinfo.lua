
-- Config menu

---@class ss
local ss = SplashSWEPs
if not (ss and ss.GetOption "enabled") then return end
local MatConfigIcon = "splashsweps/icons/config.png"
local MatWeaponListIcon = "splashsweps/icons/weaponlist.png"
local MatEquipped = Material "icon16/accept.png"
local MatFavorites = Material "icon16/star.png"
local PathFavorites = "splashsweps/record/favorites.txt"
local PathStats = "splashsweps/record/stats.txt"
---@class ss.WeaponFilters
---@field Equipped   boolean?
---@field Favorites  boolean?
---@field Sort       string?
---@field Type       string?
---@field Variations string?
local WeaponFilters = {}
local Favorites = {} ---@type table<string, boolean>
if file.Exists(PathFavorites, "DATA") then
    ---@type table<string, table>
    local f = util.JSONToTable(util.Decompress(file.Read(PathFavorites) or "") or "")
    for w in pairs(f or {}) do Favorites[w] = true end
end

hook.Add("ShutDown", "SplashSWEPs: Save player stats", function()
    if not file.Exists("splashsweps/record", "DATA") then file.CreateDir "splashsweps/record" end
    file.Write(PathFavorites, util.Compress(util.TableToJSON(Favorites)))
    if not ss.WeaponRecord[LocalPlayer()] then return end
    file.Write(PathStats, util.Compress(util.TableToJSON(ss.WeaponRecord[LocalPlayer()])))
end)

---@return Vector
local function GetColor() -- Get current color for preview model
    return ss.GetColor(ss.GetOption "inkcolor" --[[@as integer]]):ToVector()
end

---@param i PlayerType?
---@return string
---@return boolean
local function GetPlayermodel(i)
    local model = ss.Playermodel[i or ss.GetOption "playermodel"]
    or player_manager.TranslatePlayerModel(GetConVar "cl_playermodel":GetString())
    local exists = model and file.Exists(model, "GAME")
    if not exists and IsValid(LocalPlayer()) then
        model = LocalPlayer():GetModel()
    end

    return model, exists
end

---@class DModelPanel.UserInfo : DModelPanel, PANEL
---@field Angles    Angle
---@field AnimTime  number
---@field ClassName string?
---@field Pressed   boolean
---@field PressX    number
---@field PressY    number
---@field Weapon    CSEnt.UserInfo

---@class CSEnt.UserInfo : CSEnt, SplashWeaponBase
---@field Visible boolean

local function GeneratePreview(tab)
    tab.PreviewBase = vgui.Create("SplashSWEPs.DFrameChild", tab) --[[@as PANEL.DFrameChild]]
    tab.PreviewBase:SetSize(360, 540)
    tab.PreviewBase:SetTitle(ss.Text.PreviewTitle --[[@as string]])
    tab.PreviewBase:SetDraggable(true)
    tab.PreviewBase:SetSizable(true)
    tab.PreviewBase:SetPaintShadow(false)
    tab.PreviewBase:SetPos(ScrW(), ScrH())
    tab.PreviewBase:SetZPos(1)
    tab.PreviewBase.InitialScreenLock = true

    tab.Preview = tab.PreviewBase:Add "DModelPanel" --[[@as DModelPanel.UserInfo]]
    tab.Preview:Dock(FILL)
    tab.Preview:SetAnimated(true)
    tab.Preview:SetContentAlignment(5)
    tab.Preview:SetCursor "arrow"
    tab.Preview:SetDirectionalLight(BOX_BACK, color_white)
    tab.Preview:SetFOV(30)
    tab.Preview:AlignRight()
    tab.Preview:AlignTop()
    tab.Preview.Angles = Angle(0, 180)
    function tab.Preview:DragMousePress()
        self.PressX, self.PressY = gui.MousePos()
        self.Pressed = true
    end

    function tab.Preview:DragMouseRelease()
        self.Pressed = false
        return false
    end

    function tab.Preview:LayoutEntity(ent)
        if self:GetAnimated() then self:RunAnimation() end
        if self.Pressed then
            local mx, _ = input.GetCursorPos()
            self.Angles = self.Angles - Angle(0, (self.PressX or mx) - mx)
            self.PressX, self.PressY = gui.MousePos()
        end

        ent:SetAngles(self.Angles)
    end
end

local function GenerateWeaponIcons(tab)
    ---@class SplashWeaponBase.SpawnList : SplashWeaponBase
    ---@field Duration number
    ---@field Inked    number
    ---@field Recent   number
    tab.Weapon.List.IconList:Clear()
    local WeaponList = list.GetForEdit "Weapon" ---@type table<string, SplashWeaponBase.SpawnList>
    local SpawnList = {} ---@type SplashWeaponBase.SpawnList[]
    for _, c in ipairs(ss.WeaponClassNames) do
        local t = WeaponList[c]
        if not t then continue end
        t.Spawnable = true -- Write it here to be spawnable and not listed as normal weapon
        if WeaponFilters.Equipped and not LocalPlayer():HasWeapon(t.ClassName) then continue end
        if WeaponFilters.Favorites and not Favorites[t.ClassName] then continue end
        if WeaponFilters.Type and WeaponFilters.Type ~= t.Base then continue end
        if WeaponFilters.Variations == "Original" then continue end
        if WeaponFilters.Variations and WeaponFilters.Variations ~= "Original" and not t[WeaponFilters.Variations] then continue end

        local record = ss.WeaponRecord[LocalPlayer()]
        if record then
            t.Recent = record.Recent[t.ClassName] or 0
            t.Duration = record.Duration[t.ClassName] or 0
            t.Inked = record.Inked[t.ClassName] or 0
        end

        SpawnList[#SpawnList + 1] = t
    end

    for _, t in SortedPairsByMemberValue(SpawnList, WeaponFilters.Sort or "PrintName") do
        local icontest = spawnmenu.CreateContentIcon("weapon", nil, {
            material = "entities/" .. t.ClassName .. ".png",
            nicename = t.PrintName,
            spawnname = t.ClassName,
        }) --[[@as ContentIcon]]

        if not icontest then continue end
        ---@class ContentIcon.UserInfo : ContentIcon, PANEL
        ---@field Label DLabel Undocumented child control in ContentIcon
        ---@field Border number
        local icon = vgui.Create("ContentIcon", tab.Weapon.List)
        icon:SetContentType "weapon"
        icon:SetSpawnName(t.ClassName)
        icon:SetName(t.PrintName)
        icon:SetMaterial("entities/" .. t.ClassName .. ".png")
        icon:SetAdminOnly(t.AdminOnly)
        icon:SetColor(Color(135, 206, 250))
        icon.DoMiddleClick = icontest.DoMiddleClick
        icon.Click = icontest.DoClick
        icon.ClassID = t.ClassID or 0
        if ss.ProtectedCall(LocalPlayer().HasWeapon, LocalPlayer(), t.ClassName) then
            icon.Label:SetFont "DermaDefaultBold"
        end

        function icon:OpenMenu()
            local menu = DermaMenu() --[[@as DMenu]]
            if Favorites[t.ClassName] then
                menu:AddOption(ss.Text.Sidemenu.RemoveFavorite --[[@as string]], function()
                    Favorites[t.ClassName] = nil
                end):SetIcon "icon16/bullet_star.png"
            else
                menu:AddOption(ss.Text.Sidemenu.AddFavorite --[[@as string]], function()
                    Favorites[t.ClassName] = true
                end):SetIcon "icon16/star.png"
            end

            menu:AddOption("#spawnmenu.menu.copy", function()
                SetClipboardText(t.ClassName)
            end):SetIcon "icon16/page_copy.png"
            menu:AddOption("#spawnmenu.menu.spawn_with_toolgun", function()
                RunConsoleCommand("gmod_tool", "creator")
                RunConsoleCommand("creator_type", "3")
                RunConsoleCommand("creator_name", t.ClassName)
            end):SetIcon "icon16/brick_add.png"
            menu:AddSpacer()
            menu:AddOption("#spawnmenu.menu.delete", function()
                icon:Remove()
                hook.Run("SpawnlistContentChanged", icon)
            end):SetIcon "icon16/bin_closed.png"
            menu:Open()
        end

        function icon:DoClick()
            if LocalPlayer():HasWeapon(self:GetSpawnName()) then
                net.Start "SplashSWEPs: Strip weapon"
                net.WriteUInt(self.ClassID, ss.WEAPON_CLASSNAMES_BITS)
                net.SendToServer()
            else
                self:Click()
            end
        end

        local Paint = icon.Paint
        function icon:Paint(w, h)
            Paint(self, w, h)
            surface.SetDrawColor(color_white)
            local c = self:GetSpawnName()
            local x, y = self.Border + 8, self.Border + 8
            if LocalPlayer():HasWeapon(c) then
                surface.SetMaterial(MatEquipped)
                surface.DrawTexturedRect(x, y, 16, 16)
                x = x + 16 + 8
                self.Label:SetFont "DermaDefaultBold"
            else
                self.Label:SetFont "DermaDefault"
            end

            if not Favorites[c] then return end
            surface.SetMaterial(MatFavorites)
            surface.DrawTexturedRect(x, y, 16, 16)
        end

        icontest:SetVisible(false)
        icontest:Remove()
        tab.Weapon.List:Add(icon)
    end
end

---Used internally in Sandbox spawnmenu
---@class ContentContainer : DScrollPanel
---@field IconList DTileLayout
---@field SetTriggerSpawnlistChange fun(self, bTrigger: boolean)

---@param tab PANEL.DPropertySheetPlus
local function GenerateWeaponTab(tab)
    local w = ss.IsValid(LocalPlayer())
    local path = w and "entities/" .. w.ClassName .. ".png"
    ---@type { Panel: DPanel, List: ContentContainer, Tab: PANEL.DTabPlus }
    tab.Weapon = tab:AddSheet("", vgui.Create("DPanel", tab), path or MatConfigIcon)
    tab.Weapon.Panel:SetPaintBackground(false)
    tab.Weapon.List = vgui.Create("ContentContainer", tab.Weapon.Panel)
    tab.Weapon.List.IconList:MakeDroppable("SplashSWEPs", false)
    tab.Weapon.List.IconList:SetDropPos ""
    tab.Weapon.List:SetTriggerSpawnlistChange(false)
    tab.Weapon.List:Dock(FILL)
    function tab.Weapon.Tab:Think()
        local _w = ss.IsValid(LocalPlayer())
        local img = _w and "entities/" .. _w.ClassName .. ".png" or MatConfigIcon
        if img and img ~= self.Image:GetImage() then
            self.Image:SetImage(img)
        end
    end

    GenerateWeaponIcons(tab)
end

---@param tab PANEL.DPropertySheetPlus
local function GeneratePreferenceTab(tab)
    tab.Preference = tab:AddSheet("", vgui.Create "DPanel", "icon64/tool.png")
    tab.Preference.Panel:DockMargin(8, 8, 8, 8)
    tab.Preference.Panel:DockPadding(8, 8, 8, 8)

    -- "Playermodel:" Label
    tab.Preference.LabelModel = tab.Preference.Panel:Add "DLabel" --[[@as DLabel]]
    tab.Preference.LabelModel:Dock(TOP)
    tab.Preference.LabelModel:SetText("\n\n" .. ss.Text.Playermodel)
    tab.Preference.LabelModel:SetTextColor(tab.Preference.LabelModel:GetSkin().Colours.Label.Dark)
    tab.Preference.LabelModel:SizeToContents()

    -- Playermodel selection box
    tab.Preference.ModelSelector = tab.Preference.Panel:Add "DIconLayout" --[[@as DIconLayout]]
    tab.Preference.ModelSelector:Dock(TOP)
    tab.Preference.ModelSelector:SetSize(ScrW() * .16, ScrH() * .16)
    local size = tab.Preference.ModelSelector:GetWide() / #ss.Text.PlayermodelNames * 2
    for i, c in ipairs(ss.Text.PlayermodelNames --[=[@as string[]]=]) do
        local model, exists = GetPlayermodel(i)
        if not exists then continue end
        local item = tab.Preference.ModelSelector:Add "SpawnIcon" --[[@as SpawnIcon|PANEL]]
        item:SetSize(size, size)
        item:SetModel(model)
        item:SetTooltip(c)
        function item:DoClick() ss.SetOption("playermodel", i) end
        function item:Think()
            local new, newexists = GetPlayermodel(i)
            if newexists and model ~= new then
                self:SetModel(new)
                model = new
            end
        end
    end

    -- Ink resolution combo box
    tab.Preference.ResolutionSelector = tab.Preference.Panel:Add "DComboBox" --[[@as DComboBox]]
    tab.Preference.ResolutionSelector:SetSortItems(false)
    tab.Preference.ResolutionSelector:Dock(BOTTOM)
    tab.Preference.ResolutionSelector:SetSize(300, 17)
    tab.Preference.ResolutionSelector:SetTooltip(ss.Text.DescRTResolution --[[@as string]])
    tab.Preference.ResolutionSelector:SetValue(ss.Text.RTResolutions[ss.GetOption "rtresolution" + 1])
    for i = 1, #ss.Text.RTResolutions do
        tab.Preference.ResolutionSelector:AddChoice(ss.Text.RTResolutions[i])
    end

    -- "Ink buffer size:" Label
    tab.Preference.LabelResolution = tab.Preference.Panel:Add "DLabel" --[[@as DLabel]]
    tab.Preference.LabelResolution:Dock(BOTTOM)
    tab.Preference.LabelResolution:SetText(ss.Text.RTResolution --[[@as string]])
    tab.Preference.LabelResolution:SetTooltip(ss.Text.DescRTResolution --[[@as string]])
    tab.Preference.LabelResolution:SetTextColor(tab.Preference.LabelResolution:GetSkin().Colours.Label.Dark)
    tab.Preference.LabelResolution:SizeToContents()

    -- "Restart required" Label
    tab.Preference.LabelResetRequired = tab.Preference.Panel:Add "DLabel" --[[@as DLabel]]
    tab.Preference.LabelResetRequired:SetFont "DermaDefaultBold"
    tab.Preference.LabelResetRequired:Dock(BOTTOM)
    tab.Preference.LabelResetRequired:SetText(ss.Text.RTRestartRequired --[[@as string]])
    tab.Preference.LabelResetRequired:SetTextColor(Color(255, 128, 128))
    tab.Preference.LabelResetRequired:SetTooltip(ss.Text.DescRTResolution --[[@as string]])
    tab.Preference.LabelResetRequired:SetVisible(false)
    tab.Preference.LabelResetRequired:SizeToContents()

    local RTSize ---@type integer
    function tab.Preference.Panel:Think()
        local selected = tab.Preference.ResolutionSelector:GetSelectedID() or ss.GetOption "rtresolution" + 1
        selected = selected - 1
        tab.Preference.LabelResetRequired:SetVisible(RTSize and RTSize ~= ss.RenderTarget.Size[selected])
        if RTSize or not ss.RenderTarget.BaseTexture then return end
        RTSize = ss.RenderTarget.BaseTexture:Width()
    end

    function tab.Preference.ResolutionSelector:OnSelect(index, value, data)
        ss.SetOption("rtresolution", index - 1)
    end
end

---@class DCheckBoxLabel
---@field Button DCheckBox
---@field Label DLabel
---@param self DCheckBoxLabel
local function CheckBoxLabelPerformLayout(self)
    local x = self:GetIndent() or 0
    local y = math.floor((self:GetTall() - self.Button:GetTall()) / 2)
    self.Button:SetSize(15, 15)
    self.Button:SetPos(x, y)
    self.Label:SizeToContents()
    self.Label:SetPos(x + self.Button:GetWide() + 9, y)
end

---@class DCheckBoxLabel.UserInfo : DCheckBoxLabel, PANEL
---@class DCollapsibleCategory.UserInfo : DCollapsibleCategory, PANEL
---@field Contents DListLayout
---@param tab PANEL.DPropertySheetPlus
---@param side DCollapsibleCategory.UserInfo
local function GenerateFilter(tab, side)
    side:SetLabel(ss.Text.Sidemenu.FilterTitle --[[@as string]])
    side:SetContents(vgui.Create "DListLayout")
    side.Contents:SetPaintBackground(true)

    -- Filter: Equipment checkbox
    local eq = side.Contents:Add "DCheckBoxLabel" --[[@as DCheckBoxLabel.UserInfo]]
    eq:SetText(ss.Text.Sidemenu.Equipped --[[@as string]])
    eq:SizeToContents()
    eq:SetTall(eq:GetTall() + 2)
    eq:SetTextColor(eq:GetSkin().Colours.Label.Dark)
    eq.PerformLayout = CheckBoxLabelPerformLayout
    function eq:OnChange(checked)
        WeaponFilters.Equipped = checked
        GenerateWeaponIcons(tab)
    end

    -- Filter: Favorites
    local fav = side.Contents:Add "DCheckBoxLabel" --[[@as DCheckBoxLabel.UserInfo]]
    fav:SetText(ss.Text.Sidemenu.Favorites --[[@as string]])
    fav:SizeToContents()
    fav:SetTall(fav:GetTall() + 2)
    fav:SetTextColor(fav:GetSkin().Colours.Label.Dark)
    fav.PerformLayout = CheckBoxLabelPerformLayout
    function fav:OnChange(checked)
        WeaponFilters.Favorites = checked
        GenerateWeaponIcons(tab)
    end

    -- Filter: Weapon categories
    local wt = side.Contents:Add "DComboBox" --[[@as DComboBox]]
    local prefix = ss.Text.Sidemenu.WeaponTypePrefix
    wt:SetSortItems(false)
    wt:AddChoice(prefix .. ss.Text.Sidemenu.WeaponType.All, nil, true)
    for classname, categoryname in SortedPairs(ss.Text.CategoryNames --[=[@as string[]]=]) do
        wt:AddChoice(prefix .. categoryname, classname)
    end

    function wt:OnSelect(index, value, data)
        WeaponFilters.Type = data
        GenerateWeaponIcons(tab)
    end

    -- Filter: Attributes (Original, ...)
    local var = side.Contents:Add "DComboBox" --[[@as DComboBox]]
    prefix = ss.Text.Sidemenu.VariationsPrefix
    var:SetSortItems(false)
    var:AddChoice(prefix .. ss.Text.Sidemenu.Variations.All, nil, true)
    var:AddChoice(prefix .. ss.Text.Sidemenu.Variations.Original, "Original")
    function var:OnSelect(index, value, data)
        WeaponFilters.Variations = data
        GenerateWeaponIcons(tab)
    end

    -- Sort combobox
    local sort = side.Contents:Add "DComboBox" --[[@as DComboBox]]
    prefix = ss.Text.Sidemenu.SortPrefix
    sort:SetSortItems(false)
    sort:AddChoice(prefix .. ss.Text.Sidemenu.Sort.Name,    "PrintName", true)
    sort:AddChoice(prefix .. ss.Text.Sidemenu.Sort.Main,    "ClassID")
    sort:AddChoice(prefix .. ss.Text.Sidemenu.Sort.Sub,     "SubWeapon")
    sort:AddChoice(prefix .. ss.Text.Sidemenu.Sort.Special, "SpecialWeapon")
    sort:AddChoice(prefix .. ss.Text.Sidemenu.Sort.Recent,  "Recent")
    sort:AddChoice(prefix .. ss.Text.Sidemenu.Sort.Often,   "Duration")
    sort:AddChoice(prefix .. ss.Text.Sidemenu.Sort.Inked,   "Inked")
    function sort:OnSelect(index, value, data)
        WeaponFilters.Sort = data
        GenerateWeaponIcons(tab)
    end
end

---@param self DTree_Node.UserInfo
local function GenerateWeaponContents(self)
    if self.PropPanel then
        self.PropPanel.SideOption:Remove()
        if dragndrop.IsDragging() then return end
        self.PropPanel:Remove()
    end

    ---@class DPanel.UserInfo : DPanel, PANEL
    ---@field SideOption DCollapsibleCategory.UserInfo
    self.PropPanel = vgui.Create("DPanel", self.PanelContent)
    self.PropPanel:SetPaintBackground(false)
    self.PropPanel:SetVisible(false)

    local navbar = self.PanelContent.ContentNavBar
    self.PropPanel.SideOption = vgui.Create("DCollapsibleCategory", navbar) --[[@as DCollapsibleCategory.UserInfo]]
    self.PropPanel.SideOption:Dock(TOP)
    function self.PropPanel.SideOption.Think()
        local panel = self.PropPanel
        local opt = panel.SideOption
        if opt:IsVisible() ~= panel:IsVisible() then
            opt:SetVisible(panel:IsVisible())
            navbar.Tree:InvalidateLayout()
        end
    end

    local tab = vgui.Create "SplashSWEPs.DPropertySheetPlus" --[[@as PANEL.DPropertySheetPlus]]
    self.PropPanel:Add(tab)
    tab:Dock(FILL)
    tab:SetMaxTabSize(math.max(48, ScrH() * .08))
    tab:SetMinTabSize(math.max(48, ScrH() * .08))

    WeaponFilters = {}
    GeneratePreview(tab)
    GenerateWeaponTab(tab)
    GeneratePreferenceTab(tab)
    GenerateFilter(tab, self.PropPanel.SideOption)
end

hook.Add("PopulateWeapons", "SplashSWEPs: Generate weapon list",
---@class SpawnmenuContentPanel
---@field ContentNavBar ContentSidebar
---@class ContentSidebar
---@field Tree DTree
---@param PanelContent SpawnmenuContentPanel
---@param tree DTree
---@param node DTree_Node
function(PanelContent, tree, node)
    ---@class DTree_Node.UserInfo : DTree_Node, PANEL
    ---@field PanelContent SpawnmenuContentPanel
    ---@field PropPanel DPanel
    node = tree:AddNode("SplashSWEPs", MatWeaponListIcon)
    node.PanelContent = PanelContent
    node.DoPopulate = GenerateWeaponContents
    local OriginalThink = node.Think
    local scrw, scrh = ScrW(), ScrH()
    function node:DoClick()
        GenerateWeaponContents(self)
        PanelContent:SwitchPanel(self.PropPanel)
    end

    function node:Think()
        ss.ProtectedCall(OriginalThink, node)
        if ScrW() == scrw and ScrH() == scrh then return end
        scrw, scrh = ScrW(), ScrH()
        GenerateWeaponContents(self)
    end
end)
