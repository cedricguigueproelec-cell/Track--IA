local Core = exports.core:GetCoreObject()

local function isOnDuty()
    local pd = Core.Functions.GetPlayerData()
    return pd and pd.job and pd.job.name == EmsConfig.JobName and pd.job.onduty
end

CreateThread(function()
    local blip = AddBlipForCoord(EmsConfig.Station.x, EmsConfig.Station.y, EmsConfig.Station.z)
    SetBlipSprite(blip, 61)
    SetBlipColour(blip, 1)
    SetBlipScale(blip, 0.85)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Centre Médical')
    EndTextCommandSetBlipName(blip)
end)

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
        local pd = Core.Functions.GetPlayerData()
        if not IsPlayerLoaded or not pd.job or pd.job.name ~= EmsConfig.JobName then goto continue end

        if nearPoint(EmsConfig.DutyMarker, 2.0) then
            promptHelp('~INPUT_CONTEXT~ ' .. (isOnDuty() and 'Prendre repos' or 'Prendre service'), function()
                TriggerServerEvent('ems:server:toggleDuty')
            end)
        elseif isOnDuty() and nearPoint(EmsConfig.SupplyMarker, 2.0) then
            promptHelp('~INPUT_CONTEXT~ Matériel médical', function()
                SetNuiFocus(true, true)
                SendNUIMessage({ action = 'openSupply', items = EmsConfig.SupplyItems })
            end)
        elseif isOnDuty() and nearPoint(EmsConfig.VehicleSpawn, 3.0) then
            promptHelp('~INPUT_CONTEXT~ Véhicules médicaux', function()
                SetNuiFocus(true, true)
                SendNUIMessage({ action = 'openGarage', vehicles = EmsConfig.Vehicles })
            end)
        end

        ::continue::
    end
end)

RegisterNUICallback('close', function(_, cb) SetNuiFocus(false, false) cb('ok') end)
RegisterNUICallback('getSupplyItem', function(data, cb)
    TriggerServerEvent('ems:server:getSupplyItem', data.item)
    cb('ok')
end)
RegisterNUICallback('spawnVehicle', function(data, cb)
    local model = data.model
    RequestModel(model)
    local tries = 0
    while not HasModelLoaded(model) and tries < 200 do Wait(10) tries = tries + 1 end
    if HasModelLoaded(model) then
        local spawn = EmsConfig.VehicleSpawn
        local veh = CreateVehicle(model, spawn.x, spawn.y, spawn.z, spawn.heading, true, false)
        SetPedIntoVehicle(PlayerPedId(), veh, -1)
        SetVehicleFuelLevel(veh, 100.0)
        SetModelAsNoLongerNeeded(model)
    end
    SetNuiFocus(false, false)
    cb('ok')
end)

-- ---------------------------------------------------------------------
-- revive / heal nearest player
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
            if Player(sid).state.downed then
                promptHelp('~INPUT_CONTEXT~ Réanimer', function()
                    TriggerServerEvent('ems:server:revive', sid)
                end)
            else
                promptHelp('~INPUT_CONTEXT~ Soigner', function()
                    TriggerServerEvent('ems:server:heal', sid)
                end)
            end
        end

        ::continue::
    end
end)

RegisterNetEvent('ems:client:heal', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, 200)
end)
