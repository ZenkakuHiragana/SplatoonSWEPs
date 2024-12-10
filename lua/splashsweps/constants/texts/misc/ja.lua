AddCSLuaFile()
return {
    Author = "全角ひらがな",
    CleanupInk = "Splash SWEPsのインク",
    CleanupInkMessage = "Splash SWEPsのインクを消去しました。",
    DescRTResolution = [[インクの描画システムで用いるバッファサイズの設定です。
この変更を反映するにはGMODの再起動が必要です。
また、高解像度になるほど多くのVRAM容量が要求されます。
変更の際にはビデオメモリの容量が十分にあることを確認してください。]],
    LateReadyToSplat = "Splash SWEPs: マップを塗り替えす準備ができましたが、サーバーに参加し直すことを推奨します。",
    NPCWeaponMenu = "Splash SWEPs: 武器オーバーライド",
    OverrideHelpText = "サーバー側の設定を優先する",
    Sidemenu = {
        AddFavorite = "お気に入りに追加",
        Equipped = "装備中",
        Favorites = "お気に入り",
        FilterTitle = "Splash SWEPs: 武器フィルタ",
        RemoveFavorite = "お気に入りから削除",
        SortPrefix = "並べ替え: ",
        Sort = {
            Name = "名前",
            Main = "メイン",
            Sub = "サブ",
            Special = "スペシャル",
            Recent = "最近使用",
            Often = "よく使う",
            Inked = "累計塗り面積",
        },
        VariationsPrefix = "バリエーション: ",
        Variations = {
            All = "すべて",
            Original = "無印",
        },
        WeaponTypePrefix = "武器タイプ: ",
        WeaponType = {
            All = "すべて",
            Shooters = "シューター",
        },
    },
    InkColor = "インクの色:",
    Instructions = [[メイン攻撃: インクを撃つ
サブ攻撃: サブウェポンを使う
リロード: スペシャル発動
スプリント: ミニマップ
しゃがみ: 変形する]],
    Playermodel = "プレイヤーモデル:",
    PreviewTitle = "プレビュー",
    Purpose = "インクを撒き散らそう！",
    RTResolution = "インク バッファサイズ:",
    RTRestartRequired = "(再起動が必要)",
}
