HighlightPlayers = HighlightPlayers or {}

HighlightPlayers.App = {}
HighlightPlayers.App.__index = HighlightPlayers.App

function HighlightPlayers.App.New(pluginInstance)
    local instance = {
        plugin = pluginInstance,
        storage = nil,
        labels = nil,
        relationships = nil,
        targetTracker = nil,
        indicator = nil,
        labelsWindow = nil,
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

    self.labels = HighlightPlayers.Labels.New(self.storage)
    self.relationships = HighlightPlayers.Relationships.New(
        self.storage,
        self.labels
    )
    self.labels:SetRelationships(self.relationships)

    self.targetTracker = HighlightPlayers.TargetTracker.New()
    self.targetTracker:Start()

    self.indicator = HighlightPlayers.Indicator.New(
        self.storage,
        self.relationships,
        self.labels,
        self.targetTracker
    )
    self.labelsWindow = HighlightPlayers.LabelsWindow.New(
        self.storage,
        self.labels,
        self.relationships,
        self.indicator
    )
    self.cardWindow = HighlightPlayers.PlayerCardWindow.New(
        self.storage,
        self.relationships,
        self.labels
    )
    self.mainWindow = HighlightPlayers.MainWindow.New(
        self.storage,
        self.relationships,
        self.labels,
        self.targetTracker,
        self.cardWindow,
        self.labelsWindow
    )
    self.commands = HighlightPlayers.Commands.New(
        self.relationships,
        self.labels,
        self.targetTracker,
        self.indicator,
        self.mainWindow,
        self.cardWindow,
        self.labelsWindow
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
    self.labelsWindow.Stop()
    self.indicator.Stop()
    self.targetTracker:Stop()
    self.storage:Save()
    self.started = false
end

function HighlightPlayers.App:GetOptionsPanel()
    local panel = Turbine.UI.Control()
    panel:SetHeight(85)

    local openButton = Turbine.UI.Lotro.Button()
    openButton:SetParent(panel)
    openButton:SetPosition(15, 15)
    openButton:SetSize(180, 22)
    openButton:SetText("Open Enemy Highlight")
    openButton.Click = function()
        self.mainWindow.Open()
    end

    local labelsButton = Turbine.UI.Lotro.Button()
    labelsButton:SetParent(panel)
    labelsButton:SetPosition(15, 47)
    labelsButton:SetSize(180, 22)
    labelsButton:SetText("Manage labels")
    labelsButton.Click = function()
        self.labelsWindow.Open()
    end

    return panel
end
