HighlightPlayers = HighlightPlayers or {}

HighlightPlayers.Relationships = {}
HighlightPlayers.Relationships.__index = HighlightPlayers.Relationships

local function filterRecords(source, searchValue)
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

local function copyAlternativeKeys(alts)
    local result = {}

    if type(alts) ~= "table" then
        return result
    end

    for _, key in ipairs(alts) do
        table.insert(result, key)
    end

    return result
end

function HighlightPlayers.Relationships.New(storage, labels)
    local instance = {
        storage = storage,
        labels = labels,
        players = storage:GetData().players,
        byLabel = {},
        allRecords = {},
        alternativeParents = {},
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
    local pendingAlternatives = {}
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
                    note = tostring(record.note or ""),
                    alts = {}
                }
                pendingAlternatives[normalizedName] =
                    type(record.alts) == "table" and
                    copyAlternativeKeys(record.alts) or {}

                if key ~= normalizedName or type(record.alts) ~= "table" then
                    migrated = true
                end
            end
        end
    end

    for primaryKey, record in pairs(normalizedPlayers) do
        local normalizedAlternatives = {}
        local usedAlternatives = {}

        for _, value in ipairs(pendingAlternatives[primaryKey] or {}) do
            local valid, alternativeName = HighlightPlayers.Util.ValidateName(
                value
            )
            local alternativeKey = HighlightPlayers.Util.NormalizeName(
                alternativeName
            )

            if valid and alternativeKey ~= primaryKey and
                normalizedPlayers[alternativeKey] ~= nil and
                usedAlternatives[alternativeKey] ~= true then
                table.insert(normalizedAlternatives, alternativeKey)
                usedAlternatives[alternativeKey] = true
            else
                migrated = true
            end
        end

        record.alts = normalizedAlternatives
    end

    self.players = normalizedPlayers
    self.storage:GetData().players = normalizedPlayers
    return migrated
end

function HighlightPlayers.Relationships:RebuildIndex()
    local index = {}
    local allRecords = {}
    local alternativeParents = {}

    for _, label in ipairs(self.labels:GetAll()) do
        index[label.id] = {}
    end

    for key, record in pairs(self.players) do
        if index[record.labelId] == nil then
            index[record.labelId] = {}
        end

        local indexedRecord = {
            key = key,
            name = record.name,
            labelId = record.labelId,
            note = record.note,
            alternativeCount = table.getn(record.alts or {})
        }
        table.insert(index[record.labelId], indexedRecord)
        table.insert(allRecords, indexedRecord)

        for _, alternativeKey in ipairs(record.alts or {}) do
            if alternativeParents[alternativeKey] == nil then
                alternativeParents[alternativeKey] = {}
            end
            table.insert(alternativeParents[alternativeKey], key)
        end
    end

    local function sortRecords(records)
        table.sort(records, function(left, right)
            return string.lower(left.name) < string.lower(right.name)
        end)
    end

    for _, records in pairs(index) do
        sortRecords(records)
    end
    sortRecords(allRecords)

    self.byLabel = index
    self.allRecords = allRecords
    self.alternativeParents = alternativeParents
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

function HighlightPlayers.Relationships:GetAlternativeRecords(keyValue)
    local record = self:GetByKey(keyValue)
    local result = {}

    if record == nil then
        return result
    end

    for _, alternativeKey in ipairs(record.alts or {}) do
        local alternative = self.players[alternativeKey]
        if alternative ~= nil then
            table.insert(result, {
                key = alternativeKey,
                name = alternative.name,
                labelId = alternative.labelId,
                note = alternative.note
            })
        end
    end

    table.sort(result, function(left, right)
        return string.lower(left.name) < string.lower(right.name)
    end)
    return result
end

function HighlightPlayers.Relationships:GetAlternativeParents(keyValue)
    local key = HighlightPlayers.Util.NormalizeName(keyValue)
    local result = {}

    for _, parentKey in ipairs(self.alternativeParents[key] or {}) do
        local parent = self.players[parentKey]
        if parent ~= nil then
            table.insert(result, {
                key = parentKey,
                name = parent.name,
                labelId = parent.labelId,
                note = parent.note
            })
        end
    end

    table.sort(result, function(left, right)
        return string.lower(left.name) < string.lower(right.name)
    end)
    return result
end

function HighlightPlayers.Relationships:GetRelatedRecords(keyValue)
    local rootKey = HighlightPlayers.Util.NormalizeName(keyValue)
    if self.players[rootKey] == nil then
        return {}
    end

    local queue = { rootKey }
    local distances = { [rootKey] = 0 }
    local cursor = 1

    while cursor <= table.getn(queue) do
        local currentKey = queue[cursor]
        local current = self.players[currentKey]
        cursor = cursor + 1

        local neighbors = {}
        for _, alternativeKey in ipairs(current.alts or {}) do
            table.insert(neighbors, alternativeKey)
        end
        for _, parentKey in ipairs(
            self.alternativeParents[currentKey] or {}
        ) do
            table.insert(neighbors, parentKey)
        end

        for _, neighborKey in ipairs(neighbors) do
            if distances[neighborKey] == nil and
                self.players[neighborKey] ~= nil then
                distances[neighborKey] = distances[currentKey] + 1
                table.insert(queue, neighborKey)
            end
        end
    end

    local result = {}
    for key, distance in pairs(distances) do
        if key ~= rootKey then
            local record = self.players[key]
            table.insert(result, {
                key = key,
                name = record.name,
                labelId = record.labelId,
                note = record.note,
                direct = distance == 1
            })
        end
    end

    table.sort(result, function(left, right)
        if left.direct ~= right.direct then
            return left.direct
        end
        return string.lower(left.name) < string.lower(right.name)
    end)
    return result
