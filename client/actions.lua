local function LoadAnimationDict(dict)
    RequestAnimDict(dict)

    while not HasAnimDictLoaded(dict) do
        Wait(25)
    end
end

local function OpenAnimation()
    LoadAnimationDict('amb@prop_human_bum_bin@idle_b')

    TaskPlayAnim(
        PlayerPedId(),
        'amb@prop_human_bum_bin@idle_b',
        'idle_d',
        4.0,
        4.0,
        -1,
        50,
        1.0,
        false,
        false,
        false
    )
end

local function CloseAnimation()
    LoadAnimationDict('amb@prop_human_bum_bin@idle_b')

    TaskPlayAnim(
        PlayerPedId(),
        'amb@prop_human_bum_bin@idle_b',
        'exit',
        4.0,
        4.0,
        -1,
        50,
        0.0,
        false,
        false,
        false
    )

    Wait(1500)
    ClearPedTasks(PlayerPedId())
end

local function OpenStash(metadata)
    if not metadata or not metadata.random_id then
        return
    end

    local stashId = 'Container_' .. metadata.random_id

    OpenAnimation()

    exports.ox_inventory:openInventory('stash', {
        id = stashId
    })

    Wait(1000)

    while IsNuiFocused() do
        Wait(100)
    end

    CloseAnimation()
end

RegisterNetEvent('keep-containers:client:open', function(metadata)
    if not metadata then
        return
    end

    local completed = lib.progressCircle({
        duration = 2000,
        position = 'bottom',
        label = 'Opening container...',
        useWhileDead = false,
        canCancel = true,

        disable = {
            car = true,
            move = true,
            combat = true
        }
    })

    if not completed then
        return
    end

    OpenStash(metadata)
end)