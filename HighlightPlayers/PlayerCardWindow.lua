HighlightPlayers = HighlightPlayers or {}

HighlightPlayers.PlayerCardWindow = {}
local L = HighlightPlayers.Localization

function HighlightPlayers.PlayerCardWindow.New(storage, relationships, labels)
    local settings = storage:GetData().settings.cardWindow
    local window = Turbine.UI.Lotro.Window()
    local width = 430
    local height = 470
    local left, top = HighlightPlayers.Util.ClampPosition(
        settings.left,
        settings.top,
        width,
        height
    )

    window:SetSize(width, height)
    window:SetPosition(left, top)
    window:SetText(L.Get("player_card"))
    window:SetZOrder(20)
    window:SetWantsKeyEvents(true)
    window:SetVisible(false)

    local originalKey = nil
    local isNew = false

    local nameLabel = Turbine.UI.Label()
    nameLabel:SetParent(window)
    nameLabel:SetPosition(20, 45)
    nameLabel:SetSize(100, 20)
    nameLabel:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    nameLabel:SetText(L.Get("player_name"))

    local nameBox = Turbine.UI.Lotro.TextBox()
    nameBox:SetParent(window)
    nameBox:SetPosition(20, 65)
    nameBox:SetSize(width - 40, 22)
    nameBox:SetBackColor(Turbine.UI.Color(0.05, 0.05, 0.05))
    nameBox:SetForeColor(Turbine.UI.Color.White)
    nameBox:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    nameBox:SetMultiline(false)

    local labelTitle = Turbine.UI.Label()
    labelTitle:SetParent(window)
    labelTitle:SetPosition(20, 98)
    labelTitle:SetSize(width - 40, 20)
    labelTitle:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    labelTitle:SetText(L.Get("choose_one_label"))

    local labelSelector = HighlightPlayers.StatusSelector.New(
        window,
        20,
        118,
        labels,
        nil,
        width - 40,
        100
    )

    local noteLabel = Turbine.UI.Label()
    noteLabel:SetParent(window)
    noteLabel:SetPosition(20, 230)
    noteLabel:SetSize(100, 20)
    noteLabel:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    noteLabel:SetText(L.Get("note"))

    local noteBox = Turbine.UI.Lotro.TextBox()
    noteBox:SetParent(window)
    noteBox:SetPosition(20, 250)
    noteBox:SetSize(width - 57, 130)
    noteBox:SetBackColor(Turbine.UI.Color(0.05, 0.05, 0.05))
    noteBox:SetForeColor(Turbine.UI.Color.White)
    noteBox:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    noteBox:SetMultiline(true)

    local noteScroll = Turbine.UI.Lotro.ScrollBar()
    noteScroll:SetParent(window)
    noteScroll:SetPosition(width - 34, 250)
    noteScroll:SetSize(10, 130)
    noteScroll:SetOrientation(Turbine.UI.Orientation.Vertical)
    noteBox:SetVerticalScrollBar(noteScroll)

    local messageLabel = Turbine.UI.Label()
    messageLabel:SetParent(window)
    messageLabel:SetPosition(20, 386)
    messageLabel:SetSize(width - 40, 30)
    messageLabel:SetFont(Turbine.UI.Lotro.Font.Verdana12)
    messageLabel:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    messageLabel:SetVisible(false)

    local saveButton = Turbine.UI.Lotro.Button()
    saveButton:SetParent(window)
    saveButton:SetPosition(20, 426)
    saveButton:SetSize(110, 22)
    saveButton:SetText(L.Get("save_button"))

    local deleteButton = Turbine.UI.Lotro.Button()
    deleteButton:SetParent(window)
    deleteButton:SetPosition(160, 426)
    deleteButton:SetSize(110, 22)
    deleteButton:SetText(L.Get("delete_button"))

    local cancelButton = Turbine.UI.Lotro.Button()
    cancelButton:SetParent(window)
    cancelButton:SetPosition(300, 426)
    cancelButton:SetSize(110, 22)
    cancelButton:SetText(L.Get("cancel"))

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

    window.Hide = function()
        settings.left = window:GetLeft()
        settings.top = window:GetTop()
        window:SetVisible(false)
        storage:Save()
    end

    window.OpenNew = function(prefilledName, labelId)
        local existing = relationships:GetByName(prefilledName or "")
        if existing ~= nil then
            window.OpenExisting(
                HighlightPlayers.Util.NormalizeName(prefilledName)
            )
            return
        end

        local initialLabel = labels:GetById(labelId) or labels:GetFirst()
        originalKey = nil
        isNew = true
        window:SetText(L.Get("add_player"))
        nameBox:SetText(prefilledName or "")
        noteBox:SetText("")
        if initialLabel ~= nil then
            labelSelector:SetLabelId(initialLabel.id, false)
        end
        deleteButton:SetVisible(false)
        showMessage(nil, false)
        window:SetVisible(true)
        window:Activate()
        nameBox:Focus()
    end

    window.OpenExisting = function(key)
        local normalizedKey = HighlightPlayers.Util.NormalizeName(key)
        local record = relationships:GetByKey(normalizedKey)

        if record == nil then
            HighlightPlayers.Util.WriteError(L.Get("player_not_found"))
            return
        end

        originalKey = normalizedKey
        isNew = false
        window:SetText(L.Get("player_card"))
        nameBox:SetText(record.name)
        noteBox:SetText(record.note or "")
        labelSelector:SetLabelId(record.labelId, false)
        deleteButton:SetVisible(true)
        showMessage(nil, false)
        window:SetVisible(true)
        window:Activate()
        nameBox:Focus()
    end

    saveButton.Click = function()
        local succeeded, result, persisted = relationships:SavePlayer(
            originalKey,
            nameBox:GetText(),
            labelSelector:GetLabelId(),
            noteBox:GetText()
        )

        if not succeeded then
            showMessage(result, true)
            return
        end

        if not persisted then
            showMessage(L.Get("saved_memory_but_failed"), true)
            return
        end

        originalKey = result.key
        window.Hide()
    end

    deleteButton.Click = function()
        if originalKey == nil then
            return
        end

        local succeeded, errorOrRecord, persisted = relationships:Delete(
            originalKey
        )

        if not succeeded then
            showMessage(errorOrRecord, true)
            return
        end

        if not persisted then
            showMessage(L.Get("deleted_memory_but_failed"), true)
            return
        end

        originalKey = nil
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

    local function applyLocale()
        window:SetText(L.Get(isNew and "add_player" or "player_card"))
        nameLabel:SetText(L.Get("player_name"))
        labelTitle:SetText(L.Get("choose_one_label"))
        noteLabel:SetText(L.Get("note"))
        saveButton:SetText(L.Get("save_button"))
        deleteButton:SetText(L.Get("delete_button"))
        cancelButton:SetText(L.Get("cancel"))
        showMessage(nil, false)
    end

    local localeListener = L.AddListener(applyLocale)

    window.Stop = function()
        labelSelector:Stop()
        L.RemoveListener(localeListener)
        savePosition()
        window:SetVisible(false)
    end

    applyLocale()
    return window
end
