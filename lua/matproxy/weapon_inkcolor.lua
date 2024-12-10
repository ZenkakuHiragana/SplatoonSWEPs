
local OldItemTintBind ---@type function

---@param self table
---@param mat string
---@param values table<string, any>
local function ItemTintInit(self, mat, values)
    self.ResultTo = values.resultvar -- Store the name of the variable we want to set
end

for _, a in ipairs(engine.GetAddons()) do
    if a.wsid == "135491961" and a.mounted then
        include "matproxy/tf2itempaint.lua" -- Hat Painter & Crit Glow Tools conflicts
        local ItemTintColor = matproxy.ProxyList.ItemTintColor --[[@as MatProxyData]]
        ItemTintInit = ItemTintColor.init -- So take some workaround
        OldItemTintBind = ItemTintColor.bind
    end
end

local function ItemTintBind(self, mat, ent)
    if not IsValid(ent) then return end
    if isfunction(ent.GetInkColorProxy) and isvector(ent:GetInkColorProxy()) then
        -- If the target ent has a function called GetInkColorProxy then use that
        -- The function SHOULD return a Vector with the chosen ink color.
        mat:SetVector(self.ResultTo, ent:GetInkColorProxy())
    elseif OldItemTintBind then
        return OldItemTintBind(self, mat, ent)
    else
        mat:SetVector(self.ResultTo, vector_origin)
    end
end

matproxy.Add {
    name = "ItemTintColor",
    init = ItemTintInit,
    bind = ItemTintBind,
}
