local Core = exports.core:GetCoreObject()

local function nearPoint(point, radius)
    return #(GetEntityCoords(PlayerPedId()) - vector3(point.x, point.y, point.z)) < (radius or 2.5)
end

local function promptHelp(text, action)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
    if IsControlJustPressed(0, 38) then action() end
end

local function spawnVehicleAt(model, spawn, cb)
    RequestModel(model)
    local tries = 0
    while not HasModelLoaded(model) and tries < 200 do Wait(10) tries = tries + 1 end
    if not HasModelLoaded(model) then cb(nil) return end
    local veh = CreateVehicle(model, spawn.x, spawn.y, spawn.z, spawn.heading or 0.0, true, false)
    SetModelAsNoLongerNeeded(model)
    cb(veh)
end

-- ---------------------------------------------------------------------
-- blips
-- ---------------------------------------------------------------------
CreateThread(function()
    local function addBlip(coords, sprite, color, label)
        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(blip, sprite)
        SetBlipColour(blip, color)
        SetBlipScale(blip, 0.8)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(label)
        EndTextCommandSetBlipName(blip)
    end
    addBlip(VehiclesConfig.Dealership, 225, 2, 'Concession Auto')
    for _, g in ipairs(VehiclesConfig.Garages) do addBlip(g.coords, 357, 3, g.label) end
    addBlip(VehiclesConfig.Impound.coords, 68, 1, VehiclesConfig.Impound.label)
end)

-- ---------------------------------------------------------------------
-- proximity interactions
-- ---------------------------------------------------------------------
CreateThread(function()
    while true do
        Wait(300)
        if not IsPlayerLoaded then goto continue end

        if nearPoint(VehiclesConfig.Dealership, 3.0) then
            promptHelp('~INPUT_CONTEXT~ Concession automobile', function()
                SetNuiFocus(true, true)
                SendNUIMessage({ action = 'openDealership', catalog = VehiclesConfig.Catalog })
            end)
        end

        for _, g in ipairs(VehiclesConfig.Garages) do
            if nearPoint(g.coords, 3.0) then
                promptHelp('~INPUT_CONTEXT~ ' .. g.label, function()
                    Core.Functions.TriggerCallback('vehicles:getOwned', function(rows)
                        SendNUIMessage({ action = 'openGarage', vehicles = rows, garage = g.label })
                        SetNuiFocus(true, true)
                    end, g.label)
                end)
            end
        end

        if nearPoint(VehiclesConfig.Impound.coords, 3.0) then
            promptHelp('~INPUT_CONTEXT~ Fourrière', function()
                Core.Functions.TriggerCallback('vehicles:getImpounded', function(rows)
                    SendNUIMessage({ action = 'openImpound', vehicles = rows })
                    SetNuiFocus(true, true)
                end)
            end)
        end

        -- store: near any garage, currently driving own vehicle
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            if GetPedInVehicleSeat(veh, -1) == ped then
                for _, g in ipairs(VehiclesConfig.Garages) do
                    if nearPoint(g.coords, VehiclesConfig.StoreDistance) then
                        promptHelp('~INPUT_CONTEXT~ Ranger le véhicule', function()
                            local plate = GetVehicleNumberPlateText(veh):gsub('%s+$', '')
                            local fuel = GetVehicleFuelLevel(veh)
                            local engine = GetVehicleEngineHealth(veh)
                            local body = GetVehicleBodyHealth(veh)
                            DeleteVehicle(veh)
                            TriggerServerEvent('vehicles:server:storeVehicle', plate, fuel, engine, body)
                        end)
                    end
                end
            end
        end

        -- trunk: on foot, near any vehicle's rear
        if not IsPedInAnyVehicle(ped, false) then
            local nearbyVeh = GetClosestVehicle(coords.x, coords.y, coords.z, 2.5, 0, 71)
            if nearbyVeh ~= 0 then
                promptHelp('~INPUT_CONTEXT~ Ouvrir le coffre', function()
                    local plate = GetVehicleNumberPlateText(nearbyVeh):gsub('%s+$', '')
                    TriggerServerEvent('vehicles:server:openTrunk', plate)
                end)
            end
        end

        ::continue::
    end
end)

-- ---------------------------------------------------------------------
-- glovebox: seated as driver or front passenger, dedicated keybind
-- ---------------------------------------------------------------------
RegisterCommand('glovebox', function()
    if not IsPlayerLoaded then return end
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then return end
    local veh = GetVehiclePedIsIn(ped, false)
    local seat = GetPedInVehicleSeat(veh, -1) == ped and -1 or 0
    if GetPedInVehicleSeat(veh, seat) ~= ped or (seat ~= -1 and seat ~= 0) then return end
    local plate = GetVehicleNumberPlateText(veh):gsub('%s+$', '')
    TriggerServerEvent('vehicles:server:openGlovebox', plate)
end, false)
RegisterKeyMapping('glovebox', 'Ouvrir la boîte à gants (en tant que conducteur/passager avant)', 'keyboard', 'F9')

-- ---------------------------------------------------------------------
-- NUI callbacks
-- ---------------------------------------------------------------------
RegisterNUICallback('close', function(_, cb) SetNuiFocus(false, false) cb('ok') end)

RegisterNUICallback('buyVehicle', function(data, cb)
    TriggerServerEvent('vehicles:server:buyVehicle', data.model)
    cb('ok')
end)

RegisterNUICallback('testDrive', function(data, cb)
    spawnVehicleAt(data.model, VehiclesConfig.TestDriveSpawn, function(veh)
        if veh then
            SetPedIntoVehicle(PlayerPedId(), veh, -1)
            SetVehicleFuelLevel(veh, 100.0)
            SetTimeout(120000, function() if DoesEntityExist(veh) then DeleteVehicle(veh) end end)
        end
    end)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('spawnOwned', function(data, cb)
    Core.Functions.TriggerCallback('vehicles:spawnOwned', function(vehData)
        if not vehData then cb('fail') return end
        local garage = nil
        for _, g in ipairs(VehiclesConfig.Garages) do if g.label == data.garage then garage = g end end
        local spawn = garage and garage.spawn or VehiclesConfig.Impound.spawn
        spawnVehicleAt(vehData.model, spawn, function(veh)
            if veh then
                SetVehicleNumberPlateText(veh, vehData.plate)
                SetVehicleFuelLevel(veh, vehData.fuel + 0.0)
                SetVehicleEngineHealth(veh, vehData.engine + 0.0)
                SetVehicleBodyHealth(veh, vehData.body + 0.0)
            end
        end)
        cb('ok')
    end, data.id, data.payImpound)
end)

RegisterNetEvent('vehicles:client:purchased', function()
    -- no-op hook point for UI refresh if the dealership panel stays open
end)
