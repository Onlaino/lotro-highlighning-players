HighlightPlayers = HighlightPlayers or {}

HighlightPlayers.TargetTracker = {}
HighlightPlayers.TargetTracker.__index = HighlightPlayers.TargetTracker

local function getEntityType(target)
    if HighlightPlayers.Util.SafeIsA(target, Turbine.Gameplay.Player) then
        return "Player"
    end

    if HighlightPlayers.Util.SafeIsA(target, Turbine.Gameplay.Actor) then
        return "Actor"
    end

    if HighlightPlayers.Util.SafeIsA(target, Turbine.Gameplay.Entity) then
        return "Entity"
    end

    return "Unknown"
end

local function getAlignment(target)
    local succeeded, alignment = HighlightPlayers.Util.SafeMethod(
        target,
        "GetAlignment"
    )

    if not succeeded then
        return "unavailable"
    end

    if alignment == Turbine.Gameplay.Alignment.MonsterPlayer then
        return "MonsterPlayer (" .. tostring(alignment) .. ")"
    end

    if alignment == Turbine.Gameplay.Alignment.FreePeople then
        return "FreePeople (" .. tostring(alignment) .. ")"
    end

    return tostring(alignment)
end

function HighlightPlayers.TargetTracker.New()
    local instance = {
        player = nil,
        callback = nil,
        snapshot = {
            state = "empty"
        },
        listeners = {},
        started = false
    }

    setmetatable(instance, HighlightPlayers.TargetTracker)
    return instance
end

function HighlightPlayers.TargetTracker:AddListener(listener)
    table.insert(self.listeners, listener)
    return listener
end

function HighlightPlayers.TargetTracker:RemoveListener(listener)
    for index = 1, table.getn(self.listeners) do
        if self.listeners[index] == listener then
            table.remove(self.listeners, index)
            return
        end
    end
end

function HighlightPlayers.TargetTracker:Notify()
    for index = 1, table.getn(self.listeners) do
        self.listeners[index](self.snapshot)
    end
end

function HighlightPlayers.TargetTracker:ReadSnapshot()
    local succeeded, target, targetError = HighlightPlayers.Util.SafeMethod(
        self.player,
        "GetTarget"
    )

    if not succeeded then
        return {
            state = "error",
            error = targetError
        }
    end

    if target == nil then
        return {
            state = "empty"
        }
    end

    local nameSucceeded, name, nameError = HighlightPlayers.Util.SafeMethod(
        target,
        "GetName"
    )

    if not nameSucceeded then
        return {
            state = "error",
            error = nameError
        }
    end

    local localSucceeded, isLocalPlayer = HighlightPlayers.Util.SafeMethod(
        target,
        "IsLocalPlayer"
    )

    return {
        state = "target",
        name = tostring(name),
        entityType = getEntityType(target),
        alignment = getAlignment(target),
        isLocalPlayer = localSucceeded and isLocalPlayer == true
    }
end

function HighlightPlayers.TargetTracker:Refresh()
    self.snapshot = self:ReadSnapshot()
    self:Notify()
    return self.snapshot
end

function HighlightPlayers.TargetTracker:GetSnapshot()
    return self.snapshot
end

function HighlightPlayers.TargetTracker:GetCurrentName()
    if self.snapshot.state ~= "target" then
        return nil
    end

    return self.snapshot.name
end

function HighlightPlayers.TargetTracker:PrintSnapshot()
    local snapshot = self:Refresh()

    if snapshot.state == "empty" then
        HighlightPlayers.Util.WriteInfo("Target is empty.")
        return
    end

    if snapshot.state == "error" then
        HighlightPlayers.Util.WriteError(
            "Target read failed: " .. tostring(snapshot.error)
        )
        return
    end

    HighlightPlayers.Util.WriteInfo(
        "Target: " .. snapshot.name ..
        " | type=" .. snapshot.entityType ..
        " | alignment=" .. snapshot.alignment ..
        " | local=" .. tostring(snapshot.isLocalPlayer)
    )
end

function HighlightPlayers.TargetTracker:Start()
    if self.started then
        return true
    end

    local succeeded, playerOrError = pcall(function()
        return Turbine.Gameplay.LocalPlayer.GetInstance()
    end)

    if not succeeded or playerOrError == nil then
        HighlightPlayers.Util.WriteError(
            "Could not access LocalPlayer: " .. tostring(playerOrError)
        )
        return false
    end

    self.player = playerOrError
    self.callback = function()
        self:Refresh()
    end

    HighlightPlayers.Event.Add(self.player, "TargetChanged", self.callback)
    self.started = true
    self:Refresh()
    return true
end

function HighlightPlayers.TargetTracker:Stop()
    if not self.started then
        return
    end

    HighlightPlayers.Event.Remove(self.player, "TargetChanged", self.callback)
    self.callback = nil
    self.player = nil
    self.started = false
end
