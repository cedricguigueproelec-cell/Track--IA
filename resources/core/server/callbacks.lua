-- Server-authoritative request/response callback system.
-- Every resource (inventory, banking, jobs...) registers callbacks here
-- instead of trusting client-sent state.

Core.Callbacks = {}

function Core.Functions.CreateCallback(name, handler)
    Core.Callbacks[name] = handler
end

RegisterNetEvent('core:server:triggerCallback', function(name, requestId, ...)
    local src = source
    local handler = Core.Callbacks[name]
    if not handler then
        return
    end

    -- Basic rate limiting: refuse if this source is spamming callback
    -- requests (protects against a modified client flooding the event).
    Core.CallbackRate = Core.CallbackRate or {}
    local now = GetGameTimer()
    local bucket = Core.CallbackRate[src]
    if not bucket or (now - bucket.reset) > 1000 then
        bucket = { count = 0, reset = now }
        Core.CallbackRate[src] = bucket
    end
    bucket.count = bucket.count + 1
    if bucket.count > 60 then
        return -- silently drop, likely abuse
    end

    handler(src, function(...)
        TriggerClientEvent('core:client:callbackResponse', src, requestId, ...)
    end, ...)
end)

AddEventHandler('playerDropped', function()
    local src = source
    if Core.CallbackRate then Core.CallbackRate[src] = nil end
end)
