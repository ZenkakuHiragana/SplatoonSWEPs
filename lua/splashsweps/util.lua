
---@class ss
local ss = SplashSWEPs
if not ss then return end

---A wrapper function for hooks.  The func will be executed only if the player is holding a Splash weapon.
---@param func string|function
---@return function
function ss.hook(func)
    if isstring(func) then ---@cast func string
        return function(ply, ...)
            local w = ss.IsValid(ply or CLIENT and LocalPlayer() or nil)
            if w then return ss[func](w, ply, ...) end
        end
    else ---@cast func function
        return function(ply, ...)
            local w = ss.IsValid(ply or CLIENT and LocalPlayer() or nil)
            if w then return func(w, ply, ...) end
        end
    end
end

---Faster table.remove() function from stack overflow
---https://stackoverflow.com/questions/12394841/safely-remove-items-from-an-array-table-while-iterating
---tableremovefunc takes a function to remove elements.
---Returning true in the function to remove.
---@generic T
---@param t T[]
---@param toremove fun(value: T): boolean?
---@return T[]
function ss.tableremovefunc(t, toremove)
    local k = 1
    for i = 1, #t do
        if toremove(t[i]) then
            t[i] = nil
        else -- Move i's kept value to k's position, if it's not already there.
            if i ~= k then t[k], t[i] = t[i], nil end
            k = k + 1 -- Increment position of where we'll place the next kept value.
        end
    end

    return t
end

---tableremove takes a number to remove element.
---@generic T
---@param t T[]
---@param removal integer
---@return T[]
function ss.tableremove(t, removal)
    local k = 1
    for i = 1, #t do
        if i == removal then
            t[i] = nil
        else -- Move i's kept value to k's position, if it's not already there.
            if i ~= k then t[k], t[i] = t[i], nil end
            k = k + 1 -- Increment position of where we'll place the next kept value.
        end
    end

    return t
end

---Even faster than table.remove() and this removes the first element.
---@generic T
---@param t { [integer]: T }
---@return T
function ss.tablepop(t)
    local zero, one = t[0], t[1]
    for i = 1, #t do
        t[i - 1], t[i] = t[i], nil
    end

    t[0] = zero
    return one
end

---Faster than table.insert() and this inserts an element at the beginning.
---@generic T
---@param t T[]
---@param v T
function ss.tablepush(t, v)
    local n = #t
    for i = n, 1, -1 do
        t[i + 1], t[i] = t[i], nil
    end

    t[1] = v
end

---Compares each component and returns the smaller one.
---@param a Vector Vector to compare
---@param b Vector Vector to compare
---@return Vector # Vector containing smaller components
function ss.MinVector(a, b)
    return Vector(math.min(a.x, b.x), math.min(a.y, b.y), math.min(a.z, b.z))
end

---Compares each component and returns the larger one.
---@param a Vector Vector to compare
---@param b Vector Vector to compare
---@return Vector # Vector containing larger components
function ss.MaxVector(a, b)
    return Vector(math.max(a.x, b.x), math.max(a.y, b.y), math.max(a.z, b.z))
end

---Takes two AABBs and returns if they are colliding each other, but ignores Z-component.
---@param mins1 Vector First AABB
---@param maxs1 Vector First AABB
---@param mins2 Vector Second AABB
---@param maxs2 Vector Second AABB
---@return boolean # Whether or not the two AABBs intersect each other
function ss.CollisionAABB2D(mins1, maxs1, mins2, maxs2)
    return mins1.x < maxs2.x and maxs1.x > mins2.x and
            mins1.y < maxs2.y and maxs1.y > mins2.y
end

---Short for WorldToLocal()
---@param source Vector Vector to convert
---@param orgpos Vector Origin of new 2D system
---@param organg Angle Angle of new 2D system
---@return Vector # Converted 2D vector
function ss.To2D(source, orgpos, organg)
    local localpos = WorldToLocal(source, angle_zero, orgpos, organg)
    return Vector(localpos.y, localpos.z, 0)
end

---Short for LocalToWorld()
---@param source Vector 2D vector to convert
---@param orgpos Vector Origin of 2D system relative to the world
---@param organg Angle Angle of 2D system relative to the world
---@return Vector # Converted 3D vector
function ss.To3D(source, orgpos, organg)
    local localpos = Vector(0, source.x, source.y)
    local pos = LocalToWorld(localpos, angle_zero, orgpos, organg)
    return pos
