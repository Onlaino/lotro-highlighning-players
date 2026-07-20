HighlightPlayers = HighlightPlayers or {}

HighlightPlayers.Commands = {}
HighlightPlayers.Commands.__index = HighlightPlayers.Commands

function HighlightPlayers.Commands.New(
    relationships,
    targetTracker,
    indicator,
    mainWindow,
    cardWindow
)
    local instance = {
        relationships = relationships,
        targetTracker = targetTracker,
        indicator = indicator,
        mainWindow = mainWindow,
        cardWindow = cardWindow,
        command = nil
    }

    setmetatable(instance, HighlightPlayers.Commands)
    return instance
end

function HighlightPlayers.Commands:GetHelp()
    return table.concat({
        "/eh - toggle the main window",
        "/eh show | hide",
        "/eh move | lock",
        "/eh add <nickname>",
        "/eh add <nickname> <friend|neutral|enemy>",
        "/eh info <nickname> - print the saved note",
        "/eh probe - print current target diagnostics",
        "/eh help"
    }, "\n")
end

function HighlightPlayers.Commands:Execute(arguments)
    local trimmed = HighlightPlayers.Util.Trim(arguments)

    if trimmed == "" or string.lower(trimmed) == "toggle" then
        self.mainWindow.Toggle()
        return
    end

    local verb, rest = string.match(trimmed, "^(%S+)%s*(.-)%s*$")
    verb = string.lower(verb or "")
    rest = rest or ""

    if verb == "show" then
        self.mainWindow.Open()
        return
    end

    if verb == "hide" then
        self.mainWindow.Hide()
        return
    end

    if verb == "move" then
        self.indicator.SetMoveMode(true)
        return
    end

    if verb == "lock" then
        self.indicator.SetMoveMode(false)
        return
    end

    if verb == "probe" then
        self.targetTracker:PrintSnapshot()
        return
    end

    if verb == "help" then
        Turbine.Shell.WriteLine(self:GetHelp())
        return
    end

    if verb == "info" then
        local name, extra = string.match(rest, "^(%S+)%s*(.-)%s*$")

        if name == nil or name == "" or (extra ~= nil and extra ~= "") then
            HighlightPlayers.Util.WriteError(
                "Usage: /eh info <nickname>"
            )
            return
        end

        local record = self.relationships:GetByName(name)
        if record == nil then
            HighlightPlayers.Util.WriteError(
                "No saved player named " .. name .. "."
            )
            return
        end

        local note = HighlightPlayers.Util.Trim(record.note)
        if note == "" then
            HighlightPlayers.Util.WriteInfo(
                record.name .. " has no saved note."
            )
            return
        end

        HighlightPlayers.Util.WriteInfo(
            "Note for " .. record.name .. ":\n" .. note
        )
        return
    end

    if verb == "add" then
        local name, statusValue, extra = string.match(
            rest,
            "^(%S+)%s*(%S*)%s*(.-)%s*$"
        )

        if name == nil or name == "" or (extra ~= nil and extra ~= "") then
            HighlightPlayers.Util.WriteError(
                "Usage: /eh add <nickname> [friend|neutral|enemy]"
            )
            return
        end

        if statusValue == nil or statusValue == "" then
            self.cardWindow.OpenNew(name, nil)
            return
        end

        local status = HighlightPlayers.Util.ParseStatus(statusValue)
        if status == nil then
            HighlightPlayers.Util.WriteError(
                "Status must be friend, neutral or enemy."
            )
            return
        end

        local succeeded, result, persisted = self.relationships:SavePlayer(
            nil,
            name,
            status,
            nil
        )

        if not succeeded then
            HighlightPlayers.Util.WriteError(result)
            return
        end

        if persisted then
            HighlightPlayers.Util.WriteInfo(
                "Saved " .. result.name .. " as " ..
                HighlightPlayers.Constants.StatusLabels[result.status] .. "."
            )
        end
        return
    end

    HighlightPlayers.Util.WriteError("Unknown command. Use /eh help.")
end

function HighlightPlayers.Commands:Start()
    if self.command ~= nil then
        return
    end

    local owner = self
    local command = Turbine.ShellCommand()

    function command:GetShortHelp()
        return "/eh help - Enemy Highlight commands"
    end

    function command:GetHelp()
        return owner:GetHelp()
    end

    function command:Execute(commandName, arguments)
        owner:Execute(arguments)
    end

    self.command = command
    Turbine.Shell.AddCommand("eh", command)
end

function HighlightPlayers.Commands:Stop()
    if self.command == nil then
        return
    end

    Turbine.Shell.RemoveCommand(self.command)
    self.command = nil
end
