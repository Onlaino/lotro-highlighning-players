HighlightPlayers = HighlightPlayers or {}

HighlightPlayers.Indicator = {}

function HighlightPlayers.Indicator.New(
    storage,
    relationships,
    labels,
    targetTracker
)
    local settings = storage:GetData().settings.indicator
    local limits = HighlightPlayers.Constants.Indicator
    local window = Turbine.UI.Window()
    local width = limits.MinWidth
    local height = limits.MinHeight
    local left, top = HighlightPlayers.Util.ClampPosition(
        settings.left,
        settings.top,
        width,
        height
    )

    window:SetSize(width, height)
    window:SetPosition(left, top)
    window:SetZOrder(100)
    window:SetBackColor(Turbine.UI.Color.Black)
    window:SetVisible(false)

    local frame = Turbine.UI.Control()
    frame:SetParent(window)
    frame:SetBackColor(Turbine.UI.Color(0.48, 0.36, 0.17))
    frame:SetMouseVisible(false)

    local panel = Turbine.UI.Control()
    panel:SetParent(window)
    panel:SetBackColor(Turbine.UI.Color(0.07, 0.07, 0.06))
    panel:SetMouseVisible(false)

    local accent = Turbine.UI.Control()
    accent:SetParent(window)
    accent:SetMouseVisible(false)

    local badge = Turbine.UI.Label()
    badge:SetParent(window)
    badge:SetFont(Turbine.UI.Lotro.Font.TrajanPro13)
    badge:SetForeColor(Turbine.UI.Color(0.96, 0.90, 0.72))
    badge:SetOutlineColor(Turbine.UI.Color.Black)
    badge:SetFontStyle(Turbine.UI.FontStyle.Outline)
    badge:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    badge:SetMultiline(true)
    badge:SetMouseVisible(false)

    local moving = false
    local moveX = 0
    local moveY = 0
    local moveMode = settings.locked ~= true

    local function getCharacterMetrics(text, index)
        local firstByte = string.byte(text, index)
        if firstByte >= 128 then
            if firstByte < 224 then
                return 8, 2
            elseif firstByte < 240 then
                return 8, 3
            end

            return 8, 4
        end

        local character = string.sub(text, index, index)
        if character == " " then
            return 4, 1
        end

        if string.find("ijlI1.,:;!'|`", character, 1, true) ~= nil then
            return 4, 1
        end

        if string.find("MWQO@#%&wm", character, 1, true) ~= nil then
            return 10, 1
        end

        if firstByte >= 65 and firstByte <= 90 then
            return 8, 1
        end

        return 7, 1
    end

    local function measureText(value)
        local width = 0
        local text = tostring(value or "")
        local index = 1

        while index <= string.len(text) do
            local characterWidth, byteLength = getCharacterMetrics(text, index)
            width = width + characterWidth
            index = index + byteLength
        end

        return math.max(1, width)
    end

    local function getWrappedLineCount(text, availableWidth)
        local lineCount = 1
        local lineWidth = 0
        local spaceWidth = 4

        for word in string.gmatch(text, "%S+") do
            local wordWidth = measureText(word)
            local requiredWidth = wordWidth
            if lineWidth > 0 then
                requiredWidth = lineWidth + spaceWidth + wordWidth
            end

            if requiredWidth <= availableWidth then
                lineWidth = requiredWidth
            else
                if lineWidth > 0 then
                    lineCount = lineCount + 1
                end

                local extraLines = math.floor(
                    math.max(0, wordWidth - 1) / availableWidth
                )
                lineCount = lineCount + extraLines
                lineWidth = wordWidth - extraLines * availableWidth
            end
        end

        return lineCount
    end

    local function layout()
        frame:SetPosition(1, 1)
        frame:SetSize(width - 2, height - 2)
        panel:SetPosition(2, 2)
        panel:SetSize(width - 4, height - 4)
        accent:SetPosition(3, 3)
        accent:SetSize(4, math.max(8, height - 6))
        badge:SetPosition(14, 3)
        badge:SetSize(math.max(10, width - 24), height - 6)
    end

    local function applyDimensions(newWidth, newHeight)
        width = math.max(limits.MinWidth, math.min(settings.maxWidth, newWidth))
        height = math.max(
            limits.MinHeight,
            math.min(settings.maxHeight, newHeight)
        )

        window:SetSize(width, height)
        layout()

        local newLeft, newTop = HighlightPlayers.Util.ClampPosition(
            window:GetLeft(),
            window:GetTop(),
            width,
            height
        )
        window:SetPosition(newLeft, newTop)
        settings.left = newLeft
        settings.top = newTop
    end

    local function applyTextDimensions(text)
        local horizontalPadding = 30
        local textAreaPadding = 24
        local desiredWidth = measureText(text) + horizontalPadding
        local actualWidth = math.max(
            limits.MinWidth,
            math.min(settings.maxWidth, desiredWidth)
        )
        local lineCount = getWrappedLineCount(
            text,
            math.max(1, actualWidth - textAreaPadding)
        )
        local desiredHeight = 8 + lineCount * 15

        applyDimensions(actualWidth, desiredHeight)
    end

    local function getCurrentRecord()
        local targetName = targetTracker:GetCurrentName()
        if targetName == nil then
            return nil
        end

        return relationships:GetByName(targetName)
    end

    local function update()
        local record = getCurrentRecord()
        local label = record ~= nil and labels:GetById(record.labelId) or nil

        if label ~= nil then
            local color = labels:GetColor(label)
            local text = moveMode and (label.name .. "  [drag]") or label.name
            accent:SetBackColor(color)
            badge:SetText(text)
            applyTextDimensions(text)
            frame:SetBackColor(
                moveMode and Turbine.UI.Color(0.82, 0.61, 0.20) or
                Turbine.UI.Color(0.48, 0.36, 0.17)
            )
            window:SetVisible(true)
            return
        end

        if moveMode then
            local moveColor = Turbine.UI.Color(0.82, 0.61, 0.20)
            accent:SetBackColor(moveColor)
            frame:SetBackColor(moveColor)
            badge:SetText("Drag indicator")
            applyTextDimensions("Drag indicator")
            window:SetVisible(true)
        else
            window:SetVisible(false)
        end
    end

    local function savePosition()
        settings.left = window:GetLeft()
        settings.top = window:GetTop()
        storage:Save()
    end

    window.MouseDown = function(sender, args)
        if not moveMode then
            return
        end

        moveX = args.X
        moveY = args.Y
        moving = true
    end

    window.MouseMove = function(sender, args)
        if not moveMode or not moving then
            return
        end

        local newLeft = window:GetLeft() - (moveX - args.X)
        local newTop = window:GetTop() - (moveY - args.Y)
        newLeft, newTop = HighlightPlayers.Util.ClampPosition(
            newLeft,
            newTop,
            width,
            height
        )
        window:SetPosition(newLeft, newTop)
    end

    window.MouseUp = function()
        if not moving then
            return
        end

        moving = false
        savePosition()
    end

    window.SetMoveMode = function(enabled)
        moveMode = enabled == true
        moving = false
        settings.locked = not moveMode
        window:SetMouseVisible(moveMode)
        update()
        storage:Save()

        if moveMode then
            HighlightPlayers.Util.WriteInfo(
                "Indicator unlocked. Drag the badge, then use /eh lock."
            )
        else
            HighlightPlayers.Util.WriteInfo("Indicator locked.")
        end
    end

    window.ApplyLimits = function(newMaxWidth, newMaxHeight)
        settings.maxWidth = math.max(
            limits.MinWidth,
            math.min(
                limits.MaxWidth,
                math.floor(tonumber(newMaxWidth) or settings.maxWidth)
            )
        )
        settings.maxHeight = math.max(
            limits.MinHeight,
            math.min(
                limits.MaxHeight,
                math.floor(tonumber(newMaxHeight) or settings.maxHeight)
            )
        )

        storage:Save()
        update()
    end

    window.IsMoveMode = function()
        return moveMode
    end

    window.Refresh = update

    local targetListener = targetTracker:AddListener(function()
        update()
    end)

    local relationshipListener = relationships:AddListener(function()
        update()
    end)

    local labelsListener = labels:AddListener(function()
        update()
    end)

    window.Stop = function()
        targetTracker:RemoveListener(targetListener)
        relationships:RemoveListener(relationshipListener)
        labels:RemoveListener(labelsListener)
        settings.left = window:GetLeft()
        settings.top = window:GetTop()
        settings.locked = not moveMode
        window:SetVisible(false)
    end

    window:SetMouseVisible(moveMode)
    layout()
    update()
    return window
end
