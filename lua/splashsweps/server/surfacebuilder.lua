
---@class ss
local ss = SplashSWEPs
if not ss then return end

---@class PaintableSurface
---@field Angles         Angle
---@field AnglesUV       Angle?
---@field GridArraySizeX integer
---@field GridArraySizeY integer
---@field InkColorGrid   integer[]
---@field IsDisplacement boolean
---@field IsSmallProp    boolean
---@field IsWaterSurface boolean
---@field Normal         Vector
---@field Origin         Vector
---@field OriginUV       Vector?
---@field Triangles      integer[]
---@field Vertices2D     Vector[]
---@field Vertices3D     Vector[]
---@field maxs           Vector
---@field mins           Vector
---@field width          number
---@field height         number
---@field BoundaryUV     Vector?
---@field LightmapInfo   LightmapInfo
---@field OffsetUV       Vector?

---@class LightmapInfo
---@field Available    boolean
---@field Styles       integer[]
---@field SampleOffset integer
---@field MinsInLuxels Vector
---@field SizeInLuxels Vector
---@field Offset       Vector
---@field BasisS       Vector
---@field BasisT       Vector
---@field Vertices2D   Vector[]

ss.class "PaintableSurface" {
    Angles         = Angle(),
    GridArraySizeX = 0,
    GridArraySizeY = 0,
    InkColorGrid   = {}, -- number[x * 32768 + y]
    IsDisplacement = false,
    IsSmallProp    = false,
    IsWaterSurface = false,
    Normal         = Vector(),
    Origin         = Vector(),
    Triangles      = {}, -- number[]
    Vertices2D     = {}, -- Vector[]
    Vertices3D     = {}, -- Vector[]
    ---
    maxs           = -ss.vector_one * math.huge,
    mins           =  ss.vector_one * math.huge,
    width          = 0,
    height         = 0,
    LightmapInfo   = {
        Available    = false,
        Styles       = {},
        SampleOffset = 0,
        MinsInLuxels = Vector(),
        SizeInLuxels = Vector(),
        Offset       = Vector(),
        BasisS       = Vector(),
        BasisT       = Vector(),
        Vertices2D   = {},
    }
}

local abs = math.abs
local angle_zero = angle_zero
local class = ss.class
local huge = math.huge
local LocalToWorld = LocalToWorld
local OrderVectors = OrderVectors
local pairs = pairs
local Vector = Vector
local vector_one = ss.vector_one
local vector_origin = vector_origin

---Index to SURFEDGES array -> actual vertex
---@param index integer
---@return Vector
local function surfEdgeToVertex(index)
    local surfedge  = ss.BSP.Raw.SURFEDGES[index]
    local edge      = ss.BSP.Raw.EDGES[abs(surfedge) + 1]
    local vertindex = edge[surfedge < 0 and 2 or 1]
    return ss.BSP.Raw.VERTEXES[vertindex + 1]
end

