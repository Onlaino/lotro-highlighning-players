HighlightPlayers = HighlightPlayers or {}

HighlightPlayers.Labels = {}
HighlightPlayers.Labels.__index = HighlightPlayers.Labels

local function parseColorComponent(value)
    local number = tonumber(value)
    if number == nil or number < 0 or number > 255 or
        math.floor(number) ~= number then
        return nil
    end

    return math.floor(number)
end

function HighlightPlayers.Labels.New(storage)
    local instance = {
        storage = storage,
        labels = storage:GetData().labels,
        relationships = nil,
        listeners = {}
    }

    setmetatable(instance, HighlightPlayers.Labels)
    return instance
end

function HighlightPlayers.Labels:SetRelationships(relationships)
    self.relationships = relationships
end

function HighlightPlayers.Labels:AddListener(listener)
    table.insert(self.listeners, listener)
    return listener
end

function HighlightPlayers.Labels:RemoveListener(listener)
    for index = 1, table.getn(self.listeners) do
        if self.listeners[index] == listener then
            table.remove(self.listeners, index)
            return
        end
    end
end

function HighlightPlayers.Labels:Notify(eventName, label)
    for index = 1, table.getn(self.listeners) do
        self.listeners[index](eventName, label)
    end
end

function HighlightPlayers.Labels:GetAll()
    return self.labels
end

function HighlightPlayers.Labels:GetFirst()
    return self.labels[1]
end

function HighlightPlayers.Labels:GetById(id)
    for _, label in ipairs(self.labels) do
        if label.id == id then
            return label
        end
    end

    return nil
end

function HighlightPlayers.Labels:FindByName(name)
    local normalized = HighlightPlayers.Util.NormalizeName(name)

    for _, label in ipairs(self.labels) do
        if HighlightPlayers.Util.NormalizeName(label.name) == normalized then
            return label
        end
    end

    return nil
end

function HighlightPlayers.Labels:GetColor(labelOrId)
    local label = labelOrId
    if type(labelOrId) ~= "table" then
        label = self:GetById(labelOrId)
    end

    if label == nil then
        return Turbine.UI.Color(0.65, 0.65, 0.65)
    end

    return Turbine.UI.Color(
        label.red / 255,
        label.green / 255,
        label.blue / 255
    )
end

function HighlightPlayers.Labels:ValidateName(nameValue, excludedId)
    local name = HighlightPlayers.Util.Trim(nameValue)

    if name == "" then
        return false, "Label name is required."
    end

    if string.len(name) > HighlightPlayers.Constants.LabelNameMaxLength then
        return false, "Label name is too long."
    end

    if string.find(name, "[%c]") ~= nil then
        return false, "Label name contains invalid characters."
    end

    local existing = self:FindByName(name)
    if existing ~= nil and existing.id ~= excludedId then
        return false, "A label with this name already exists."
    end

    return true, name
end

function HighlightPlayers.Labels:GenerateId()
    local data = self.storage:GetData()

    while true do
        local id = "custom_" .. tostring(data.nextLabelId)
        data.nextLabelId = data.nextLabelId + 1

        if self:GetById(id) == nil then
            return id
        end
    end
end

function HighlightPlayers.Labels:SaveLabel(id, nameValue, red, green, blue)
    local valid, nameOrError = self:ValidateName(nameValue, id)
    if not valid then
        return false, nameOrError, false
    end

    local parsedRed = parseColorComponent(red)
    local parsedGreen = parseColorComponent(green)
    local parsedBlue = parseColorComponent(blue)

    if parsedRed == nil or parsedGreen == nil or parsedBlue == nil then
        return false, "RGB values must be whole numbers from 0 to 255.", false
    end

    local label = nil
    local eventName = "updated"

    if id ~= nil then
        label = self:GetById(id)
        if label == nil then
            return false, "Label was not found.", false
        end
    else
        label = { id = self:GenerateId() }
        table.insert(self.labels, label)
        eventName = "added"
    end

    label.name = nameOrError
    label.red = parsedRed
    label.green = parsedGreen
    label.blue = parsedBlue

    local persisted = self.storage:Save()
    self:Notify(eventName, label)
    return true, label, persisted
end

function HighlightPlayers.Labels:Delete(id)
    if table.getn(self.labels) <= 1 then
        return false, "The last label cannot be deleted.", false
    end

    local usageCount = 0
    if self.relationships ~= nil then
        usageCount = self.relationships:GetCount(id)
    end

    if usageCount > 0 then
        return false,
            "Reassign or delete " .. tostring(usageCount) ..
            " player(s) using this label first.",
            false
    end

    for index = 1, table.getn(self.labels) do
        if self.labels[index].id == id then
            local removed = table.remove(self.labels, index)
            local persisted = self.storage:Save()
            self:Notify("deleted", removed)
            return true, removed, persisted
        end
    end

    return false, "Label was not found.", false
end
