--========================================================--
--                  KEEP CONTAINERS                      --
--              QBOX + OX INVENTORY                     --
--========================================================--

local creation_list = {}

--========================================================--
--                    SUPER USER                         --
--========================================================--

local function GetDiscordId(source)
    source = tonumber(source)

    if not source then
        return nil
    end

    local identifier = GetPlayerIdentifierByType(source, 'discord')

    if not identifier then
        return nil
    end

    return identifier:gsub('^discord:', '')
end

local function IsDiscordSuperUser(source)
    local discordId = GetDiscordId(source)

    if not discordId then
        return false
    end

    if not Config.super_users then
        return false
    end

    return Config.super_users[tostring(discordId)] == true
end

local function IsAceSuperUser(source)
    source = tonumber(source)

    if not source then
        return false
    end

    -- Qbox standard ACE groups
    if IsPlayerAceAllowed(source, 'group.admin') then
        return true
    end

    if IsPlayerAceAllowed(source, 'group.god') then
        return true
    end

    -- Compatibility with servers using these permissions
    if IsPlayerAceAllowed(source, 'admin') then
        return true
    end

    if IsPlayerAceAllowed(source, 'god') then
        return true
    end

    return false
end

local function IsSuperUser(source)
    source = tonumber(source)

    if not source then
        return false
    end

    -- Discord whitelist
    if IsDiscordSuperUser(source) then
        return true
    end

    -- Qbox / ACE
    if IsAceSuperUser(source) then
        return true
    end

    return false
end

-- Export this in case another keep-containers file needs it.
exports('IsSuperUser', function(source)
    return IsSuperUser(source)
end)

--========================================================--
--                 SUPER USER REQUEST                    --
--========================================================--

RegisterNetEvent(
    'keep-containers:server:request_super_user',
    function()
        local src = source
        local allowed = IsSuperUser(src)

        TriggerClientEvent(
            'keep-containers:client:set_super_user',
            src,
            allowed
        )

        local player = Player(src)

        if player and player.state then
            player.state:set(
                'keepContainersSuperUser',
                allowed,
                true
            )
        end
    end
)

-- Compatibility with the previous event name
RegisterNetEvent(
    'keep-containers:server:checkSuperUser',
    function()
        local src = source
        local allowed = IsSuperUser(src)

        TriggerClientEvent(
            'keep-containers:client:set_super_user',
            src,
            allowed
        )

        local player = Player(src)

        if player and player.state then
            player.state:set(
                'keepContainersSuperUser',
                allowed,
                true
            )
        end
    end
)

--========================================================--
--                     HELPERS                           --
--========================================================--

local function GetPlayer(source)
    if not source then
        return nil
    end

    return exports.qbx_core:GetPlayer(source)
end

local function GetCitizenId(player)
    if not player then
        return nil
    end

    return player.PlayerData
        and player.PlayerData.citizenid
        or nil
end

local function GetJob(source)
    local player = GetPlayer(source)

    if not player
        or not player.PlayerData
        or not player.PlayerData.job
    then
        return nil, nil
    end

    local job = player.PlayerData.job
    local grade = 0

    if type(job.grade) == 'table' then
        grade =
            tonumber(job.grade.level)
            or tonumber(job.grade.grade)
            or 0
    else
        grade = tonumber(job.grade) or 0
    end

    return job.name, grade
end

local function HasAccessToBoltCutter(source)
    local jobName, jobGrade = GetJob(source)

    if not jobName then
        return false
    end

    if not Config.bolt_cutter then
        return false
    end

    local jobConfig =
        Config.bolt_cutter[tostring(jobName)]

    if not jobConfig then
        return false
    end

    return jobConfig[tonumber(jobGrade)] == true
end

local function HasBoltCutter(source)
    local itemName = Config.bolt_cutter_item_name

    if not itemName then
        return false
    end

    local count =
        exports.ox_inventory:Search(
            source,
            'count',
            itemName
        )

    return tonumber(count) and tonumber(count) > 0
end

