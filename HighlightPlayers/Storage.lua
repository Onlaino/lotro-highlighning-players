HighlightPlayers = HighlightPlayers or {}

HighlightPlayers.Storage = {}
HighlightPlayers.Storage.__index = HighlightPlayers.Storage

local function clamp(value, minimum, maximum, fallback)
    local number = tonumber(value)
    if number == nil then
        return fallback
    end

    return math.max(minimum, math.min(maximum, math.floor(number)))
end

local function defaultData()
    local indicator = HighlightPlayers.Constants.Indicator

    return {
        version = HighlightPlayers.Constants.DataVersion,
        labels = HighlightPlayers.Constants.CopyDefaultLabels(),
        nextLabelId = 1,
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
            labelsWindow = {
                left = 300,
                top = 180
            },
            launcher = {
                left = 20,
                top = math.floor(Turbine.UI.Display.GetHeight() / 2)
            },
            indicator = {
                left = Turbine.UI.Display.GetWidth() - 340,
                top = 65,
                width = indicator.DefaultWidth,
                height = indicator.DefaultHeight,
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

local function normalizeLabels(loaded, defaults)
    if type(loaded.labels) ~= "table" or table.getn(loaded.labels) == 0 then
        loaded.labels = HighlightPlayers.Constants.CopyDefaultLabels()
        return
    end

    local normalized = {}
    local usedIds = {}

    for _, label in ipairs(loaded.labels) do
        if type(label) == "table" then
            local id = HighlightPlayers.Util.Trim(label.id)
            local name = HighlightPlayers.Util.Trim(label.name)

            if id ~= "" and name ~= "" and usedIds[id] ~= true then
                usedIds[id] = true
                table.insert(normalized, {
                    id = id,
                    name = string.sub(
                        name,
                        1,
                        HighlightPlayers.Constants.LabelNameMaxLength
                    ),
                    red = clamp(label.red, 0, 255, 180),
                    green = clamp(label.green, 0, 255, 180),
                    blue = clamp(label.blue, 0, 255, 180)
                })
            end
        end
    end

    if table.getn(normalized) == 0 then
        loaded.labels = defaults.labels
    else
        loaded.labels = normalized
    end
end

local function normalizeLoadedData(loaded)
    local defaults = defaultData()

    if type(loaded) ~= "table" then
        return defaults
    end

    loaded.version = tonumber(loaded.version) or 1
    loaded.nextLabelId = math.floor(
        math.max(1, tonumber(loaded.nextLabelId) or 1)
    )

    if type(loaded.players) ~= "table" then
        loaded.players = {}
    end

    if type(loaded.settings) ~= "table" then
        loaded.settings = {}
    end

    normalizeLabels(loaded, defaults)
    ensurePosition(loaded.settings, "mainWindow", defaults.settings.mainWindow)
    ensurePosition(loaded.settings, "cardWindow", defaults.settings.cardWindow)
    ensurePosition(
        loaded.settings,
        "labelsWindow",
        defaults.settings.labelsWindow
    )
    ensurePosition(loaded.settings, "launcher", defaults.settings.launcher)
    ensurePosition(loaded.settings, "indicator", defaults.settings.indicator)

    local indicator = loaded.settings.indicator
    local limits = HighlightPlayers.Constants.Indicator
    indicator.width = clamp(
        indicator.width,
        limits.MinWidth,
        limits.MaxWidth,
        limits.DefaultWidth
    )
    indicator.height = clamp(
        indicator.height,
        limits.MinHeight,
        limits.MaxHeight,
        limits.DefaultHeight
    )

    if type(indicator.locked) ~= "boolean" then
        indicator.locked = true
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
