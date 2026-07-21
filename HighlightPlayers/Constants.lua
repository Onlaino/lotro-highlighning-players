HighlightPlayers = HighlightPlayers or {}

HighlightPlayers.Constants = {
    DataKey = "HighlightPlayers",
    DataVersion = 5,
    LabelNameMaxLength = 32,
    Indicator = {
        DefaultMaxWidth = 112,
        DefaultMaxHeight = 26,
        MinWidth = 60,
        MaxWidth = 300,
        MinHeight = 20,
        MaxHeight = 80
    },
    DefaultLabels = {
        {
            id = "friend",
            name = "Friend",
            red = 51,
            green = 230,
            blue = 64
        },
        {
            id = "neutral",
            name = "Neutral",
            red = 255,
            green = 140,
            blue = 26
        },
        {
            id = "enemy",
            name = "Enemy",
            red = 242,
            green = 38,
            blue = 38
        }
    }
}

function HighlightPlayers.Constants.CopyDefaultLabels()
    local result = {}

    for index, label in ipairs(HighlightPlayers.Constants.DefaultLabels) do
        result[index] = {
            id = label.id,
            name = label.name,
            red = label.red,
            green = label.green,
            blue = label.blue
        }
    end

    return result
end
