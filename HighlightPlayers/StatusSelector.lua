HighlightPlayers = HighlightPlayers or {}

HighlightPlayers.StatusSelector = {}

function HighlightPlayers.StatusSelector.New(
    parent,
    left,
    top,
    labels,
    onChanged,
    width
)
    local selector = {
        labels = labels,
        labelId = nil,
        listener = nil
    }

    local totalWidth = width or 320
    local arrowWidth = 30

    local previousButton = Turbine.UI.Lotro.Button()
    previousButton:SetParent(parent)
    previousButton:SetPosition(left, top)
    previousButton:SetSize(arrowWidth, 22)
    previousButton:SetText("<")

    local display = Turbine.UI.Label()
    display:SetParent(parent)
    display:SetPosition(left + arrowWidth + 4, top)
    display:SetSize(totalWidth - arrowWidth * 2 - 8, 22)
    display:SetFont(Turbine.UI.Lotro.Font.Verdana12)
    display:SetForeColor(Turbine.UI.Color.Black)
    display:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

    local nextButton = Turbine.UI.Lotro.Button()
    nextButton:SetParent(parent)
    nextButton:SetPosition(left + totalWidth - arrowWidth, top)
    nextButton:SetSize(arrowWidth, 22)
    nextButton:SetText(">")

    local function findCurrentIndex(all)
        for index, label in ipairs(all) do
            if label.id == selector.labelId then
                return index
            end
        end

        return nil
    end

    function selector:Refresh()
        local all = self.labels:GetAll()
        local current = self.labels:GetById(self.labelId)

        if current == nil then
            current = all[1]
            self.labelId = current ~= nil and current.id or nil
        end

        if current == nil then
            display:SetText("No labels")
            display:SetBackColor(Turbine.UI.Color(0.50, 0.50, 0.50))
            previousButton:SetEnabled(false)
            nextButton:SetEnabled(false)
            return
        end

        display:SetText(current.name)
        display:SetBackColor(self.labels:GetColor(current))
        previousButton:SetEnabled(table.getn(all) > 1)
        nextButton:SetEnabled(table.getn(all) > 1)
    end

    function selector:SetLabelId(labelId, notify)
        if self.labels:GetById(labelId) == nil then
            return false
        end

        self.labelId = labelId
        self:Refresh()

        if notify == true and onChanged ~= nil then
            onChanged(labelId)
        end

        return true
    end

    function selector:GetLabelId()
        return self.labelId
    end

    function selector:Move(direction)
        local all = self.labels:GetAll()
        local count = table.getn(all)
        if count == 0 then
            return
        end

        local index = findCurrentIndex(all) or 1
        index = index + direction

        if index < 1 then
            index = count
        elseif index > count then
            index = 1
        end

        self:SetLabelId(all[index].id, true)
    end

    function selector:Stop()
        if self.listener ~= nil then
            self.labels:RemoveListener(self.listener)
            self.listener = nil
        end
    end

    previousButton.Click = function()
        selector:Move(-1)
    end

    nextButton.Click = function()
        selector:Move(1)
    end

    selector.listener = labels:AddListener(function()
        selector:Refresh()
    end)

    selector:Refresh()
    return selector
end
