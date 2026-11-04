local ZONE = {}
local current_zone
local loaded = false

Core = GetCoreObject()
local FrameworkType = Framework()

Containers = {
    data = {}
}



local function GetPlayerData()
    if FrameworkType == 3 then
        return exports.qbx_core:GetPlayerData()
    elseif FrameworkType == 1 then
        return Core.Functions.GetPlayerData()
    elseif FrameworkType == 2 then
        return Core.PlayerData
    end
end

local function GetCitizenId(data)
    if not data then
        return nil
    end

    if FrameworkType == 3 then
        return data.citizenid
    elseif FrameworkType == 1 then
        return data.citizenid
    elseif FrameworkType == 2 then
        return data.identifier
    end
end

local function GetJob()
    local data = GetPlayerData()

    if not data or not data.job then
        return nil, nil
    end

    if FrameworkType == 3 then
        return data.job.name, tonumber(data.job.grade and data.job.grade.level or 0)
    elseif FrameworkType == 1 then
        return data.job.name, tonumber(data.job.grade and data.job.grade.level or 0)
    elseif FrameworkType == 2 then
        return data.job.name, tonumber(data.job.grade or 0)
    end
end

function Notification_c(message, notificationType)
    if notificationType == 'primary' then
        notificationType = 'inform'
    end

    lib.notify({
        title = 'Container Depot',
        description = message,
        type = notificationType or 'inform'
    })
end

RegisterNetEvent('keep-containers:client:notification', function(message, notificationType)
    Notification_c(message, notificationType)
end)

local function SpawnObject(model, coord, rotation, offset)
    local modelHash = GetHashKey(model)

    LoadModel(modelHash)

    local entity = CreateObject(
        modelHash,
        coord.x + offset.x,
        coord.y + offset.y,
        coord.z + offset.z,
        false,
        false,
        false
    )

    WaitForEntity(entity)

    SetEntityAsMissionEntity(entity, true, true)
    SetEntityRotation(entity, rotation.x, rotation.y, rotation.z, 2, true)
    FreezeEntityPosition(entity, true)

    SetEntityProofs(
        entity,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )

    SetModelAsNoLongerNeeded(modelHash)

    return entity
end

local function ShowDrawText(text)
    lib.showTextUI(text or 'Container Depot', {
        icon = 'warehouse',
        style = {
            borderRadius = 0,
            backgroundColor = '#48BB78',
            color = 'white'
        }
    })
end

local function HideDrawText()
    lib.hideTextUI()
end

local function CreateBlip(options)
    if not options or not options.coords then
        return
    end

    local blip = AddBlipForCoord(options.coords)

    SetBlipSprite(blip, options.sprite or 677)
    SetBlipScale(blip, options.scale or 1.0)
    SetBlipColour(blip, options.color or 49)
    SetBlipDisplay(blip, 4)
    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(options.name or 'Container Depot')
    EndTextCommandSetBlipName(blip)

    return blip
end

local function PointToVec3(point, z)
    return vec3(
        tonumber(point.x) or 0.0,
        tonumber(point.y) or 0.0,
        tonumber(z) or 0.0
    )
end

local function LoadZoneContainers(zoneName)
    if current_zone ~= zoneName then
        return
    end

    if not Config.PlaceAnywhere then Containers:clean_up() end

    TriggerCallback(
        'keep-containers:server:GET:ZONE:containers',
        function(containers)
            if current_zone ~= zoneName then
                return
            end

            local present = {}
            for _, container in pairs(containers or {}) do
                present[container.random_id] = true
                local existing = Containers.data[container.random_id]
                if existing and existing.position ~= container.position then
                    existing.remove_object()
                    Containers.data[container.random_id] = nil
                end
                if not Containers.data[container.random_id] then
                    Containers:new(container)
                end
            end
            if Config.PlaceAnywhere then
                for id, container in pairs(Containers.data) do
                    if not present[id] then
                        container.remove_object()
                        Containers.data[id] = nil
                    end
                end
            end
        end,
        zoneName
    )
end