local function RemoveItem(source, itemName, amount, slot)
    amount = amount or 1

    local success =
        exports.ox_inventory:RemoveItem(
            source,
            itemName,
            amount,
            nil,
            slot
        )

    return success == true
end

local function IsOwner(ownerCitizenId, currentCitizenId)
    return ownerCitizenId ~= nil
        and currentCitizenId ~= nil
        and ownerCitizenId == currentCitizenId
end

local function GetContainerInfo(containerName)
    if not containerName then
        return nil
    end

    if GetContainerInfromation then
        local info =
            GetContainerInfromation(containerName)

        if info then
            return info
        end
    end

    return nil
end

local function RegisterContainerStash(
    randomId,
    containerInfo
)
    if not randomId or not containerInfo then
        return false
    end

    local containerType = containerInfo.type

    if not containerType then
        return false
    end

    local stashId =
        'Container_' .. tostring(randomId)

    local slots =
        tonumber(containerType.slots) or 10

    local maxWeight =
        tonumber(containerType.size) or 10000

    exports.ox_inventory:RegisterStash(
        stashId,
        'Container',
        slots,
        maxWeight,
        false
    )

    return stashId, slots, maxWeight
end

local function OpenContainer(
    source,
    randomId,
    containerInfo
)
    if not source
        or not randomId
        or not containerInfo
    then
        return false
    end

    local stashId, slots, maxWeight =
        RegisterContainerStash(
            randomId,
            containerInfo
        )

    if not stashId then
        return false
    end

    TriggerClientEvent(
        'keep-containers:client:open',
        source,
        {
            random_id = randomId,
            slots = slots,
            size = maxWeight
        }
    )

    return true
end

--========================================================--
--                     DATABASE                          --
--========================================================--

