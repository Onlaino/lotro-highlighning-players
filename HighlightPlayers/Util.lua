HighlightPlayers = HighlightPlayers or {}
HighlightPlayers.Util = HighlightPlayers.Util or {}

function HighlightPlayers.Util.Trim(value)
    if value == nil then
        return ""
    end

    return string.gsub(tostring(value), "^%s*(.-)%s*$", "%1")
end

function HighlightPlayers.Util.NormalizeName(value)
    return string.lower(HighlightPlayers.Util.Trim(value))
end

function HighlightPlayers.Util.ValidateName(value)
    local name = HighlightPlayers.Util.Trim(value)

    if name == "" then
        return false, "Player name is required."
    end

    if string.len(name) > 64 then
        return false, "Player name is too long."
    end

    if string.find(name, "%s") ~= nil then
        return false, "Player name cannot contain spaces."
    end

    if string.find(name, "[%c]") ~= nil then
        return false, "Player name contains invalid characters."
    end

    return true, name
end

function HighlightPlayers.Util.IsStatus(value)
    return value == HighlightPlayers.Constants.Status.Friend or
        value == HighlightPlayers.Constants.Status.Neutral or
        value == HighlightPlayers.Constants.Status.Enemy
end

function HighlightPlayers.Util.ParseStatus(value)
    local status = string.lower(HighlightPlayers.Util.Trim(value))

    if HighlightPlayers.Util.IsStatus(status) then
        return status
    end

    return nil
end

function HighlightPlayers.Util.SafeMethod(object, methodName)
    if object == nil then
        return false, nil, "object is nil"
    end

    local lookupSucceeded, method = pcall(function()
        return object[methodName]
    end)

    if not lookupSucceeded or type(method) ~= "function" then
        return false, nil, methodName .. " is unavailable"
    end

    local callSucceeded, value = pcall(method, object)
    if not callSucceeded then
        return false, nil, tostring(value)
    end

    return true, value, nil
end

function HighlightPlayers.Util.SafeIsA(object, classType)
    if object == nil or classType == nil then
        return false
    end

    local succeeded, result = pcall(function()
        return object:IsA(classType)
    end)

    return succeeded and result == true
end

function HighlightPlayers.Util.ClampPosition(left, top, width, height)
    local displayWidth = Turbine.UI.Display.GetWidth()
    local displayHeight = Turbine.UI.Display.GetHeight()
    local maxLeft = math.max(0, displayWidth - width)
    local maxTop = math.max(0, displayHeight - height)

    return math.max(0, math.min(tonumber(left) or 0, maxLeft)),
        math.max(0, math.min(tonumber(top) or 0, maxTop))
end

function HighlightPlayers.Util.WriteError(message)
    Turbine.Shell.WriteLine(
        "<rgb=#FF5555>[HighlightPlayers] " .. tostring(message) .. "</rgb>"
    )
end

function HighlightPlayers.Util.WriteInfo(message)
    Turbine.Shell.WriteLine(
        "<rgb=#FFAA33>[HighlightPlayers] " .. tostring(message) .. "</rgb>"
    )
end
