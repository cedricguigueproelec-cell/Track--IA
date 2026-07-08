local Core = exports.core:GetCoreObject()

local function alert(jobName, alertType, title, coords, extra)
    for _, entry in ipairs(Core.Functions.GetPlayers()) do
        if entry.pd.job.name == jobName and entry.pd.job.onduty then
            TriggerClientEvent('dispatch:client:alert', entry.source, {
                type = alertType, title = title, coords = coords, extra = extra or '',
            })
        end
    end
end

exports('SendAlert', alert)

-- ---------------------------------------------------------------------
-- 911 (any player can call police)
-- ---------------------------------------------------------------------
RegisterNetEvent('dispatch:server:call911', function(message)
    local src = source
    local pd = Core.Functions.GetPlayer(src)
    if not pd then return end
    message = tostring(message or ''):sub(1, 200)
    if message == '' then return end

    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    alert('police', '911', ('Appel 911: %s'):format(message), { x = coords.x, y = coords.y, z = coords.z },
        pd.charinfo.firstname .. ' ' .. pd.charinfo.lastname)
    TriggerClientEvent('core:client:notify', src, 'success', 'Votre appel a été transmis à la police.')
end)

-- ---------------------------------------------------------------------
-- medical emergencies: hook the internal event fired by `medical`
-- ---------------------------------------------------------------------
AddEventHandler('medical:playerDowned', function(src, pd)
    local ped = GetPlayerPed(src)
    if ped == 0 then return end
    local coords = GetEntityCoords(ped)
    alert('ems', 'medical', 'Personne à terre signalée', { x = coords.x, y = coords.y, z = coords.z },
        pd.charinfo.firstname .. ' ' .. pd.charinfo.lastname)
end)

-- ---------------------------------------------------------------------
-- generic crime alert (e.g. store robbery, drug bust) other resources can raise
-- ---------------------------------------------------------------------
RegisterNetEvent('dispatch:server:crimeAlert', function(title, coordsOverride)
    local src = source
    local ped = GetPlayerPed(src)
    if ped == 0 then return end
    local coords = coordsOverride or GetEntityCoords(ped)
    alert('police', 'crime', title, { x = coords.x, y = coords.y, z = coords.z })
end)