local function InitDatabase()

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `keep_containers` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `random_id` varchar(50) NOT NULL,
            `container_type` varchar(50) NOT NULL,
            `owner_citizenid` varchar(50) DEFAULT NULL,
            `password` CHAR(60) DEFAULT NULL,
            `position` TEXT DEFAULT NULL,
            `zone` varchar(50) DEFAULT NULL,
            `deleted` BOOLEAN NOT NULL DEFAULT TRUE,
            `deleted_by` varchar(50) DEFAULT NULL,
            PRIMARY KEY (`id`),
            KEY `random_id` (`random_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `keep_containers_access_log` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `random_id` varchar(50) NOT NULL,
            `citizenid` varchar(50) DEFAULT NULL,
            `action` varchar(50) DEFAULT NULL,
            `metadata` TEXT DEFAULT NULL,
            PRIMARY KEY (`id`),
            KEY `random_id` (`random_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    print(
        '^2[keep-containers]^7 Database initialized.'
    )
end

CreateThread(function()

    Wait(1000)

    if GetResourceState('oxmysql') ~= 'started' then
        print(
            '^1[keep-containers]^7 oxmysql is not started!'
        )

        return
    end

    InitDatabase()
end)

--========================================================--
--                  CREATE CONTAINER                     --
--========================================================--

RegisterNetEvent(
    'keep-containers:server:create_container',
    function(password, position, zone_name)

        local src = source
        local player = GetPlayer(src)

        if not player then
            return
        end

        local citizenid =
            GetCitizenId(player)

        local containerType =
            creation_list[src]

        if Config.PlaceAnywhere then zone_name = '__world__' end

        if not Config.PlaceAnywhere and (not zone_name
            or not Config.container_depots
            or not Config.container_depots[zone_name])
        then
            Notification_S(
                src,
                'Depot is not valid',
                'error'
            )

            return
        end

        if not password or password == '' then
            Notification_S(
                src,
                'Enter a better password',
                'primary'
            )

            return
        end

        if not containerType then
            Notification_S(
                src,
                'Wrong container type',
                'error'
            )

            return
        end

        local containerInfo =
            GetContainerInfo(containerType)

        if not containerInfo then
            Notification_S(
                src,
                'Invalid container type',
                'error'
            )

            return
        end

        local itemCount =
            exports.ox_inventory:Search(
                src,
                'count',
                containerType
            )

        if not itemCount
            or tonumber(itemCount) < 1
        then
            Notification_S(
                src,
                'The requested container was not found in your inventory!',
                'error'
            )

            creation_list[src] = nil
            return
        end

        if not RemoveItem(
            src,
            containerType,
            1
        ) then
            Notification_S(
                src,
                'Could not remove the container from your inventory.',
                'error'
            )

            creation_list[src] = nil
            return
        end

        local randomId =
            RandomID(9)

        local passwordHash =
            GetPasswordHash(password)

        local insertId =
            MySQL.insert.await([[
                INSERT INTO keep_containers
                (
                    random_id,
                    container_type,
                    owner_citizenid,
                    password,
                    position,
                    zone,
                    deleted,
                    deleted_by
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ]], {
                randomId,
                containerType,
                citizenid,
                passwordHash,
                json.encode(position),
                zone_name,
                false,
                ''
            })

        creation_list[src] = nil

        if insertId then

            TriggerClientEvent(
                'keep-containers:client:update_zone',
                -1,
                zone_name
            )

            Notification_S(
                src,
                'Container placed successfully.',
                'success'
            )

        else

            Notification_S(
                src,
                'Failed to save the container.',
                'error'
            )

        end
    end
)

--========================================================--
--                GET ZONE CONTAINERS                    --
--========================================================--

CreateCallback(
    'keep-containers:server:GET:ZONE:containers',
    function(source, cb, zone_name)
        if Config.PlaceAnywhere then
            local ped = GetPlayerPed(source)
            if ped == 0 then cb({}); return end
            local coords = GetEntityCoords(ped)
            local radius = tonumber(Config.ContainerStreamDistance) or 150.0
            local rows = MySQL.query.await([[
                SELECT random_id, position, container_type
                FROM keep_containers WHERE deleted = false
            ]])
            local nearby = {}
            for _, row in ipairs(rows or {}) do
                local ok, pos = pcall(json.decode, row.position or '')
                if ok and type(pos) == 'table' and tonumber(pos.x)
                    and tonumber(pos.y) and tonumber(pos.z) then
                    local dx, dy, dz = coords.x-pos.x, coords.y-pos.y, coords.z-pos.z
                    if dx*dx+dy*dy+dz*dz <= radius*radius then
                        nearby[#nearby+1] = row
                    end
                end
            end
            cb(nearby)
            return
        end

        local results =
            MySQL.query.await([[
                SELECT
                    random_id,
                    position,
                    container_type
                FROM keep_containers
                WHERE zone = ?
                AND deleted = false
            ]], {
                zone_name
            })

        cb(results or {})
    end
)

--========================================================--
--                  PASSWORD CHECK                       --
--========================================================--

function VerifyPassword(
    src,
    password,
    passwordHash,
    notification
)

    if not password
        or password == ''
        or not passwordHash
    then

        if notification then
            Notification_S(
                src,
                'Bad password input!',
                'error'
            )
        end

        return false
    end

    local result =
        VerifyPasswordHash(
            password,
            passwordHash
        )

    if result == 1
        or result == true
    then

        if notification then
            Notification_S(
                src,
                'Success',
                'success'
            )
        end

        return true
    end

    if notification then
        Notification_S(
            src,
            'Password is wrong',
            'error'
        )
    end

    return false
end

--========================================================--
--                  OPEN CONTAINER                       --
--========================================================--

RegisterNetEvent(
    'keep-containers:server:container:check_password',
    function(
        random_id,
        password,
        zone_name
    )

        local src = source

        if not random_id then
            return
        end

        local results =
            MySQL.query.await([[
                SELECT
                    random_id,
                    container_type,
                    password,
                    deleted,
                    zone
                FROM keep_containers
                WHERE random_id = ?
                LIMIT 1
            ]], {
                random_id
            })

        local result =
            results and results[1]

        if not result then

            Notification_S(
                src,
                'Container could not be found.',
                'error'
            )

            return
        end

        if result.deleted then

            Notification_S(
                src,
                'This container has been removed.',
                'error'
            )

            return
        end

        if not Config.PlaceAnywhere and zone_name
            and result.zone
            and result.zone ~= zone_name
        then

            Notification_S(
                src,
                'This container is not in this depot.',
                'error'
            )

            return
        end

        local containerInfo =
            GetContainerInfo(
                result.container_type
            )

        if not containerInfo then

            Notification_S(
                src,
                'Container type is invalid.',
                'error'
            )

            return
        end

        if not VerifyPassword(
            src,
            password,
            result.password,
            true
        ) then
            return
        end

        OpenContainer(
            src,
            random_id,
            containerInfo
        )
    end
)

--========================================================--
--                    BOLT CUTTER                        --
--========================================================--

RegisterNetEvent(
    'keep-containers:server:use_bolt_cutter',
    function(
        entity,
        random_id,
        zone_name
    )

        local src = source

        if not HasBoltCutter(src) then

            Notification_S(
                src,
                "You don't have a bolt cutter on you.",
                'error'
            )

            return
        end

        if not HasAccessToBoltCutter(src) then

            Notification_S(
                src,
                "You can't use a bolt cutter.",
                'error'
            )

            return
        end

        TriggerClientEvent(
            'keep-containers:targets:use_bolt_cutter',
            src,
            entity,
            random_id,
            zone_name
        )
    end
)

--========================================================--
--              OPEN WITH BOLT CUTTER                    --
--========================================================--

RegisterNetEvent(
    'keep-containers:server:open_with_bolt_cutter',
    function(
        random_id,
        zone_name
    )

        local src = source

        if not HasAccessToBoltCutter(src) then

            Notification_S(
                src,
                "You can't use a bolt cutter.",
                'error'
            )

            return
        end

        if not HasBoltCutter(src) then

            Notification_S(
                src,
                "You don't have a bolt cutter on you.",
                'error'
            )

            return
        end

        if Config.remove_bolt_cutter_on_use then

            if not RemoveItem(
                src,
                Config.bolt_cutter_item_name,
                1
            ) then

                Notification_S(
                    src,
                    "Can't remove the bolt cutter from you!",
                    'error'
                )

                return
            end
        end

        local results =
            MySQL.query.await([[
                SELECT
                    random_id,
                    container_type,
                    deleted,
                    zone
                FROM keep_containers
                WHERE random_id = ?
                LIMIT 1
            ]], {
                random_id
            })

        local result =
            results and results[1]

        if not result then

            Notification_S(
                src,
                'Container could not be found.',
                'error'
            )

            return
        end

        if result.deleted then

            Notification_S(
                src,
                'This container has been removed.',
                'error'
            )

            return
        end

        if not Config.PlaceAnywhere and zone_name
            and result.zone
            and result.zone ~= zone_name
        then

            Notification_S(
                src,
                'This container is not in this depot.',
                'error'
            )

            return
        end

        local containerInfo =
            GetContainerInfo(
                result.container_type
            )

        if not containerInfo then

            Notification_S(
                src,
                'Invalid container type.',
                'error'
            )

            return
        end

        OpenContainer(
            src,
            random_id,
            containerInfo
        )
    end
)

--========================================================--
--                CHANGE PASSWORD                        --
--========================================================--

RegisterNetEvent(
    'keep-containers:server:container:change_password',
    function(
        random_id,
        current_password,
        new_password,
        zone_name
    )

        local src = source
        local player = GetPlayer(src)

        if not player then
            return
        end

        local citizenid =
            GetCitizenId(player)

        if not new_password
            or new_password == ''
        then

            Notification_S(
                src,
                'Bad password input.',
                'error'
            )

            return
        end

        local results =
            MySQL.query.await([[
                SELECT
                    id,
                    owner_citizenid,
                    password
                FROM keep_containers
                WHERE random_id = ?
                LIMIT 1
            ]], {
                random_id
            })

        local result =
            results and results[1]

        if not result then

            Notification_S(
                src,
                'Container could not be found.',
                'error'
            )

            return
        end

        if not IsOwner(
            result.owner_citizenid,
            citizenid
        ) then

            Notification_S(
                src,
                'Only the owner of this container can change the password!',
                'error'
            )

            return
        end

        if not VerifyPassword(
            src,
            current_password,
            result.password,
            false
        ) then

            Notification_S(
                src,
                'Current password is wrong.',
                'error'
            )

            return
        end

        local newHash =
            GetPasswordHash(new_password)

        MySQL.update.await([[
            UPDATE keep_containers
            SET password = ?
            WHERE id = ?
        ]], {
            newHash,
            result.id
        })

        Notification_S(
            src,
            'Password Updated.',
            'primary'
        )
    end
)

--========================================================--
--                TRANSFER OWNERSHIP                     --
--========================================================--

RegisterNetEvent(
    'keep-containers:server:container:transfer_ownership',
    function(
        random_id,
        zone_name,
        new_owner
    )

        local src = source

        new_owner = tonumber(new_owner)

        if not new_owner then

            Notification_S(
                src,
                'Invalid player ID.',
                'error'
            )

            return
        end

        if src == new_owner then

            Notification_S(
                src,
                "You can't transfer it to yourself.",
                'primary'
            )

            return
        end

        local ownerPlayer =
            GetPlayer(src)

        if not ownerPlayer then
            return
        end

        local ownerCitizenId =
            GetCitizenId(ownerPlayer)

        local newOwnerPlayer =
            GetPlayer(new_owner)

        if not newOwnerPlayer then

            Notification_S(
                src,
                "We can't find that player in the city.",
                'primary'
            )

            return
        end

        local newCitizenId =
            GetCitizenId(newOwnerPlayer)

        if not newCitizenId then

            Notification_S(
                src,
                "We can't find that player's citizen ID.",
                'primary'
            )

            return
        end

        local results =
            MySQL.query.await([[
                SELECT
                    id,
                    owner_citizenid
                FROM keep_containers
                WHERE random_id = ?
                LIMIT 1
            ]], {
                random_id
            })

        local result =
            results and results[1]

        if not result then

            Notification_S(
                src,
                'Container could not be found.',
                'error'
            )

            return
        end

        if not IsOwner(
            result.owner_citizenid,
            ownerCitizenId
        ) then

            Notification_S(
                src,
                'Only the owner of this container can transfer ownership!',
                'primary'
            )

            return
        end

        MySQL.update.await([[
            UPDATE keep_containers
            SET
                owner_citizenid = ?,
                password = ?
            WHERE id = ?
        ]], {
            newCitizenId,
            GetPasswordHash('0000'),
            result.id
        })

        Notification_S(
            src,
            'Transfer completed.',
            'primary'
        )

        Notification_S(
            new_owner,
            'Transfer completed.',
            'primary'
        )

        Notification_S(
            new_owner,
            "Password is set to '0000'",
            'success'
        )
    end
)

--========================================================--
--                 DELETE CONTAINER                      --
--========================================================--

RegisterNetEvent(
    'keep-containers:server:container:delete',
    function(
        random_id,
        zone_name
    )

        local src = source

        -- IMPORTANT:
        -- Check Discord / ACE directly.
        -- Do NOT use citizenid here.
        if not IsSuperUser(src) then

            Notification_S(
                src,
                "Hmm, you can't do that!",
                'primary'
            )

            return
        end

        local player =
            GetPlayer(src)

        if not player then
            return
        end

        local citizenid =
            GetCitizenId(player)

        local changed =
            MySQL.update.await([[
                UPDATE keep_containers
                SET
                    deleted = ?,
                    deleted_by = ?
                WHERE random_id = ?
                AND (zone = ? OR ? = 1)
            ]], {
                true,
                citizenid or GetDiscordId(src) or 'admin',
                random_id,
                zone_name,
                Config.PlaceAnywhere and 1 or 0
            })

        if changed and changed > 0 then

            Notification_S(
                src,
                'Container has been removed!',
                'success'
            )

            TriggerClientEvent(
                'keep-containers:client:update_zone',
                -1,
                zone_name
            )

        else

            Notification_S(
                src,
                'Container could not be found.',
                'error'
            )
        end
    end
)

--========================================================--
--                UPDATE POSITION                        --
--========================================================--

RegisterNetEvent(
    'keep-containers:server:container:update_position',
    function(
        random_id,
        zone_name,
        new_position
    )

        local src = source

        -- IMPORTANT:
        -- Check Discord / ACE directly.
        if not IsSuperUser(src) then

            Notification_S(
                src,
                "Hmm, you can't do that!",
                'primary'
            )

            TriggerClientEvent(
                'keep-containers:client:update_zone',
                src,
                zone_name
            )

            return
        end

        if not new_position
            or type(new_position) ~= 'vector4'
        then

            Notification_S(
                src,
                'Wrong position type!',
                'primary'
            )

            return
        end

        local results =
            MySQL.query.await([[
                SELECT
                    id
                FROM keep_containers
                WHERE random_id = ?
                LIMIT 1
            ]], {
                random_id
            })

        local result =
            results and results[1]

        if not result then

            Notification_S(
                src,
                'Container could not be found.',
                'error'
            )

            return
        end

        local changed =
            MySQL.update.await([[
                UPDATE keep_containers
                SET position = ?
                WHERE id = ?
            ]], {
                json.encode({
                    x = new_position.x,
                    y = new_position.y,
                    z = new_position.z,
                    w = new_position.w
                }),
                result.id
            })

        if changed and changed > 0 then

            Notification_S(
                src,
                'Completed.',
                'success'
            )

            TriggerClientEvent(
                'keep-containers:client:update_zone',
                -1,
                zone_name
            )

        else

            Notification_S(
                src,
                'Could not update the container position.',
                'error'
            )
        end
    end
)

--========================================================--
--                 CONTAINER ITEMS                       --
--========================================================--

CreateThread(function()

    Wait(1500)

    local items =
        GetContainerItems()

    if not items then

        print(
            '^1[keep-containers]^7 Could not load container items.'
        )

        return
    end

    for itemName, _ in pairs(items) do

        exports.qbx_core:CreateUseableItem(
            itemName,
            function(source, item)

                local player =
                    exports.qbx_core:GetPlayer(source)

                if not player then
                    return
                end

                creation_list[source] =
                    itemName

                TriggerClientEvent(
                    'keep-containers:client:container:place',
                    source,
                    itemName
                )
            end
        )

        print(
            ('^2[keep-containers]^7 Registered Qbox usable item: ^3%s^7')
            :format(itemName)
        )
    end
end)

--========================================================--
--                  PLAYER CLEANUP                       --
--========================================================--

AddEventHandler(
    'playerDropped',
    function()

        local src = source

        creation_list[src] = nil
    end
)

--========================================================--
--                 DEBUG COMMAND                         --
--========================================================--

RegisterCommand(
    'kcperm',
    function(source)

        if source == 0 then
            print(
                '[keep-containers] Console cannot use this command.'
            )
            return
        end

        local discordId =
            GetDiscordId(source)

        local aceAdmin =
            IsPlayerAceAllowed(
                source,
                'group.admin'
            )

        local aceGod =
            IsPlayerAceAllowed(
                source,
                'group.god'
            )

        local discordAllowed =
            IsDiscordSuperUser(source)

        local finalResult =
            IsSuperUser(source)

        print(
            ('[keep-containers] %s | Discord: %s | Config: %s | ACE admin: %s | ACE god: %s | SUPER: %s')
            :format(
                GetPlayerName(source) or 'Unknown',
                discordId or 'NONE',
                tostring(discordAllowed),
                tostring(aceAdmin),
                tostring(aceGod),
                tostring(finalResult)
            )
        )

        Notification_S(
            source,
            'Keep Containers permission: '
                .. tostring(finalResult),
            finalResult and 'success' or 'error'
        )
    end,
    false
)