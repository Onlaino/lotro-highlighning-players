HighlightPlayers = HighlightPlayers or {}

HighlightPlayers.MainWindow = {}

function HighlightPlayers.MainWindow.New(
    storage,
    relationships,
    labels,
    targetTracker,
    cardWindow,
    labelsWindow
)
    local settings = storage:GetData().settings.mainWindow
    local window = Turbine.UI.Lotro.Window()
    local width = 620
    local height = 580
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

    local firstLabel = labels:GetFirst()
    local selectedLabelId = firstLabel ~= nil and firstLabel.id or nil
    local searchQueries = {}
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
    nameBox:SetSize(255, 22)
    nameBox:SetBackColor(Turbine.UI.Color(0.05, 0.05, 0.05))
    nameBox:SetForeColor(Turbine.UI.Color.White)
    nameBox:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    nameBox:SetMultiline(false)

    local targetButton = Turbine.UI.Lotro.Button()
    targetButton:SetParent(window)
    targetButton:SetPosition(285, 62)
    targetButton:SetSize(100, 22)
    targetButton:SetText("Use target")

    local addButton = Turbine.UI.Lotro.Button()
    addButton:SetParent(window)
    addButton:SetPosition(395, 62)
    addButton:SetSize(100, 22)
    addButton:SetText("Add / update")

    local manageButton = Turbine.UI.Lotro.Button()
    manageButton:SetParent(window)
    manageButton:SetPosition(505, 62)
    manageButton:SetSize(95, 22)
    manageButton:SetText("Manage labels")

    local labelTitle = Turbine.UI.Label()
    labelTitle:SetParent(window)
    labelTitle:SetPosition(20, 93)
    labelTitle:SetSize(340, 20)
    labelTitle:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
    labelTitle:SetText("Choose a label for this player")

    local labelSelector = HighlightPlayers.StatusSelector.New(
        window,
        20,
        113,
        labels,
        nil,
        340,
        96
    )

    local messageLabel = Turbine.UI.Label()
    messageLabel:SetParent(window)
    messageLabel:SetPosition(375, 101)
    messageLabel:SetSize(225, 96)
    messageLabel:SetFont(Turbine.UI.Lotro.Font.Verdana12)
    messageLabel:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    messageLabel:SetMultiline(true)
    messageLabel:SetVisible(false)

    local categoriesTitle = Turbine.UI.Label()
    categoriesTitle:SetParent(window)
    categoriesTitle:SetPosition(20, 230)
    categoriesTitle:SetSize(145, 20)
    categoriesTitle:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
    categoriesTitle:SetText("Labels")

    local categoryList = Turbine.UI.ListBox()
    categoryList:SetParent(window)
    categoryList:SetPosition(20, 253)
    categoryList:SetSize(140, 280)

    local categoryScroll = Turbine.UI.Lotro.ScrollBar()
    categoryScroll:SetParent(window)
    categoryScroll:SetPosition(162, 253)
    categoryScroll:SetSize(10, 280)
    categoryScroll:SetOrientation(Turbine.UI.Orientation.Vertical)
    categoryList:SetVerticalScrollBar(categoryScroll)

    local searchLabel = Turbine.UI.Label()
    searchLabel:SetParent(window)
    searchLabel:SetPosition(185, 230)
    searchLabel:SetSize(55, 20)
    searchLabel:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
    searchLabel:SetText("Search")

    local searchBox = Turbine.UI.Lotro.TextBox()
    searchBox:SetParent(window)
    searchBox:SetPosition(243, 227)
    searchBox:SetSize(267, 22)
    searchBox:SetBackColor(Turbine.UI.Color(0.05, 0.05, 0.05))
    searchBox:SetForeColor(Turbine.UI.Color.White)
    searchBox:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    searchBox:SetMultiline(false)

    local clearSearchButton = Turbine.UI.Lotro.Button()
    clearSearchButton:SetParent(window)
    clearSearchButton:SetPosition(520, 227)
    clearSearchButton:SetSize(80, 22)
    clearSearchButton:SetText("Clear")

    local list = Turbine.UI.ListBox()
    list:SetParent(window)
    list:SetPosition(185, 253)
    list:SetSize(398, 280)

    local listScroll = Turbine.UI.Lotro.ScrollBar()
    listScroll:SetParent(window)
    listScroll:SetPosition(590, 253)
    listScroll:SetSize(10, 280)
    listScroll:SetOrientation(Turbine.UI.Orientation.Vertical)
    list:SetVerticalScrollBar(listScroll)

    local emptyLabel = Turbine.UI.Label()
    emptyLabel:SetParent(window)
    emptyLabel:SetPosition(185, 370)
    emptyLabel:SetSize(398, 30)
    emptyLabel:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
    emptyLabel:SetForeColor(Turbine.UI.Color(0.65, 0.65, 0.65))
    emptyLabel:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    emptyLabel:SetVisible(false)

    local hintLabel = Turbine.UI.Label()
    hintLabel:SetParent(window)
    hintLabel:SetPosition(20, 545)
    hintLabel:SetSize(width - 40, 18)
    hintLabel:SetFont(Turbine.UI.Lotro.Font.Verdana12)
    hintLabel:SetForeColor(Turbine.UI.Color(0.70, 0.70, 0.70))
    hintLabel:SetText("Click a player to edit. Label settings: /eh labels")

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
        if labels:GetById(selectedLabelId) == nil then
            local fallback = labels:GetFirst()
            selectedLabelId = fallback ~= nil and fallback.id or nil
            updatingSearch = true
            searchBox:SetText(searchQueries[selectedLabelId] or "")
            updatingSearch = false
        end

        categoryList:ClearItems()
        for _, label in ipairs(labels:GetAll()) do
            local currentId = label.id
            local button = Turbine.UI.Lotro.Button()
            button:SetSize(categoryList:GetWidth(), 28)
            button:SetText(
                label.name .. " (" ..
                tostring(relationships:GetCount(label.id)) .. ")"
            )
            button:SetEnabled(currentId ~= selectedLabelId)
            button.Click = function()
                selectedLabelId = currentId
                labelSelector:SetLabelId(currentId, false)
                updatingSearch = true
                searchBox:SetText(searchQueries[currentId] or "")
                updatingSearch = false
                window.Refresh()
            end
            categoryList:AddItem(button)
        end

        list:ClearItems()
        local search = searchQueries[selectedLabelId] or ""
        local records = relationships:GetList(selectedLabelId, search)
        emptyLabel:SetText(
            HighlightPlayers.Util.Trim(search) == "" and
            "No saved players with this label." or
            "No players match the search."
        )
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
            HighlightPlayers.Util.Trim(search) ~= ""
        )
    end

    searchBox.TextChanged = function()
        if updatingSearch then
            return
        end

        searchQueries[selectedLabelId] = searchBox:GetText()
        window.Refresh()
    end

    clearSearchButton.Click = function()
        searchQueries[selectedLabelId] = ""
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
        window:Focus()
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

    manageButton.Click = function()
        labelsWindow.Open()
    end

    addButton.Click = function()
        local succeeded, result, persisted = relationships:SavePlayer(
            nil,
            nameBox:GetText(),
            labelSelector:GetLabelId(),
            nil
        )

        if not succeeded then
            showMessage(result, true)
            return
        end

        selectedLabelId = result.labelId
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

    local labelListener = labels:AddListener(function()
        if window:IsVisible() then
            window.Refresh()
        end
    end)

    local targetListener = targetTracker:AddListener(function()
        targetButton:SetEnabled(targetTracker:GetCurrentName() ~= nil)
    end)

    window.Stop = function()
        relationships:RemoveListener(relationshipListener)
        labels:RemoveListener(labelListener)
        targetTracker:RemoveListener(targetListener)
        labelSelector:Stop()
        savePosition()
        window:SetVisible(false)
    end

    window.Refresh()
    return window
end
