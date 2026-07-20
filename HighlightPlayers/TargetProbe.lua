HighlightPlayers = HighlightPlayers or {}

HighlightPlayers.TargetProbe = {}
HighlightPlayers.TargetProbe.__index = HighlightPlayers.TargetProbe

local function safeMethod(object, methodName)
    if object == nil then
        return false, nil, "object is nil"
    end

    local lookupSucceeded, method = pcall(function()
        return object[methodName]
    end)

    if not lookupSucceeded or type(method) ~= "function" then
        return false, nil, methodName .. " is unavailable"
    end

    local callSucceeded, value = pcall(method, object)
    if not callSucceeded then
        return false, nil, tostring(value)
    end

    return true, value, nil
end

local function safeIsA(object, classType)
    if object == nil or classType == nil then
        return false
    end

    local succeeded, result = pcall(function()
        return object:IsA(classType)
    end)

    return succeeded and result == true
end

local function getEntityType(target)
    if safeIsA(target, Turbine.Gameplay.Player) then
        return "Player"
    end

    if safeIsA(target, Turbine.Gameplay.Actor) then
        return "Actor"
    end

    if safeIsA(target, Turbine.Gameplay.Entity) then
        return "Entity"
    end

    return "Unknown"
end

local function getAlignment(target)
    local succeeded, alignment = safeMethod(target, "GetAlignment")
    if not succeeded then
        return "unavailable"
    end

    if alignment == Turbine.Gameplay.Alignment.MonsterPlayer then
        return "MonsterPlayer (" .. tostring(alignment) .. ")"
    end

    return tostring(alignment)
end

local function getLocalPlayerSide(player)
    local succeeded, alignment = safeMethod(player, "GetAlignment")
    if not succeeded then
        return "unknown", "unavailable"
    end

    if alignment == Turbine.Gameplay.Alignment.MonsterPlayer then
        return "MonsterPlayer", tostring(alignment)
    end

    return "FreePeople", tostring(alignment)
end

function HighlightPlayers.TargetProbe.New()
    local instance = {
        player = nil,
        targetChangedCallback = nil,
        lastSnapshot = nil,
        started = false
    }

    setmetatable(instance, HighlightPlayers.TargetProbe)
    return instance
end

function HighlightPlayers.TargetProbe:ReadSnapshot()
    local targetSucceeded, target, targetError = safeMethod(self.player, "GetTarget")

    if not targetSucceeded then
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

    local nameSucceeded, name, nameError = safeMethod(target, "GetName")
    if not nameSucceeded then
        return {
            state = "error",
            error = nameError
        }
    end

    local localPlayerSucceeded, isLocalPlayer = safeMethod(target, "IsLocalPlayer")

    return {
        state = "target",
        name = tostring(name),
        entityType = getEntityType(target),
        alignment = getAlignment(target),
        isLocalPlayer = localPlayerSucceeded and isLocalPlayer == true
    }
end

function HighlightPlayers.TargetProbe:PrintSnapshot(reason)
    local snapshot = self:ReadSnapshot()
    self.lastSnapshot = snapshot

    if snapshot.state == "empty" then
        Turbine.Shell.WriteLine("[HighlightPlayers] Target cleared (" .. reason .. ").")
        return snapshot
    end

    if snapshot.state == "error" then
        Turbine.Shell.WriteLine(
            "[HighlightPlayers] Target read failed (" .. reason .. "): " ..
            tostring(snapshot.error)
        )
        return snapshot
    end

    Turbine.Shell.WriteLine(
        "[HighlightPlayers] Target: " .. snapshot.name ..
        " | type=" .. snapshot.entityType ..
        " | alignment=" .. snapshot.alignment ..
        " | local=" .. tostring(snapshot.isLocalPlayer) ..
        " | reason=" .. reason
    )

    return snapshot
end

function HighlightPlayers.TargetProbe:Start()
    if self.started then
        return true
    end

    local playerSucceeded, playerOrError = pcall(function()
        return Turbine.Gameplay.LocalPlayer.GetInstance()
    end)

    if not playerSucceeded or playerOrError == nil then
        Turbine.Shell.WriteLine(
            "[HighlightPlayers] Could not access LocalPlayer: " ..
            tostring(playerOrError)
        )
        return false
    end

    self.player = playerOrError

    local nameSucceeded, playerName = safeMethod(self.player, "GetName")
    local side, alignment = getLocalPlayerSide(self.player)
    Turbine.Shell.WriteLine(
        "[HighlightPlayers] Local player: " ..
        (nameSucceeded and tostring(playerName) or "unknown") ..
        " | side=" .. side ..
        " | alignment=" .. alignment
    )

    self.targetChangedCallback = function()
        self:PrintSnapshot("TargetChanged")
    end

    HighlightPlayers.Event.Add(
        self.player,
        "TargetChanged",
        self.targetChangedCallback
    )

    self.started = true
    self:PrintSnapshot("startup")
    return true
end

function HighlightPlayers.TargetProbe:Stop()
    if not self.started then
        return
    end

    HighlightPlayers.Event.Remove(
        self.player,
        "TargetChanged",
        self.targetChangedCallback
    )

    self.targetChangedCallback = nil
    self.player = nil
    self.started = false
end