local function Init()
    if loaded then
        return
    end

    loaded = true

    if Config.PlaceAnywhere then
        current_zone = '__world__'
        ZONE[current_zone] = { contains = function() return true end }
        CreateThread(function()
            while loaded do
                if current_zone then LoadZoneContainers(current_zone) end
                Wait(5000)
            end
        end)
        return
    end

    for name, depot in pairs(Config.container_depots) do
        CreateBlip(depot.blip)

        local minZ = tonumber(depot.minz) or 0.0
        local maxZ = tonumber(depot.maxz) or (minZ + 5.0)
        local middleZ = minZ + ((maxZ - minZ) / 2.0)

        local points = {}

        for _, point in ipairs(depot.positions or {}) do
            points[#points + 1] = PointToVec3(point, middleZ)
        end

        if #points >= 3 then
            ZONE[name] = lib.zones.poly({
                points = points,
                thickness = math.max(maxZ - minZ, 0.1),
                debug = Config.MagicTouch == true,

                onEnter = function()
                    current_zone = name

                    Wait(50)

                    ShowDrawText(depot.name or 'Container Depot')

                    LoadZoneContainers(name)
                end,

                onExit = function()
                    if current_zone ~= name then
                        return
                    end

                    current_zone = nil

                    Containers:clean_up()

                    HideDrawText()
                end
            })
        else
            print(('[keep-containers] Invalid depot polygon: %s'):format(name))
        end
    end
end

function Containers:new(options)
    if not options or not options.random_id then
        return
    end

    local containerData = GetContainerInfromation(options.container_type)

    if not containerData then
        print(('[keep-containers] Unknown container type: %s'):format(
            tostring(options.container_type)
        ))

        return
    end

    local self = {}

    local private = {
        random_id = options.random_id,
        position = json.decode(options.position),
        container_type = options.container_type,
        objects = {}
    }

    local function AddTarget(entity)
        if Config.esx_target:lower() == 'ox_target' then
            Ox_target(private, entity)
        elseif Config.esx_target:lower() == 'qtarget' then
            Qtarget(private, entity)
        elseif Config.esx_target:lower() == 'qb-target' then
            Qb_target(private, entity)
        end
    end

    local function Spawn()
        if not private.position then
            return
        end

        local coords = TableToVector3(private.position)
        local heading = tonumber(private.position.w) or 0.0

        local entity = SpawnObject(
            containerData.object.name,
            coords,
            vector3(0.0, 0.0, heading),
            containerData.object.offset
        )

        private.objects[#private.objects + 1] = entity

        AddTarget(entity)
    end

    function self.remove_object()
        for _, entity in pairs(private.objects) do
            if DoesEntityExist(entity) then
                DeleteEntity(entity)
            end
        end

        private.objects = {}
    end

    self.position = options.position
    Spawn()

    Containers.data[options.random_id] = self

    return self
end

function Containers:clean_up()
    for _, container in pairs(self.data) do
        if container and container.remove_object then
            container.remove_object()
        end
    end

    self.data = {}
end

function GetCurrentZone()
    if not current_zone then
        return nil, nil
    end

    return current_zone, ZONE[current_zone]
end

RegisterNetEvent('keep-containers:client:update_zone', function(zoneName)
    if Config.PlaceAnywhere then
        LoadZoneContainers(current_zone)
        return
    end
    if zoneName ~= current_zone then return end
    LoadZoneContainers(zoneName)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    Wait(1000)

    Init()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    Containers:clean_up()

    for _, zone in pairs(ZONE) do
        if zone and zone.remove then
            zone:remove()
        end
    end

    HideDrawText()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    if FrameworkType == 1 or FrameworkType == 3 then
        Init()
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    if FrameworkType == 1 or FrameworkType == 3 then
        current_zone = Config.PlaceAnywhere and '__world__' or nil
        Containers:clean_up()
        HideDrawText()
    end
end)

RegisterNetEvent('esx:playerLoaded', function()
    if FrameworkType == 2 then
        Init()
    end
end)

CreateThread(function()
    Wait(1500)
    Init()
end)


--========================================================--
-- KEEP-CONTAINERS QBOX SUPER USER PERMISSION
--========================================================--

local isKeepContainersSuperUser = false

-- Current permission event
RegisterNetEvent("keep-containers:client:set_super_user", function(state)
    isKeepContainersSuperUser = state == true
end)

-- Compatibility with older versions
RegisterNetEvent("keep-containers:client:setSuperUser", function(state)
    isKeepContainersSuperUser = state == true
end)

local function RequestKeepContainersPermission()
    TriggerServerEvent(
        "keep-containers:server:request_super_user"
    )
end

-- Initial permission check
CreateThread(function()
    Wait(5000)

    RequestKeepContainersPermission()
end)

-- Re-check when the player loads
RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    Wait(1000)

    RequestKeepContainersPermission()
end)

-- Qbox compatibility
RegisterNetEvent("QBX:Client:OnPlayerLoaded", function()
    Wait(1000)

    RequestKeepContainersPermission()
end)

function SuperUser()
    return isKeepContainersSuperUser == true
end