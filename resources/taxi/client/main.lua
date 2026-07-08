local Core = exports.core:GetCoreObject()

local meterOn = false
local lastCoords = nil
local tripDistance = 0.0

local function isOnDuty()
    local pd = Core.Functions.GetPlayerData()
    return pd and pd.job and pd.job.name == TaxiConfig.JobName and pd.job.onduty
end

CreateThread(function()
    local blip = AddBlipForCoord(TaxiConfig.Depot.x, TaxiConfig.Depot.y, TaxiConfig.Depot.z)
    SetBlipSprite(blip, 198)
    SetBlipColour(blip, 5)
    SetBlipScale(blip, 0.85)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Dépôt Taxi')
    EndTextCommandSetBlipName(blip)
end)

local function nearPoint(point, radius)
    return #(GetEntityCoords(PlayerPedId()) - vector3(point.x, point.y, point.z)) < (radius or 2.0)
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
        if not IsPlayerLoaded or not pd.job or pd.job.name ~= TaxiConfig.JobName then goto continue end

        if nearPoint(TaxiConfig.DutyMarker, 2.0) then
            promptHelp('~INPUT_CONTEXT~ ' .. (isOnDuty() and 'Prendre repos' or 'Prendre service'), function()
                TriggerServerEvent('taxi:server:toggleDuty')
            end)
        elseif isOnDuty() and nearPoint(TaxiConfig.VehicleSpawn, 3.0) then
            promptHelp('~INPUT_CONTEXT~ Prendre un taxi', function()
                local model = TaxiConfig.VehicleModel
                RequestModel(model)
                local tries = 0
                while not HasModelLoaded(model) and tries < 200 do Wait(10) tries = tries + 1 end
                if HasModelLoaded(model) then
                    local spawn = TaxiConfig.VehicleSpawn
                    local veh = CreateVehicle(model, spawn.x, spawn.y, spawn.z, spawn.heading, true, false)
                    SetPedIntoVehicle(PlayerPedId(), veh, -1)
                    SetVehicleFuelLevel(veh, 100.0)
                    SetModelAsNoLongerNeeded(model)
                end
            end)
        end

        ::continue::
    end
end)

RegisterCommand('meter', function()
    if not isOnDuty() then return end
    meterOn = not meterOn
    if meterOn then
        tripDistance = 0.0
        lastCoords = GetEntityCoords(PlayerPedId())
        TriggerEvent('core:client:notify', 'info', 'Compteur enclenché.')
    else
        TriggerServerEvent('taxi:server:payout', tripDistance)
        lastCoords = nil
    end
end, false)
RegisterKeyMapping('meter', 'Activer/Désactiver le compteur taxi', 'keyboard', 'F8')

CreateThread(function()
    while true do
        Wait(1000)
        if meterOn and lastCoords then
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                local coords = GetEntityCoords(ped)
                tripDistance = tripDistance + #(coords - lastCoords)
                lastCoords = coords
            end
        end
    end
end)
