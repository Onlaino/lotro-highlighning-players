HighlightPlayers = HighlightPlayers or {}

HighlightPlayers.LabelsWindow = {}
local L = HighlightPlayers.Localization

local function createTextBox(parent, left, top, width)
    local box = Turbine.UI.Lotro.TextBox()
    box:SetParent(parent)
    box:SetPosition(left, top)
    box:SetSize(width, 22)
    box:SetBackColor(Turbine.UI.Color(0.05, 0.05, 0.05))
    box:SetForeColor(Turbine.UI.Color.White)
    box:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    box:SetMultiline(false)
    return box
end

local function createLabel(parent, left, top, width, text)
    local label = Turbine.UI.Label()
    label:SetParent(parent)
    label:SetPosition(left, top)
    label:SetSize(width, 20)
    label:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    label:SetText(text)
    return label
end

function HighlightPlayers.LabelsWindow.New(
    storage,
    labels,
    relationships,
    indicator
)
    local settings = storage:GetData().settings.labelsWindow
    local indicatorSettings = storage:GetData().settings.indicator
    local window = Turbine.UI.Lotro.Window()
    local width = 560
    local height = 455
    local left, top = HighlightPlayers.Util.ClampPosition(
        settings.left,
        settings.top,
        width,
        height
    )

    window:SetSize(width, height)
    window:SetPosition(left, top)
    window:SetText(L.Get("manage_labels"))
    window:SetZOrder(30)
    window:SetWantsKeyEvents(true)
    window:SetVisible(false)

    local selectedId = nil

    local labelsTitle = createLabel(
        window,
        20,
        43,
        185,
        L.Get("labels_select")
    )
    local list = Turbine.UI.ListBox()
    list:SetParent(window)
    list:SetPosition(20, 65)
    list:SetSize(185, 270)

    local listScroll = Turbine.UI.Lotro.ScrollBar()
    listScroll:SetParent(window)
    listScroll:SetPosition(207, 65)
    listScroll:SetSize(10, 270)
    listScroll:SetOrientation(Turbine.UI.Orientation.Vertical)
    list:SetVerticalScrollBar(listScroll)

    local labelNameTitle = createLabel(
        window,
        235,
        43,
        160,
        L.Get("label_name")
    )
    local nameBox = createTextBox(window, 235, 65, 300)

    local colorTitle = createLabel(
        window,
        235,
        98,
        300,
        L.Get("color_components")
    )
    local redCaption = createLabel(window, 235, 123, 15, "R")
    redCaption:SetFont(Turbine.UI.Lotro.Font.Verdana12)
    local redBox = createTextBox(window, 252, 120, 55)
    local greenCaption = createLabel(window, 315, 123, 15, "G")
    greenCaption:SetFont(Turbine.UI.Lotro.Font.Verdana12)
    local greenBox = createTextBox(window, 332, 120, 55)
    local blueCaption = createLabel(window, 395, 123, 15, "B")
    blueCaption:SetFont(Turbine.UI.Lotro.Font.Verdana12)
    local blueBox = createTextBox(window, 412, 120, 55)

    local preview = Turbine.UI.Label()
    preview:SetParent(window)
    preview:SetPosition(475, 120)
    preview:SetSize(60, 22)
    preview:SetText(L.Get("preview"))
    preview:SetFont(Turbine.UI.Lotro.Font.Verdana12)
    preview:SetForeColor(Turbine.UI.Color.Black)
    preview:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

    local newButton = Turbine.UI.Lotro.Button()
    newButton:SetParent(window)
    newButton:SetPosition(235, 158)
    newButton:SetSize(90, 22)
    newButton:SetText(L.Get("new_button"))

    local saveButton = Turbine.UI.Lotro.Button()
    saveButton:SetParent(window)
    saveButton:SetPosition(340, 158)
    saveButton:SetSize(90, 22)
    saveButton:SetText(L.Get("save_button"))

    local deleteButton = Turbine.UI.Lotro.Button()
    deleteButton:SetParent(window)
    deleteButton:SetPosition(445, 158)
    deleteButton:SetSize(90, 22)
    deleteButton:SetText(L.Get("delete_button"))

    local modeLabel = Turbine.UI.Label()
    modeLabel:SetParent(window)
    modeLabel:SetPosition(235, 188)
    modeLabel:SetSize(300, 20)
    modeLabel:SetFont(Turbine.UI.Lotro.Font.Verdana14)

    local usageLabel = Turbine.UI.Label()
    usageLabel:SetParent(window)
    usageLabel:SetPosition(235, 210)
    usageLabel:SetSize(300, 35)
    usageLabel:SetFont(Turbine.UI.Lotro.Font.Verdana12)
    usageLabel:SetMultiline(true)

    local limitsTitle = createLabel(
        window,
        235,
        250,
        300,
        L.Get("automatic_limits")
    )
    local widthCaption = createLabel(
        window,
        235,
        275,
        45,
        L.Get("max_width")
    )
    widthCaption:SetFont(Turbine.UI.Lotro.Font.Verdana12)
    local widthBox = createTextBox(window, 280, 272, 55)
    local heightCaption = createLabel(
        window,
        345,
        275,
        45,
        L.Get("max_height")
    )
    heightCaption:SetFont(Turbine.UI.Lotro.Font.Verdana12)
    local heightBox = createTextBox(window, 392, 272, 55)
    widthBox:SetText(tostring(indicatorSettings.maxWidth))
    heightBox:SetText(tostring(indicatorSettings.maxHeight))

    local applySizeButton = Turbine.UI.Lotro.Button()
    applySizeButton:SetParent(window)
    applySizeButton:SetPosition(447, 272)
    applySizeButton:SetSize(88, 22)
    applySizeButton:SetText(L.Get("apply_limits"))

    local sizeHint = Turbine.UI.Label()
    sizeHint:SetParent(window)
    sizeHint:SetPosition(235, 302)
    sizeHint:SetSize(300, 35)
    sizeHint:SetFont(Turbine.UI.Lotro.Font.Verdana12)
    sizeHint:SetMultiline(true)
    sizeHint:SetForeColor(Turbine.UI.Color(0.70, 0.70, 0.70))
    sizeHint:SetText(
        L.Get("indicator_hint")
    )

    local showTooltipCheck = Turbine.UI.Lotro.CheckBox()
    showTooltipCheck:SetParent(window)
    showTooltipCheck:SetPosition(235, 337)
    showTooltipCheck:SetSize(300, 20)
    showTooltipCheck:SetText(L.Get("show_note_tooltip"))
    showTooltipCheck:SetChecked(indicatorSettings.showNoteTooltip == true)

    local messageLabel = Turbine.UI.Label()
    messageLabel:SetParent(window)
    messageLabel:SetPosition(20, 363)
    messageLabel:SetSize(width - 40, 32)
    messageLabel:SetFont(Turbine.UI.Lotro.Font.Verdana12)
    messageLabel:SetMultiline(true)
    messageLabel:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    messageLabel:SetVisible(false)

    local closeButton = Turbine.UI.Lotro.Button()
    closeButton:SetParent(window)
    closeButton:SetPosition(width - 130, 407)
    closeButton:SetSize(110, 22)
    closeButton:SetText(L.Get("close_button"))

    local function showMessage(text, isError)
        messageLabel:SetText(text or "")
        messageLabel:SetForeColor(
            isError and Turbine.UI.Color(1.00, 0.25, 0.25) or
            Turbine.UI.Color(0.25, 1.00, 0.35)
        )
        messageLabel:SetVisible(text ~= nil and text ~= "")
    end

    local function updatePreview()
        local red = math.max(0, math.min(255, tonumber(redBox:GetText()) or 0))
        local green = math.max(
            0,
            math.min(255, tonumber(greenBox:GetText()) or 0)
        )
        local blue = math.max(
            0,
            math.min(255, tonumber(blueBox:GetText()) or 0)
        )
        preview:SetBackColor(Turbine.UI.Color(red / 255, green / 255, blue / 255))
    end

    local function updateUsageState(label)
        if label == nil then
            usageLabel:SetText(L.Get("label_create_hint"))
            deleteButton:SetEnabled(false)
            return
        end

        local count = relationships:GetCount(label.id)
        local isLast = table.getn(labels:GetAll()) <= 1

        if count > 0 then
            usageLabel:SetText(L.Get("assigned_reassign", { count = count }))
        elseif isLast then
            usageLabel:SetText(L.Get("assigned_last"))
        else
            usageLabel:SetText(L.Get("assigned_can_delete"))
        end

        deleteButton:SetEnabled(count == 0 and not isLast)
    end

    local function loadLabel(label)
        selectedId = label ~= nil and label.id or nil

        if label == nil then
            modeLabel:SetText(L.Get("creating_label"))
            nameBox:SetText("")
            redBox:SetText("180")
            greenBox:SetText("180")
            blueBox:SetText("180")
        else
            modeLabel:SetText(L.Get("editing_label", { label = label.name }))
            nameBox:SetText(label.name)
            redBox:SetText(tostring(label.red))
            greenBox:SetText(tostring(label.green))
            blueBox:SetText(tostring(label.blue))
        end

        updateUsageState(label)
        updatePreview()
    end

    window.Refresh = function()
        list:ClearItems()

        for _, label in ipairs(labels:GetAll()) do
            local currentId = label.id
            local item = Turbine.UI.Control()
            item:SetSize(list:GetWidth(), 30)

            local button = Turbine.UI.Lotro.Button()
            button:SetParent(item)
            button:SetPosition(1, 3)
            button:SetSize(item:GetWidth() - 2, 24)
            button:SetText(
                label.name .. " (" ..
                tostring(relationships:GetCount(label.id)) .. ")"
            )
            button:SetEnabled(currentId ~= selectedId)
            button.Click = function()
                loadLabel(labels:GetById(currentId))
                window.Refresh()
            end

            local swatchBorder = Turbine.UI.Label()
            swatchBorder:SetParent(item)
            swatchBorder:SetPosition(1, 3)
            swatchBorder:SetSize(26, 24)
            swatchBorder:SetBackColor(Turbine.UI.Color.Black)
            swatchBorder:SetMouseVisible(false)

            local swatch = Turbine.UI.Label()
            swatch:SetParent(item)
            swatch:SetPosition(3, 5)
            swatch:SetSize(22, 20)
            swatch:SetBackColor(labels:GetColor(label))
            swatch:SetMouseVisible(false)

            list:AddItem(item)
        end

        if selectedId ~= nil and labels:GetById(selectedId) == nil then
            loadLabel(labels:GetFirst())
        end
    end

    newButton.Click = function()
        loadLabel(nil)
        window.Refresh()
        showMessage(nil, false)
        nameBox:Focus()
    end

    saveButton.Click = function()
        local succeeded, result, persisted = labels:SaveLabel(
            selectedId,
            nameBox:GetText(),
            redBox:GetText(),
            greenBox:GetText(),
            blueBox:GetText()
        )

        if not succeeded then
            showMessage(result, true)
            return
        end

        selectedId = result.id
        loadLabel(result)
        window.Refresh()
        showMessage(
            persisted and L.Get("label_saved") or
            L.Get("saved_memory_failed"),
            not persisted
        )
    end

    deleteButton.Click = function()
        if selectedId == nil then
            return
        end

        local succeeded, result, persisted = labels:Delete(selectedId)
        if not succeeded then
            showMessage(result, true)
            return
        end

        loadLabel(labels:GetFirst())
        window.Refresh()
        showMessage(
            persisted and L.Get("label_deleted") or
            L.Get("deleted_memory_failed"),
            not persisted
        )
    end

    applySizeButton.Click = function()
        local limits = HighlightPlayers.Constants.Indicator
        local newWidth = tonumber(widthBox:GetText())
        local newHeight = tonumber(heightBox:GetText())

        if newWidth == nil or newHeight == nil or
            newWidth < limits.MinWidth or newWidth > limits.MaxWidth or
            newHeight < limits.MinHeight or newHeight > limits.MaxHeight then
            showMessage(
                L.Get("invalid_limits"),
                true
            )
            return
        end

        newWidth = math.floor(newWidth)
        newHeight = math.floor(newHeight)
        widthBox:SetText(tostring(newWidth))
        heightBox:SetText(tostring(newHeight))
        indicator.ApplyLimits(newWidth, newHeight)
        showMessage(L.Get("limits_saved"), false)
    end

    redBox.TextChanged = updatePreview
    greenBox.TextChanged = updatePreview
    blueBox.TextChanged = updatePreview
    showTooltipCheck.CheckedChanged = function()
        indicator.SetShowNoteTooltip(showTooltipCheck:IsChecked())
        showMessage(L.Get("tooltip_setting_saved"), false)
    end

    window.Open = function()
        local newLeft, newTop = HighlightPlayers.Util.ClampPosition(
            window:GetLeft(),
            window:GetTop(),
            width,
            height
        )
        window:SetPosition(newLeft, newTop)
        widthBox:SetText(tostring(indicatorSettings.maxWidth))
        heightBox:SetText(tostring(indicatorSettings.maxHeight))
        showTooltipCheck:SetChecked(
            indicatorSettings.showNoteTooltip == true
        )

        loadLabel(labels:GetById(selectedId) or labels:GetFirst())

        window.Refresh()
        showMessage(nil, false)
        window:SetVisible(true)
        window:Activate()
    end

    window.Hide = function()
        settings.left = window:GetLeft()
        settings.top = window:GetTop()
        window:SetVisible(false)
        storage:Save()
    end

    closeButton.Click = function()
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

    local labelListener = labels:AddListener(function()
        if window:IsVisible() then
            window.Refresh()
        end
    end)

    local relationshipListener = relationships:AddListener(function()
        if window:IsVisible() then
            window.Refresh()
            local selected = labels:GetById(selectedId)
            if selected ~= nil then
                updateUsageState(selected)
            end
        end
    end)

    local function applyLocale()
        window:SetText(L.Get("manage_labels"))
        labelsTitle:SetText(L.Get("labels_select"))
        labelNameTitle:SetText(L.Get("label_name"))
        colorTitle:SetText(L.Get("color_components"))
        preview:SetText(L.Get("preview"))
        newButton:SetText(L.Get("new_button"))
        saveButton:SetText(L.Get("save_button"))
        deleteButton:SetText(L.Get("delete_button"))
        limitsTitle:SetText(L.Get("automatic_limits"))
        widthCaption:SetText(L.Get("max_width"))
        heightCaption:SetText(L.Get("max_height"))
        applySizeButton:SetText(L.Get("apply_limits"))
        sizeHint:SetText(L.Get("indicator_hint"))
        showTooltipCheck:SetText(L.Get("show_note_tooltip"))
        closeButton:SetText(L.Get("close_button"))
        local selected = labels:GetById(selectedId)
        if selected == nil then
            modeLabel:SetText(L.Get("creating_label"))
            updateUsageState(nil)
        else
            modeLabel:SetText(L.Get("editing_label", {
                label = selected.name
            }))
            updateUsageState(selected)
        end
        showMessage(nil, false)
        window.Refresh()
    end

    local localeListener = L.AddListener(applyLocale)

    window.Stop = function()
        labels:RemoveListener(labelListener)
        relationships:RemoveListener(relationshipListener)
        L.RemoveListener(localeListener)
        settings.left = window:GetLeft()
        settings.top = window:GetTop()
        window:SetVisible(false)
    end

    loadLabel(labels:GetFirst())
    applyLocale()
    window.Refresh()
    return window
end
