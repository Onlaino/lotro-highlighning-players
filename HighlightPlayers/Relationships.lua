HighlightPlayers = HighlightPlayers or {}

HighlightPlayers.Relationships = {}
HighlightPlayers.Relationships.__index = HighlightPlayers.Relationships

function HighlightPlayers.Relationships.New(storage, labels)
    local instance = {
        storage = storage,
        labels = labels,
        players = storage:GetData().players,
        byLabel = {},
        listeners = {}
    }

    setmetatable(instance, HighlightPlayers.Relationships)
    local migrated = instance:NormalizeLoadedPlayers()
    instance:RebuildIndex()

    if migrated then
        storage:Save()
    end

    return instance
end

function HighlightPlayers.Relationships:NormalizeLoadedPlayers()
    local normalizedPlayers = {}
    local fallback = self.labels:GetFirst()
    local migrated = false

    for key, record in pairs(self.players) do
        if type(record) == "table" then
            local valid, name = HighlightPlayers.Util.ValidateName(
                record.name or key
            )
            local labelId = record.labelId or record.status

            if self.labels:GetById(labelId) == nil and fallback ~= nil then
                labelId = fallback.id
                migrated = true
            end

            if record.status ~= nil or record.labelId ~= labelId then
                migrated = true
            end

            if valid and labelId ~= nil then
                local normalizedName = HighlightPlayers.Util.NormalizeName(name)
                normalizedPlayers[normalizedName] = {
                    name = name,
                    labelId = labelId,
                    note = tostring(record.note or "")
                }
            end
        end
    end

    self.players = normalizedPlayers
    self.storage:GetData().players = normalizedPlayers
    return migrated
end

function HighlightPlayers.Relationships:RebuildIndex()
    local index = {}

    for _, label in ipairs(self.labels:GetAll()) do
        index[label.id] = {}
    end

    for key, record in pairs(self.players) do
        if index[record.labelId] == nil then
            index[record.labelId] = {}
        end

        table.insert(index[record.labelId], {
            key = key,
            name = record.name,
            labelId = record.labelId,
            note = record.note
        })
    end

    for _, records in pairs(index) do
        table.sort(records, function(left, right)
            return string.lower(left.name) < string.lower(right.name)
        end)
    end

    self.byLabel = index
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

function HighlightPlayers.Relationships:GetList(labelId, searchValue)
    local source = self.byLabel[labelId] or {}
    local search = HighlightPlayers.Util.NormalizeName(searchValue)

    if search == "" then
        return source
    end

    local result = {}
    for _, record in ipairs(source) do
        local normalizedName = HighlightPlayers.Util.NormalizeName(record.name)
        if string.find(normalizedName, search, 1, true) ~= nil then
            table.insert(result, record)
        end
    end

    return result
end

function HighlightPlayers.Relationships:GetCount(labelId)
    return table.getn(self.byLabel[labelId] or {})
end

function HighlightPlayers.Relationships:SavePlayer(
    originalKey,
    nameValue,
    labelId,
    noteValue
)
    local valid, nameOrError = HighlightPlayers.Util.ValidateName(nameValue)
    if not valid then
        return false, nameOrError, false
    end

    if self.labels:GetById(labelId) == nil then
        return false, "Choose an existing label.", false
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
        labelId = labelId,
        note = tostring(note)
    }

    self.players[key] = record
    self:RebuildIndex()
    local persisted = self.storage:Save()
    self:Notify("saved", record)

    return true, {
        key = key,
        name = record.name,
        labelId = record.labelId,
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
    self:RebuildIndex()
    local persisted = self.storage:Save()
    self:Notify("deleted", record)

    return true, record, persisted
end
