local Core = exports.core:GetCoreObject()

local function findCatalogEntry(model)
    for _, v in ipairs(VehiclesConfig.Catalog) do
        if v.model == model then return v end
    end
    return nil
end

RegisterNetEvent('vehicles:server:buyVehicle', function(model)
    local src = source
    local pd = Core.Functions.GetPlayer(src)
    if not pd then return end

    local entry = findCatalogEntry(model)
    if not entry then return end

    if Core.Functions.GetMoney(src, 'bank') < entry.price then
        TriggerClientEvent('core:client:notify', src, 'error', Core.Translate('not_enough_bank'))
        return
    end

    local plate
    repeat
        plate = Core.Utils.GeneratePlate()
        local exists = Core.DB.Scalar('SELECT COUNT(*) FROM vehicles WHERE plate = ?', { plate })
    until exists == 0 or exists == nil

    if Core.Functions.RemoveMoney(src, 'bank', entry.price, 'invoice') then
        Core.DB.Insert(
            'INSERT INTO vehicles (plate, citizenid, model, garage, state, fuel, engine, body) VALUES (?, ?, ?, ?, ?, 100, 1000, 1000)',
            { plate, pd.citizenid, entry.model, VehiclesConfig.Garages[1].label, 'garaged' })
        TriggerClientEvent('core:client:notify', src, 'success', ('Véhicule acheté ! Plaque: %s'):format(plate))
        TriggerClientEvent('vehicles:client:purchased', src)
    end
end)

Core.Functions.CreateCallback('vehicles:getOwned', function(src, cb, garageLabel)
    local pd = Core.Functions.GetPlayer(src)
    if not pd then cb({}) return end
    local rows = Core.DB.All(
        'SELECT id, plate, model, state, fuel, engine, body, impound_fee FROM vehicles WHERE citizenid = ? AND garage = ?',
        { pd.citizenid, garageLabel })
    cb(rows)
end)

Core.Functions.CreateCallback('vehicles:getImpounded', function(src, cb)
    local pd = Core.Functions.GetPlayer(src)
    if not pd then cb({}) return end
    local rows = Core.DB.All(
        "SELECT id, plate, model, impound_fee FROM vehicles WHERE citizenid = ? AND state = 'impound'",
        { pd.citizenid })
    cb(rows)
end)

Core.Functions.CreateCallback('vehicles:spawnOwned', function(src, cb, vehicleId, payImpound)
    local pd = Core.Functions.GetPlayer(src)
    if not pd then cb(nil) return end

    local row = Core.DB.Single('SELECT * FROM vehicles WHERE id = ? AND citizenid = ?', { vehicleId, pd.citizenid })
    if not row then cb(nil) return end
    if row.state == 'out' then
        TriggerClientEvent('core:client:notify', src, 'error', 'Ce véhicule est déjà sorti.')
        cb(nil)
        return
    end

    if row.state == 'impound' then
        if not payImpound then cb(nil) return end
        if Core.Functions.GetMoney(src, 'bank') < row.impound_fee then
            TriggerClientEvent('core:client:notify', src, 'error', Core.Translate('not_enough_bank'))
            cb(nil)
            return
        end
        Core.Functions.RemoveMoney(src, 'bank', row.impound_fee, 'fine')
    end

    Core.DB.Update("UPDATE vehicles SET state = 'out', impound_fee = 0 WHERE id = ?", { vehicleId })
    cb({
        id = row.id, plate = row.plate, model = row.model,
        fuel = row.fuel, engine = row.engine, body = row.body,
        mods = Core.Utils.FromJson(row.mods, {}),
    })
end)

RegisterNetEvent('vehicles:server:storeVehicle', function(plate, fuel, engine, body)
    local src = source
    local pd = Core.Functions.GetPlayer(src)
    if not pd or type(plate) ~= 'string' then return end

    local row = Core.DB.Single('SELECT id FROM vehicles WHERE plate = ? AND citizenid = ? AND state = ?', { plate, pd.citizenid, 'out' })
    if not row then return end

    Core.DB.Update('UPDATE vehicles SET state = ?, fuel = ?, engine = ?, body = ? WHERE id = ?', {
        'garaged',
        Core.Utils.Clamp(tonumber(fuel) or 100, 0, 100),
        Core.Utils.Clamp(tonumber(engine) or 1000, 0, 1000),
        Core.Utils.Clamp(tonumber(body) or 1000, 0, 1000),
        row.id,
    })
    TriggerClientEvent('core:client:notify', src, 'success', 'Véhicule rangé au garage.')
end)

--- Police/mechanic call this to impound a plate (see police/mechanic resources).
exports('ImpoundVehicle', function(plate, fee)
    Core.DB.Update("UPDATE vehicles SET state = 'impound', impound_fee = ? WHERE plate = ?", { fee or VehiclesConfig.ImpoundFee, plate })
end)

-- ---------------------------------------------------------------------
-- trunk / glovebox — any vehicle's plate becomes an inventory owner id.
-- No ownership check for the trunk (matches vanilla behaviour: an
-- unlocked car's trunk is accessible), the glovebox requires the client
-- to already be seated (enforced client-side by only offering the prompt
-- while driving/riding).
-- ---------------------------------------------------------------------
RegisterNetEvent('vehicles:server:openTrunk', function(plate)
    local src = source
    if type(plate) ~= 'string' or plate == '' then return end
    exports.inventory:OpenSecondary(src, 'trunk-' .. plate, 'trunk', VehiclesConfig.TrunkMaxWeight or 60000, VehiclesConfig.TrunkMaxSlots or 40, 'Coffre — ' .. plate)
    TriggerClientEvent('inventory:client:openUI', src)
end)

RegisterNetEvent('vehicles:server:openGlovebox', function(plate)
    local src = source
    if type(plate) ~= 'string' or plate == '' then return end
    exports.inventory:OpenSecondary(src, 'glove-' .. plate, 'glovebox', VehiclesConfig.GloveboxMaxWeight or 5000, VehiclesConfig.GloveboxMaxSlots or 5, 'Boîte à gants — ' .. plate)
    TriggerClientEvent('inventory:client:openUI', src)
end)