-- Generating convex hull by monotone chain method
---@param source Vector[]
---@return Vector[]
local function getConvex(source)
    local vertices2D = table.Copy(source)
    table.sort(vertices2D, function(a, b)
        return Either(a.x == b.x, a.y < b.y, a.x < b.x)
    end)

    local convex = {} ---@type Vector[]
    for i = 1, #vertices2D do
        if i > 2 then
            local p = convex[#convex]
            local q = convex[#convex - 1]
            local pq = q - p
            local pr = vertices2D[i] - p
            local cross = pq:Cross(pr)
            if cross.z > 0 or pq:LengthSqr() < ss.eps or pr:LengthSqr() < ss.eps then
                convex[#convex] = nil
            end
        end

        if i == #vertices2D then continue end
        convex[#convex + 1] = vertices2D[i]
    end

    for i = #vertices2D, 1, -1 do
        if i < #vertices2D - 1 then
            local p = convex[#convex]
            local q = convex[#convex - 1]
            local pq = q - p
            local pr = vertices2D[i] - p
            local cross = pq:Cross(pr)
            if cross.z > 0 or pq:LengthSqr() < ss.eps or pr:LengthSqr() < ss.eps then
                convex[#convex] = nil
            end
        end

        if i == 1 then continue end
        convex[#convex + 1] = vertices2D[i]
    end

    return convex
end

---Minimizes AABB of given convex.
---@param surf PaintableSurface
local function get2DComponents(surf)
    local desiredDir = nil ---@type Vector
    local add90deg   = false
    local minarea    = math.huge
    local vertices2D = {} ---@type Vector[]
    for i, v in ipairs(surf.Vertices3D) do
        vertices2D[i] = ss.To2D(v, surf.Origin, surf.Angles)
    end

    local convex = getConvex(vertices2D)
    for i = 1, #convex do
        local p0, p1 = convex[i], convex[i % #convex + 1]
        local dp = p1 - p0
        if dp:LengthSqr() > 0 then
            local dir  = dp:GetNormalized()

            -- Rotaion matrix
            local rx = Vector( dir.x, dir.y)
            local ry = Vector(-dir.y, dir.x)

            local xmax, xmin = -math.huge, math.huge
            local ymax, ymin = -math.huge, math.huge
            for _, v in ipairs(convex) do
                local x, y = v:Dot(rx), v:Dot(ry)
                xmin = math.min(xmin, x)
                ymin = math.min(ymin, y)
                xmax = math.max(xmax, x)
                ymax = math.max(ymax, y)
            end

            local xlength = xmax - xmin
            local ylength = ymax - ymin
            if minarea > xlength * ylength then
                desiredDir = dir
                add90deg = xlength < ylength
                minarea = xlength * ylength
            end
        end
    end

    -- Rotation matrix
    local rx = Vector( desiredDir.x, desiredDir.y)
    local ry = Vector(-desiredDir.y, desiredDir.x)

    --  cos(x)  sin(x)   +90deg    -sin(x)  cos(x)
    -- -sin(x)  cos(x)  -------->  -cos(x) -sin(x)
    if add90deg then
        rx, ry = ry, -rx ---@type Vector, Vector
    end
    surf.Angles.roll = -math.deg(math.atan2(ry.x, rx.x))

    -- Rotate all vertices to minimize AABB
    local mins = ss.vector_one * math.huge
    for _, v in ipairs(vertices2D) do
        v.x, v.y = v:Dot(rx), v:Dot(ry)
        mins = ss.MinVector(mins, v)
    end

    -- Set new origin to bounding box minimum
    surf.Origin = ss.To3D(mins, surf.Origin, surf.Angles)

    -- Shift vertices to eliminate negative components
    local mins2D, maxs2D ---@type Vector, Vector
    for _, v in ipairs(vertices2D) do
        v:Sub(mins)
        mins2D = ss.MinVector(mins2D or v, v)
        maxs2D = ss.MaxVector(maxs2D or v, v)
    end

    surf.Vertices2D     = vertices2D
    surf.width          = math.Round(maxs2D.x - mins2D.x, 4)
    surf.height         = math.Round(maxs2D.y - mins2D.y, 4)
    surf.GridArraySizeX = math.floor(surf.width / ss.InkGridSize)
    surf.GridArraySizeY = math.floor(surf.height / ss.InkGridSize)
end

---@type table<string, { material: string, triangles: MeshVertex[], vertices: MeshVertex[] }[]>
local ModelMeshCache = {}
local MaterialCache = {} ---@type table<string, IMaterial>

---@param name string
---@return IMaterial
local function getMaterial(name)
    if not MaterialCache[name] then MaterialCache[name] = Material(name) end
    return MaterialCache[name]
end

---@param name string
---@return { material: string, triangles: MeshVertex[], vertices: MeshVertex[] }[]
local function getModelMeshes(name)
    if not ModelMeshCache[name] then ModelMeshCache[name] = util.GetModelMeshes(name) end
    return ModelMeshCache[name]
end

local TextureFilterBits = bit.bor(
    SURF_SKY, SURF_NOPORTAL, SURF_TRIGGER,
    SURF_NODRAW, SURF_HINT, SURF_SKIP)
-- Construct a polygon from a raw face data
---@param faceindex integer
---@param rawFace BSP.Face
---@return PaintableSurface?
local function buildFace(faceindex, rawFace)
    -- Collect texture information and see if it's valid
    local rawTexInfo   = ss.BSP.Raw.TEXINFO
    local rawTexData   = ss.BSP.Raw.TEXDATA
    local rawTexDict   = ss.BSP.Raw.TEXDATA_STRING_TABLE
    local rawTexIndex  = ss.BSP.Raw.TexDataStringTableToIndex
    local rawTexString = ss.BSP.Raw.TEXDATA_STRING_DATA
    local texInfo      = rawTexInfo[rawFace.texInfo + 1]
    local texData      = rawTexData[texInfo.texData + 1]
    local texOffset    = rawTexDict[texData.nameStringTableID + 1]
    local texIndex     = rawTexIndex[texOffset]
    local texName      = rawTexString[texIndex]:lower()
    local texMaterial  = getMaterial(texName)
    if bit.band(texInfo.flags, TextureFilterBits) ~= 0 then return end
    if texMaterial:GetString "$surfaceprop" == "metalgrate" then return end
    if texName:find "tools/" then return end

    -- Collect geometrical information
    local rawPlanes = ss.BSP.Raw.PLANES
    local plane     = rawPlanes[rawFace.planeNum + 1]
    local firstedge = rawFace.firstEdge + 1
    local lastedge  = rawFace.firstEdge + rawFace.numEdges
    local normal    = plane.normal

    -- Collect "raw" vertex list
    local rawVertices = {} ---@type Vector[]
    for i = firstedge, lastedge do
        rawVertices[#rawVertices + 1] = surfEdgeToVertex(i)
    end

    -- Filter out colinear vertices and calculate the center
    -- This is also good time to calculate bounding box
    local filteredVertices = {} ---@type Vector[]
    local vertexSum = Vector()
    local maxs, mins = nil, nil ---@type Vector, Vector
    for i, current in ipairs(rawVertices) do
        local before = rawVertices[(#rawVertices + i - 2) % #rawVertices + 1]
        local after  = rawVertices[i % #rawVertices + 1]
        local cross  = (before - current):Cross(after - current)
        if normal:Dot(cross:GetNormalized()) > 0 then
            vertexSum:Add(current)
            filteredVertices[#filteredVertices + 1] = current
            maxs = ss.MaxVector(maxs or current, current)
            mins = ss.MinVector(mins or current, current)
        end
    end

    -- Check if it's valid to add to polygon list
    if #filteredVertices < 3 then return end
    local center = vertexSum / #filteredVertices
    local contents = util.PointContents(center - normal * 0.01)
    local isDisplacement = rawFace.dispInfo >= 0
    local isSolid = bit.band(contents, MASK_SOLID) > 0
    local isWater = texName:find "water"
    if not (isDisplacement or isSolid or isWater) then return end

    local surf = ss.class "PaintableSurface"
    surf.Angles         = normal:Angle()
    surf.IsDisplacement = isDisplacement
    surf.IsWaterSurface = tobool(isWater)
    surf.maxs           = maxs
    surf.mins           = mins
    surf.Normal         = normal
    surf.Origin         = center
    surf.Vertices3D     = filteredVertices

    -- Register lightmap info
    local li = surf.LightmapInfo
    li.Available    = true
    li.Styles       = rawFace.styles
    li.SampleOffset = rawFace.lightOffset
    li.MinsInLuxels = Vector(rawFace.lightmapTextureMinsInLuxels[1], rawFace.lightmapTextureMinsInLuxels[2])
    li.SizeInLuxels = Vector(rawFace.lightmapTextureSizeInLuxels[1], rawFace.lightmapTextureSizeInLuxels[2])
    li.Offset       = Vector(texInfo.lightmapOffsetS, texInfo.lightmapOffsetT)
    li.BasisS       = texInfo.lightmapVecS
    li.BasisT       = texInfo.lightmapVecT

    if not isDisplacement then
        if not isWater then get2DComponents(surf) end
        for i = 2, #filteredVertices - 1 do
            surf.Triangles[#surf.Triangles + 1] = 1
            surf.Triangles[#surf.Triangles + 1] = i
            surf.Triangles[#surf.Triangles + 1] = i + 1
        end
        return surf
    end

    -- Collect displacement info
    local rawDispInfo     = ss.BSP.Raw.DISPINFO
    local rawDispVerts    = ss.BSP.Raw.DISP_VERTS
    local dispInfo        = rawDispInfo[rawFace.dispInfo + 1]
    local power           = 2 ^ dispInfo.power + 1
    local numMeshVertices = power ^ 2
    do
        -- dispInfo.startPosition isn't always equal to
        -- surf.Vertices3D[1] so find correct one and sort them
        ---@type integer[], number, integer
        local indices, mindist, startindex = {}, math.huge, 0
        for i, v in ipairs(surf.Vertices3D) do
            local dist = dispInfo.startPosition:DistToSqr(v)
            if dist < mindist then
                startindex, mindist = i, dist
            end
        end

        for i = 1, 4 do
            indices[i] = (i + startindex - 2) % 4 + 1
        end

        -- Sort them using index table
        surf.Vertices3D[1], surf.Vertices3D[2],
        surf.Vertices3D[3], surf.Vertices3D[4]
            = surf.Vertices3D[indices[1]], surf.Vertices3D[indices[2]],
              surf.Vertices3D[indices[3]], surf.Vertices3D[indices[4]]
    end

    --  ^ y
    --  |
    -- (4) -------- (3)
    --  |            |
    --  ^            ^
    -- v1           v2
    --  |            |
    -- (1) -u1->--- (2) --> x
    local u1 = surf.Vertices3D[4] - surf.Vertices3D[1]
    local v1 = surf.Vertices3D[2] - surf.Vertices3D[1]
    local v2 = surf.Vertices3D[3] - surf.Vertices3D[4]
    local triangles = {} ---@type integer[] Indices of triangle mesh
    local vertices  = {} ---@type Vector[]  List of vertices
    maxs, mins = nil, nil ---@type Vector, Vector
    for i = 1, numMeshVertices do
        -- Calculate x-y offset
        local dispVert = rawDispVerts[dispInfo.dispVertStart + i]
        local xi, yi = (i - 1) % power, math.floor((i - 1) / power)
        local x,  y  = xi / (power - 1), yi / (power - 1)
        local origin = u1 * x + LerpVector(x, v1, v2) * y

        -- Calculate mesh vertex position
        local displacement = dispVert.vec * dispVert.dist
        local localPos     = origin   + displacement
        local worldPos     = dispInfo.startPosition + localPos
        vertices[#vertices + 1] = worldPos

        -- Modifies indices a bit to invert triangle orientation
        local invert = Either(i % 2 == 1, 1, 0)

        -- Generate triangle indices from displacement mesh
        if xi < power - 1 and yi < power - 1 then
            triangles[#triangles + 1] = i + invert + power
            triangles[#triangles + 1] = i + 1
            triangles[#triangles + 1] = i
            triangles[#triangles + 1] = i - invert + 1
            triangles[#triangles + 1] = i + power
            triangles[#triangles + 1] = i + power + 1
        end

        -- Set bounding box
        maxs = ss.MaxVector(maxs or worldPos, worldPos)
        mins = ss.MinVector(mins or worldPos, worldPos)
    end

    surf.maxs = maxs
    surf.mins = mins
    surf.Triangles = triangles
    surf.Vertices3D = vertices
    if not isWater then get2DComponents(surf) end
    return surf
end

local PROJECTION_NORMALS = {
    ["x+"] = Vector( 1,  0,  0),
    ["y+"] = Vector( 0,  1,  0),
    ["z+"] = Vector( 0,  0,  1),
    ["x-"] = Vector(-1,  0,  0),
    ["y-"] = Vector( 0, -1,  0),
    ["z-"] = Vector( 0,  0, -1),
}
local PROJECTION_ANGLES = {
    ["x+"] = PROJECTION_NORMALS["x+"]:Angle(),
    ["y+"] = PROJECTION_NORMALS["y+"]:Angle(),
    ["z+"] = PROJECTION_NORMALS["z+"]:Angle(),
    ["x-"] = PROJECTION_NORMALS["x-"]:Angle(),
    ["y-"] = PROJECTION_NORMALS["y-"]:Angle(),
    ["z-"] = PROJECTION_NORMALS["z-"]:Angle(),
}
---@param origin Vector
---@param angle Angle
---@param triangles { pos: Vector, normal: Vector }[]
---@return table<string, PaintableSurface>
local function processStaticPropConvex(origin, angle, triangles)
    local surfaces = {
        ["x+"] = class "PaintableSurface",
        ["y+"] = class "PaintableSurface",
        ["z+"] = class "PaintableSurface",
        ["x-"] = class "PaintableSurface",
        ["y-"] = class "PaintableSurface",
        ["z-"] = class "PaintableSurface",
    }
    local maxs_all = {
        ["x+"] = -vector_one * huge,
        ["y+"] = -vector_one * huge,
        ["z+"] = -vector_one * huge,
        ["x-"] = -vector_one * huge,
        ["y-"] = -vector_one * huge,
        ["z-"] = -vector_one * huge,
    }
    local mins_all = {
        ["x+"] = vector_one * huge,
        ["y+"] = vector_one * huge,
        ["z+"] = vector_one * huge,
        ["x-"] = vector_one * huge,
        ["y-"] = vector_one * huge,
        ["z-"] = vector_one * huge,
    }

    for i = 1, #triangles, 3 do
        local v1 = LocalToWorld(triangles[i    ].pos, angle_zero, origin, angle)
        local v2 = LocalToWorld(triangles[i + 1].pos, angle_zero, origin, angle)
        local v3 = LocalToWorld(triangles[i + 2].pos, angle_zero, origin, angle)
        local n = (triangles[i].normal or Vector())
            + (triangles[i + 1].normal or Vector())
            + (triangles[i + 2].normal or Vector())
        if n:IsZero() then
            local v2v1 = v1 - v2
            local v2v3 = v3 - v2
            n = v2v1:Cross(v2v3) -- normal around v1<-v2->v3
            if n:LengthSqr() < 1 then continue end -- normal is valid then
        else
            n = LocalToWorld(n, angle_zero, vector_origin, angle)
        end

        -- Find proper plane for projection
        local nx, ny, nz, plane_index = abs(n.x), abs(n.y), abs(n.z)
        if nx > ny and nx > nz then
            plane_index = n.x > 0 and "x+" or "x-"
        elseif ny > nx and ny > nz then
            plane_index = n.y > 0 and "y+" or "y-"
        else
            plane_index = n.z > 0 and "z+" or "z-"
        end

        OrderVectors(Vector(v1), maxs_all[plane_index])
        OrderVectors(Vector(v2), maxs_all[plane_index])
        OrderVectors(Vector(v3), maxs_all[plane_index])
        OrderVectors(mins_all[plane_index], Vector(v1))
        OrderVectors(mins_all[plane_index], Vector(v2))
        OrderVectors(mins_all[plane_index], Vector(v3))

        local surf = surfaces[plane_index]
        surf.Origin:Add(v1 + v2 + v3)
        surf.Vertices3D[#surf.Vertices3D + 1] = v1
        surf.Vertices3D[#surf.Vertices3D + 1] = v2
        surf.Vertices3D[#surf.Vertices3D + 1] = v3
        surf.Triangles[#surf.Triangles + 1] = #surf.Vertices3D - 2
        surf.Triangles[#surf.Triangles + 1] = #surf.Vertices3D - 1
        surf.Triangles[#surf.Triangles + 1] = #surf.Vertices3D
    end

    for k, n in pairs(PROJECTION_NORMALS) do
        local surf = surfaces[k]
        if #surf.Vertices3D < 3 then continue end
        surf.Origin:Div(#surf.Vertices3D)
        surf.maxs = maxs_all[k]
        surf.mins = mins_all[k]
        surf.Angles = Angle(PROJECTION_ANGLES[k])
        surf.Normal = n
        get2DComponents(surf)
    end

    return surfaces
end

---@param ph PhysObj
---@param name string?
---@param org Vector?
---@param ang Angle?
---@return PaintableSurface[]?
local function buildFacesFromPropMesh(ph, name, org, ang)
    if not IsValid(ph) then return end
    local mat = ph:GetMaterial()
    if mat:find "chain" or mat:find "grate" then return end

    ---@type MeshVertex[]|{ material: string, triangles: MeshVertex[], vertices: MeshVertex[] }[]
    local meshes = name and getModelMeshes(name) or ph:GetMeshConvexes()
    if not meshes or #meshes == 0 then return end

    local surfaces = {} ---@type PaintableSurface[]
    org, ang = org or ph:GetPos(), ang or ph:GetAngles()
    for _, t in ipairs(meshes) do
        if t.material then
            local m = getMaterial(t.material)
            if m then
                if m:IsError() then continue end
                if (m:GetInt "$translucent" or 0) ~= 0 then continue end
                if (m:GetInt "$alphatest" or 0) ~= 0 then continue end
            end
        end
        for _, surf in pairs(processStaticPropConvex(org, ang, t.triangles or t)) do
            if #surf.Vertices3D < 3 then continue end
            surfaces[#surfaces + 1] = surf
        end
    end

    return surfaces
end

---@param ph PhysObj
---@param name string
---@param origin Vector
---@param angle Angle
---@param mins Vector
---@param maxs Vector
---@return PaintableSurface[]?
local function buildStaticPropSurface(ph, name, origin, angle, mins, maxs)
    if IsValid(ph) then
       local mat = ph:GetMaterial()
       if mat:find "chain" or mat:find "grate" then return end
    end

    local surf = class "PaintableSurface"
    local meshes = getModelMeshes(name)
    surf.Angles = angle
    surf.IsSmallProp = true
    surf.Origin = origin
    surf.maxs = LocalToWorld(maxs, angle_zero, origin, angle)
    surf.mins = LocalToWorld(mins, angle_zero, origin, angle)
    surf.width = 0
    surf.height = 0
    OrderVectors(surf.mins, surf.maxs)
    for _, t in ipairs(meshes) do
        local m = getMaterial(t.material or "")
        if m then
            if m:IsError() then continue end
            if (m:GetInt "$translucent" or 0) ~= 0 then continue end
            if (m:GetInt "$alphatest" or 0) ~= 0 then continue end
        end
        local triangles = t.triangles
        for i = 1, #triangles, 3 do
            local v1 = LocalToWorld(triangles[i    ].pos, angle_zero, origin, angle)
            local v2 = LocalToWorld(triangles[i + 1].pos, angle_zero, origin, angle)
            local v3 = LocalToWorld(triangles[i + 2].pos, angle_zero, origin, angle)
            surf.Vertices2D[#surf.Vertices2D + 1] = Vector()
            surf.Vertices2D[#surf.Vertices2D + 1] = Vector()
            surf.Vertices2D[#surf.Vertices2D + 1] = Vector()
            surf.Vertices3D[#surf.Vertices3D + 1] = v1
            surf.Vertices3D[#surf.Vertices3D + 1] = v2
            surf.Vertices3D[#surf.Vertices3D + 1] = v3
            surf.Triangles[#surf.Triangles + 1] = #surf.Vertices3D - 2
            surf.Triangles[#surf.Triangles + 1] = #surf.Vertices3D - 1
            surf.Triangles[#surf.Triangles + 1] = #surf.Vertices3D
        end
    end

    if #surf.Vertices3D < 3 then return end
    return { surf }
end

---@param prop BSP.StaticProp
---@return PaintableSurface[]?
---@return boolean?
local function buildStaticProp(prop)
    local name = ss.BSP.Raw.sprp.name[prop.propType + 1]
    if not name then return end
    if not file.Exists(name, "GAME") then return end
    if not file.Exists(name:sub(1, -4) .. "phy", "GAME") then return end

    local mdl = ents.Create "base_anim"
    if not IsValid(mdl) then return end
    mdl:SetModel(name)
    mdl:Spawn()
    local ph ---@type PhysObj
    -- local mins, maxs = mdl:GetModelBounds()
    -- local size = maxs - mins
    if prop.solid == SOLID_VPHYSICS then
        mdl:PhysicsInit(SOLID_VPHYSICS)
        ph = mdl:GetPhysicsObject()
    end
    mdl:Remove()

    -- if math.max(size.x, size.y, size.z) > 10 then
        -- Always use physics collision mesh instead of model mesh for now
        return buildFacesFromPropMesh(ph, nil, prop.origin, prop.angle), false
    -- else
    --     return buildStaticPropSurface(ph, name, prop.origin, prop.angle, mins, maxs), true
    -- end
end

---@param surf PaintableSurface?
---@param output PaintableSurface[]
local function addSurface(surf, output)
    if not surf then return end
    if surf.IsWaterSurface then
        ss.WaterSurfaces[#ss.WaterSurfaces + 1] = ss.getraw(surf)
    else
        output[#output + 1] = ss.getraw(surf)
    end
end

function ss.GenerateSurfaces()
    local t0 = SysTime()
    print "Generating inkable surfaces..."
    for i, face in ipairs(ss.BSP.Raw.FACES or {}) do
        addSurface(buildFace(i, face), ss.SurfaceArrayLDR)
    end
    print("    Generated " .. #ss.BSP.Raw.FACES .. " surfaces for LDR.")
    for i, face in ipairs(ss.BSP.Raw.FACES_HDR or {}) do
        addSurface(buildFace(i, face), ss.SurfaceArrayHDR)
    end
    print("    Generated " .. #ss.BSP.Raw.FACES_HDR .. " surfaces for HDR.")

    print "Generating static prop surfaces..."
    local numLargeProps = 0
    local numSmallProps = 0
    for _, prop in ipairs(ss.BSP.Raw.sprp.prop or {}) do
        local surfaces, issmall = buildStaticProp(prop)
        if issmall then
            numSmallProps = numSmallProps + 1
        else
            numLargeProps = numLargeProps + 1
        end

        for _, surf in ipairs(surfaces or {}) do
            addSurface(surf, ss.SurfaceArrayDetails)
        end
    end
    print("    Generated surfaces for "
    .. numLargeProps .. " standard static props and "
    .. numSmallProps .. " small static props.")

    print "Generating surfaces for func_lods..."
    local funclod = ents.FindByClass "func_lod"
    for _, prop in ipairs(funclod) do
        local ph = prop:GetPhysicsObject()
        for _, surf in ipairs(buildFacesFromPropMesh(ph) or {}) do
            addSurface(surf, ss.SurfaceArrayDetails)
        end
    end
    print("    Generated surfaces for " .. #(funclod or {}) .. " func_lods.")

    local elapsed = math.Round((SysTime() - t0) * 1000, 2)
    print("Done!  Elapsed time: " .. elapsed .. " ms.")
end

-- function ss.GenerateCubemapTree()
--     ss.Cubemaps = {}
--     local path = "maps/" .. game.GetMap() .. "/c%d_%d_%d"
--     for i, cubemap in ipairs(ss.BSP.Raw.CUBEMAPS) do
--         local formatted = path:format(cubemap.origin.x, cubemap.origin.y, cubemap.origin.z)
--         ss.Cubemaps[i] = {
--             pos = cubemap.origin,
--             ldr = formatted,
--             hdr = formatted .. ".hdr",
--         }
--         if not file.Exists("materials/" .. ss.Cubemaps[i].hdr .. ".vtf", "GAME") then
--             ss.Cubemaps[i].hdr = ss.Cubemaps[i].ldr
--         end
--     end
-- end
