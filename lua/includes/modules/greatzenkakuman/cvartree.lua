AddCSLuaFile()
local serverflags = {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE}
local clientflags = {FCVAR_ARCHIVE, FCVAR_USERINFO}
local cvarlist    = {} ---@type cvartree.CVarItem
local cvarprefix  = {} ---@type string[]
local cvarseparator = "_"
module("greatzenkakuman.cvartree", package.seeall)
local cvartree = greatzenkakuman.cvartree or {}
cvartree.OverrideHelpText = "Override this setting with serverside value"

---@alias cvartree.OnChangeCVar fun(self: cvartree.CVarItem): fun(convar: string, old: string, new: string)
---@alias cvartree.DermaOnChange fun(self: cvartree.CVarItem): fun(convar: Panel, value: string|number|boolean)
---@alias cvartree.OnMakePanel fun(parent: DForm, self: cvartree.CVarItem, cvar: ConVar, admin: boolean?): DPanel
---@alias cvartree.OnTypeChange fun(value: any): any

---@class cvartree.Panel : Panel
---@field CheckBox DCheckBox?
---@field CVarName string
---@field Label    DLabel

---@alias cvartree.PreferenceTypes boolean|string|number
---@alias cvartree.AddCVarPrefixReturns 
---| fun(prefix: string|string[], options: cvartree.CVarOption): cvartree.AddCVarPrefixReturns
---@alias cvartree.RemoveCVarPrefixReturns fun(n: integer?): cvartree.RemoveCVarPrefixReturns
---@alias cvartree.SetPreferenceReturns (fun(cvar: string[], value: any): cvartree.SetPreferenceReturns)?
---@alias cvartree.GetPreferenceReturns
---| cvartree.PreferenceTypes?
---| fun(cvar: string|string[]?, ply: Player?): cvartree.GetPreferenceReturns

---@class cvartree.CVarCategory
---@field __closed      boolean?
---@field __subcategory boolean?
---@field [string] cvartree.CVarCategory|cvartree.CVarOption|boolean

---@class cvartree.CVarItem
---@field options     cvartree.CVarOption? Various configurations for this preference
---@field location    string[]?            The path of this preference
---@field sv          ConVar?              Serverside ConVar object
---@field cl          ConVar?              Clientside ConVar object
---@field iscvarlayer boolean?             Indicates if this is a layer to hold other preferences
---@field panel       Panel?
---@field paneladmin  Panel?
---@field [string]    cvartree.CVarItem   [Preference name] = its details

---@class cvartree.CVarOption : { [1]: boolean|number? }
---@field bottomorder    integer?                The order from the bottom of the GUI
---@field clientside     boolean?                Indicates if this only exists clientside
---@field closed         boolean?                Indicates if this makes its collapsible category closed by default
---@field cvaronchange   cvartree.OnChangeCVar?
---@field decimals       integer?                The decimal places to round to
---@field dermaonchange  cvartree.DermaOnChange?
---@field enablepanel    any?
---@field helptext       string?                 Help text in the console
---@field hidden         boolean?                Indicates if this doesn not generate GUI panel
---@field makepanel      cvartree.OnMakePanel?
---@field max            number?                 Maximum value for DNumSlider
---@field min            number?                 Minimum value for DNumSlider
---@field order          integer?                The order placed in the GUI
---@field printname      string?                 Name shown in GUI
---@field serverside     boolean?                Indicates if this only exists serverside
---@field subcategory    boolean?                Indicates if this CVarLayer does not create collapsible category
---@field type           string|"color"?         Type of the value
---@field typeconversion cvartree.OnTypeChange?

---Creates a new category
---@param nametable string[] e.g. { "splashsweps", "weapon_splashsweps_shooter" }
---@return string                 "_splashsweps_weapon_splashsweps_shooter"
---@return cvartree.CVarItem
local function CreateCategory(nametable)
    local n, placeholder = "", cvarlist
    for _, s in ipairs(nametable) do
        n = string.format("%s%s%s", n, cvarseparator, s)
        placeholder[s] = placeholder[s] or { iscvarlayer = true, options = {} }
        placeholder = placeholder[s] ---@type cvartree.CVarItem
    end

    return n, placeholder
