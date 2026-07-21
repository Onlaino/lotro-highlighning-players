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
        noteWindow = nil,
        mainWindow = nil,
        launcher = nil,
        commands = nil,
        optionsPanel = nil,
        optionsLocaleListener = nil,
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
    HighlightPlayers.Localization.Initialize(self.storage)

    self.labels = HighlightPlayers.Labels.New(self.storage)
    self.relationships = HighlightPlayers.Relationships.New(
        self.storage,
        self.labels
    )
    self.labels:SetRelationships(self.relationships)

    self.targetTracker = HighlightPlayers.TargetTracker.New()
    self.targetTracker:Start()

    self.cardWindow = HighlightPlayers.PlayerCardWindow.New(
        self.storage,
        self.relationships,
        self.labels
    )
    self.noteWindow = HighlightPlayers.PlayerNoteWindow.New(
        self.storage,
        self.relationships,
        self.labels
    )
    self.indicator = HighlightPlayers.Indicator.New(
        self.storage,
        self.relationships,
        self.labels,
        self.targetTracker,
        self.noteWindow
    )
    self.labelsWindow = HighlightPlayers.LabelsWindow.New(
        self.storage,
        self.labels,
        self.relationships,
        self.indicator
    )
    self.mainWindow = HighlightPlayers.MainWindow.New(
        self.storage,
        self.relationships,
        self.labels,
        self.targetTracker,
        self.cardWindow,
        self.labelsWindow
    )
    self.launcher = HighlightPlayers.Launcher.New(
        self.storage,
        self.mainWindow
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
        HighlightPlayers.Localization.Get("app_loaded", {
            version = self.plugin:GetVersion()
        })
    )
end

function HighlightPlayers.App:Stop()
    if not self.started then
        return
    end

    self.commands:Stop()
    if self.optionsLocaleListener ~= nil then
        HighlightPlayers.Localization.RemoveListener(
            self.optionsLocaleListener
        )
        self.optionsLocaleListener = nil
    end
    self.launcher.Stop()
    self.mainWindow.Stop()
    self.cardWindow.Stop()
    self.noteWindow.Stop()
    self.labelsWindow.Stop()
    self.indicator.Stop()
    self.targetTracker:Stop()
    self.storage:Save()
    self.started = false
end

function HighlightPlayers.App:GetOptionsPanel()
    if self.optionsPanel ~= nil then
        return self.optionsPanel
    end

    local panel = Turbine.UI.Control()
    panel:SetHeight(117)

    local openButton = Turbine.UI.Lotro.Button()
    openButton:SetParent(panel)
    openButton:SetPosition(15, 15)
    openButton:SetSize(180, 22)
    openButton.Click = function()
        self.mainWindow.Open()
    end

    local labelsButton = Turbine.UI.Lotro.Button()
    labelsButton:SetParent(panel)
    labelsButton:SetPosition(15, 47)
    labelsButton:SetSize(180, 22)
    labelsButton.Click = function()
        self.labelsWindow.Open()
    end

    local languageButton = Turbine.UI.Lotro.Button()
    languageButton:SetParent(panel)
    languageButton:SetPosition(15, 79)
    languageButton:SetSize(250, 22)
    languageButton.Click = function()
        local succeeded, languageOrError =
            HighlightPlayers.Localization.CycleLanguage()
        if succeeded then
            HighlightPlayers.Util.WriteInfo(
                HighlightPlayers.Localization.Get("language_changed", {
                    language = languageOrError
                })
            )
        else
            HighlightPlayers.Util.WriteError(languageOrError)
        end
    end

    local function applyLocale()
        openButton:SetText(HighlightPlayers.Localization.Get("open_plugin"))
        labelsButton:SetText(
            HighlightPlayers.Localization.Get("manage_labels")
        )
        languageButton:SetText(
            HighlightPlayers.Localization.Get("language_button", {
                language = HighlightPlayers.Localization.GetSelectionName()
            })
        )
    end

    self.optionsLocaleListener = HighlightPlayers.Localization.AddListener(
        applyLocale
    )
    self.optionsPanel = panel
    applyLocale()

    return panel
end
