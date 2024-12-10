
---@class ss
local ss = SplashSWEPs
if not ss then return end

---@param surf PaintableSurface
---@return Vector[]
---@return Vector[]
local function calculateTangents(surf)
    if surf.IsSmallProp then return {}, {} end

    -- Straightly taken from https://github.com/CapsAdmin/pac3/pull/578/commits/43fa75c262cde661713cdaa9d1b09bc29ec796b4
    -- Lengyel, Eric. “Computing Tangent Space Basis Vectors for an Arbitrary Mesh”. Terathon Software, 2001. http://terathon.com/code/tangent.html
    local tan1, tan2 = {}, {} ---@type Vector[], Vector[]
    for i = 1, #surf.Triangles do
        tan1[i] = Vector()
        tan2[i] = Vector()
    end

    local tex = surf.Vertices2D
    local verts = surf.Vertices3D
    for i = 1, #surf.Triangles, 3 do
        local i1 = surf.Triangles[i]
        local i2 = surf.Triangles[i + 1]
        local i3 = surf.Triangles[i + 2]
        local p1, p2, p3 = verts[i1], verts[i2], verts[i3]
        local u1, u2, u3 = tex[i1].x, tex[i2].x, tex[i3].x
        local v1, v2, v3 = tex[i1].y, tex[i2].y, tex[i3].y

        local x1 = p2.x - p1.x
        local x2 = p3.x - p1.x
        local y1 = p2.y - p1.y
        local y2 = p3.y - p1.y
        local z1 = p2.z - p1.z
        local z2 = p3.z - p1.z

        local s1 = u2 - u1
        local s2 = u3 - u1
        local t1 = v2 - v1
        local t2 = v3 - v1

        local r = 1 / (s1 * t2 - s2 * t1)
        local sdir = Vector((t2 * x1 - t1 * x2) * r, (t2 * y1 - t1 * y2) * r, (t2 * z1 - t1 * z2) * r)
        local tdir = Vector((s1 * x2 - s2 * x1) * r, (s1 * y2 - s2 * y1) * r, (s1 * z2 - s2 * z1) * r)

        tan1[i    ]:Add(sdir)
        tan1[i + 1]:Add(sdir)
        tan1[i + 2]:Add(sdir)
        tan2[i    ]:Add(tdir)
        tan2[i + 1]:Add(tdir)
        tan2[i + 2]:Add(tdir)
    end

    return tan1, tan2
end

