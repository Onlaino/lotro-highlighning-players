HighlightPlayers = HighlightPlayers or {}
HighlightPlayers.Event = HighlightPlayers.Event or {}

function HighlightPlayers.Event.Add(object, eventName, callback)
    if object[eventName] == nil then
        object[eventName] = callback
    elseif type(object[eventName]) == "table" then
        table.insert(object[eventName], callback)
    else
        object[eventName] = { object[eventName], callback }
    end

    return callback
end

function HighlightPlayers.Event.Remove(object, eventName, callback)
    if object[eventName] == callback then
        object[eventName] = nil
        return
    end

    if type(object[eventName]) ~= "table" then
        return
    end

    for index = 1, table.getn(object[eventName]) do
        if object[eventName][index] == callback then
            table.remove(object[eventName], index)
            return
        end
    end
end
