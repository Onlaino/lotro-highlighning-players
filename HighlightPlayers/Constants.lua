HighlightPlayers = HighlightPlayers or {}

HighlightPlayers.Constants = {
    DataKey = "HighlightPlayers",
    DataVersion = 1,
    Status = {
        Friend = "friend",
        Neutral = "neutral",
        Enemy = "enemy"
    },
    StatusOrder = { "friend", "neutral", "enemy" },
    StatusLabels = {
        friend = "Friend",
        neutral = "Neutral",
        enemy = "Enemy"
    },
    StatusColors = {
        friend = Turbine.UI.Color(0.20, 0.90, 0.25),
        neutral = Turbine.UI.Color(1.00, 0.55, 0.10),
        enemy = Turbine.UI.Color(0.95, 0.15, 0.15)
    }
}
