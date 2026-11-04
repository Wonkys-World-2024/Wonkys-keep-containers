ServerCallbacks = {}

function TriggerCallback(name, cb, ...)
    ServerCallbacks[name] = cb
    TriggerServerEvent('keep-containers:server:callback', name, ...)
end

RegisterNetEvent('keep-containers:client:callback', function(name, ...)
    local callback = ServerCallbacks[name]

    if callback then
        ServerCallbacks[name] = nil
        callback(...)
    end
end)