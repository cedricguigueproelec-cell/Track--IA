local Core = exports.core:GetCoreObject()

local function isPolice()
    local pd = Core.Functions.GetPlayerData()
    return pd and pd.job and pd.job.name == PoliceConfig.JobName
end

local function isOnDuty()
    local pd = Core.Functions.GetPlayerData()
    return pd and pd.job and pd.job.name == PoliceConfig.JobName and pd.job.onduty
end

-- ---------------------------------------------------------------------
-- blips
-- ---------------------------------------------------------------------
CreateThread(function()
    local blip = AddBlipForCoord(PoliceConfig.Station.x, PoliceConfig.Station.y, PoliceConfig.Station.z)
    SetBlipSprite(blip, 60)
    SetBlipColour(blip, 3)
    SetBlipScale(blip, 0.85)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Commissariat')
    EndTextCommandSetBlipName(blip)
end)

-- ---------------------------------------------------------------------
-- duty / armory / vehicle markers
-- ---------------------------------------------------------------------
local function nearPoint(point, radius)
    local coords = GetEntityCoords(PlayerPedId())
    return #(coords - vector3(point.x, point.y, point.z)) < (radius or 2.0)
end

local function promptHelp(text, action)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
    if IsControlJustPressed(0, 38) then action() end
end

CreateThread(function()
    while true do
        Wait(300)
        if not IsPlayerLoaded or not isPolice() then goto continue end

        if nearPoint(PoliceConfig.DutyMarker, 2.0) then
            promptHelp('~INPUT_CONTEXT~ ' .. (isOnDuty() and 'Prendre repos' or 'Prendre service'), function()
                TriggerServerEvent('police:server:toggleDuty')
            end)
        elseif isOnDuty() and nearPoint(PoliceConfig.ArmoryMarker, 2.0) then
            promptHelp('~INPUT_CONTEXT~ Armurerie', function()
                SetNuiFocus(true, true)
                SendNUIMessage({ action = 'openArmory', items = PoliceConfig.ArmoryItems })
            end)
        elseif isOnDuty() and nearPoint(PoliceConfig.VehicleSpawn, 3.0) then
            promptHelp('~INPUT_CONTEXT~ Véhicules de service', function()
                SetNuiFocus(true, true)
                SendNUIMessage({ action = 'openGarage', vehicles = PoliceConfig.Vehicles })
            end)
        end

        ::continue::
    end
end)

RegisterNUICallback('close', function(_, cb) SetNuiFocus(false, false) cb('ok') end)
RegisterNUICallback('getArmoryItem', function(data, cb)
    TriggerServerEvent('police:server:getArmoryItem', data.item)
    cb('ok')
end)
RegisterNUICallback('spawnVehicle', function(data, cb)
    local model = data.model
    RequestModel(model)
    local tries = 0
    while not HasModelLoaded(model) and tries < 200 do Wait(10) tries = tries + 1 end
    if HasModelLoaded(model) then
        local spawn = PoliceConfig.VehicleSpawn
        local veh = CreateVehicle(model, spawn.x, spawn.y, spawn.z, spawn.heading, true, false)
        SetPedIntoVehicle(PlayerPedId(), veh, -1)
        SetVehicleFuelLevel(veh, 100.0)
        SetModelAsNoLongerNeeded(model)
        SetVehicleNumberPlateText(veh, 'PD' .. tostring(math.random(1000, 9999)))
    end
    SetNuiFocus(false, false)
    cb('ok')
end)

-- ---------------------------------------------------------------------
-- cuffing (E on nearby player while on duty)
-- ---------------------------------------------------------------------
CreateThread(function()
    while true do
        Wait(400)
        if not isOnDuty() then goto continue end

        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local closest, closestDist = nil, 2.5

        for _, playerId in ipairs(GetActivePlayers()) do
            if playerId ~= PlayerId() then
                local dist = #(coords - GetEntityCoords(GetPlayerPed(playerId)))
                if dist < closestDist then closest, closestDist = playerId, dist end
            end
        end

        if closest then
            local sid = GetPlayerServerId(closest)
            promptHelp('~INPUT_CONTEXT~ Menotter / Démenotter', function()
                TriggerServerEvent('police:server:cuff', sid)
            end)
        end

        ::continue::
    end
end)

-- disable weapon/sprint while cuffed (state bag set by server, replicated)
CreateThread(function()
    while true do
        Wait(0)
        if LocalPlayer.state.cuffed then
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 47, true)
            DisableControlAction(0, 58, true)
            DisableControlAction(0, 22, true) -- jump
            DisablePlayerFiring(PlayerId(), true)
        else
            Wait(300)
        end
    end
end)

-- ---------------------------------------------------------------------
-- jail
-- ---------------------------------------------------------------------
RegisterNetEvent('police:client:jailed', function(coords, minutes)
    DoScreenFadeOut(400)
    Wait(500)
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(PlayerPedId(), coords.heading or 0.0)
    DoScreenFadeIn(500)
    TriggerEvent('core:client:notify', 'info', ('Vous êtes en cellule pour %d minute(s).'):format(minutes))
end)

RegisterNetEvent('police:client:released', function(coords)
    DoScreenFadeOut(400)
    Wait(500)
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, false)
    DoScreenFadeIn(500)
    TriggerEvent('core:client:notify', 'success', 'Vous êtes libéré.')
end)

-- ---------------------------------------------------------------------
-- search command (on-duty)
-- ---------------------------------------------------------------------
RegisterCommand('search', function(_, args)
    if not isOnDuty() then return end
    local targetId = tonumber(args[1])
    if not targetId then return end

    Core.Functions.TriggerCallback('police:searchPlayer', function(snapshot, charinfo)
        if not snapshot then return end
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'openSearch', targetId = targetId, name = charinfo and (charinfo.firstname .. ' ' .. charinfo.lastname) or ('#' .. targetId), snapshot = snapshot })
    end, targetId)
end, false)

RegisterNUICallback('seizeItem', function(data, cb)
    TriggerServerEvent('police:server:seizeItem', data.targetId, data.slot)
    cb('ok')
end)

RegisterCommand('jail', function(_, args)
    if not isOnDuty() then return end
    local targetId, minutes = tonumber(args[1]), tonumber(args[2]) or 5
    if not targetId then return end
    TriggerServerEvent('police:server:jail', targetId, minutes)
end, false)

-- ---------------------------------------------------------------------
-- MDT
-- ---------------------------------------------------------------------
RegisterCommand('mdt', function()
    if not isOnDuty() then return end
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openMdt' })
end, false)
RegisterKeyMapping('mdt', 'Ouvrir le MDT (police en service)', 'keyboard', 'F7')

RegisterNUICallback('mdtSearchCitizen', function(data, cb)
    Core.Functions.TriggerCallback('police:mdtSearchCitizen', function(rows)
        cb(rows)
    end, data.query)
end)

RegisterNUICallback('mdtSearchPlate', function(data, cb)
    Core.Functions.TriggerCallback('police:mdtSearchPlate', function(row)
        cb(row)
    end, data.plate)
end)