end

---Retrieves ConVar list
---@return cvartree.CVarItem
function cvartree.GetCVarList() return cvarlist end

---Retrieves current ConVar prefixes (i.e. current depth of the layer)
---@return string[]
function cvartree.GetCVarPrefix() return cvarprefix end

---Sets ConVar prefixes by given parameters
---@param prefix  string|string[]
---@param options cvartree.CVarOption?
---@return cvartree.AddCVarPrefixReturns
function cvartree.SetCVarPrefix(prefix, options)
    table.Empty(cvarprefix)
    return cvartree.AddCVarPrefix(prefix, options)
end

---Adds a prefix to the current ConVar prefixes
---@param prefix  string|string[] The name of prefix(es) to append
---@param options cvartree.CVarOption?
---@return cvartree.AddCVarPrefixReturns
function cvartree.AddCVarPrefix(prefix, options)
    if isstring(prefix) then --[[@cast prefix string]]
        cvarprefix[#cvarprefix + 1] = prefix:lower()
        local placeholder = select(2, CreateCategory(cvarprefix))
        if istable(options) then --[[@cast options -?]]
            table.Merge(placeholder.options, options)
        end
    elseif istable(prefix) then --[=[@cast prefix string[]]=]
        for _, s in ipairs(prefix) do cvartree.AddCVarPrefix(s) end
    end

    return cvartree.AddCVarPrefix
end

---Removes (pops) the last n prefix(es) from the current ConVar prefixes
---@param n integer?
---@return cvartree.RemoveCVarPrefixReturns
function cvartree.RemoveCVarPrefix(n)
    for _ = 1, n or 1 do cvarprefix[#cvarprefix] = nil end
    return cvartree.RemoveCVarPrefix
end

---Adds a ConVar at current prefixes
---@param name     string|string[]      The name of CVar.  Passing a string array for absolute path
---@param default  boolean|number       Default value
---@param helptext string               Help text on the console
---@param options  cvartree.CVarOption? ConVar options
function cvartree.AddCVar(name, default, helptext, options)
    local nametable ---@type string[]
    if istable(name) then ---@cast name string[]
        nametable = name
    else ---@cast name string
        nametable = table.Copy(cvarprefix)
        nametable[#nametable + 1] = name:lower()
    end

    options = options or {} ---@type cvartree.CVarOption
    name, nametable[#nametable] = nametable[#nametable], nil
    local n, placeholder = CreateCategory(nametable)

    if #n == 0 then return end
    local cvartable = placeholder[name] or {}
    if not options.clientside then
        local svdefault = not (options and options.serverside) and -1 or default
        local svname = string.format("sv%s%s%s", n, cvarseparator, name)
        if isbool(svdefault) then svdefault = svdefault and 1 or 0 end
        cvartable.sv = CreateConVar(svname, tostring(svdefault), serverflags, helptext)
    end

    if not options.serverside then
        local clname = string.format("cl%s%s%s", n, cvarseparator, name)
        local cldefault = isbool(default) and (default and 1 or 0) or default
        cvartable.cl = CreateConVar(clname, tostring(cldefault), clientflags, helptext)
    end

    options.type = options.type == nil and type(default) or options.type
    cvartable.options = options
    cvartable.location = nametable
    placeholder[name] = cvartable
end

---Retrieves a table of ConVars
---@param cvar string|string[]?
---@param root cvartree.CVarItem?
---@return cvartree.CVarItem
function cvartree.GetCVarTable(cvar, root)
    local t = root or cvarlist
    if isstring(cvar) then
        cvar = { cvar --[[@as string]] }
    end

    ---@cast cvar -string
    for _, n in ipairs(cvar or {}) do
        t = assert(t[n:lower()], "GreatZenkakuMan's Module: preference is not found.")
    end

    return t
end

local TranslateType = {
    boolean = tobool,
    number = tonumber,
}
---Retrieves current CVar value for given player
---@param t   cvartree.CVarItem
---@param ply Entity?
---@return cvartree.PreferenceTypes
function cvartree.GetValue(t, ply)
    local isplayer = IsValid(ply) and ply--[[@as Entity]]:IsPlayer()
    local servervalue = t.sv and t.sv:GetString()
    local clientvalue = t.cl and t.cl:GetString()
    local override = tonumber(servervalue) ~= -1
    local translate = TranslateType[t.options.type] or t.options.typeconversion
    if t.cl and isplayer then ---@cast ply Player
        clientvalue = ply:GetInfo(t.cl:GetName())
        if clientvalue == "" then
            clientvalue = t.cl:GetDefault()
        end
    end
    if translate then
        if servervalue then servervalue = translate(servervalue) end
        if clientvalue then clientvalue = translate(clientvalue) end
    end
    if t.options.clientside then return clientvalue end
    if t.options.serverside then return servervalue end
    if override then return servervalue end
    return clientvalue
end

---Retrieves current CVar value from its name recursively for given player
---@param cvar string|string[]
---@param ply  Entity?
---@param root cvartree.CVarItem?
---@return cvartree.GetPreferenceReturns
function cvartree.GetPreference(cvar, ply, root)
    local t = cvartree.GetCVarTable(cvar, root)
    if not (t.cl or t.sv) then
        return function(c, p) return cvartree.GetPreference(c, p, t) end
    end

    return cvartree.GetValue(t, ply)
end

---Sets CVar value from its name recursively
---@param cvar string[]
---@param value any
---@param root cvartree.CVarItem?
---@return cvartree.SetPreferenceReturns
function cvartree.SetPreference(cvar, value, root)
    local t = cvartree.GetCVarTable(cvar, root)
    local str = tostring(value)
    if not (t.cl or t.sv) then
        return function(c, v) return cvartree.SetPreference(c, v, t) end
    end
    if not t.options.clientside then
        if CLIENT and game.SinglePlayer() then
            net.Start "greatzenkakuman.cvartree.sendchange"
            net.WriteString("sv" .. cvarseparator .. table.concat(cvar, cvarseparator))
            net.WriteString(str)
            net.SendToServer()
        else
            t.sv:SetString(tostring(value))
        end
    end
    if not t.options.serverside then
        if value == nil then str = "" end
        if isbool(value) then str = value and "1" or "0" end
        if CLIENT and game.SinglePlayer() then
            net.Start "greatzenkakuman.cvartree.sendchange"
            net.WriteString("cl" .. cvarseparator .. table.concat(cvar, cvarseparator))
            net.WriteString(str)
            net.SendToServer()
        else
            t.cl:SetString(str)
        end
    end
end

---Iterates over defined preferences
---@param root string|string[]?
---@return fun(_table: cvartree.CVarItem): string, cvartree.CVarItem
function cvartree.IteratePreferences(root)
    local t = root and cvartree.GetCVarTable(root) or cvarlist
    ---@param r cvartree.CVarItem?
    local function f(r)
        for prefname, preftable in pairs(r or t --[[@as table<string, cvartree.CVarItem>]]) do
            if istable(preftable) then
                if preftable.iscvarlayer then
                    f(preftable)
                elseif preftable.cl or preftable.sv then
                    coroutine.yield(prefname, preftable)
                end
            end
        end
    end

    return coroutine.wrap(f)
end

if SERVER then
    util.AddNetworkString "greatzenkakuman.cvartree.adminchange"
    util.AddNetworkString "greatzenkakuman.cvartree.sendchange"
    util.AddNetworkString "greatzenkakuman.cvartree.synchronizeconvars"
    net.Receive("greatzenkakuman.cvartree.adminchange", function(_, ply)
        if not ply:IsAdmin() then return end
        local cvar = GetConVar(net.ReadString())
        if not cvar then return end
        cvar:SetString(net.ReadString())
    end)

    net.Receive("greatzenkakuman.cvartree.sendchange", function(_, ply)
        local name = net.ReadString()
        if not name:StartsWith "cl_" then return end
        local cvar = GetConVar(name)
        if not cvar then return end
        cvar:SetString(net.ReadString())
    end)

    net.Receive("greatzenkakuman.cvartree.synchronizeconvars", function(_, ply)
        for _, cvartable in cvartree.IteratePreferences() do
            if cvartable.options and cvartable.options.serverside then
                local str = cvartable.sv:GetString() -- It's really hacky way
                cvartable.sv:SetString(str .. "*") -- to synchronize CVars,
                cvartable.sv:SetString(str) -- but whatever.
            end
        end
    end)

    return
end

hook.Add("PlayerConnect", "greatzenkakuman.cvartree.synchronizeconvars", function(name, ply)
    net.Start "greatzenkakuman.cvartree.synchronizeconvars"
    net.SendToServer()
end)

-- PreferenceTable -> pt, IsEnabledPanel -> e
local idprefix = "GreatZenkakuMan's Module: CVarTree"

---Enables or disables the Derma panel for given preference definition
---@param panel     Panel
---@param panelType string
---@param enabled   boolean
---@param func      fun(panel: Panel, enabled: boolean)?
local function EnablePanel(panel, panelType, enabled, func)
    panel:SetEnabled(enabled)
    for _, child in ipairs(panel:GetChildren()) do child:SetEnabled(enabled) end
    if panelType == "number" then ---@cast panel DNumSlider
        local label = panel.Label --[[@as DLabel]]
        local skin = enabled and "Dark" or "Default"
        local textentry = panel:GetTextArea()
        label:SetTextColor(label:GetSkin().Colours.Label[skin])
        textentry:SetTextColor(textentry:GetSkin().Colours.Label[skin])
        for _, child in ipairs(panel:GetChildren()) do
            child:SetMouseInputEnabled(enabled)
            child:SetKeyboardInputEnabled(enabled)
        end
    elseif isfunction(func) then ---@cast func -?
        func(panel, enabled)
    end
end

---Generates OnChange event for given prefernce definition
---@param pt cvartree.CVarItem
---@return fun(convar: string, old: string, new: string)
local function GetCVarOnChange(pt)
    if pt.options.type == "boolean" then
        return function(convar, old, new)
            if not (IsValid(LocalPlayer()) and LocalPlayer():IsAdmin()) then return end
            if pt.panel then pt.panel:SetChecked(tobool(new)) end
            if pt.paneladmin then pt.paneladmin:SetChecked(tobool(new)) end
        end
    elseif pt.options.type == "number" then
        return function(convar, old, new)
            if not (IsValid(LocalPlayer()) and LocalPlayer():IsAdmin()) then return end
            if pt.panel and not pt.panel:IsEditing() then pt.panel:SetValue(tonumber(new)) end
            if pt.paneladmin and not pt.paneladmin:IsEditing() then pt.paneladmin:SetValue(tonumber(new)) end
        end
    elseif isfunction(pt.options.cvaronchange) then
        return pt.options.cvaronchange(pt)
    else
        error "GreatZenkakuMan's Module: Can't create CVar change callback."
    end
end

---Generates callback function called when the value is changed using Derma panel
---@param pt cvartree.CVarItem
---@return fun(self: Panel, value: string|number|boolean)?
local function GetDermaPanelOnChange(pt)
    local panel = pt.paneladmin
    if not panel then return end
    if pt.options.type == "boolean" then
        ---@cast panel DCheckBoxLabel
        function panel:OnChange(value)
            ---@cast self +cvartree.Panel
            net.Start "greatzenkakuman.cvartree.adminchange"
            net.WriteString(self.CVarName)
            net.WriteString(value and "1" or "0")
            net.SendToServer()
        end

        return panel.OnChange
    elseif pt.options.type == "number" then
        ---@cast panel DNumSlider
        function panel:OnValueChanged(value)
            value = math.Round(value, self:GetDecimals())
            ---@cast self +cvartree.Panel
            net.Start "greatzenkakuman.cvartree.adminchange"
            net.WriteString(self.CVarName)
            net.WriteString(tostring(value))
            net.SendToServer()
        end

        return panel.OnValueChanged
    elseif isfunction(pt.options.dermaonchange) then
        return pt.options.dermaonchange(pt)
    end
end

---Make a Derma element on the panel for given preference definition
---@param parent DForm
---@param admin  boolean?
---@param pt     cvartree.CVarItem
local function MakeElement(parent, admin, pt)
    local cvar = Either(admin, pt.sv, pt.cl)
    local panelname = admin and "paneladmin" or "panel"
    if not cvar or Either(admin, pt.options.clientside, pt.options.serverside) then return end
    if game.SinglePlayer() and admin and not pt.options.serverside then return end
    local panel = nil
    if pt.options.type == "boolean" then
        panel = vgui.Create("DCheckBoxLabel", parent)
        panel:SetTextColor(panel:GetSkin().Colours.Label.Dark)
        panel:SetValue(cvar:GetBool())
    elseif pt.options.type == "number" then
        panel = vgui.Create("DNumSlider", parent)
        panel:SetMinMax(pt.options.min, pt.options.max)
        panel:SetDecimals(pt.options.decimals or 0)
        panel:SetValue(cvar:GetInt())
        ---@cast panel +cvartree.Panel
        panel.Label:SetTextColor(panel.Label:GetSkin().Colours.Label.Dark)
    elseif isfunction(pt.options.makepanel) then
        panel = pt.options.makepanel(parent, pt, cvar, admin)
    else
        error "GreatZenkakuMan's Module: Can't create VGUI element."
    end

    ---@cast panel +cvartree.Panel
    panel.CVarName = cvar:GetName()
    panel:SetText(pt.options.printname)
    pt[panelname] = panel ---@type Panel

    local override = nil
    if admin then
        local dermaonchange = GetDermaPanelOnChange(pt)
        cvars.AddChangeCallback(panel.CVarName, GetCVarOnChange(pt))

        if not pt.options.serverside then
            local checked = cvar:GetInt() ~= -1
            EnablePanel(pt.paneladmin, pt.options.type, checked)
            override = vgui.Create("DCheckBox", parent)
            override:SetTooltip(cvartree.OverrideHelpText)
            override:SetValue(checked)
            cvars.AddChangeCallback(panel.CVarName,
            ---@param convar string
            ---@param old string
            ---@param new string
            function(convar, old, new)
                if not (IsValid(LocalPlayer()) and LocalPlayer():IsAdmin()) then return end
                local chk = tonumber(new) ~= -1
                override:SetChecked(chk)
                EnablePanel(pt.paneladmin, pt.options.type, chk)
            end)

            ---@param chk boolean
            function override:OnChange(chk)
                EnablePanel(pt.paneladmin, pt.options.type, chk)
                if dermaonchange then dermaonchange(pt.paneladmin, pt.cl:GetDefault()) end
                net.Start "greatzenkakuman.cvartree.adminchange"
                net.WriteString(panel.CVarName)
                net.WriteString(chk and pt.cl:GetDefault() or "-1")
                net.SendToServer()
            end
        end
    elseif isfunction(panel.SetConVar) then
        panel:SetConVar(cvar:GetName())
    end

    if not admin and pt.sv then
        ---@cast panel +PANEL
        function panel:Think()
            EnablePanel(self, pt.options.type, pt.sv:GetInt() == -1, pt.options.enablepanel)
        end
    end

    parent:AddItem(override or panel, override and panel)
    if override then
        local t = (panel:GetTall() - 15) / 2
        local b = t + (t > math.floor(t) and 1 or 0)
        override:DockMargin(0, math.floor(t), 0, b)
        override:SetWidth(15)
        panel.CheckBox = override
        panel:Dock(TOP)
        panel:DockMargin(10, 0, 0, 0)
    end

    if not pt.options.helptext then return end
    panel:SetTooltip(pt.options.helptext)
end

---Make a group of Derma elements for given preference category
---@param panel     DForm
---@param nametable string[]
---@param admin     boolean?
local function MakeGUI(panel, nametable, admin)
    local categories  = {} ---@type table<string, cvartree.CVarItem>
    local preferences = {} ---@type table<string, cvartree.CVarItem>
    local sorted      = {} ---@type cvartree.CVarItem[]
    local sortedlast  = {} ---@type cvartree.CVarItem[]
    ---@type table<string, cvartree.CVarItem>
    local cvartable = cvartree.GetCVarTable(nametable)
    for name, pt in pairs(cvartable) do
        ---@cast name string
        ---@cast pt cvartree.CVarItem
        if not name:StartsWith "__" and istable(pt) then
            if pt.iscvarlayer then
                categories[name] = pt
            elseif pt.options and not pt.options.hidden then
                if pt.options.order then
                    sorted[pt.options.order] = pt
                elseif pt.options.bottomorder then
                    sortedlast[pt.options.bottomorder] = pt
                else
                    local printname = pt.options.printname or name
                    pt.options.printname = printname
                    preferences[printname] = pt
                end
            end
        end
    end

    for _, pt in SortedPairs(sorted) do
        ---@cast pt cvartree.CVarItem
        MakeElement(panel, admin, pt)
    end
    for _, pt in SortedPairs(preferences) do
        ---@cast pt cvartree.CVarItem
        MakeElement(panel, admin, pt)
    end
    for _, pt in SortedPairs(sortedlast, true) do
        ---@cast pt cvartree.CVarItem
        MakeElement(panel, admin, pt)
    end
    for name, pt in SortedPairs(categories) do
        ---@cast name string
        ---@cast pt cvartree.CVarItem
        if pt.options.subcategory then
            pt.panel = panel
            local label = panel:Help(pt.options.printname)
            label:DockMargin(0, 0, 8, 8)
            label:SetTextColor(label:GetSkin().Colours.Tree.Hover)
        else
            pt.panel = vgui.Create("ControlPanel", panel)
            pt.panel:SetLabel(pt.options.printname)
            if pt.options.closed then pt.panel:SetExpanded(false) end
            panel:AddItem(pt.panel)
        end

        local nt = table.Copy(nametable)
        nt[#nt + 1] = name
        MakeGUI(pt.panel --[[@as DForm]], nt, admin)
    end

    for _, item in ipairs(panel:GetChildren()) do
        local child = item:GetChild(0)
        if child and child:GetName() ~= "DLabel" then return end
    end

    panel:Remove()
end

---Generates GUI panels for registered ConVars
---@param name string|string[]
function cvartree.AddGUI(name)
    if isstring(name) then name = {name --[[@as string]]} end
    ---@cast name -string
    local t = cvartree.GetCVarTable(name)
    local printname = t.options and t.options.printname or name[#name]
    hook.Add("PopulateToolMenu", idprefix .. printname, function()
        spawnmenu.AddToolMenuOption("Utilities", "User",
        idprefix .. printname, printname, "", "",
        ---@param panel DForm
        function(panel)
            panel:Clear()
            MakeGUI(panel, name)
        end)

        spawnmenu.AddToolMenuOption("Utilities", "Admin",
        "CVarTreeAdmin" .. printname, printname, "", "",
        ---@param panel DForm
        function(panel)
            panel:Clear()
            MakeGUI(panel, name, true)
            ---@cast panel +PANEL
            local think = panel.Think
            function panel:Think()
                if not IsValid(LocalPlayer()) then return end
                panel.Think = think
                if LocalPlayer():IsAdmin() then return end
                panel:Remove()
            end
        end)
    end)
end

return cvartree

-- local cvartree = require "greatzenkakuman/cvartree"
-- cvartree.AddCVar({"greatzenkakuman", "tree", "preference1"}, 0, "Text Help")
-- cvartree.AddCVarPrefix "greatzenkakuman" "tree"
-- cvartree.AddCVar("preference2", 25, "Overridable/GZM/Tree/preference2", {type = "number", min = 0, max = 50})
-- cvartree.SetCVarPrefix "greatzenkakuman" "tree2"
-- cvartree.AddCVar("serveronly1", 1, "Serveronly/GZM/Tree2/Serveronly1", {serverside = true})
-- cvartree.AddCVar("clientonly1", 1, "Clientonly/GZM/Tree2/Clientonly1", {clientside = true})
-- cvartree.SetCVarPrefix()
-- cvartree.AddCVar({"greatzenkakuman", "tree3", "subtree1", "four_layers"}, 2, "Four layers test", {type = "number", min = 1, max = 3, decimals = 1})

-- if CLIENT then cvartree.AddGUI "greatzenkakuman" end
-- PrintTable(cvartree.GetCVarList())
