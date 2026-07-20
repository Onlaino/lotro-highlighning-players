HighlightPlayers = HighlightPlayers or {}

HighlightPlayers.App = {}
HighlightPlayers.App.__index = HighlightPlayers.App

function HighlightPlayers.App.New(pluginInstance)
    local instance = {
        plugin = pluginInstance,
        storage = nil,
        relationships = nil,
        targetTracker = nil,
        indicator = nil,
        cardWindow = nil,
        mainWindow = nil,
        commands = nil,
        started = false
    }

    setmetatable(instance, HighlightPlayers.App)
    return instance
end

function HighlightPlayers.App:Start()
    if self.started then
        return
    end

    self.storage = HighlightPlayers.Storage.New()
    self.storage:Load()

    self.relationships = HighlightPlayers.Relationships.New(self.storage)
    self.targetTracker = HighlightPlayers.TargetTracker.New()
    self.targetTracker:Start()

    self.cardWindow = HighlightPlayers.PlayerCardWindow.New(
        self.storage,
        self.relationships
    )
    self.mainWindow = HighlightPlayers.MainWindow.New(
        self.storage,
        self.relationships,
        self.targetTracker,
        self.cardWindow
    )
    self.indicator = HighlightPlayers.Indicator.New(
        self.storage,
        self.relationships,
        self.targetTracker
    )
    self.commands = HighlightPlayers.Commands.New(
        self.relationships,
        self.targetTracker,
        self.indicator,
        self.mainWindow,
        self.cardWindow
    )
    self.commands:Start()

    self.started = true
    HighlightPlayers.Util.WriteInfo(
        "Enemy Highlight v" .. self.plugin:GetVersion() ..
        " loaded. Use /eh to open."
    )
end

function HighlightPlayers.App:Stop()
    if not self.started then
        return
    end

    self.commands:Stop()
    self.mainWindow.Stop()
    self.cardWindow.Stop()
    self.indicator.Stop()
    self.targetTracker:Stop()
    self.storage:Save()
    self.started = false
end

function HighlightPlayers.App:GetOptionsPanel()
    local panel = Turbine.UI.Control()
    panel:SetHeight(55)

    local openButton = Turbine.UI.Lotro.Button()
    openButton:SetParent(panel)
    openButton:SetPosition(15, 15)
    openButton:SetSize(180, 22)
    openButton:SetText("Open Enemy Highlight")
    openButton.Click = function()
        self.mainWindow.Open()
    end

    return panel
end
