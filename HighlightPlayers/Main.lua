import "Turbine"
import "Turbine.Gameplay"
import "HighlightPlayers"

HighlightPlayers = HighlightPlayers or {}

local probe = HighlightPlayers.TargetProbe.New()
local command = Turbine.ShellCommand()

function command:GetShortHelp()
    return "/eh probe - print information about the current target"
end

function command:GetHelp()
    return self:GetShortHelp()
end

function command:Execute(commandName, arguments)
    local trimmedArguments = string.gsub(
        arguments or "",
        "^%s*(.-)%s*$",
        "%1"
    )
    local normalizedArguments = string.lower(trimmedArguments)

    if normalizedArguments == "" or normalizedArguments == "probe" then
        probe:PrintSnapshot("command")
        return
    end

    if normalizedArguments == "help" then
        Turbine.Shell.WriteLine("[HighlightPlayers] " .. self:GetHelp())
        return
    end

    Turbine.Shell.WriteLine(
        "[HighlightPlayers] Unknown prototype command. " .. self:GetHelp()
    )
end

Turbine.Shell.AddCommand("eh", command)

probe:Start()

Turbine.Shell.WriteLine(
    "[HighlightPlayers] Enemy Highlight v0.1.0 loaded (target prototype). " ..
    "Select a target or use /eh probe."
)

plugin.Unload = function()
    probe:Stop()
    Turbine.Shell.RemoveCommand(command)
end
