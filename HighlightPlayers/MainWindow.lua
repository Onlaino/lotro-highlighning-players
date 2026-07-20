HighlightPlayers = HighlightPlayers or {}

HighlightPlayers.MainWindow = {}

function HighlightPlayers.MainWindow.New(
    storage,
    relationships,
    targetTracker,
    cardWindow
)
    local settings = storage:GetData().settings.mainWindow
    local window = Turbine.UI.Lotro.Window()
    local width = 520
    local height = 470
    local left, top = HighlightPlayers.Util.ClampPosition(
        settings.left,
        settings.top,
        width,
        height
    )

    window:SetSize(width, height)
    window:SetPosition(left, top)
    window:SetText("Enemy Highlight")
    window:SetZOrder(10)
    window:SetWantsKeyEvents(true)
    window:SetVisible(false)

    local selectedTab = HighlightPlayers.Constants.Status.Friend
    local searchQueries = {
        friend = "",
        neutral = "",
        enemy = ""
    }
    local updatingSearch = false

    local nameLabel = Turbine.UI.Label()
    nameLabel:SetParent(window)
    nameLabel:SetPosition(20, 42)
    nameLabel:SetSize(100, 20)
    nameLabel:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
    nameLabel:SetText("Player name")

    local nameBox = Turbine.UI.Lotro.TextBox()
    nameBox:SetParent(window)
    nameBox:SetPosition(20, 62)
    nameBox:SetSize(245, 22)
    nameBox:SetBackColor(Turbine.UI.Color(0.05, 0.05, 0.05))
    nameBox:SetForeColor(Turbine.UI.Color.White)
    nameBox:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    nameBox:SetMultiline(false)

    local targetButton = Turbine.UI.Lotro.Button()
    targetButton:SetParent(window)
    targetButton:SetPosition(275, 62)
    targetButton:SetSize(105, 22)
    targetButton:SetText("Use target")

    local addButton = Turbine.UI.Lotro.Button()
    addButton:SetParent(window)
    addButton:SetPosition(390, 62)
    addButton:SetSize(110, 22)
    addButton:SetText("Add / update")

    local statusLabel = Turbine.UI.Label()
    statusLabel:SetParent(window)
    statusLabel:SetPosition(20, 93)
    statusLabel:SetSize(100, 20)
    statusLabel:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
    statusLabel:SetText("Status")

    local statusSelector = HighlightPlayers.StatusSelector.New(
        window,
        20,
        113,
        nil
    )

    local messageLabel = Turbine.UI.Label()
    messageLabel:SetParent(window)
    messageLabel:SetPosition(345, 105)
    messageLabel:SetSize(155, 35)
    messageLabel:SetFont(Turbine.UI.Lotro.Font.Verdana12)
    messageLabel:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    messageLabel:SetMultiline(true)
    messageLabel:SetVisible(false)

    local tabButtons = {}
    local searchBox

    for index, status in ipairs(HighlightPlayers.Constants.StatusOrder) do
        local tabStatus = status
        local button = Turbine.UI.Lotro.Button()
        button:SetParent(window)
        button:SetPosition(20 + (index - 1) * 160, 153)
        button:SetSize(150, 24)

        button.Click = function()
            selectedTab = tabStatus
            updatingSearch = true
            searchBox:SetText(searchQueries[selectedTab])
            updatingSearch = false
            window.Refresh()
        end

        tabButtons[tabStatus] = button
    end

    local searchLabel = Turbine.UI.Label()
    searchLabel:SetParent(window)
    searchLabel:SetPosition(20, 190)
    searchLabel:SetSize(55, 20)
    searchLabel:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
    searchLabel:SetText("Search")

    searchBox = Turbine.UI.Lotro.TextBox()
    searchBox:SetParent(window)
    searchBox:SetPosition(78, 187)
    searchBox:SetSize(320, 22)
    searchBox:SetBackColor(Turbine.UI.Color(0.05, 0.05, 0.05))
    searchBox:SetForeColor(Turbine.UI.Color.White)
    searchBox:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    searchBox:SetMultiline(false)

    local clearSearchButton = Turbine.UI.Lotro.Button()
    clearSearchButton:SetParent(window)
    clearSearchButton:SetPosition(408, 187)
    clearSearchButton:SetSize(92, 22)
    clearSearchButton:SetText("Clear")

    local list = Turbine.UI.ListBox()
    list:SetParent(window)
    list:SetPosition(20, 219)
    list:SetSize(width - 57, 213)

    local listScroll = Turbine.UI.Lotro.ScrollBar()
    listScroll:SetParent(window)
    listScroll:SetPosition(width - 34, 219)
    listScroll:SetSize(10, 213)
    listScroll:SetOrientation(Turbine.UI.Orientation.Vertical)
    list:SetVerticalScrollBar(listScroll)

    local emptyLabel = Turbine.UI.Label()
    emptyLabel:SetParent(window)
    emptyLabel:SetPosition(20, 290)
    emptyLabel:SetSize(width - 40, 30)
    emptyLabel:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
    emptyLabel:SetForeColor(Turbine.UI.Color(0.65, 0.65, 0.65))
    emptyLabel:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    emptyLabel:SetText("No saved players in this tab.")
    emptyLabel:SetVisible(false)

    local hintLabel = Turbine.UI.Label()
    hintLabel:SetParent(window)
    hintLabel:SetPosition(20, 438)
    hintLabel:SetSize(width - 40, 18)
    hintLabel:SetFont(Turbine.UI.Lotro.Font.Verdana12)
    hintLabel:SetForeColor(Turbine.UI.Color(0.70, 0.70, 0.70))
    hintLabel:SetText("Click a player to open the card. Command help: /eh help")

    local function showMessage(text, isError)
        messageLabel:SetText(text or "")
        messageLabel:SetForeColor(
            isError and Turbine.UI.Color(1.00, 0.25, 0.25) or
            Turbine.UI.Color(0.25, 1.00, 0.35)
        )
        messageLabel:SetVisible(text ~= nil and text ~= "")
    end

    local function savePosition()
        settings.left = window:GetLeft()
        settings.top = window:GetTop()
        storage:Save()
    end

    window.Refresh = function()
        for _, status in ipairs(HighlightPlayers.Constants.StatusOrder) do
            local count = relationships:GetCount(status)
            tabButtons[status]:SetText(
                HighlightPlayers.Constants.StatusLabels[status] ..
                " (" .. tostring(count) .. ")"
            )
            tabButtons[status]:SetEnabled(status ~= selectedTab)
        end

        list:ClearItems()
        local search = searchQueries[selectedTab]
        local records = relationships:GetList(selectedTab, search)
        if HighlightPlayers.Util.Trim(search) == "" then
            emptyLabel:SetText("No saved players in this tab.")
        else
            emptyLabel:SetText("No players match the search.")
        end
        emptyLabel:SetVisible(table.getn(records) == 0)

        for _, record in ipairs(records) do
            local recordKey = record.key
            local item = Turbine.UI.Lotro.Button()
            item:SetSize(list:GetWidth(), 25)
            item:SetText(
                record.name ..
                ((record.note ~= nil and record.note ~= "") and "  *" or "")
            )

            item.Click = function()
                cardWindow.OpenExisting(recordKey)
            end

            list:AddItem(item)
        end

        targetButton:SetEnabled(targetTracker:GetCurrentName() ~= nil)
        clearSearchButton:SetEnabled(
            HighlightPlayers.Util.Trim(searchQueries[selectedTab]) ~= ""
        )
    end

    searchBox.TextChanged = function()
        if updatingSearch then
            return
        end

        searchQueries[selectedTab] = searchBox:GetText()
        window.Refresh()
    end

    clearSearchButton.Click = function()
        searchQueries[selectedTab] = ""
        updatingSearch = true
        searchBox:SetText("")
        updatingSearch = false
        window.Refresh()
        searchBox:Focus()
    end

    window.Open = function()
        local newLeft, newTop = HighlightPlayers.Util.ClampPosition(
            window:GetLeft(),
            window:GetTop(),
            width,
            height
        )
        window:SetPosition(newLeft, newTop)
        showMessage(nil, false)
        window.Refresh()
        window:SetVisible(true)
        window:Activate()
        nameBox:Focus()
    end

    window.Hide = function()
        settings.left = window:GetLeft()
        settings.top = window:GetTop()
        window:SetVisible(false)
        storage:Save()
    end

    window.Toggle = function()
        if window:IsVisible() then
            window.Hide()
        else
            window.Open()
        end
    end

    targetButton.Click = function()
        local targetName = targetTracker:GetCurrentName()

        if targetName == nil then
            showMessage("No target selected.", true)
            return
        end

        nameBox:SetText(targetName)
        showMessage(nil, false)
    end

    addButton.Click = function()
        local succeeded, result, persisted = relationships:SavePlayer(
            nil,
            nameBox:GetText(),
            statusSelector:GetStatus(),
            nil
        )

        if not succeeded then
            showMessage(result, true)
            return
        end

        selectedTab = result.status
        window.Refresh()

        if persisted then
            showMessage("Saved " .. result.name .. ".", false)
            nameBox:SetText("")
        else
            showMessage("Saved in memory; persistence failed.", true)
        end
    end

    window.Closed = function()
        window.Hide()
    end

    window.KeyDown = function(sender, args)
        if args.Action == Turbine.UI.Lotro.Action.Escape then
            window.Hide()
        end
    end

    window.PositionChanged = function()
        settings.left = window:GetLeft()
        settings.top = window:GetTop()
    end

    local relationshipListener = relationships:AddListener(function()
        if window:IsVisible() then
            window.Refresh()
        end
    end)

    local targetListener = targetTracker:AddListener(function()
        targetButton:SetEnabled(targetTracker:GetCurrentName() ~= nil)
    end)

    window.Stop = function()
        relationships:RemoveListener(relationshipListener)
        targetTracker:RemoveListener(targetListener)
        savePosition()
        window:SetVisible(false)
    end

    window.Refresh()
    return window
end
