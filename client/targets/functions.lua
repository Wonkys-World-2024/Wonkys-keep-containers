function MoveContainer(private, entity)
    local zone_name, zone = GetCurrentZone()

    if not zone_name or not zone then
        Notification_c("The container cannot be moved outside the depot!", "error")
        return
    end

    if Config.input == "qb-input" or Config.input == "keep-input" then
        local confData = exports[Config.input]:ShowInput({
            inputs = {
                {
                    type = "text",
                    isRequired = true,
                    name = "conf",
                    text = "Type Confirm (^.^)",
                    icon = "fa-solid fa-money-bill-trend-up",
                    title = "Confirm"
                }
            }
        })

        if confData and confData.conf == "Confirm" then
            TriggerEvent(
                "keep-containers:client:container:update_location",
                private.random_id,
                zone_name,
                private.container_type
            )

            DeleteEntity(entity)
        end

    elseif Config.input == "ox_lib" then
        local inputData = lib.inputDialog("Confirm", {
            {
                type = "input",
                label = "Confirmation",
                placeholder = "Type Confirm",
                required = true
            }
        })

        if inputData and inputData[1] == "Confirm" then
            TriggerEvent(
                "keep-containers:client:container:update_location",
                private.random_id,
                zone_name,
                private.container_type
            )

            DeleteEntity(entity)
        end
    end
end


function DeleteContainer(private, entity)
    local zone_name, zone = GetCurrentZone()

    if not zone_name or not zone then
        Notification_c("The container cannot be deleted outside the depot!", "error")
        return
    end

    if Config.input == "qb-input" or Config.input == "keep-input" then
        local confData = exports[Config.input]:ShowInput({
            inputs = {
                {
                    type = "text",
                    isRequired = true,
                    name = "conf",
                    text = "Type Confirm (^.^)",
                    icon = "fa-solid fa-money-bill-trend-up",
                    title = "Confirm"
                }
            }
        })

        if confData and confData.conf == "Confirm" then
            TriggerServerEvent(
                "keep-containers:server:container:delete",
                private.random_id,
                zone_name
            )
        end

    elseif Config.input == "ox_lib" then
        local inputData = lib.inputDialog("Confirm", {
            {
                type = "input",
                label = "Confirmation",
                placeholder = "Type Confirm",
                required = true
            }
        })

        if inputData and inputData[1] == "Confirm" then
            TriggerServerEvent(
                "keep-containers:server:container:delete",
                private.random_id,
                zone_name
            )
        end
    end
end


function TransferOwnership(private, entity)
    local zone_name, zone = GetCurrentZone()

    if not zone_name or not zone then
        Notification_c("The container cannot be transferred outside the depot!", "error")
        return
    end

    if Config.input == "qb-input" or Config.input == "keep-input" then

        local inputData = exports[Config.input]:ShowInput({
            header = "Transfer Ownership",
            inputs = {
                {
                    type = "number",
                    name = "new_owner",
                    icon = "fa-solid fa-user",
                    title = "New Owner's State ID",
                    text = "New Owner's State ID",
                    isRequired = true
                }
            }
        })

        if inputData and inputData.new_owner then

            local confData = exports[Config.input]:ShowInput({
                inputs = {
                    {
                        type = "text",
                        isRequired = true,
                        name = "conf",
                        text = "Type Confirm (^.^)",
                        icon = "fa-solid fa-money-bill-trend-up",
                        title = ("Confirm transfer to State ID %s"):format(inputData.new_owner)
                    }
                }
            })

            if confData and confData.conf == "Confirm" then
                TriggerServerEvent(
                    "keep-containers:server:container:transfer_ownership",
                    private.random_id,
                    zone_name,
                    inputData.new_owner
                )
            end
        end

    elseif Config.input == "ox_lib" then

        local inputData = lib.inputDialog("Transfer Ownership", {
            {
                type = "number",
                label = "New Owner's State ID",
                required = true,
                min = 1
            }
        })

        if inputData and inputData[1] then

            local alert = lib.alertDialog({
                header = "Transfer Ownership",
                content = ("Confirm transfer of this container to State ID **%s**."):format(inputData[1]),
                centered = true,
                cancel = true
            })

            if alert == "confirm" then
                TriggerServerEvent(
                    "keep-containers:server:container:transfer_ownership",
                    private.random_id,
                    zone_name,
                    inputData[1]
                )
            else
                Notification_c(
                    "Transfer of ownership has been canceled.",
                    "error"
                )
            end
        end
    end
