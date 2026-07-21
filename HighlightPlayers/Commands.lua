HighlightPlayers = HighlightPlayers or {}

HighlightPlayers.Commands = {}
HighlightPlayers.Commands.__index = HighlightPlayers.Commands

function HighlightPlayers.Commands.New(
    relationships,
    labels,
    targetTracker,
    indicator,
    mainWindow,
    cardWindow,
    labelsWindow
)
    local instance = {
        relationships = relationships,
        labels = labels,
        targetTracker = targetTracker,
        indicator = indicator,
        mainWindow = mainWindow,
        cardWindow = cardWindow,
        labelsWindow = labelsWindow,
        command = nil
    }

    setmetatable(instance, HighlightPlayers.Commands)
    return instance
end

function HighlightPlayers.Commands:GetHelp()
    return table.concat({
        HighlightPlayers.Localization.Get("help_toggle"),
        HighlightPlayers.Localization.Get("help_show_hide"),
        HighlightPlayers.Localization.Get("help_move_lock"),
        HighlightPlayers.Localization.Get("help_labels"),
        HighlightPlayers.Localization.Get("help_add"),
        HighlightPlayers.Localization.Get("help_add_label"),
        HighlightPlayers.Localization.Get("help_info"),
        HighlightPlayers.Localization.Get("help_probe"),
        HighlightPlayers.Localization.Get("help_language"),
        HighlightPlayers.Localization.Get("help_help")
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

    if verb == "labels" then
        self.labelsWindow.Open()
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

    if verb == "language" then
        local succeeded, languageOrError =
            HighlightPlayers.Localization.SetLanguage(rest)
        if not succeeded then
            HighlightPlayers.Util.WriteError(languageOrError)
            return
        end

        HighlightPlayers.Util.WriteInfo(
            HighlightPlayers.Localization.Get("language_changed", {
                language = languageOrError
            })
        )
        return
    end

    if verb == "info" then
        local name, extra = string.match(rest, "^(%S+)%s*(.-)%s*$")

        if name == nil or name == "" or (extra ~= nil and extra ~= "") then
            HighlightPlayers.Util.WriteError(
                HighlightPlayers.Localization.Get("usage_info")
            )
            return
        end

        local record = self.relationships:GetByName(name)
        if record == nil then
            HighlightPlayers.Util.WriteError(
                HighlightPlayers.Localization.Get("no_saved_player", {
                    name = name
                })
            )
            return
        end

        local note = HighlightPlayers.Util.Trim(record.note)
        if note == "" then
            HighlightPlayers.Util.WriteInfo(
                HighlightPlayers.Localization.Get("player_has_no_note", {
                    name = record.name
                })
            )
            return
        end

        HighlightPlayers.Util.WriteInfo(HighlightPlayers.Localization.Get(
            "note_for",
            { name = record.name, note = note }
        ))
        return
    end

    if verb == "add" then
        local name, labelName = string.match(rest, "^(%S+)%s*(.-)%s*$")

        if name == nil or name == "" then
            HighlightPlayers.Util.WriteError(
                HighlightPlayers.Localization.Get("usage_add")
            )
            return
        end

        if labelName == nil or labelName == "" then
            self.cardWindow.OpenNew(name, nil)
            return
        end

        local label = self.labels:FindByName(labelName)
        if label == nil then
            HighlightPlayers.Util.WriteError(
                HighlightPlayers.Localization.Get("unknown_label", {
                    label = labelName
                })
            )
            return
        end

        local succeeded, result, persisted = self.relationships:SavePlayer(
            nil,
            name,
            label.id,
            nil
        )

        if not succeeded then
            HighlightPlayers.Util.WriteError(result)
            return
        end

        if persisted then
            HighlightPlayers.Util.WriteInfo(
                HighlightPlayers.Localization.Get("saved_as", {
                    name = result.name,
                    label = label.name
                })
            )
        end
        return
    end

    HighlightPlayers.Util.WriteError(
        HighlightPlayers.Localization.Get("unknown_command")
    )
end

function HighlightPlayers.Commands:Start()
    if self.command ~= nil then
        return
    end

    local owner = self
    local command = Turbine.ShellCommand()

    function command:GetShortHelp()
        return HighlightPlayers.Localization.Get("short_help")
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
