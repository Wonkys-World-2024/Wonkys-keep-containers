--                _
--               | |
--   _____      _| | _____  ___ _ __
--  / __\ \ /\ / / |/ / _ \/ _ \ '_ \
--  \__ \\ V  V /|   <  __/  __/ |_) |
--  |___/ \_/\_/ |_|\_\___|\___| .__/
--                             | |
--                             |_|
-- https://github.com/swkeep

local function Draw2DText(content, font, colour, scale, x, y)
    SetTextFont(font)
    SetTextScale(scale, scale)
    SetTextColour(colour[1], colour[2], colour[3], 255)
    SetTextEntry("STRING")
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextEdge(4, 0, 0, 0, 255)
    SetTextOutline()
    AddTextComponentString(content)
    DrawText(x, y)
end

local function RotationToDirection(rotation)
    local adjustedRotation = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }

    return {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
end

local function RayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot()
    local cameraCoord = GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)

    local destination = {
        x = cameraCoord.x + direction.x * distance,
        y = cameraCoord.y + direction.y * distance,
        z = cameraCoord.z + direction.z * distance
    }

    local rayHandle = StartShapeTestRay(
        cameraCoord.x,
        cameraCoord.y,
        cameraCoord.z,
        destination.x,
        destination.y,
        destination.z,
        -1,
        PlayerPedId(),
        0
    )

    local _, hit, coords, _, entity = GetShapeTestResult(rayHandle)

    return coords, hit, entity
end

--========================================================--
--                      MOVEMENT                         --
--========================================================--

local function up(object, offset)
    DisableControlAction(0, 27, true)

    if IsDisabledControlPressed(0, 27) then
        local delta = 0.05

        DisableControlAction(0, 36, true)

        if IsDisabledControlPressed(0, 36) then
            delta = 0.10
        end

        local objectCoords = GetEntityCoords(object)

        SetEntityCoords(
            object,
            objectCoords.x + offset.x,
            objectCoords.y + offset.y,
            objectCoords.z + offset.z + delta,
            false,
            false,
            false,
            false
        )
    end
end

local function down(object, offset)
    DisableControlAction(0, 173, true)

    if IsDisabledControlPressed(0, 173) then
        local delta = 0.05

        DisableControlAction(0, 36, true)

        if IsDisabledControlPressed(0, 36) then
            delta = 0.10
        end

        local objectCoords = GetEntityCoords(object)

        SetEntityCoords(
            object,
            objectCoords.x + offset.x,
            objectCoords.y + offset.y,
            objectCoords.z + offset.z - delta,
            false,
            false,
            false,
            false
        )
    end
end

local function left(object, offset, xy)
    DisableControlAction(0, 174, true)

    if IsDisabledControlPressed(0, 174) then
        local delta = 0.05

        DisableControlAction(0, 36, true)

        if IsDisabledControlPressed(0, 36) then
            delta = 0.10
        end

        local objectCoords = GetEntityCoords(object)

        if xy == "x" then
            SetEntityCoords(
                object,
                objectCoords.x + offset.x + delta,
                objectCoords.y + offset.y,
                objectCoords.z + offset.z,
                false,
                false,
                false,
                false
            )
        else
            SetEntityCoords(
                object,
                objectCoords.x + offset.x,
                objectCoords.y + offset.y + delta,
                objectCoords.z + offset.z,
                false,
                false,
                false,
                false
            )
        end
    end
end

local function right(object, offset, xy)
    DisableControlAction(0, 175, true)

    if IsDisabledControlPressed(0, 175) then
        local delta = 0.05

        DisableControlAction(0, 36, true)

        if IsDisabledControlPressed(0, 36) then
            delta = 0.10
        end

        local objectCoords = GetEntityCoords(object)

        if xy == "x" then
            SetEntityCoords(
                object,
                objectCoords.x + offset.x - delta,
                objectCoords.y + offset.y,
                objectCoords.z + offset.z,
                false,
                false,
                false,
                false
            )
        else
            SetEntityCoords(
                object,
                objectCoords.x + offset.x,
                objectCoords.y + offset.y - delta,
                objectCoords.z + offset.z,
                false,
                false,
                false,
                false
            )
        end
    end
end

--========================================================--
--                    ZONE CHECK                         --
--========================================================--

