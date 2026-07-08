local Core = exports.core:GetCoreObject()

local function isOnDuty()
    local pd = Core.Functions.GetPlayerData()
    return pd and pd.job and pd.job.name == MechanicConfig.JobName and pd.job.onduty
end

CreateThread(function()
    local blip = AddBlipForCoord(MechanicConfig.Garage.x, MechanicConfig.Garage.y, MechanicConfig.Garage.z)
    SetBlipSprite(blip, 446)
    SetBlipColour(blip, 5)
    SetBlipScale(blip, 0.85)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Atelier Mécanique')
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
        if not IsPlayerLoaded or not pd.job or pd.job.name ~= MechanicConfig.JobName then goto continue end

        if nearPoint(MechanicConfig.DutyMarker, 2.0) then
            promptHelp('~INPUT_CONTEXT~ ' .. (isOnDuty() and 'Prendre repos' or 'Prendre service'), function()
                TriggerServerEvent('mechanic:server:toggleDuty')
            end)
        end

        ::continue::
    end
end)

-- ---------------------------------------------------------------------
-- repair nearest vehicle
-- ---------------------------------------------------------------------
CreateThread(function()
    while true do
        Wait(500)
        if not isOnDuty() then goto continue end

        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local veh = GetClosestVehicle(coords.x, coords.y, coords.z, MechanicConfig.RepairDistance, 0, 71)

        if veh ~= 0 then
            promptHelp('~INPUT_CONTEXT~ Réparer le véhicule (kit requis)', function()
                Core.Functions.TriggerCallback('mechanic:repairVehicle', function(ok)
                    if ok then
                        SetVehicleFixed(veh)
                        SetVehicleDeformationFixed(veh)
                        SetVehicleUndriveable(veh, false)
                        SetVehicleEngineHealth(veh, 1000.0)
                        SetVehicleBodyHealth(veh, 1000.0)
                        TriggerEvent('core:client:notify', 'success', 'Véhicule réparé.')
                    end
                end)
            end)
        end

        ::continue::
    end
end)
