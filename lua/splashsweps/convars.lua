
---@class ss
local ss = SplashSWEPs
if not ss then return end

local cvartree = require "greatzenkakuman/cvartree" or greatzenkakuman.cvartree
local HelpTextPrefix = "Splash SWEPs: "
local RealmPrefix = {[true] = "sv", [false] = "cl"}
local InkColors = ss.InkColors        -- These are needed when the SWEPs are disabled.
local ColorNames = ss.Text.ColorNames --

cvartree.OverrideHelpText = ss.Text.OverrideHelpText
cvartree.SetCVarPrefix("splashsweps", { printname = ss.Text.Category --[[@as string]] })

---Stores value to cvarname serverside
---@param cvarname string
---@param value integer
function ss.SetCVarClientside(cvarname, value)
    if ss.sp or cvarname:StartsWith "sv_" then
        net.Start "greatzenkakuman.cvartree.adminchange"
        net.WriteString(cvarname)
        net.WriteString(tostring(value))
        net.SendToServer()
    elseif not GetGlobalBool "SplashSWEPs: IsDedicated" and LocalPlayer():IsAdmin() then
        net.Start "greatzenkakuman.cvartree.sendchange"
        net.WriteString(cvarname)
        net.WriteString(tostring(value))
        net.SendToServer()
    else
        local cvar = GetConVar(cvarname)
        if not cvar then return end
        cvar:SetInt(value)
    end
end

---Custom function for generating color picker GUI
---@param parent_panel DForm
---@param paneltable   cvartree.CVarItem
---@param cvar         ConVar
---@param admin        boolean
---@return DPanel
local function MakeColorGUI(parent_panel, paneltable, cvar, admin)
    local cvarname = cvar:GetName()
    local element = vgui.Create("DPanel", parent_panel)
    local label = Label(paneltable.options.printname, element)
    local colorpicker = vgui.Create("DIconLayout", element)
    element:DockPadding(4, 0, 4, 4)
    label:Dock(TOP)
    label:SetTextColor(label:GetSkin().Colours.Label.Dark)
    colorpicker:Dock(FILL)
    colorpicker:SetSpaceX(5)
    colorpicker:SetSpaceY(5)
    colorpicker:SetStretchHeight(true)
    for i, c in ipairs(InkColors) do
        local item = vgui.Create("DColorButton", colorpicker)
        item:SetSize(32, 32)
        item:SetColor(c)
        item:SetTooltip(ColorNames[i])
        item:SetContentAlignment(5)
        ---@cast item +PANEL
        function item:Think()
            item:SetText(i == cvar:GetInt() and "X" or "")
        end
        function item:DoClick()
            ss.SetCVarClientside(cvarname, i)
        end
    end

    colorpicker:Layout()
    ---@cast element +PANEL, +cvartree.Panel
    function element:PerformLayout()
        colorpicker:InvalidateLayout(true)
        self:SizeToChildren(false, true)
        if not self.CheckBox then return end
        self.CheckBox:DockMargin(0, 4, 0, self:GetTall() - 15 - 4)
    end

    ---@cast element -PANEL, -cvartree.Panel
    return element
end

---Custom function for change callback of color picker
---@param paneltable cvartree.CVarItem
---@return fun(self: Panel, value: number)
local function MakeOnChangeDerma(paneltable)
    return function(self, value)
        ---@cast self +cvartree.Panel
        ss.SetCVarClientside(self.CVarName, value)
    end
end

---Custom function for change callback using the console of color picker
---@param paneltable cvartree.CVarItem
---@return fun(convar: string, old: string, new: string)
local function MakeOnChangeCVar(paneltable)
    return function(convar, old, new)
    end
end

---@alias ss.RecursiveText string|{[string]: ss.RecursiveText}

---Automatically generates ConVars using given tables
---@param opt      cvartree.CVarCategory Pairs of CVar name and definition
---@param helptext ss.RecursiveText
---@param guitext  ss.RecursiveText
local function RegisterConVars(opt, helptext, guitext)
    for cvarname, cvartable in pairs(opt --[[@as table<string, cvartree.CVarOption>]] ) do
        if cvarname:StartsWith "__" then continue end
        if not istable(cvartable) or cvartable[1] ~= nil then
            if not istable(cvartable) then cvartable = { cvartable --[[@as boolean]] } end
            ---@cast helptext table<string, string>
            ---@cast guitext  table<string, string>
            local options = table.Copy(cvartable)
            options[1] = nil
            options.printname = guitext[cvarname]
            options.helptext = guitext[cvarname .. "_help"]
            if options.type == "color" then
                options.cvaronchange = MakeOnChangeCVar
                options.dermaonchange = MakeOnChangeDerma
                options.enablepanel = nil
                options.makepanel = MakeColorGUI
                options.typeconversion = tonumber
            end

            cvartree.AddCVar(cvarname, cvartable[1], HelpTextPrefix .. helptext[cvarname], options)
        else
            ---@cast cvartable cvartree.CVarCategory
            cvartree.AddCVarPrefix(cvarname, {
                subcategory = cvartable.__subcategory,
                closed = cvartable.__closed,
                printname =
                ss.Text.CategoryNames[cvarname] -- Weapon category name (Shooters, Rollers, etc.)
                or ss.Text.PrintNames[cvarname] -- Weapon name (.52 Gallon, etc.)
                or guitext[cvarname].__printname --[[@as string]], -- Other categories (Gain, NPC ink color, etc.)
            })

            RegisterConVars(cvartable, helptext[cvarname], guitext[cvarname])
            cvartree.RemoveCVarPrefix()
        end
    end
end

RegisterConVars(ss.Options, ss.Text.CVars, ss.Text.Options)
if CLIENT then cvartree.AddGUI "splashsweps" end

---Retrieves full ConVar name from string array
---@param name string|string[]
---@param serverside boolean?
---@return string?
function ss.GetConVarName(name, serverside)
    local cvar = (RealmPrefix[serverside] or "") .. "_splashsweps"
    if isstring(name) then
        return cvar .. "_" .. name
    elseif istable(name) then ---@cast name -string
        for _, n in ipairs(name) do cvar = cvar .. "_" .. n end
        return cvar
    end
end

---Retrieves ConVar object from string array
---@param name       string|string[]
---@param serverside boolean?
---@return ConVar
function ss.GetConVar(name, serverside)
    local prefix = serverside == nil and "cl" or ""
    return GetConVar(prefix .. ss.GetConVarName(name, serverside))
end

---Fetch the given option.
---@param name string|string[] The option name
---@param ply  Player?         Whose option the function will return
---@return cvartree.GetPreferenceReturns
function ss.GetOption(name, ply)
    local nametable = {"splashsweps"}
    if isstring(name) then name = { name --[[@as string]] } end
    ---@cast name -string
    for _, n in ipairs(name) do nametable[#nametable + 1] = n:lower() end
    return cvartree.GetPreference(nametable, ply)
end

---Set a value to given option.
---@param name string|string[] The option name
---@param value any The value to set
---@return cvartree.SetPreferenceReturns
function ss.SetOption(name, value)
    local nametable = {"splashsweps"}
    if isstring(name) then name = { name --[[@as string]] } end
    ---@cast name -string
    for _, n in ipairs(name) do nametable[#nametable + 1] = n:lower() end
    return cvartree.SetPreference(nametable, value)
end
