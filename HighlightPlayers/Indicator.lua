HighlightPlayers = HighlightPlayers or {}

HighlightPlayers.Indicator = {}

function HighlightPlayers.Indicator.New(storage, relationships, targetTracker)
    local settings = storage:GetData().settings.indicator
    local window = Turbine.UI.Window()
    local width = 132
    local height = 30
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

    local badge = Turbine.UI.Label()
    badge:SetParent(window)
    badge:SetPosition(2, 2)
    badge:SetSize(width - 4, height - 4)
    badge:SetFont(Turbine.UI.Lotro.Font.TrajanPro15)
    badge:SetForeColor(Turbine.UI.Color.Black)
    badge:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    badge:SetMouseVisible(false)

    local moving = false
    local moveX = 0
    local moveY = 0
    local moveMode = settings.locked ~= true

    local function getCurrentRecord()
        local targetName = targetTracker:GetCurrentName()
        if targetName == nil then
            return nil
        end

        return relationships:GetByName(targetName)
    end

    local function update()
        local record = getCurrentRecord()

        if record ~= nil then
            badge:SetBackColor(
                HighlightPlayers.Constants.StatusColors[record.status]
            )
            if moveMode then
                badge:SetText("MOVE: " .. string.upper(record.status))
            else
                badge:SetText(string.upper(record.status))
            end
            window:SetVisible(true)
            return
        end

        if moveMode then
            badge:SetBackColor(Turbine.UI.Color(0.80, 0.80, 0.80))
            badge:SetText("MOVE INDICATOR")
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

    window.Stop = function()
        targetTracker:RemoveListener(targetListener)
        relationships:RemoveListener(relationshipListener)
        settings.left = window:GetLeft()
        settings.top = window:GetTop()
        settings.locked = not moveMode
        window:SetVisible(false)
    end

    window:SetMouseVisible(moveMode)
    update()
    return window
end