local rt = ss.RenderTarget
local MAX_TRIANGLES = math.floor(32768 / 3) -- mesh library limitation
function ss.BuildInkMesh()
    local rects = {} ---@type ss.Rectangle[]
    local NumMeshTriangles = 0
    for i, surf in ipairs(ss.SurfaceArray) do
        rects[i] = ss.MakeRectangle(surf.width + 1, surf.height + 1, 0, 0, surf)
        NumMeshTriangles = NumMeshTriangles + #surf.Triangles / 3
    end

    local packer = ss.MakeRectanglePacker(rects):packall()
    local RT_MARGIN_PIXELS = 4
    local rtSize = rt.BaseTexture:Width()
    local margin = packer.maxsize / rtSize * RT_MARGIN_PIXELS
    for i, surf in ipairs(ss.SurfaceArray) do
        rects[i] = ss.MakeRectangle(surf.width + margin, surf.height + margin, 0, 0, surf)
    end

    packer = ss.MakeRectanglePacker(rects):packall()

    local rectSizeHU = packer.maxsize -- Size of generated rectangle in Hammer Units
    local unitsPerPixel = rectSizeHU / rtSize
    ss.PixelsToUnits = unitsPerPixel
    ss.UVToUnits = rectSizeHU
    ss.UVToPixels = rtSize
    ss.UnitsToPixels = 1 / ss.PixelsToUnits
    ss.UnitsToUV = 1 / ss.UVToUnits
    ss.PixelsToUV = 1 / ss.UVToPixels
    print("SplashSWEPs: Total mesh triangles = ", NumMeshTriangles)

    local meshindex = 1
    for _ = 1, math.ceil(NumMeshTriangles / MAX_TRIANGLES) do
        ss.IMesh[#ss.IMesh + 1] = Mesh(rt.Material)
    end

    -- Building MeshVertex
    if #ss.IMesh == 0 then return end
    mesh.Begin(ss.IMesh[meshindex], MATERIAL_TRIANGLES, math.min(NumMeshTriangles, MAX_TRIANGLES))
    local function ContinueMesh()
        if mesh.VertexCount() < MAX_TRIANGLES * 3 then return end
        mesh.End()
        mesh.Begin(ss.IMesh[meshindex + 1], MATERIAL_TRIANGLES,
        math.min(NumMeshTriangles - MAX_TRIANGLES * meshindex, MAX_TRIANGLES))
        meshindex = meshindex + 1
    end

    for _, index in ipairs(packer.results) do
        local r = packer.rects[index]
        local surf = r.tag ---@type PaintableSurface
        local v3 = surf.Vertices3D
        local textureUV = surf.Vertices2D
        local lightmapUV = surf.LightmapInfo.Vertices2D
        surf.OffsetUV = ss.PixelsToUV * Vector(
            math.Round(r.left * ss.UnitsToPixels),
            math.Round(r.bottom * ss.UnitsToPixels))
        surf.BoundaryUV = ss.PixelsToUV * Vector(
            math.Round((r.width - margin) * ss.UnitsToPixels),
            math.Round((r.height - margin) * ss.UnitsToPixels))
        surf.AnglesUV = Angle(surf.Angles)
        surf.OriginUV = Vector(surf.Origin)
        if r.istall then
            surf.AnglesUV.roll = surf.AnglesUV.roll + 90
            surf.OriginUV:Sub(surf.AnglesUV:Up() * (r.height - margin))
        end

        for i = 1, #textureUV do
            if r.istall then
                textureUV[i].x, textureUV[i].y = textureUV[i].y, r.height - margin - textureUV[i].x
            end

            textureUV[i]:Mul(ss.UnitsToUV)
            textureUV[i]:Add(surf.OffsetUV)
        end

        local tan1, tan2 = calculateTangents(surf)
        for i = 1, #surf.Triangles, 3 do
            local i1 = surf.Triangles[i]
            local i2 = surf.Triangles[i + 1]
            local i3 = surf.Triangles[i + 2]
            local n = (v3[i1] - v3[i2]):Cross(v3[i3] - v3[i2]):GetNormalized()
            for j = 1, 3 do
                local k = surf.Triangles[i + j - 1]
                local tan, bitan, w = Vector(), Vector(), 1
                if not surf.IsSmallProp then
                    local s, t = tan2[i + j - 1], tan1[i + j - 1]
                    tan = (t - n * n:Dot(t)):GetNormalized()
                    bitan = (s - n * n:Dot(s)):GetNormalized()
                    w = n:Cross(t):Dot(s) < 0 and -1 or 1
                end

                mesh.Normal(n)
                mesh.UserData(tan.x, tan.y, tan.z, w)
                mesh.TangentS(tan * w) -- These functions actually DO something
                mesh.TangentT(bitan)   -- in terms of bumpmap for LightmappedGeneric
                mesh.Position(v3[k])
                mesh.TexCoord(0, textureUV[k].x, textureUV[k].y)
                local color = Color(255, 255, 255, 255)
                if #lightmapUV > 0 then
                    mesh.TexCoord(1, lightmapUV[k].x, lightmapUV[k].y)
                else
                    mesh.TexCoord(1, 1, 1)
                    local sample = render.GetLightColor(v3[k])
                    color.r = math.Round(sample.x ^ (1 / 2.2) / 2 * 255)
                    color.g = math.Round(sample.y ^ (1 / 2.2) / 2 * 255)
                    color.b = math.Round(sample.z ^ (1 / 2.2) / 2 * 255)
                end
                mesh.Color(color:Unpack())
                mesh.AdvanceVertex()
            end

            ContinueMesh()
        end

        -- surf.Triangles, surf.Vertices3D, surf.Vertices2D = nil, nil, nil
    end
    mesh.End()
end

function ss.BuildWaterMesh()
    local NumMeshTriangles, meshindex = 0, 1
    for _, surf in ipairs(ss.WaterSurfaces) do
        NumMeshTriangles = NumMeshTriangles + #surf.Vertices3D - 2
    end
    for _ = 1, math.ceil(NumMeshTriangles / MAX_TRIANGLES) do
        ss.WaterMesh[#ss.WaterMesh + 1] = Mesh(ss.GetWaterMaterial())
    end

    if #ss.WaterMesh == 0 then return end
    mesh.Begin(ss.WaterMesh[meshindex], MATERIAL_TRIANGLES, math.min(NumMeshTriangles, MAX_TRIANGLES))
    local function ContinueMesh()
        if mesh.VertexCount() < MAX_TRIANGLES * 3 then return end
        mesh.End()
        mesh.Begin(ss.WaterMesh[meshindex + 1], MATERIAL_TRIANGLES,
        math.min(NumMeshTriangles - MAX_TRIANGLES * meshindex, MAX_TRIANGLES))
        meshindex = meshindex + 1
    end

    for _, surf in ipairs(ss.WaterSurfaces) do
        local v3 = surf.Vertices3D
        for i = 1, #surf.Triangles, 3 do
            local i1 = surf.Triangles[i]
            local i2 = surf.Triangles[i + 1]
            local i3 = surf.Triangles[i + 2]
            local n = (v3[i1] - v3[i2]):Cross(v3[i3] - v3[i2]):GetNormalized()
            for j = 1, 3 do
                local v = v3[surf.Triangles[i + j - 1]]
                mesh.Normal(n)
                mesh.Position(v)
                mesh.TexCoord(0, v.x, v.y)
                mesh.TexCoord(1, v.x, v.y)
                mesh.AdvanceVertex()
            end

            ContinueMesh()
        end
    end
    mesh.End()

    ss.WaterSurfaces = nil
end

---@param data ss.Transferrable
function ss.PrepareInkSurface(data)
    util.TimerCycle()

    ss.Lightmap = data.Lightmap
    ss.MinimapAreaBounds = data.MinimapAreaBounds
    local ldr = data.SurfaceArrayLDR ---@type PaintableSurface[]?
    local hdr = data.SurfaceArrayHDR ---@type PaintableSurface[]?
    local details = data.SurfaceArrayDetails
    local isusinghdr = false
    if render.GetHDREnabled() then
        isusinghdr = #hdr > 0 and ss.Lightmap.hdr and #ss.Lightmap.hdr > 0 or false
    else
        isusinghdr = not (#ldr > 0 and ss.Lightmap.ldr and #ss.Lightmap.ldr > 0)
    end

    if isusinghdr then ---@cast hdr -?
        ss.SurfaceArray, hdr, ldr = hdr, nil, nil
    else ---@cast ldr -?
        ss.SurfaceArray, hdr, ldr = ldr, nil, nil
    end
    table.Add(ss.SurfaceArray, details)

    ss.WaterSurfaces = data.WaterSurfaces
    ss.SURFACE_ID_BITS = select(2, math.frexp(#ss.SurfaceArray))

    local lightmapmat ---@type IMaterial
    local lightmap = render.GetHDREnabled() and ss.Lightmap.hdr or ss.Lightmap.ldr or ""
    local lightpng = "splashsweps/" .. game.GetMap() .. ".png"
    file.Write(lightpng, lightmap)
    if lightmap and #lightmap > 0 then
        lightmapmat = Material("../data/" .. lightpng, "smooth")
    else
        lightmapmat = Material "grey"
    end

    if not lightmapmat:IsError() then
        rt.Lightmap = lightmapmat:GetTexture "$basetexture"
        rt.Lightmap:Download()
    end

    if rt.Lightmap and render.GetHDREnabled() then -- If HDR lighting computation has been done
        local intensity = 128
        if ss.Lightmap.lightColor then -- If there is light_environment
            local lightIntensity = Vector(unpack(ss.Lightmap.lightColor)):Dot(ss.GrayScaleFactor) / 255
            local brightness = ss.Lightmap.lightColor[4] or 0
            local scale = ss.Lightmap.lightScaleHDR or 1
            intensity = intensity + lightIntensity * brightness * scale
        end
        local value = ss.vector_one * intensity / 4096
        rt.Material:SetVector("$color", value)
        rt.Material:SetVector("$envmaptint", value / 16)
    end

    ss.PrecachePaintTextures()
    ss.GenerateHashTable()
    ss.BuildInkMesh()
    ss.BuildWaterMesh()
    ss.ClearAllInk()
    ss.InitializeMoveEmulation(LocalPlayer())
    net.Start "SplashSWEPs: Ready to splat"
    net.WriteString(LocalPlayer():SteamID64() or "")
    net.SendToServer()
    ss.WeaponRecord[LocalPlayer()] = util.JSONToTable(
    util.Decompress(file.Read "splashsweps/record/stats.txt" or "") or "") or {
        Duration = {},
        Inked = {},
        Recent = {},
    }

    rt.Ready = true
    collectgarbage "collect"
    print("MAKE", util.TimerCycle())
end