end

---Returns true if two numbers are close to equal
---@param a number Number to compare
---@param b number Number to compare
---@return boolean # Mostly like a == b
function ss.IsClose(a, b)
    return math.abs(a - b) <= ss.eps * math.max(1, math.abs(a), math.abs(b))
end

---Shared version of util.IsInWorld() as it only exists in serverside
---@param pos Vector Vector to test
---@return boolean # Whether or not the vector is in the world
function ss.IsInWorld(pos)
    return not util.TraceLine {
        start = pos,
        endpos = pos,
        collisiongroup = COLLISION_GROUP_WORLD,
    }.HitWorld
end

---For Charger's interpolation
---@param frac number  Fraction [0--1]
---@param min  number  Minimum value
---@param max  number  Maximum value
---@param full number? Optional value returned when frac == 1
---@return number # Interpolated value
function ss.Lerp3(frac, min, max, full)
    return frac < 1 and Lerp(frac, min, max) or full or max
end

---Gets either -1 or +1
---@param seed string? Random seed used by util.SharedRandom()
---@return number sign Either -1 or +1
function ss.RandomSign(seed)
    local rand = seed and util.SharedRandom(seed, 0, 1, CurTime()) or math.random()
    return math.Round(rand) * 2 - 1
end

---Generates a biased random value ranges from 0 to 1, used by weapon spread
---@param bias number  Amount of bias: 0 makes it always returns 0, 0.5 means non-biased, 1 makes it return either +1 or -1
---@param seed string? Random seed used by util.SharedRandom()
---@return number # Generated random value
function ss.GetBiasedRandom(bias, seed)
    local sign = ss.RandomSign(seed)
    local selectrand = seed and util.SharedRandom(seed, 0, 1, CurTime() * 2) or math.random()
    local select = bias > selectrand
    local fracmin = select and bias or 0
    local fracmax = select and 1    or bias
    local frac = seed and util.SharedRandom(seed, fracmin, fracmax, CurTime() * 3) or math.Rand(fracmin, fracmax)
    return sign * frac
end

---Short for checking isfunction() and call it
---@param  func function? The function to call
---@param  ...  any       vararg Arguments passed to the function
---@return ...  any     # Returns from the function
function ss.ProtectedCall(func, ...)
    if isfunction(func) then ---@cast func -?
        return func(...)
    end
end

---Modify the given table with given units
---@param source { [string]: number } The parameter table = {[string ParameterName] = [number Value]}
---@param units { [string]: string } table to describe what units each parameter should have = {[string ParameterName] = [string Unit]}
function ss.ConvertUnits(source, units)
    for name, value in pairs(source) do
        if isnumber(value) then
            local unit = units[name]
            local converter = unit and ss.UnitsConverter[unit] or 1
            source[name] = value * converter
        end
    end
end

local HostTimeScale = GetConVar "host_timescale"
---Get player timescale
---@param ply Entity? If given, it returns player's local timescale instead
---@return number # The game timescale
function ss.GetTimeScale(ply)
    if IsValid(ply) and ply--[[@as Entity]]:IsPlayer() then ---@cast ply Player
        return ply:GetLaggedMovementValue()
    else
        return game.GetTimeScale() * HostTimeScale:GetFloat()
    end
end

---Get path of transformed model from PlayerType enum
---@param pmid PlayerType
---@return string?
function ss.GetTransformedModel(pmid)
    if pmid == ss.PLAYER.NOCHANGE then return end
    local transformed = ss.TransformModel[ss.TransformModelIndex[pmid] or ss.TRANSFORM.STANDARD]
    return file.Exists(transformed, "GAME") and transformed or nil
end

---Checks if the given entity is holding a Splash weapon
---@param ply Entity? The entity to be chekcked
---@return SplashWeaponBase? # The weapon it has, if any
function ss.IsValid(ply)
    if not IsValid(ply) then return end ---@cast ply Player
    local w = ss.ProtectedCall(ply.GetActiveWeapon, ply) --[[@as SplashWeaponBase]]
    return IsValid(w) and w.IsSplashWeapon and not w:GetHolstering() and w or nil
