AddCSLuaFile()
local TEXTUREFLAGS = include "textureflags.lua" ---@type table<string, integer>
local MINIMUM   = 0 -- 2048x2048,       32MB
local SMALL     = 1 -- 4096x4096,       128MB
local DSMALL    = 2 -- 2x4096x4096,     256MB
local MEDIUM    = 3 -- 8192x8192,       512MB
local DMEDIUM   = 4 -- 2x8192x8192,     1GB
local LARGE     = 5 -- 16384x16384,     2GB
---@class ss.RenderTarget
---@field BaseTexture ITexture
---@field Bumpmap     ITexture
---@field Lightmap    ITexture
---@field Material    IMaterial
---@field Ready       boolean
local rt = {
    RESOLUTION = { ---@type table<string, integer>
        MINIMUM = MINIMUM,
        SMALL   = SMALL,
        DSMALL  = DSMALL,
        MEDIUM  = MEDIUM,
        DMEDIUM = DMEDIUM,
        LARGE   = LARGE,
    },
    Size = { ---@type table<integer, integer>
        [MINIMUM] = 2048,
        [SMALL  ] = 4096,
        [DSMALL ] = 5792,
        [MEDIUM ] = 8192,
        [DMEDIUM] = 11586,
        [LARGE  ] = 16384,
    },
    SizeFromPixels = { ---@type table<integer, integer>
        [2048 ] = MINIMUM,
        [4096 ] = SMALL,
        [5792 ] = DSMALL,
        [8192 ] = MEDIUM,
        [11586] = DMEDIUM,
        [16384] = LARGE,
    },
    Name = { ---@type table<string, string>
        BaseTexture   = "splashsweps_basetexture",
        Bumpmap       = "splashsweps_bumpmap",
        Lightmap      = "splashsweps_lightmap",
        RenderTarget  = "splashsweps_rendertarget",
        RTScope       = "splashsweps_rtscope",
        WaterMaterial = "splashsweps_watermaterial",
    },
    Flags = { ---@type table<string, integer>
        BaseTexture = bit.bor(
            TEXTUREFLAGS.NOMIP,
            TEXTUREFLAGS.NOLOD,
            TEXTUREFLAGS.ALL_MIPS,
            TEXTUREFLAGS.RENDERTARGET,
            TEXTUREFLAGS.NODEPTHBUFFER
        ),
        Bumpmap = bit.bor(
            TEXTUREFLAGS.NORMAL,
            TEXTUREFLAGS.NOMIP,
            TEXTUREFLAGS.NOLOD,
            TEXTUREFLAGS.ALL_MIPS,
            TEXTUREFLAGS.RENDERTARGET,
            TEXTUREFLAGS.NODEPTHBUFFER
        ),
        Lightmap = bit.bor(
            TEXTUREFLAGS.NOMIP,
            TEXTUREFLAGS.NOLOD,
            TEXTUREFLAGS.ALL_MIPS,
            TEXTUREFLAGS.RENDERTARGET,
            TEXTUREFLAGS.NODEPTHBUFFER
        ),
    },
}
return rt
