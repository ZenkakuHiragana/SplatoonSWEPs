AddCSLuaFile()
return {
    Author = "Zenkaku",
    Category = "Splash SWEPs",
    CleanupInk = "Splash SWEPs ink",
    CleanupInkMessage = "Cleaned up Splash SWEPs ink.",
    DescRTResolution = [[Buffer size used in ink system.
To apply the change, restart your GMOD client.
Higher option needs more VRAM.
Make sure your graphics card has enough space of video memory.]],
    LateReadyToSplat = "Splash SWEPs: You're now ready to paint the map, but re-joining the server is recommended.",
    NPCWeaponMenu = "Splash SWEPs Weapon Override",
    OverrideHelpText = "Override this setting with serverside value",
    Sidemenu = {
        AddFavorite = "Add to favorites",
        Equipped = "Equipped",
        Favorites = "Favorites",
        FilterTitle = "Splash SWEPs: Weapons Filter",
        RemoveFavorite = "Remove from favorites",
        SortPrefix = "Sort: ",
        Sort = {
            Name = "Name",
            Main = "Main weapon",
            Sub = "Sub weapon",
            Special = "Special weapon",
            Recent = "Recent",
            Often = "Most often",
            Inked = "Most inked",
        },
        VariationsPrefix = "Variations: ",
        Variations = {
            All = "All",
            Original = "Original",
        },
        WeaponTypePrefix = "Weapon type: ",
        WeaponType = {
            All = "All",
            Shooters = "Shooters",
        },
    },
    InkColor = "Ink color:",
    Instructions = [[Primary: Shoot ink.
Secondary: Use sub weapon.
Reload: Use special weapon.
Sprint: Open minimap.
Crouch: Transform.]],
    Playermodel = "Playermodel:",
    PreviewTitle = "Preview",
    Purpose = "Splat ink!",
    RTResolution = "Ink buffer size:",
    RTRestartRequired = "(Requires restart)",
}