end

function HighlightPlayers.Relationships:GetList(labelId, searchValue)
    local source = self.byLabel[labelId] or {}
    return filterRecords(source, searchValue)
end

function HighlightPlayers.Relationships:GetAllList(searchValue)
    return filterRecords(self.allRecords, searchValue)
end

function HighlightPlayers.Relationships:GetCount(labelId)
    return table.getn(self.byLabel[labelId] or {})
end

function HighlightPlayers.Relationships:GetTotalCount()
    return table.getn(self.allRecords)
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
        return false,
            HighlightPlayers.Localization.Get("choose_existing_label"),
            false
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
        return false, HighlightPlayers.Localization.Get("player_name_exists"),
            false
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

        for _, player in pairs(self.players) do
            for index, alternativeKey in ipairs(player.alts or {}) do
                if alternativeKey == normalizedOriginalKey then
                    player.alts[index] = key
                end
            end
        end
    end

    local record = {
        name = name,
        labelId = labelId,
        note = tostring(note),
        alts = existing ~= nil and copyAlternativeKeys(existing.alts) or {}
    }

    self.players[key] = record
    self:RebuildIndex()
    local persisted = self.storage:Save()
    self:Notify("saved", record)

    return true, {
        key = key,
        name = record.name,
        labelId = record.labelId,
        note = record.note,
        alts = copyAlternativeKeys(record.alts)
    }, persisted
end

function HighlightPlayers.Relationships:AddAlternative(
    primaryKeyValue,
    alternativeNameValue
)
    local primaryKey = HighlightPlayers.Util.NormalizeName(primaryKeyValue)
    local primary = self.players[primaryKey]
    if primary == nil then
        return false, HighlightPlayers.Localization.Get("player_not_found"), false
    end

    local valid, alternativeName = HighlightPlayers.Util.ValidateName(
        alternativeNameValue
    )
    if not valid then
        return false, alternativeName, false
    end

    local alternativeKey = HighlightPlayers.Util.NormalizeName(alternativeName)
    if alternativeKey == primaryKey then
        return false, HighlightPlayers.Localization.Get("alternative_self"), false
    end

    for _, key in ipairs(primary.alts or {}) do
        if key == alternativeKey then
            return false,
                HighlightPlayers.Localization.Get("alternative_exists"), false
        end
    end

    if self.players[alternativeKey] == nil then
        self.players[alternativeKey] = {
            name = alternativeName,
            labelId = primary.labelId,
            note = "",
            alts = {}
        }
    end

    primary.alts = primary.alts or {}
    table.insert(primary.alts, alternativeKey)
    self:RebuildIndex()
    local persisted = self.storage:Save()
    self:Notify("alternative_added", primary)

    return true, self.players[alternativeKey], persisted
end

function HighlightPlayers.Relationships:RemoveConnection(
    firstKeyValue,
    secondKeyValue
)
    local firstKey = HighlightPlayers.Util.NormalizeName(firstKeyValue)
    local secondKey = HighlightPlayers.Util.NormalizeName(secondKeyValue)
    local first = self.players[firstKey]
    local second = self.players[secondKey]

    if first == nil or second == nil then
        return false, HighlightPlayers.Localization.Get("player_not_found"), false
    end

    local removed = false
    local function removeFrom(record, key)
        for index = table.getn(record.alts or {}), 1, -1 do
            if record.alts[index] == key then
                table.remove(record.alts, index)
                removed = true
            end
        end
    end

    removeFrom(first, secondKey)
    removeFrom(second, firstKey)

    if not removed then
        return false, HighlightPlayers.Localization.Get("alternative_not_found"), false
    end

    self:RebuildIndex()
    local persisted = self.storage:Save()
    self:Notify("alternative_removed", first)
    return true, first, persisted
end

function HighlightPlayers.Relationships:Delete(keyValue)
    local key = HighlightPlayers.Util.NormalizeName(keyValue)
    local record = self.players[key]

    if record == nil then
        return false, HighlightPlayers.Localization.Get("player_not_found"),
            false
    end

    self.players[key] = nil
    for _, player in pairs(self.players) do
        for index = table.getn(player.alts or {}), 1, -1 do
            if player.alts[index] == key then
                table.remove(player.alts, index)
            end
        end
    end
    self:RebuildIndex()
    local persisted = self.storage:Save()
    self:Notify("deleted", record)

    return true, record, persisted
end
