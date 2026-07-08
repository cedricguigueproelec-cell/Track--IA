local isOpen = false
local drops = {}
local dropObjects = {}

local function closeInventory()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    TriggerServerEvent('inventory:server:closeSecondary')
end

local function openInventory()
    if isOpen then return closeInventory() end
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
end

--- Other resources (housing stash, vehicle trunk/glovebox...) call
--- exports.inventory:OpenSecondary(src, ...) server-side then fire this
--- event to actually pop the NUI open on that client.
RegisterNetEvent('inventory:client:openUI', function()
    if isOpen then return end
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
end)

RegisterKeyMapping('inventory', 'Ouvrir/Fermer l\'inventaire', 'keyboard', 'TAB')
RegisterCommand('inventory', function()
    if not IsPlayerLoaded then return end
    openInventory()
end, false)

RegisterNetEvent('inventory:client:state', function(payload)
    SendNUIMessage({ action = 'state', payload = payload })
end)

RegisterNetEvent('inventory:client:consumeEffect', function(effect)
    if effect.hunger and GetResourceState('hud') == 'started' then
        exports.hud:AddHunger(effect.hunger)
    end
    if effect.thirst and GetResourceState('hud') == 'started' then
        exports.hud:AddThirst(effect.thirst)
    end
    if effect.health then
        local ped = PlayerPedId()
        local newHealth = math.min(200, GetEntityHealth(ped) + effect.health)
        SetEntityHealth(ped, newHealth)
    end
end)

RegisterNUICallback('close', function(_, cb)
    closeInventory()
    cb('ok')
end)

RegisterNUICallback('useItem', function(data, cb)
    TriggerServerEvent('inventory:server:useItem', tonumber(data.slot))
    cb('ok')
end)

RegisterNUICallback('dropItem', function(data, cb)
    TriggerServerEvent('inventory:server:dropItem', tonumber(data.slot), tonumber(data.amount) or 1)
    cb('ok')
end)

RegisterNUICallback('transferItem', function(data, cb)
    TriggerServerEvent('inventory:server:transferItem', data.fromOwner, tonumber(data.slot), tonumber(data.amount) or 1, data.toOwner)
    cb('ok')
end)

-- ---------------------------------------------------------------------
-- ground drops: lightweight synced props + proximity pickup prompt
-- ---------------------------------------------------------------------
local function refreshDropProps()
    for id, obj in pairs(dropObjects) do
        if not drops[id] and DoesEntityExist(obj) then
            DeleteObject(obj)
            dropObjects[id] = nil
        end
    end
    for id, drop in pairs(drops) do
        if not dropObjects[id] then
            local model = `prop_paper_bag_01`
            RequestModel(model)
            local tries = 0
            while not HasModelLoaded(model) and tries < 100 do Wait(10) tries = tries + 1 end
            if HasModelLoaded(model) then
                local obj = CreateObject(model, drop.coords.x, drop.coords.y, drop.coords.z - 1.0, false, false, false)
                PlaceObjectOnGroundProperly(obj)
                FreezeEntityPosition(obj, true)
                SetModelAsNoLongerNeeded(model)
                dropObjects[id] = obj
            end
        end
    end
end

RegisterNetEvent('inventory:client:syncDrops', function(serverDrops)
    drops = serverDrops or {}
    refreshDropProps()
end)

CreateThread(function()
    while true do
        Wait(500)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local closestId, closestDist = nil, 2.5

        for id, drop in pairs(drops) do
            local dist = #(coords - vector3(drop.coords.x, drop.coords.y, drop.coords.z))
            if dist < closestDist then
                closestId, closestDist = id, dist
            end
        end

        if closestId then
            local drop = drops[closestId]
            local def = Items and Items[drop.item]
            local label = def and def.label or drop.item
            BeginTextCommandDisplayHelp('STRING')
            AddTextComponentSubstringPlayerName(('~INPUT_CONTEXT~ Ramasser %s x%d'):format(label, drop.amount))
            EndTextCommandDisplayHelp(0, false, true, -1)

            if IsControlJustPressed(0, 38) then -- E
                TriggerServerEvent('inventory:server:pickupDrop', closestId)
            end
        end
    end
end)
