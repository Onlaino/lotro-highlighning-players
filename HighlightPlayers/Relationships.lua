HighlightPlayers = HighlightPlayers or {}

HighlightPlayers.Relationships = {}
HighlightPlayers.Relationships.__index = HighlightPlayers.Relationships

function HighlightPlayers.Relationships.New(storage)
    local instance = {
        storage = storage,
        players = storage:GetData().players,
        listeners = {}
    }

    setmetatable(instance, HighlightPlayers.Relationships)
    instance:NormalizeLoadedPlayers()
    return instance
end

function HighlightPlayers.Relationships:NormalizeLoadedPlayers()
    local normalizedPlayers = {}

    for key, record in pairs(self.players) do
        if type(record) == "table" then
            local valid, name = HighlightPlayers.Util.ValidateName(
                record.name or key
            )
            local status = HighlightPlayers.Util.ParseStatus(record.status)

            if valid and status ~= nil then
                local normalizedName = HighlightPlayers.Util.NormalizeName(name)
                normalizedPlayers[normalizedName] = {
                    name = name,
                    status = status,
                    note = tostring(record.note or "")
                }
            end
        end
    end

    self.players = normalizedPlayers
    self.storage:GetData().players = normalizedPlayers
end

function HighlightPlayers.Relationships:AddListener(listener)
    table.insert(self.listeners, listener)
    return listener
end

function HighlightPlayers.Relationships:RemoveListener(listener)
    for index = 1, table.getn(self.listeners) do
        if self.listeners[index] == listener then
            table.remove(self.listeners, index)
            return
        end
    end
end

function HighlightPlayers.Relationships:Notify(eventName, record)
    for index = 1, table.getn(self.listeners) do
        self.listeners[index](eventName, record)
    end
end

function HighlightPlayers.Relationships:GetByName(name)
    return self.players[HighlightPlayers.Util.NormalizeName(name)]
end

function HighlightPlayers.Relationships:GetByKey(key)
    return self.players[HighlightPlayers.Util.NormalizeName(key)]
end

function HighlightPlayers.Relationships:GetList(status, searchValue)
    local result = {}
    local search = HighlightPlayers.Util.NormalizeName(searchValue)

    for key, record in pairs(self.players) do
        local normalizedName = HighlightPlayers.Util.NormalizeName(record.name)
        local matchesSearch = search == "" or
            string.find(normalizedName, search, 1, true) ~= nil

        if record.status == status and matchesSearch then
            table.insert(result, {
                key = key,
                name = record.name,
                status = record.status,
                note = record.note
            })
        end
    end

    table.sort(result, function(left, right)
        return string.lower(left.name) < string.lower(right.name)
    end)

    return result
end

function HighlightPlayers.Relationships:GetCount(status)
    local count = 0

    for _, record in pairs(self.players) do
        if record.status == status then
            count = count + 1
        end
    end

    return count
end

function HighlightPlayers.Relationships:SavePlayer(
    originalKey,
    nameValue,
    statusValue,
    noteValue
)
    local valid, nameOrError = HighlightPlayers.Util.ValidateName(nameValue)
    if not valid then
        return false, nameOrError, false
    end

    local status = HighlightPlayers.Util.ParseStatus(statusValue)
    if status == nil then
        return false, "Choose Friend, Neutral or Enemy.", false
    end

    local name = nameOrError
    local key = HighlightPlayers.Util.NormalizeName(name)
    local normalizedOriginalKey = nil

    if originalKey ~= nil then
        normalizedOriginalKey = HighlightPlayers.Util.NormalizeName(originalKey)
    end

    if normalizedOriginalKey ~= nil and
        normalizedOriginalKey ~= key and
        self.players[key] ~= nil then
        return false, "A player with this name already exists.", false
    end

    local existing = self.players[key]
    if existing == nil and normalizedOriginalKey ~= nil then
        existing = self.players[normalizedOriginalKey]
    end

    local note = noteValue
    if note == nil then
        note = existing ~= nil and existing.note or ""
    end

    if normalizedOriginalKey ~= nil and normalizedOriginalKey ~= key then
        self.players[normalizedOriginalKey] = nil
    end

    local record = {
        name = name,
        status = status,
        note = tostring(note)
    }

    self.players[key] = record
    local persisted = self.storage:Save()
    self:Notify("saved", record)

    return true, {
        key = key,
        name = record.name,
        status = record.status,
        note = record.note
    }, persisted
end

function HighlightPlayers.Relationships:Delete(keyValue)
    local key = HighlightPlayers.Util.NormalizeName(keyValue)
    local record = self.players[key]

    if record == nil then
        return false, "Player was not found.", false
    end

    self.players[key] = nil
    local persisted = self.storage:Save()
    self:Notify("deleted", record)

    return true, record, persisted
end