end


function ChangePassword(private, entity)
    local zone_name, zone = GetCurrentZone()

    if not zone_name or not zone then
        Notification_c("The container cannot be changed outside the depot!", "error")
        return
    end

    if Config.input == "qb-input" or Config.input == "keep-input" then

        local Input = {
            header = "Change Password",
            inputs = {
                {
                    type = "password",
                    name = "current_password",
                    icon = "fa-solid fa-lock",
                    title = "Current Password",
                    text = "Current Password",
                    isRequired = true
                },
                {
                    type = "password",
                    name = "new_password",
                    icon = "fa-solid fa-lock",
                    title = "New Password",
                    text = "New Password",
                    isRequired = true
                }
            }
        }

        local inputData = exports[Config.input]:ShowInput(Input)

        if inputData
            and inputData.current_password
            and inputData.new_password then

            TriggerServerEvent(
                "keep-containers:server:container:change_password",
                private.random_id,
                inputData.current_password,
                inputData.new_password,
                zone_name
            )
        end

    elseif Config.input == "ox_lib" then

        local inputData = lib.inputDialog("Change Password", {
            {
                type = "input",
                label = "Current Password",
                password = true,
                icon = "lock",
                required = true
            },
            {
                type = "input",
                label = "New Password",
                password = true,
                icon = "lock",
                required = true
            }
        })

        if inputData and inputData[1] and inputData[2] then
            TriggerServerEvent(
                "keep-containers:server:container:change_password",
                private.random_id,
                inputData[1],
                inputData[2],
                zone_name
            )
        end
    end
end


