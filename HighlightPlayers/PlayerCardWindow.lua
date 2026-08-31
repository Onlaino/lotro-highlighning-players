HighlightPlayers = HighlightPlayers or {}

HighlightPlayers.PlayerCardWindow = {}
local L = HighlightPlayers.Localization

function HighlightPlayers.PlayerCardWindow.New(storage, relationships, labels)
    local settings = storage:GetData().settings.cardWindow
    local window = Turbine.UI.Lotro.Window()
    local width = 540
    local height = 670
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
    noteBox:SetSize(width - 57, 92)
    noteBox:SetBackColor(Turbine.UI.Color(0.05, 0.05, 0.05))
    noteBox:SetForeColor(Turbine.UI.Color.White)
    noteBox:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    noteBox:SetMultiline(true)

    local noteScroll = Turbine.UI.Lotro.ScrollBar()
    noteScroll:SetParent(window)
    noteScroll:SetPosition(width - 34, 250)
    noteScroll:SetSize(10, 92)
    noteScroll:SetOrientation(Turbine.UI.Orientation.Vertical)
    noteBox:SetVerticalScrollBar(noteScroll)

    local alternativesTitle = Turbine.UI.Label()
    alternativesTitle:SetParent(window)
    alternativesTitle:SetPosition(20, 353)
    alternativesTitle:SetSize(width - 40, 20)
    alternativesTitle:SetFont(Turbine.UI.Lotro.Font.Verdana16)
    alternativesTitle:SetText(L.Get("related_characters"))

    local alternativeBox = Turbine.UI.Lotro.TextBox()
    alternativeBox:SetParent(window)
    alternativeBox:SetPosition(20, 373)
    alternativeBox:SetSize(width - 190, 22)
    alternativeBox:SetBackColor(Turbine.UI.Color(0.05, 0.05, 0.05))
    alternativeBox:SetForeColor(Turbine.UI.Color.White)
    alternativeBox:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    alternativeBox:SetMultiline(false)

    local addAlternativeButton = Turbine.UI.Lotro.Button()
    addAlternativeButton:SetParent(window)
    addAlternativeButton:SetPosition(width - 160, 373)
    addAlternativeButton:SetSize(140, 22)
    addAlternativeButton:SetText(L.Get("add_alternative"))

    local alternativeList = Turbine.UI.ListBox()
    alternativeList:SetParent(window)
    alternativeList:SetPosition(20, 402)
    alternativeList:SetSize(width - 57, 165)

    local alternativeScroll = Turbine.UI.Lotro.ScrollBar()
    alternativeScroll:SetParent(window)
    alternativeScroll:SetPosition(width - 34, 402)
    alternativeScroll:SetSize(10, 165)
    alternativeScroll:SetOrientation(Turbine.UI.Orientation.Vertical)
    alternativeList:SetVerticalScrollBar(alternativeScroll)

    local messageLabel = Turbine.UI.Label()
    messageLabel:SetParent(window)
    messageLabel:SetPosition(20, 575)
    messageLabel:SetSize(width - 40, 30)
    messageLabel:SetFont(Turbine.UI.Lotro.Font.Verdana12)
    messageLabel:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    messageLabel:SetVisible(false)

    local saveButton = Turbine.UI.Lotro.Button()
    saveButton:SetParent(window)
    saveButton:SetPosition(20, 621)
    saveButton:SetSize(110, 22)
    saveButton:SetText(L.Get("save_button"))

    local deleteButton = Turbine.UI.Lotro.Button()
    deleteButton:SetParent(window)
    deleteButton:SetPosition(math.floor((width - 110) / 2), 621)
    deleteButton:SetSize(110, 22)
    deleteButton:SetText(L.Get("delete_button"))

    local cancelButton = Turbine.UI.Lotro.Button()
    cancelButton:SetParent(window)
    cancelButton:SetPosition(width - 130, 621)
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

    local function refreshAlternatives()
        alternativeList:ClearItems()

        if originalKey == nil then
            return
        end

        for _, record in ipairs(
            relationships:GetRelatedRecords(originalKey)
        ) do
            local row = Turbine.UI.Control()
            row:SetSize(alternativeList:GetWidth(), 30)

            local name = Turbine.UI.Lotro.Button()
            name:SetParent(row)
            name:SetPosition(10, 1)
            name:SetSize(
                row:GetWidth() - (record.direct and 120 or 12),
                28
            )
            name:SetFont(Turbine.UI.Lotro.Font.Verdana14)
            local label = labels:GetById(record.labelId)
            name:SetText(
                record.name ..
                (label ~= nil and "  [" .. label.name .. "]" or "") ..
                "  — " .. L.Get(
                    record.direct and "direct_link" or "group_member"
                )
            )
            name.Click = function()
                window.OpenExisting(record.key)
            end

            if label ~= nil then
                local swatch = Turbine.UI.Control()
                swatch:SetParent(row)
                swatch:SetPosition(2, 6)
                swatch:SetSize(5, 18)
                swatch:SetBackColor(labels:GetColor(label))
                swatch:SetMouseVisible(false)
            end

            if record.direct then
                local removeButton = Turbine.UI.Lotro.Button()
                removeButton:SetParent(row)
                removeButton:SetPosition(row:GetWidth() - 110, 4)
                removeButton:SetSize(108, 22)
                removeButton:SetText(L.Get("remove_alternative"))
                removeButton.Click = function()
                    local succeeded, result, persisted =
                        relationships:RemoveConnection(originalKey, record.key)
                    if not succeeded then
                        showMessage(result, true)
                        return
                    end

                    if not persisted then
                        showMessage(L.Get("saved_memory_but_failed"), true)
                        refreshAlternatives()
                        return
                    end

                    showMessage(L.Get("alternative_removed"), false)
                    refreshAlternatives()
                end
            end

            alternativeList:AddItem(row)
        end
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
        alternativeBox:SetText("")
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
        alternativeBox:SetText("")
        refreshAlternatives()
        showMessage(nil, false)
        window:SetVisible(true)
        window:Activate()
        nameBox:Focus()
    end

    local function saveCurrentPlayer()
        local succeeded, result, persisted = relationships:SavePlayer(
            originalKey,
            nameBox:GetText(),
            labelSelector:GetLabelId(),
            noteBox:GetText()
        )

        if not succeeded then
            showMessage(result, true)
            return false
        end

        originalKey = result.key
        isNew = false
        deleteButton:SetVisible(true)

        if not persisted then
            showMessage(L.Get("saved_memory_but_failed"), true)
            refreshAlternatives()
            return false
        end

        return true
    end

    saveButton.Click = function()
        if not saveCurrentPlayer() then
            return
        end

        window.Hide()
    end

    addAlternativeButton.Click = function()
        if not saveCurrentPlayer() then
            return
        end

        local succeeded, result, persisted = relationships:AddAlternative(
            originalKey,
            alternativeBox:GetText()
        )
        if not succeeded then
            showMessage(result, true)
            return
        end

        if not persisted then
            showMessage(L.Get("saved_memory_but_failed"), true)
            refreshAlternatives()
            return
        end

        alternativeBox:SetText("")
        showMessage(L.Get("alternative_added", { name = result.name }), false)
        refreshAlternatives()
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
        alternativesTitle:SetText(L.Get("related_characters"))
        addAlternativeButton:SetText(L.Get("add_alternative"))
        saveButton:SetText(L.Get("save_button"))
        deleteButton:SetText(L.Get("delete_button"))
        cancelButton:SetText(L.Get("cancel"))
        showMessage(nil, false)
        refreshAlternatives()
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
