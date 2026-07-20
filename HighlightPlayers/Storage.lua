HighlightPlayers = HighlightPlayers or {}

HighlightPlayers.Storage = {}
HighlightPlayers.Storage.__index = HighlightPlayers.Storage

local function defaultData()
    return {
        version = HighlightPlayers.Constants.DataVersion,
        players = {},
        settings = {
            mainWindow = {
                left = 180,
                top = 160
            },
            cardWindow = {
                left = 250,
                top = 190
            },
            indicator = {
                left = Turbine.UI.Display.GetWidth() - 340,
                top = 65,
                locked = true
            }
        }
    }
end

local function ensurePosition(settings, name, fallback)
    if type(settings[name]) ~= "table" then
        settings[name] = fallback
        return
    end

    settings[name].left = tonumber(settings[name].left) or fallback.left
    settings[name].top = tonumber(settings[name].top) or fallback.top
end

local function normalizeLoadedData(loaded)
    local defaults = defaultData()

    if type(loaded) ~= "table" then
        return defaults
    end

    loaded.version = tonumber(loaded.version) or 1

    if type(loaded.players) ~= "table" then
        loaded.players = {}
    end

    if type(loaded.settings) ~= "table" then
        loaded.settings = {}
    end

    ensurePosition(
        loaded.settings,
        "mainWindow",
        defaults.settings.mainWindow
    )
    ensurePosition(
        loaded.settings,
        "cardWindow",
        defaults.settings.cardWindow
    )
    ensurePosition(
        loaded.settings,
        "indicator",
        defaults.settings.indicator
    )

    if type(loaded.settings.indicator.locked) ~= "boolean" then
        loaded.settings.indicator.locked = true
    end

    loaded.version = HighlightPlayers.Constants.DataVersion
    return loaded
end

function HighlightPlayers.Storage.New()
    local instance = {
        data = defaultData(),
        lastError = nil
    }

    setmetatable(instance, HighlightPlayers.Storage)
    return instance
end

function HighlightPlayers.Storage:Load()
    local succeeded, loadedOrError = pcall(function()
        return Turbine.PluginData.Load(
            Turbine.DataScope.Server,
            HighlightPlayers.Constants.DataKey
        )
    end)

    if not succeeded then
        self.lastError = tostring(loadedOrError)
        HighlightPlayers.Util.WriteError(
            "Could not load saved data: " .. self.lastError
        )
        self.data = defaultData()
        return false
    end

    self.data = normalizeLoadedData(loadedOrError)
    self.lastError = nil
    return true
end

function HighlightPlayers.Storage:Save()
    self.data.version = HighlightPlayers.Constants.DataVersion

    local succeeded, saveError = pcall(function()
        Turbine.PluginData.Save(
            Turbine.DataScope.Server,
            HighlightPlayers.Constants.DataKey,
            self.data
        )
    end)

    if not succeeded then
        self.lastError = tostring(saveError)
        HighlightPlayers.Util.WriteError(
            "Could not save data: " .. self.lastError
        )
        return false
    end

    self.lastError = nil
    return true
end

function HighlightPlayers.Storage:GetData()
    return self.data
end