function OpenContainer(private, entity)
    local zone_name, zone = GetCurrentZone()

    if not zone_name or not zone then
        Notification_c("The container cannot be opened outside the depot!", "error")
        return
    end

    if Config.input == "qb-input" or Config.input == "keep-input" then

        local Input = {
            header = "Container Password",
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

        if inputData and inputData.password then
            TriggerServerEvent(
                "keep-containers:server:container:check_password",
                private.random_id,
                inputData.password,
                zone_name
            )
        end

    elseif Config.input == "ox_lib" then

        local inputData = lib.inputDialog("Container", {
            {
                type = "input",
                label = "Password",
                password = true,
                icon = "lock",
                required = true
            }
        })

        if inputData and inputData[1] then
            TriggerServerEvent(
                "keep-containers:server:container:check_password",
                private.random_id,
                inputData[1],
                zone_name
            )
        end
    end
end


local function LoadAnimationDict(animation)
    RequestAnimDict(animation)

    while not HasAnimDictLoaded(animation) do
        Wait(25)
    end

    return true
end


local function bolt_cutter(entity, random_id, zone_name)
    local scene
    local playerped = PlayerPedId()

    local playercoords = GetEntityCoords(playerped)
    local pedRotation = GetEntityRotation(playerped)

    local animDict = "anim@scripted@heist@ig4_bolt_cutters@male@"

    local scenePos = vector3(
        playercoords.x,
        playercoords.y,
        playercoords.z + 0.2
    )

    local sceneRot = pedRotation

    LoadAnimationDict(animDict)

    local cutterModel = GetHashKey("h4_prop_h4_bolt_cutter_01a")
    local bagModel = GetHashKey("ch_p_m_bag_var02_arm_s")

    LoadModel(cutterModel)
    LoadModel(bagModel)

    local cutter = CreateObject(
        cutterModel,
        playercoords.x,
        playercoords.y,
        playercoords.z,
        true,
        true,
        false
    )

    local bag = CreateObject(
        bagModel,
        playercoords.x,
        playercoords.y,
        playercoords.z,
        true,
        true,
        false
    )

    Wait(50)

    scene = NetworkCreateSynchronisedScene(
        scenePos,
        sceneRot,
        2,
        true,
        false,
        1065353216,
        0,
        1.3
    )

    NetworkAddPedToSynchronisedScene(
        playerped,
        scene,
        animDict,
        "action_male",
        4.0,
        -4.0,
        1033,
        0,
        1000.0,
        0
    )

    NetworkAddEntityToSynchronisedScene(
        cutter,
        scene,
        animDict,
        "action_cutter",
        1.0,
        -1.0,
        1148846080
    )

    NetworkAddEntityToSynchronisedScene(
        bag,
        scene,
        animDict,
        "action_bag",
        1.0,
        -1.0,
        1148846080
    )

    NetworkStartSynchronisedScene(scene)

    Wait(5750)

    NetworkStopSynchronisedScene(scene)

    if DoesEntityExist(bag) then
        DeleteEntity(bag)
    end

    if DoesEntityExist(cutter) then
        DeleteEntity(cutter)
    end

    TriggerServerEvent(
        "keep-containers:server:open_with_bolt_cutter",
        random_id,
        zone_name
    )
end


RegisterNetEvent(
    "keep-containers:targets:use_bolt_cutter",
    function(entity, random_id, zone_name)
        bolt_cutter(entity, random_id, zone_name)
    end
)


function BoltCutter(private, entity)
    local zone_name, Zone = GetCurrentZone()

    if not zone_name or not Zone then
        Notification_c(
            "The container cannot be outside the depot!",
            "error"
        )
        return
    end

    TriggerServerEvent(
        "keep-containers:server:use_bolt_cutter",
        entity,
        private.random_id,
        zone_name
    )
end


--========================================================--
-- QBOX SUPER USER / PERMISSION SYSTEM
--========================================================--

local keepContainersSuperUser = false

RegisterNetEvent("keep-containers:client:set_super_user", function(state)
    keepContainersSuperUser = state == true
end)

RegisterNetEvent("keep-containers:client:setSuperUser", function(state)
    keepContainersSuperUser = state == true
end)

local function RequestKeepContainersPermission()
    TriggerServerEvent("keep-containers:server:request_super_user")
end

CreateThread(function()
    Wait(5000)

    RequestKeepContainersPermission()
end)

-- Re-check when Qbox finishes loading the player.
RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    Wait(1000)
    RequestKeepContainersPermission()
end)

-- Qbox player load/update compatibility.
RegisterNetEvent("QBX:Client:OnPlayerLoaded", function()
    Wait(1000)
    RequestKeepContainersPermission()
end)

function SuperUser()
    return keepContainersSuperUser == true
end



--========================================================--
-- BOLT CUTTER PERMISSIONS
--========================================================--

function HasAccessToBoltCutter()
    local playerData = exports.qbx_core:GetPlayerData()

    if not playerData then
        return false
    end

    if not playerData.job then
        return false
    end

    local job_name = playerData.job.name

    if not job_name then
        return false
    end

    local job_grade = 0

    if playerData.job.grade then
        if type(playerData.job.grade) == "table" then
            job_grade =
                tonumber(playerData.job.grade.level)
                or tonumber(playerData.job.grade.grade)
                or 0
        else
            job_grade = tonumber(playerData.job.grade) or 0
        end
    end

    if not Config.bolt_cutter then
        return false
    end

    local jobConfig = Config.bolt_cutter[tostring(job_name)]

    if not jobConfig then
        return false
    end

    return jobConfig[tonumber(job_grade)] == true
end