local hunger, thirst, stress = 100, 100, 0
local visible = false

local function notify(kind, message)
    SendNUIMessage({ action = 'notify', kind = kind or 'info', message = message })
end

exports('Notify', notify)

RegisterNetEvent('core:client:notify', function(kind, message)
    notify(kind, message)
end)

RegisterNetEvent('core:client:playerLoaded', function(pd)
    visible = true
    hunger = (pd.metadata and pd.metadata.hunger) or 100
    thirst = (pd.metadata and pd.metadata.thirst) or 100
    stress = (pd.metadata and pd.metadata.stress) or 0
    SendNUIMessage({ action = 'show' })
end)

RegisterNetEvent('core:client:updateMoney', function(money)
    SendNUIMessage({ action = 'money', cash = money.cash, bank = money.bank })
end)

RegisterNetEvent('core:client:updateMetadata', function(meta)
    hunger = meta.hunger or hunger
    thirst = meta.thirst or thirst
    stress = meta.stress or stress
end)

function AddHunger(amount)
    hunger = math.max(0, math.min(100, hunger + amount))
    TriggerServerEvent('core:server:setMetaData', 'hunger', hunger)
end
exports('AddHunger', AddHunger)

function AddThirst(amount)
    thirst = math.max(0, math.min(100, thirst + amount))
    TriggerServerEvent('core:server:setMetaData', 'thirst', thirst)
end
exports('AddThirst', AddThirst)

-- ---------------------------------------------------------------------
-- Hunger / thirst passive decay
-- ---------------------------------------------------------------------
CreateThread(function()
    while true do
        Wait(60000)
        if visible then
            hunger = math.max(0, hunger - 1)
            thirst = math.max(0, thirst - 1)
            TriggerServerEvent('core:server:setMetaData', 'hunger', hunger)
            TriggerServerEvent('core:server:setMetaData', 'thirst', thirst)
            if hunger <= 0 or thirst <= 0 then
                local ped = PlayerPedId()
                local hp = GetEntityHealth(ped)
                SetEntityHealth(ped, math.max(0, hp - 2))
            end
        end
    end
end)

-- ---------------------------------------------------------------------
-- Main render loop
-- ---------------------------------------------------------------------
CreateThread(function()
    while true do
        Wait(300)
        if not visible then
            goto continue
        end

        local ped = PlayerPedId()
        local health = math.max(0, math.floor(((GetEntityHealth(ped) - 100) / 100) * 100))
        local armor = GetPedArmour(ped)
        local stamina = math.floor(GetPlayerSprintStamina(PlayerId()))
        local talking = NetworkIsPlayerTalking(PlayerId())

        local vehData = nil
        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            local speedMs = GetEntitySpeed(veh)
            local fuel = Entity(veh).state.fuel or 100
            vehData = {
                speed = math.floor(speedMs * 3.6), -- km/h
                gear = GetVehicleCurrentGear(veh),
                fuel = math.floor(fuel),
                seatbelt = Entity(veh).state.seatbelt or false,
                rpm = GetVehicleCurrentRpm(veh),
            }
        end

        SendNUIMessage({
            action = 'stats',
            health = health,
            armor = armor,
            hunger = math.floor(hunger),
            thirst = math.floor(thirst),
            stress = math.floor(stress),
            stamina = math.max(0, math.min(100, stamina)),
            talking = talking,
            vehicle = vehData,
        })

        ::continue::
    end
end)
