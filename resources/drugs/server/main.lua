local Core = exports.core:GetCoreObject()

local lastPick = {} -- [src] = GetGameTimer()

local function nearAny(src, points, radius)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    local coords = GetEntityCoords(ped)
    for _, p in ipairs(points) do
        if #(coords - vector3(p.x, p.y, p.z)) < (radius or 3.0) then return true end
    end
    return false
end

local function near(src, point, radius)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    return #(GetEntityCoords(ped) - vector3(point.x, point.y, point.z)) < (radius or 3.0)
end

RegisterNetEvent('drugs:server:pick', function()
    local src = source
    local pd = Core.Functions.GetPlayer(src)
    if not pd then return end
    if not nearAny(src, DrugsConfig.WeedFields, DrugsConfig.InteractDistance) then return end

    local now = GetGameTimer()
    if lastPick[src] and (now - lastPick[src]) < DrugsConfig.PickCooldownMs then return end
    lastPick[src] = now

    local amount = math.random(DrugsConfig.PickYieldMin, DrugsConfig.PickYieldMax)
    if exports.inventory:AddItem(pd.citizenid, 'weed_raw', amount) then
        TriggerClientEvent('core:client:notify', src, 'success', ('Récolté: %dx cannabis brut.'):format(amount))
    else
        TriggerClientEvent('core:client:notify', src, 'error', Core.Translate('inventory_full'))
    end

    if math.random(100) <= DrugsConfig.PickAlertChance and GetResourceState('dispatch') == 'started' then
        local ped = GetPlayerPed(src)
        exports.dispatch:SendAlert('police', 'crime', 'Activité suspecte signalée', GetEntityCoords(ped))
    end
end)

Core.Functions.CreateCallback('drugs:process', function(src, cb)
    local pd = Core.Functions.GetPlayer(src)
    if not pd or not near(src, DrugsConfig.ProcessSpot, 4.0) then cb(false) return end

    local ratio = DrugsConfig.ProcessRatio
    if not exports.inventory:HasItem(pd.citizenid, 'weed_raw', ratio) then
        TriggerClientEvent('core:client:notify', src, 'error', 'Pas assez de cannabis brut.')
        cb(false)
        return
    end

    exports.inventory:RemoveItem(pd.citizenid, 'weed_raw', ratio)
    exports.inventory:AddItem(pd.citizenid, 'weed_processed', 1)
    TriggerClientEvent('core:client:notify', src, 'success', 'Cannabis conditionné.')
    cb(true)
end)

RegisterNetEvent('drugs:server:sell', function(itemName, amount)
    local src = source
    local pd = Core.Functions.GetPlayer(src)
    if not pd or not near(src, DrugsConfig.SellSpot, 4.0) then return end

    amount = Core.Utils.Clamp(tonumber(amount) or 0, 1, 500)
    local def = exports.inventory:GetItemDefinition(itemName)
    if not def or not def.sellPrice or not def.illegal then return end

    if not exports.inventory:HasItem(pd.citizenid, itemName, amount) then
        TriggerClientEvent('core:client:notify', src, 'error', Core.Translate('item_not_found'))
        return
    end

    exports.inventory:RemoveItem(pd.citizenid, itemName, amount)
    local total = def.sellPrice * amount
    Core.Functions.AddMoney(src, 'cash', total, 'drug_sale')
    TriggerClientEvent('core:client:notify', src, 'success', ('Vendu pour %d$.'):format(total))

    if math.random(100) <= DrugsConfig.SellAlertChance and GetResourceState('dispatch') == 'started' then
        local ped = GetPlayerPed(src)
        exports.dispatch:SendAlert('police', 'crime', 'Trafic de stupéfiants signalé', GetEntityCoords(ped))
    end
end)

-- ---------------------------------------------------------------------
-- gang stash + gang chat
-- ---------------------------------------------------------------------
RegisterNetEvent('drugs:server:openGangStash', function()
    local src = source
    local pd = Core.Functions.GetPlayer(src)
    if not pd or pd.gang.name == 'none' then
        TriggerClientEvent('core:client:notify', src, 'error', Core.Translate('no_permission'))
        return
    end
    exports.inventory:OpenSecondary(src, 'gang-' .. pd.gang.name, 'stash', DrugsConfig.GangStashMaxWeight, DrugsConfig.GangStashMaxSlots, 'Planque du gang')
    TriggerClientEvent('inventory:client:openUI', src)
end)

RegisterCommand('gc', function(src, args)
    local pd = Core.Functions.GetPlayer(src)
    if not pd or pd.gang.name == 'none' then return end
    local message = table.concat(args, ' ')
    if message == '' then return end

    for _, entry in ipairs(Core.Functions.GetPlayers()) do
        if entry.pd.gang.name == pd.gang.name then
            TriggerClientEvent('chat:addMessage', entry.source, {
                color = { 255, 80, 80 },
                args = { ('[GANG] %s'):format(pd.charinfo.firstname), message },
            })
        end
    end
end, false)

AddEventHandler('playerDropped', function()
    lastPick[source] = nil
end)
