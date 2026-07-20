import "Turbine"
import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"
import "HighlightPlayers"

HighlightPlayers = HighlightPlayers or {}

local app = HighlightPlayers.App.New(plugin)
app:Start()

plugin.GetOptionsPanel = function()
    return app:GetOptionsPanel()
end

plugin.Unload = function()
    app:Stop()
end
