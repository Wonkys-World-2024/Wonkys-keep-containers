--========================================================--
-- KEEP-CONTAINERS QBOX PERMISSIONS
-- Supports:
--   1. Qbox/ACE admin
--   2. Qbox/ACE god
--   3. Discord ID whitelist
--========================================================--

local DynamicSuperUsers = {}

local function GetDiscordId(src)
    local identifiers = GetPlayerIdentifiers(src)

    for _, identifier in ipairs(identifiers) do
        if identifier:sub(1, 8) == "discord:" then
            return identifier:sub(9)
        end
    end

    return nil
end

local function IsDiscordSuperUser(src)
    local discordId = GetDiscordId(src)

    if not discordId then
        return false
    end

    if not Config.super_users then
        return false
    end

    return Config.super_users[discordId] == true
end

local function IsAceSuperUser(src)
    if IsPlayerAceAllowed(src, "group.admin") then
        return true
    end

    if IsPlayerAceAllowed(src, "group.god") then
        return true
    end

    -- Compatibility with servers using bare ACE permissions
    if IsPlayerAceAllowed(src, "admin") then
        return true
    end

    if IsPlayerAceAllowed(src, "god") then
        return true
    end

    return false
end

function KeepContainersIsSuperUser(src)
    src = tonumber(src)

    if not src then
        return false
    end

    -- Discord whitelist
    if IsDiscordSuperUser(src) then
        return true
    end

    -- Qbox / ACE admin
    if Config.FrameWork == "qbox" then
        if IsAceSuperUser(src) then
            return true
        end
    end

    -- Session-only super user cache
    if DynamicSuperUsers[src] == true then
        return true
    end

    return false
end


--========================================================--
-- REQUEST SUPER USER STATUS
--========================================================--

RegisterNetEvent("keep-containers:server:request_super_user", function()
    local src = source

    local allowed = KeepContainersIsSuperUser(src)

    if allowed then
        DynamicSuperUsers[src] = true
    else
        DynamicSuperUsers[src] = nil
    end

    -- Send state to client
    TriggerClientEvent(
        "keep-containers:client:set_super_user",
        src,
        allowed
    )

    -- Also expose it as a player state value
    local player = Player(src)

    if player and player.state then
        player.state:set(
            "keepContainersSuperUser",
            allowed,
            true
        )
    end
end)


--========================================================--
-- CLEANUP
--========================================================--

AddEventHandler("playerDropped", function()
    local src = source

    DynamicSuperUsers[src] = nil
end)