end

---Checks if the given two colors are the same, considering FF setting
---@param c1 Entity|number? Color to compare
---@param c2 Entity|number? Color to compare
---@return boolean # True if the colors are same
function ss.IsAlly(c1, c2)
    if isentity(c1) and IsValid(c1) and isentity(c2) and IsValid(c2) and c1 == c2 then
        return not ss.GetOption "hurtowner"
    end

    ---@cast c1 Entity
    ---@cast c2 Entity
    c1 = isentity(c1) and IsValid(c1) and c1:GetNWInt "inkcolor" or c1
    c2 = isentity(c2) and IsValid(c2) and c2:GetNWInt "inkcolor" or c2
    return not ss.GetOption "ff" and c1 == c2
end

---Play a sound that can only be heard by one player
---@param ply          Player|Player[] The player(s) who can hear it
---@param soundName    string          Sound name to play
---@param soundLevel   number?
---@param pitchPercent number?
---@param volume       number?
---@param channel      number?
function ss.EmitSound(ply, soundName, soundLevel, pitchPercent, volume, channel)
    if not (istable(ply) or IsValid(ply) and ply:IsPlayer()) then return end
    if SERVER and ss.mp then
        net.Start "SplashSWEPs: Send a sound"
        net.WriteString(soundName)
        net.WriteUInt(soundLevel or 75, 9)
        net.WriteUInt(pitchPercent or 100, 8)
        net.WriteFloat(volume or 1)
        net.WriteUInt((channel or CHAN_AUTO) + 1, 8)
        net.Send(ply)
    elseif CLIENT and IsFirstTimePredicted() or ss.sp then
        if not istable(ply) then
            ply:EmitSound(soundName, soundLevel, pitchPercent, volume, channel)
        else
            for _, p in ipairs(ply) do
                p:EmitSound(soundName, soundLevel, pitchPercent, volume, channel)
            end
        end
    end
end

---Play a sound properly in a weapon predicted hook
---@param ply Entity?            The owner of the weapon
---@param ent SplashWeaponBase The weapon entity
---@param ... any                Arguments of Entity:EmitSound()
function ss.EmitSoundPredicted(ply, ent, ...)
    ss.SuppressHostEventsMP(ply)
    ent:EmitSound(...)
    ss.EndSuppressHostEventsMP(ply)
end

---SuppressHostEvents but can be uniformly called in both multiplayer/singleplayer
---@param ply Entity? The player to suppress host events
function ss.SuppressHostEventsMP(ply)
    if ss.sp or CLIENT then return end
    if IsValid(ply) and --[[@cast ply -?]] ply:IsPlayer() then
        SuppressHostEvents(ply --[[@as Player]])
    end
end

---End of SuppressHostEvents but can be uniformly called in both multiplayer/singleplayer
---@param ply Entity? The player previously applied SuppressHostEvents
function ss.EndSuppressHostEventsMP(ply)
    if ss.sp or CLIENT then return end
    if IsValid(ply) and --[[@cast ply -?]] ply:IsPlayer() then
        SuppressHostEvents(NULL --[[@as Player]])
    end
end

---Gets normalized gravity direction considering physenv settings
---@return Vector
function ss.GetGravityDirection()
    local g = physenv.GetGravity()
    if not g then return -vector_up end
    return g:GetNormalized()
end

---@param ent Entity
---@param color integer?
---@param state boolean
function ss.SetEntityFilter(ent, color, state)
    if not IsValid(ent) then return end
    color = color or ent:GetNWInt("inkcolor", -1)
    if color < 0 then return end
    if state and not ss.EntityFilters[color] then
        ss.EntityFilters[color] = {}
    end
    if ss.EntityFilters[color] then
        ss.EntityFilters[color][ent] = state or nil
        if not next(ss.EntityFilters[color]) then
            ss.EntityFilters[color] = nil
        end
    end
    if CLIENT then return end
    if #ss.PlayersReady == 0 then return end
    net.Start "SplashSWEPs: Sync entity filter"
    net.WriteEntity(ent)
    net.WriteUInt(color, ss.COLOR_BITS)
    net.WriteBool(state)
    net.Send(ss.PlayersReady)
end

