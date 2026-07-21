HighlightPlayers = HighlightPlayers or {}

HighlightPlayers.PlayerNoteWindow = {}

function HighlightPlayers.PlayerNoteWindow.New(storage, relationships, labels)
    local settings = storage:GetData().settings.noteWindow
    local window = Turbine.UI.Lotro.Window()
    local width = 420
    local height = 330
    local left, top = HighlightPlayers.Util.ClampPosition(
        settings.left,
        settings.top,
        width,
        height
    )

    window:SetSize(width, height)
    window:SetPosition(left, top)
    window:SetText("Player note")
    window:SetZOrder(25)
    window:SetWantsKeyEvents(true)
    window:SetVisible(false)

    local currentKey = nil

    local playerName = Turbine.UI.Label()
    playerName:SetParent(window)
    playerName:SetPosition(20, 43)
    playerName:SetSize(width - 40, 24)
    playerName:SetFont(Turbine.UI.Lotro.Font.TrajanPro18)

    local labelPanel = Turbine.UI.Control()
    labelPanel:SetParent(window)
    labelPanel:SetPosition(20, 73)
    labelPanel:SetSize(width - 40, 28)
    labelPanel:SetBackColor(Turbine.UI.Color(0.07, 0.07, 0.06))
    labelPanel:SetMouseVisible(false)

    local labelAccent = Turbine.UI.Control()
    labelAccent:SetParent(labelPanel)
    labelAccent:SetPosition(2, 2)
    labelAccent:SetSize(5, 24)
    labelAccent:SetMouseVisible(false)

    local labelName = Turbine.UI.Label()
    labelName:SetParent(labelPanel)
    labelName:SetPosition(14, 2)
    labelName:SetSize(width - 60, 24)
    labelName:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    labelName:SetForeColor(Turbine.UI.Color.White)
    labelName:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    labelName:SetMouseVisible(false)

    local noteLabel = Turbine.UI.Label()
    noteLabel:SetParent(window)
    noteLabel:SetPosition(20, 111)
    noteLabel:SetSize(100, 20)
    noteLabel:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
    noteLabel:SetText("Note")

    local noteBox = Turbine.UI.Lotro.TextBox()
    noteBox:SetParent(window)
    noteBox:SetPosition(20, 132)
    noteBox:SetSize(width - 57, 112)
    noteBox:SetBackColor(Turbine.UI.Color(0.05, 0.05, 0.05))
    noteBox:SetForeColor(Turbine.UI.Color.White)
    noteBox:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    noteBox:SetMultiline(true)

    local noteScroll = Turbine.UI.Lotro.ScrollBar()
    noteScroll:SetParent(window)
    noteScroll:SetPosition(width - 34, 132)
    noteScroll:SetSize(10, 112)
    noteScroll:SetOrientation(Turbine.UI.Orientation.Vertical)
    noteBox:SetVerticalScrollBar(noteScroll)

    local messageLabel = Turbine.UI.Label()
    messageLabel:SetParent(window)
    messageLabel:SetPosition(20, 251)
    messageLabel:SetSize(width - 40, 28)
    messageLabel:SetFont(Turbine.UI.Lotro.Font.Verdana12)
    messageLabel:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    messageLabel:SetVisible(false)

    local saveButton = Turbine.UI.Lotro.Button()
    saveButton:SetParent(window)
    saveButton:SetPosition(20, 286)
    saveButton:SetSize(120, 22)
    saveButton:SetText("Save note")

    local cancelButton = Turbine.UI.Lotro.Button()
    cancelButton:SetParent(window)
    cancelButton:SetPosition(width - 140, 286)
    cancelButton:SetSize(120, 22)
    cancelButton:SetText("Cancel")

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

    local function loadCurrentRecord()
        if currentKey == nil then
            return false
        end

        local record = relationships:GetByKey(currentKey)
        if record == nil then
            currentKey = nil
            window:SetVisible(false)
            return false
        end

        local label = labels:GetById(record.labelId)
        playerName:SetText(record.name)
        labelName:SetText(
            label ~= nil and ("Label: " .. label.name) or "Label unavailable"
        )
        labelAccent:SetBackColor(labels:GetColor(label))
        return true
    end

    window.Hide = function()
        settings.left = window:GetLeft()
        settings.top = window:GetTop()
        window:SetVisible(false)
        storage:Save()
    end

    window.OpenExisting = function(key)
        currentKey = HighlightPlayers.Util.NormalizeName(key)
        local record = relationships:GetByKey(currentKey)

        if record == nil then
            currentKey = nil
            HighlightPlayers.Util.WriteError("Player was not found.")
            return
        end

        local newLeft, newTop = HighlightPlayers.Util.ClampPosition(
            window:GetLeft(),
            window:GetTop(),
            width,
            height
        )
        window:SetPosition(newLeft, newTop)
        loadCurrentRecord()
        noteBox:SetText(record.note or "")
        showMessage(nil, false)
        window:SetVisible(true)
        window:Activate()
        noteBox:Focus()
    end

    saveButton.Click = function()
        local record = currentKey ~= nil and
            relationships:GetByKey(currentKey) or nil

        if record == nil then
            showMessage("Player was not found.", true)
            return
        end

        local succeeded, result, persisted = relationships:SavePlayer(
            currentKey,
            record.name,
            record.labelId,
            noteBox:GetText()
        )

        if not succeeded then
            showMessage(result, true)
            return
        end

        if not persisted then
            showMessage("Saved in memory, but persistence failed.", true)
            return
        end

        currentKey = result.key
        window.Hide()
    end

    cancelButton.Click = function()
        window.Hide()
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
            loadCurrentRecord()
        end
    end)

    local labelListener = labels:AddListener(function()
        if window:IsVisible() then
            loadCurrentRecord()
        end
    end)

    window.Stop = function()
        relationships:RemoveListener(relationshipListener)
        labels:RemoveListener(labelListener)
        savePosition()
        window:SetVisible(false)
    end

    return window
end
