PlayerData = {}
IsPlayerLoaded = false

local Core = { Functions = {} }

-- ---------------------------------------------------------------------
-- Callback system (client side)
-- ---------------------------------------------------------------------
local callbackId = 0
local pendingCallbacks = {}

function Core.Functions.TriggerCallback(name, cb, ...)
    callbackId = callbackId + 1
    local id = callbackId
    pendingCallbacks[id] = cb
    TriggerServerEvent('core:server:triggerCallback', name, id, ...)

    -- safety timeout so a dropped response never leaks memory / hangs a caller
    SetTimeout(10000, function()
        pendingCallbacks[id] = nil
    end)
end

RegisterNetEvent('core:client:callbackResponse', function(id, ...)
    local cb = pendingCallbacks[id]
    if cb then
        pendingCallbacks[id] = nil
        cb(...)
    end
end)

function Core.Functions.GetPlayerData()
    return PlayerData
end

function Core.Functions.IsLoaded()
    return IsPlayerLoaded
end

-- ---------------------------------------------------------------------
-- Player data sync
-- ---------------------------------------------------------------------
RegisterNetEvent('core:client:playerLoaded', function(pd)
    PlayerData = pd
    IsPlayerLoaded = true
    TriggerEvent('core:client:onPlayerLoaded', pd)
end)

RegisterNetEvent('core:client:updateMoney', function(money)
    PlayerData.money = money
    TriggerEvent('core:client:onMoneyUpdate', money)
end)

RegisterNetEvent('core:client:updateJob', function(job)
    PlayerData.job = job
    TriggerEvent('core:client:onJobUpdate', job)
end)

-- Minimal fallback so a missing HUD resource never leaves the player
-- silently uninformed; the `hud` resource also listens and renders a
-- proper toast (both handlers run, no conflict).
RegisterNetEvent('core:client:notify', function(type, message)
    if GetResourceState('hud') ~= 'started' then
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandThefeedPostTicker(false, true)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    pendingCallbacks = {}
end)

exports('GetCoreObject', function()
    return Core
end)
