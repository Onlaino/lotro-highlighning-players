HighlightPlayers = HighlightPlayers or {}

HighlightPlayers.LabelsWindow = {}

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
    label:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
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
    window:SetText("Manage labels")
    window:SetZOrder(30)
    window:SetWantsKeyEvents(true)
    window:SetVisible(false)

    local selectedId = nil

    createLabel(window, 20, 43, 170, "Labels")
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

    createLabel(window, 235, 43, 120, "Label name")
    local nameBox = createTextBox(window, 235, 65, 300)

    createLabel(window, 235, 98, 120, "Color RGB")
    local redBox = createTextBox(window, 235, 120, 70)
    local greenBox = createTextBox(window, 315, 120, 70)
    local blueBox = createTextBox(window, 395, 120, 70)

    local preview = Turbine.UI.Label()
    preview:SetParent(window)
    preview:SetPosition(475, 120)
    preview:SetSize(60, 22)
    preview:SetText("Preview")
    preview:SetFont(Turbine.UI.Lotro.Font.Verdana12)
    preview:SetForeColor(Turbine.UI.Color.Black)
    preview:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

    local newButton = Turbine.UI.Lotro.Button()
    newButton:SetParent(window)
    newButton:SetPosition(235, 158)
    newButton:SetSize(90, 22)
    newButton:SetText("New")

    local saveButton = Turbine.UI.Lotro.Button()
    saveButton:SetParent(window)
    saveButton:SetPosition(340, 158)
    saveButton:SetSize(90, 22)
    saveButton:SetText("Save")

    local deleteButton = Turbine.UI.Lotro.Button()
    deleteButton:SetParent(window)
    deleteButton:SetPosition(445, 158)
    deleteButton:SetSize(90, 22)
    deleteButton:SetText("Delete")

    local usageLabel = Turbine.UI.Label()
    usageLabel:SetParent(window)
    usageLabel:SetPosition(235, 188)
    usageLabel:SetSize(300, 20)
    usageLabel:SetFont(Turbine.UI.Lotro.Font.Verdana12)

    createLabel(window, 235, 225, 250, "Indicator size (pixels)")
    local widthCaption = createLabel(window, 235, 250, 20, "W")
    widthCaption:SetFont(Turbine.UI.Lotro.Font.Verdana12)
    local widthBox = createTextBox(window, 258, 247, 70)
    local heightCaption = createLabel(window, 340, 250, 20, "H")
    heightCaption:SetFont(Turbine.UI.Lotro.Font.Verdana12)
    local heightBox = createTextBox(window, 363, 247, 67)
    widthBox:SetText(tostring(indicatorSettings.width))
    heightBox:SetText(tostring(indicatorSettings.height))

    local applySizeButton = Turbine.UI.Lotro.Button()
    applySizeButton:SetParent(window)
    applySizeButton:SetPosition(445, 247)
    applySizeButton:SetSize(90, 22)
    applySizeButton:SetText("Apply size")

    local sizeHint = Turbine.UI.Label()
    sizeHint:SetParent(window)
    sizeHint:SetPosition(235, 275)
    sizeHint:SetSize(300, 35)
    sizeHint:SetFont(Turbine.UI.Lotro.Font.Verdana12)
    sizeHint:SetMultiline(true)
    sizeHint:SetForeColor(Turbine.UI.Color(0.70, 0.70, 0.70))
    sizeHint:SetText("Width 60-300, height 20-80. Position: /eh move")

    local messageLabel = Turbine.UI.Label()
    messageLabel:SetParent(window)
    messageLabel:SetPosition(20, 350)
    messageLabel:SetSize(width - 40, 45)
    messageLabel:SetFont(Turbine.UI.Lotro.Font.Verdana12)
    messageLabel:SetMultiline(true)
    messageLabel:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    messageLabel:SetVisible(false)

    local closeButton = Turbine.UI.Lotro.Button()
    closeButton:SetParent(window)
    closeButton:SetPosition(width - 130, 407)
    closeButton:SetSize(110, 22)
    closeButton:SetText("Close")

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

    local function loadLabel(label)
        selectedId = label ~= nil and label.id or nil

        if label == nil then
            nameBox:SetText("")
            redBox:SetText("180")
            greenBox:SetText("180")
            blueBox:SetText("180")
            usageLabel:SetText("Creating a new label")
            deleteButton:SetEnabled(false)
        else
            nameBox:SetText(label.name)
            redBox:SetText(tostring(label.red))
            greenBox:SetText(tostring(label.green))
            blueBox:SetText(tostring(label.blue))
            usageLabel:SetText(
                "Assigned players: " ..
                tostring(relationships:GetCount(label.id))
            )
            deleteButton:SetEnabled(true)
        end

        updatePreview()
    end

    window.Refresh = function()
        list:ClearItems()

        for _, label in ipairs(labels:GetAll()) do
            local currentId = label.id
            local button = Turbine.UI.Lotro.Button()
            button:SetSize(list:GetWidth(), 28)
            button:SetText(
                label.name .. " (" ..
                tostring(relationships:GetCount(label.id)) .. ")"
            )
            button:SetEnabled(currentId ~= selectedId)
            button.Click = function()
                loadLabel(labels:GetById(currentId))
                window.Refresh()
            end
            list:AddItem(button)
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
            persisted and "Label saved." or
            "Saved in memory; persistence failed.",
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
            persisted and "Label deleted." or
            "Deleted in memory; persistence failed.",
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
            showMessage("Width must be 60-300 and height 20-80.", true)
            return
        end

        newWidth = math.floor(newWidth)
        newHeight = math.floor(newHeight)
        widthBox:SetText(tostring(newWidth))
        heightBox:SetText(tostring(newHeight))
        indicator.ApplySize(newWidth, newHeight)
        showMessage("Indicator size saved.", false)
    end

    redBox.TextChanged = updatePreview
    greenBox.TextChanged = updatePreview
    blueBox.TextChanged = updatePreview

    window.Open = function()
        local newLeft, newTop = HighlightPlayers.Util.ClampPosition(
            window:GetLeft(),
            window:GetTop(),
            width,
            height
        )
        window:SetPosition(newLeft, newTop)
        widthBox:SetText(tostring(indicatorSettings.width))
        heightBox:SetText(tostring(indicatorSettings.height))

        if selectedId == nil then
            loadLabel(labels:GetFirst())
        end

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
                usageLabel:SetText(
                    "Assigned players: " ..
                    tostring(relationships:GetCount(selected.id))
                )
            end
        end
    end)

    window.Stop = function()
        labels:RemoveListener(labelListener)
        relationships:RemoveListener(relationshipListener)
        settings.left = window:GetLeft()
        settings.top = window:GetTop()
        window:SetVisible(false)
    end

    loadLabel(labels:GetFirst())
    window.Refresh()
    return window
end
