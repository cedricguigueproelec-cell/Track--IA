local Core = exports.core:GetCoreObject()

Core.Functions.CreateCallback('housing:getProperties', function(src, cb)
    local rows = Core.DB.All([[
        SELECT p.id, p.label, p.coords, p.price, p.tier, p.owner_citizenid,
               c.firstname, c.lastname
        FROM properties p
        LEFT JOIN characters c ON c.citizenid = p.owner_citizenid
    ]])
    for _, row in ipairs(rows) do
        row.coords = Core.Utils.FromJson(row.coords, {})
    end
    cb(rows)
end)

RegisterNetEvent('housing:server:buyProperty', function(propertyId)
    local src = source
    local pd = Core.Functions.GetPlayer(src)
    if not pd then return end

    local row = Core.DB.Single('SELECT * FROM properties WHERE id = ?', { propertyId })
    if not row then return end
    if row.owner_citizenid then
        TriggerClientEvent('core:client:notify', src, 'error', 'Ce bien a déjà un propriétaire.')
        return
    end
    if Core.Functions.GetMoney(src, 'bank') < row.price then
        TriggerClientEvent('core:client:notify', src, 'error', Core.Translate('not_enough_money_property'))
        return
    end

    if Core.Functions.RemoveMoney(src, 'bank', row.price, 'invoice') then
        Core.DB.Update('UPDATE properties SET owner_citizenid = ? WHERE id = ?', { pd.citizenid, propertyId })
        TriggerClientEvent('core:client:notify', src, 'success', Core.Translate('property_bought'))
        TriggerClientEvent('housing:client:refresh', src)
    end
end)

RegisterNetEvent('housing:server:sellProperty', function(propertyId)
    local src = source
    local pd = Core.Functions.GetPlayer(src)
    if not pd then return end

    local row = Core.DB.Single('SELECT * FROM properties WHERE id = ? AND owner_citizenid = ?', { propertyId, pd.citizenid })
    if not row then return end

    Core.DB.Update('UPDATE properties SET owner_citizenid = NULL WHERE id = ?', { propertyId })
    local refund = math.floor(row.price * HousingConfig.SellRefundRatio)
    Core.Functions.AddMoney(src, 'bank', refund, 'invoice')
    TriggerClientEvent('core:client:notify', src, 'success', ('Bien vendu pour %d$.'):format(refund))
    TriggerClientEvent('housing:client:refresh', src)
end)

RegisterNetEvent('housing:server:openStash', function(propertyId)
    local src = source
    local pd = Core.Functions.GetPlayer(src)
    if not pd then return end

    local row = Core.DB.Single('SELECT * FROM properties WHERE id = ? AND owner_citizenid = ?', { propertyId, pd.citizenid })
    if not row then
        TriggerClientEvent('core:client:notify', src, 'error', Core.Translate('no_permission'))
        return
    end

    local tierConf = HousingConfig.StashByTier[row.tier] or HousingConfig.StashByTier[1]
    exports.inventory:OpenSecondary(src, row.stash_id, 'stash', tierConf.maxWeight, tierConf.maxSlots, row.label)
    TriggerClientEvent('inventory:client:openUI', src)
end)
