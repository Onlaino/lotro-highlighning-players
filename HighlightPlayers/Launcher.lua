HighlightPlayers = HighlightPlayers or {}

HighlightPlayers.Launcher = {}

function HighlightPlayers.Launcher.New(storage, mainWindow)
    local settings = storage:GetData().settings.launcher
    local window = Turbine.UI.Window()
    local width = 42
    local height = 42
    local left, top = HighlightPlayers.Util.ClampPosition(
        settings.left,
        settings.top,
        width,
        height
    )

    window:SetSize(width, height)
    window:SetPosition(left, top)
    window:SetZOrder(95)
    window:SetBackColor(Turbine.UI.Color.Black)
    window:SetMouseVisible(true)

    local face = Turbine.UI.Control()
    face:SetParent(window)
    face:SetPosition(2, 2)
    face:SetSize(width - 4, height - 4)
    face:SetBackground("HighlightPlayers/Resources/launcher.jpg")
    face:SetMouseVisible(false)

    local pressed = false
    local dragged = false
    local pressX = 0
    local pressY = 0

    window.MouseDown = function(sender, args)
        pressX = args.X
        pressY = args.Y
        pressed = true
        dragged = false
    end

    window.MouseEnter = function()
        window:SetBackColor(Turbine.UI.Color(0.85, 0.65, 0.22))
    end

    window.MouseLeave = function()
        if not pressed then
            window:SetBackColor(Turbine.UI.Color.Black)
        end
    end

    window.MouseMove = function(sender, args)
        if not pressed then
            return
        end

        local deltaX = args.X - pressX
        local deltaY = args.Y - pressY
        if math.abs(deltaX) > 2 or math.abs(deltaY) > 2 then
            dragged = true
        end

        local newLeft = window:GetLeft() + deltaX
        local newTop = window:GetTop() + deltaY
        newLeft, newTop = HighlightPlayers.Util.ClampPosition(
            newLeft,
            newTop,
            width,
            height
        )
        window:SetPosition(newLeft, newTop)
    end

    window.MouseUp = function()
        if not pressed then
            return
        end

        pressed = false
        window:SetBackColor(Turbine.UI.Color.Black)
        settings.left = window:GetLeft()
        settings.top = window:GetTop()

        if dragged then
            storage:Save()
        else
            mainWindow.Toggle()
        end

        dragged = false
    end

    window.Stop = function()
        settings.left = window:GetLeft()
        settings.top = window:GetTop()
        window:SetVisible(false)
    end

    window:SetVisible(true)
    return window
end
