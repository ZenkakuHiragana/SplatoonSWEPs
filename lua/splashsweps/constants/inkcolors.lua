AddCSLuaFile()
local RED = 1
local ORANGE = 2
local YELLOW = 3
local YELLOWISH_GREEN = 4
local LIME = 5
local SPRING_GREEN = 6
local CYAN = 7
local AZURE_BLUE = 8
local BLUE = 9
local LIGHT_INDIGO = 10
local MAGENTA = 11
local DEEP_PINK = 12

local MAROON = 13
local OLIVE = 14
local GREEN = 15
local DARK_CYAN = 16
local NAVY = 17
local PURPLE = 18

local LIGHT_GREEN = 19
local LIGHT_BLUE = 20
local PINK = 21

local BLACK = 22
local GRAY = 23
local LIGHT_GRAY = 24
local WHITE = 25

return {
    [RED]               = {0,   1, 1,   ORANGE},
    [ORANGE]            = {30,  1, 1,   RED},
    [YELLOW]            = {60,  1, 1,   OLIVE},
    [YELLOWISH_GREEN]   = {80,  1, 1,   OLIVE},
    [LIME]              = {120, 1, 1,   GREEN},
    [SPRING_GREEN]      = {150, 1, 1,   DARK_CYAN},
    [CYAN]              = {180, 1, 1,   DARK_CYAN},
    [AZURE_BLUE]        = {210, 1, 1,   LIGHT_INDIGO},
    [BLUE]              = {240, 1, 1,   PURPLE},
    [LIGHT_INDIGO]      = {270, 1, 1,   BLUE},
    [MAGENTA]           = {300, 1, 1,   DEEP_PINK},
    [DEEP_PINK]         = {330, 1, 1,   MAGENTA},

    [MAROON]            = {0,   1, .5,  RED},
    [OLIVE]             = {60,  1, .5,  GREEN},
    [GREEN]             = {120, 1, .5,  LIGHT_GREEN},
    [DARK_CYAN]         = {180, 1, .5,  LIGHT_INDIGO},
    [NAVY]              = {240, 1, .5,  LIGHT_INDIGO},
    [PURPLE]            = {300, 1, .5,  AZURE_BLUE},

    [LIGHT_GREEN]       = {105, .5, 1,  GREEN},
    [LIGHT_BLUE]        = {210, .5, 1,  DARK_CYAN},
    [PINK]              = {315, .5, 1,  MAGENTA},

    [BLACK]             = {0, 0, .125,  BLACK},
    [GRAY]              = {0, 0, .5,    GRAY},
    [LIGHT_GRAY]        = {0, 0, .75,   LIGHT_GRAY},
    [WHITE]             = {0, 0, .875,  WHITE},
}
