local Core = exports.core:GetCoreObject()

local function findInList(list, key, value)
    for _, entry in ipairs(list) do
        if entry[key] == value then return entry end
    end
    return nil
end

RegisterNetEvent('shops:server:buyGeneralItem', function(itemKey)
    local src = source
    local pd = Core.Functions.GetPlayer(src)
    if not pd then return end
    local entry = findInList(ShopsConfig.GeneralStock, 'item', itemKey)
    if not entry or entry.disabled then return end

    if Core.Functions.GetMoney(src, 'cash') < entry.price then
        TriggerClientEvent('core:client:notify', src, 'error', Core.Translate('not_enough_cash'))
        return
    end
    if not exports.inventory:AddItem(pd.citizenid, entry.item, 1) then
        TriggerClientEvent('core:client:notify', src, 'error', Core.Translate('inventory_full'))
        return
    end
    Core.Functions.RemoveMoney(src, 'cash', entry.price, 'shop')
    TriggerClientEvent('core:client:notify', src, 'success', ('%s acheté.'):format(entry.label))
end)

RegisterNetEvent('shops:server:buyWeapon', function(itemKey)
    local src = source
    local pd = Core.Functions.GetPlayer(src)
    if not pd then return end
    local entry = findInList(ShopsConfig.WeaponStock, 'item', itemKey)
    if not entry then return end

    if Core.Functions.GetMoney(src, 'cash') < entry.price then
        TriggerClientEvent('core:client:notify', src, 'error', Core.Translate('not_enough_cash'))
        return
    end
    if not exports.inventory:AddItem(pd.citizenid, entry.item, 1) then
        TriggerClientEvent('core:client:notify', src, 'error', Core.Translate('inventory_full'))
        return
    end
    if entry.ammoItem then
        exports.inventory:AddItem(pd.citizenid, entry.ammoItem, entry.ammoAmount or 1)
    end
    Core.Functions.RemoveMoney(src, 'cash', entry.price, 'shop')
    TriggerClientEvent('core:client:notify', src, 'success', ('%s acheté.'):format(entry.label))
end)

RegisterNetEvent('shops:server:buyOutfit', function(index)
    local src = source
    local pd = Core.Functions.GetPlayer(src)
    if not pd then return end
    index = tonumber(index)
    local outfit = ShopsConfig.Outfits[index]
    if not outfit then return end

    if Core.Functions.GetMoney(src, 'cash') < outfit.price then
        TriggerClientEvent('core:client:notify', src, 'error', Core.Translate('not_enough_cash'))
        return
    end

    Core.Functions.RemoveMoney(src, 'cash', outfit.price, 'shop')
    Core.Functions.SetSkin(src, { components = outfit.components, props = outfit.props })
    TriggerClientEvent('core:client:notify', src, 'success', ('%s achetée et appliquée.'):format(outfit.label))
end)

RegisterNetEvent('shops:server:refuel', function(units)
    local src = source
    units = Core.Utils.Clamp(tonumber(units) or 0, 0, 100)
    if units <= 0 then return end
    local price = math.floor(units * ShopsConfig.GasPricePerUnit)

    if Core.Functions.GetMoney(src, 'cash') < price then
        TriggerClientEvent('core:client:notify', src, 'error', Core.Translate('not_enough_cash'))
        return
    end
    Core.Functions.RemoveMoney(src, 'cash', price, 'shop')
    TriggerClientEvent('shops:client:refuelApproved', src, units)
end)