local function IsPositionInsideZone(zone, position)
    if not zone or not position then
        return false
    end

    -- ChooseSpawnLocation returns vector4 because we need
    -- the heading. ox_lib polygon zones require vector3.
    local checkPosition = vector3(
        position.x,
        position.y,
        position.z
    )

    if zone.contains then
        return zone:contains(checkPosition)
    end

    if zone.containsPoint then
        return zone:containsPoint(checkPosition)
    end

    return false
end

--========================================================--
--                 OBJECT PLACEMENT                      --
--========================================================--

local object

local function ChooseSpawnLocation(model, offset)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    local objectPlaced = false
    local axis = "x"

    object = CreateObject(
        GetHashKey(model),
        playerCoords.x + offset.x,
        playerCoords.y + offset.y,
        playerCoords.z + offset.z,
        true,
        false,
        false
    )

    if not DoesEntityExist(object) then
        Notification_c(
            "Unable to create the container object.",
            "error"
        )

        object = nil
        return "exit"
    end

    SetEntityAlpha(object, 150, true)
    SetEntityCollision(object, false, false)
    FreezeEntityPosition(object, false)

    while true do
        Wait(0)

        if not DoesEntityExist(object) then
            object = nil
            return "exit"
        end

        BlockWeaponWheelThisFrame()

        local coords, hit = RayCastGamePlayCamera(50.0)

        --================================================--
        --                 INSTRUCTIONS                   --
        --================================================--

        Draw2DText(
            "Press ~g~E~w~ To Lock Position | ~g~Mouse Wheel~w~ To Rotate | Press ~g~ESC~w~ To Exit",
            4,
            {255, 255, 255},
            0.4,
            0.43,
            0.888
        )

        Draw2DText(
            "Press ~g~Up~w~/~g~Down~w~/~g~Left~w~/~g~Right~w~ After Position Is Locked",
            4,
            {255, 255, 255},
            0.4,
            0.43,
            0.913
        )

        Draw2DText(
            "Press ~g~Page Up~w~ to change X Axis | Press ~g~Page Down~w~ to Y Axis | Current Axis: " .. axis,
            4,
            {255, 255, 255},
            0.4,
            0.43,
            0.938
        )

        Draw2DText(
            "Press ~g~ENTER~w~ To Confirm",
            4,
            {255, 255, 255},
            0.4,
            0.50,
            0.86
        )

        --================================================--
        --              POSITION WITH CAMERA              --
        --================================================--

        if not objectPlaced and coords then
            SetEntityCoords(
                object,
                coords.x + offset.x,
                coords.y + offset.y,
                coords.z + offset.z,
                false,
                false,
                false,
                false
            )
        end

        --================================================--
        --                LOCK POSITION                  --
        --================================================--

        if IsControlJustReleased(0, 38) then
            objectPlaced = true
        end

        --================================================--
        --                  CONFIRM                      --
        --================================================--

        if IsControlJustReleased(0, 191) then
            local entityCoords = GetEntityCoords(object)
            local heading = GetEntityHeading(object)

            DeleteEntity(object)
            object = nil

            return vector4(
                entityCoords.x - offset.x,
                entityCoords.y - offset.y,
                entityCoords.z - offset.z,
                heading
            )
        end

        --================================================--
        --                  MOVEMENT                     --
        --================================================--

        if objectPlaced then
            up(object, offset)
            down(object, offset)
            right(object, offset, axis)
            left(object, offset, axis)
        end

        --================================================--
        --              ROTATE CLOCKWISE                --
        --================================================--

        DisableControlAction(0, 81, true)

        if IsDisabledControlJustPressed(0, 81) then
            local heading = GetEntityHeading(object)
            local delta = 7.5

            DisableControlAction(0, 36, true)

            if IsDisabledControlPressed(0, 36) then
                delta = 1.0
            end

            SetEntityHeading(
                object,
                heading + delta
            )
        end

        --================================================--
        --           ROTATE COUNTER-CLOCKWISE           --
        --================================================--

        DisableControlAction(0, 99, true)

        if IsDisabledControlJustPressed(0, 99) then
            local heading = GetEntityHeading(object)
            local delta = 7.5

            DisableControlAction(0, 36, true)

            if IsDisabledControlPressed(0, 36) then
                delta = 1.0
            end

            SetEntityHeading(
                object,
                heading - delta
            )
        end

        --================================================--
        --                     ESC                      --
        --================================================--

        DisableControlAction(0, 200, true)

        if IsDisabledControlJustPressed(0, 200) then
            DeleteEntity(object)
            object = nil

            return "exit"
        end

        --================================================--
        --                  CHANGE AXIS                  --
        --================================================--

        if IsControlPressed(0, 10) then
            axis = "x"
        end

        if IsControlPressed(0, 11) then
            axis = "y"
        end

        DisableControlAction(0, 36, true)
    end
