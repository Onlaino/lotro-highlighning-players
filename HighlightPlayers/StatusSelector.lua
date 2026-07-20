HighlightPlayers = HighlightPlayers or {}

HighlightPlayers.StatusSelector = {}

function HighlightPlayers.StatusSelector.New(parent, left, top, onChanged)
    local selector = {
        status = HighlightPlayers.Constants.Status.Friend,
        buttons = {}
    }

    local buttonWidth = 100
    local gap = 8

    for index, status in ipairs(HighlightPlayers.Constants.StatusOrder) do
        local buttonStatus = status
        local button = Turbine.UI.Lotro.Button()
        button:SetParent(parent)
        button:SetPosition(left + (index - 1) * (buttonWidth + gap), top)
        button:SetSize(buttonWidth, 22)
        button:SetText(HighlightPlayers.Constants.StatusLabels[buttonStatus])

        button.Click = function()
            selector:SetStatus(buttonStatus)
            if onChanged ~= nil then
                onChanged(buttonStatus)
            end
        end

        selector.buttons[buttonStatus] = button
    end

    function selector:SetStatus(status)
        if not HighlightPlayers.Util.IsStatus(status) then
            return
        end

        self.status = status

        for _, currentStatus in ipairs(HighlightPlayers.Constants.StatusOrder) do
            self.buttons[currentStatus]:SetEnabled(currentStatus ~= status)
        end
    end

    function selector:GetStatus()
        return self.status
    end

    selector:SetStatus(selector.status)
    return selector
end
