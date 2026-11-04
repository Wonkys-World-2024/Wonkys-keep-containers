ServerCallbacks = {}

function CreateCallback(name, callback)
    ServerCallbacks[name] = callback
end

RegisterNetEvent('keep-containers:server:callback', function(name, ...)
    local src = source
    local callback = ServerCallbacks[name]

    if not callback then
        return
    end

    callback(src, function(...)
        TriggerClientEvent(
            'keep-containers:client:callback',
            src,
            name,
            ...
        )
    end, ...)
end)

function Notification_S(src, message, notificationType)
    TriggerClientEvent(
        'keep-containers:client:notification',
        src,
        message,
        notificationType or 'inform'
    )
end