end

--========================================================--
--                 PLACE CONTAINER                      --
--========================================================--

RegisterNetEvent(
    "keep-containers:client:container:place",
    function(containerType)

        local zoneName, zone = GetCurrentZone()

        if not zoneName or not zone then
            Notification_c(
                "The container cannot be placed outside the depot!",
                "error"
            )
            return
        end

        local container = GetContainerInfromation(containerType)

        if not container then
            print(
                "^1[keep-containers]^7 Invalid container type: "
                .. tostring(containerType)
            )

            Notification_c(
                "Invalid container type.",
                "error"
            )

            return
        end

        local password

        --================================================--
        --                    OX LIB                    --
        --================================================--

        if Config.input == "ox_lib" then

            local inputData = lib.inputDialog(
                "Enter Password",
                {
                    {
                        type = "input",
                        label = "Password",
                        password = true,
                        icon = "lock",
                        required = true
                    }
                }
            )

            if not inputData
                or not inputData[1]
                or inputData[1] == ""
            then
                Notification_c(
                    "Use a better password!",
                    "error"
                )

                return
            end

            password = inputData[1]

        --================================================--
        --                 LEGACY INPUT                 --
        --================================================--

        else

            local Input = {
                header = "Set Password",
                inputs = {
                    {
                        type = "password",
                        name = "password",
                        icon = "fa-solid fa-lock",
                        title = "Password",
                        text = "Enter Password",
                        isRequired = true
                    }
                }
            }

            local inputData = exports[Config.input]:ShowInput(Input)

            if not inputData
                or not inputData.password
                or inputData.password == ""
            then
                Notification_c(
                    "Use a better password!",
                    "error"
                )

                return
            end

            password = inputData.password
        end

        --================================================--
        --              CHOOSE LOCATION                 --
        --================================================--

        local position = ChooseSpawnLocation(
            container.object.name,
            container.object.offset
        )

        if position == "exit" then
            Notification_c(
                "The container placement has been cancelled!",
                "error"
            )
            return
        end

        --================================================--
        --                  ZONE CHECK                   --
        --================================================--

        local isInZone = IsPositionInsideZone(
            zone,
            position
        )

        if not isInZone then
            Notification_c(
                "The container is outside of depot!",
                "error"
            )

            return
        end

        --================================================--
        --              CREATE CONTAINER                --
        --================================================--

        TriggerServerEvent(
            "keep-containers:server:create_container",
            password,
            position,
            zoneName
        )
    end
)

--========================================================--
--              UPDATE CONTAINER LOCATION               --
--========================================================--

AddEventHandler(
    "keep-containers:client:container:update_location",
    function(
        randomId,
        zoneName,
        containerType
    )

        local currentZoneName, zone = GetCurrentZone()

        if not currentZoneName or not zone then
            Notification_c(
                "The container cannot be placed outside the depot!",
                "error"
            )

            return
        end

        local container = GetContainerInfromation(containerType)

        if not container then
            Notification_c(
                "Invalid container type.",
                "error"
            )

            return
        end

        local position = ChooseSpawnLocation(
            container.object.name,
            container.object.offset
        )

        if position == "exit" then
            TriggerEvent(
                "keep-containers:client:update_zone",
                zoneName
            )

            return
        end

        local isInZone = IsPositionInsideZone(
            zone,
            position
        )

        if isInZone then

            TriggerServerEvent(
                "keep-containers:server:container:update_position",
                randomId,
                zoneName,
                position
            )

        else

            TriggerEvent(
                "keep-containers:client:update_zone",
                zoneName
            )

            Notification_c(
                "The container is outside of the depot!",
                "error"
            )
        end
    end
)

--========================================================--
--                  RESOURCE STOP                       --
--========================================================--

AddEventHandler(
    "onResourceStop",
    function(resource)

        if resource ~= GetCurrentResourceName() then
            return
        end

        if object and DoesEntityExist(object) then
            DeleteEntity(object)
        end

        object = nil
    end
)