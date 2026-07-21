HighlightPlayers = HighlightPlayers or {}

HighlightPlayers.Localization = {}

local supported = { "auto", "en", "fr", "de", "ru" }
local settings = nil
local storage = nil
local selectedLanguage = "auto"
local resolvedLanguage = "en"
local listeners = {}

local function isSupported(code)
    for _, value in ipairs(supported) do
        if value == code then
            return true
        end
    end
    return false
end

local function detectLanguage()
    local succeeded, language = pcall(function()
        return Turbine.Engine.GetLanguage()
    end)

    if not succeeded then
        return "en"
    end

    if Turbine.Language ~= nil then
        if Turbine.Language.French ~= nil and
            language == Turbine.Language.French then
            return "fr"
        end
        if Turbine.Language.German ~= nil and
            language == Turbine.Language.German then
            return "de"
        end
        if Turbine.Language.Russian ~= nil and
            language == Turbine.Language.Russian then
            return "ru"
        end
    end

    return "en"
end

local function resolveLanguage(code)
    if code == "auto" then
        return detectLanguage()
    end
    return isSupported(code) and code or "en"
end

local function getTable(code)
    local data = HighlightPlayers.LocaleData or {}
    return data[code] or data.en or {}
end

function HighlightPlayers.Localization.Get(key, values)
    local current = getTable(resolvedLanguage)
    local fallback = getTable("en")
    local text = current[key] or fallback[key] or key

    if values == nil then
        return text
    end

    local rendered = string.gsub(text, "{([%w_]+)}", function(name)
        local value = values[name]
        return value ~= nil and tostring(value) or ("{" .. name .. "}")
    end)
    return rendered
end

function HighlightPlayers.Localization.Initialize(storageInstance)
    storage = storageInstance
    settings = storage:GetData().settings
    selectedLanguage = tostring(settings.language or "auto")
    if not isSupported(selectedLanguage) then
        selectedLanguage = "auto"
    end
    settings.language = selectedLanguage
    resolvedLanguage = resolveLanguage(selectedLanguage)
end

function HighlightPlayers.Localization.GetSelectedLanguage()
    return selectedLanguage
end

function HighlightPlayers.Localization.GetResolvedLanguage()
    return resolvedLanguage
end

function HighlightPlayers.Localization.GetLanguageName(code)
    return HighlightPlayers.Localization.Get("language_" .. tostring(code))
end

function HighlightPlayers.Localization.GetSelectionName()
    if selectedLanguage ~= "auto" then
        return HighlightPlayers.Localization.GetLanguageName(selectedLanguage)
    end

    return HighlightPlayers.Localization.Get("language_auto") .. " (" ..
        HighlightPlayers.Localization.GetLanguageName(resolvedLanguage) .. ")"
end

function HighlightPlayers.Localization.AddListener(listener)
    table.insert(listeners, listener)
    return listener
end

function HighlightPlayers.Localization.RemoveListener(listener)
    for index = 1, table.getn(listeners) do
        if listeners[index] == listener then
            table.remove(listeners, index)
            return
        end
    end
end

function HighlightPlayers.Localization.SetLanguage(code)
    local normalized = string.lower(tostring(code or ""))
    if not isSupported(normalized) then
        return false, HighlightPlayers.Localization.Get("language_invalid")
    end

    selectedLanguage = normalized
    resolvedLanguage = resolveLanguage(selectedLanguage)
    if settings ~= nil then
        settings.language = selectedLanguage
    end
    if storage ~= nil then
        storage:Save()
    end

    for index = 1, table.getn(listeners) do
        listeners[index](selectedLanguage, resolvedLanguage)
    end

    return true, HighlightPlayers.Localization.GetSelectionName()
end

function HighlightPlayers.Localization.CycleLanguage()
    local currentIndex = 1
    for index, code in ipairs(supported) do
        if code == selectedLanguage then
            currentIndex = index
            break
        end
    end

    local nextIndex = currentIndex + 1
    if nextIndex > table.getn(supported) then
        nextIndex = 1
    end
    return HighlightPlayers.Localization.SetLanguage(supported[nextIndex])
end