---@param ent Entity
---@param color integer?
---@param state boolean
function ss.SetPlayerFilter(ent, color, state)
    if not IsValid(ent) then return end
    color = color or ent:GetNWInt("inkcolor", -1)
    if color < 0 then return end
    if state and not ss.PlayerFilters[color] then
        ss.PlayerFilters[color] = {}
    end
    if ss.PlayerFilters[color] then
        ss.PlayerFilters[color][ent] = state or nil
        if not next(ss.PlayerFilters[color]) then
            ss.PlayerFilters[color] = nil
        end
    end
    if CLIENT then return end
    if #ss.PlayersReady == 0 then return end
    net.Start "SplashSWEPs: Sync player filter"
    net.WriteEntity(ent)
    net.WriteUInt(color, ss.COLOR_BITS)
    net.WriteBool(state)
    net.Send(ss.PlayersReady)
end

---Make a table of entities assumed to have the same color
---@param weapon SplashWeaponBase
---@param includePlayers boolean?
---@return Entity[]
function ss.MakeAllyFilter(weapon, includePlayers)
    local owner = weapon:GetOwner()
    local color = weapon:GetNWInt "inkcolor"
    local entities = { weapon, owner } ---@type Entity[]
    for ent in pairs(ss.EntityFilters[color] or {}) do
        if IsValid(ent) then
            if ent:GetOwner() == owner then
                entities[#entities + 1] = ent
            end
        else
            ss.SetEntityFilter(ent, color, false)
        end
    end
    if not includePlayers then return entities end
    for ply in pairs(ss.PlayerFilters[color] or {}) do
        entities[#entities + 1] = ply
    end
    return entities
end

---Performs a deep copy for given table
---@generic T: table, K, V
---@param t T
---@param lookup table?
---@return T?
function ss.deepcopy(t, lookup)
    if t == nil then return nil end
    local copy = setmetatable({}, ss.deepcopy(getmetatable(t)))

    ---@diagnostic disable-next-line: no-unknown
    for k, v in pairs(t) do
        if istable(v) then
            lookup = lookup or {}
            ---@diagnostic disable-next-line: no-unknown
            lookup[t] = copy
            if lookup[v] then
                ---@diagnostic disable-next-line: no-unknown
                copy[k] = lookup[v]
            else
                ---@diagnostic disable-next-line: no-unknown
                copy[k] = ss.deepcopy(v, lookup)
            end
        elseif isvector(v) then
            ---@diagnostic disable-next-line: no-unknown
            copy[k] = Vector(v)
        elseif isangle(v) then
            ---@diagnostic disable-next-line: no-unknown
            copy[k] = Angle(v)
        elseif ismatrix(v) then
            ---@diagnostic disable-next-line: no-unknown
            copy[k] = Matrix(v)
        else
            ---@diagnostic disable-next-line: no-unknown
            copy[k] = v
        end
    end

    return copy
end

---Gets the real table from given class instance
---@generic T
---@param t T
---@return T
function ss.getraw(t)
    local instance = getmetatable(t).instance ---@type table?
    return instance or t
end

---Defines a class or makes an instance of given class name
---@generic T
---@param name `T`
---@return T
function ss.class(name)
    local getraw = ss.getraw
    local def = ss.ClassDefinitions
    if not def[name] then
        return function(t --[[@as table]]) def[name] = t end
    else
        local instance = ss.deepcopy(def[name])
        local function read(self, key)
            assert(rawget(getraw(self), key) ~= nil, "no matching field '" .. key .. "'")
            return rawget(getraw(self), key)
        end

        local function write(self, key, value)
            local v = rawget(getraw(self), key)
            local t = type(v)
            local u = type(value)
            if t == "table" then t = (getmetatable(v) or {}).__class or t end
            if u == "table" then u = (getmetatable(value) or {}).__class or u end
            assert(v ~= nil, "no matching field '" .. key .. "'")
            assert(t == u, "type mismatch, expected: '" .. t .. "', given: '" .. u .. "'")
            rawset(getraw(self), key, value)
        end

        local function str(self)
            return "[instanceof " .. getmetatable(self).__class .. "]"
        end

        return setmetatable({}, {
            instance = instance,
            __call = function() end,
            __class = name,
            __index = read,
            __newindex = write,
            __tostring = str,
        })
    end
end
