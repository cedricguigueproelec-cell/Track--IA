-- Server-authoritative slot-based inventory. The client NEVER decides
-- outcomes — it only sends intents (use/drop/transfer) and the server
-- replies with the resulting state. This is the #1 anti-dupe boundary.

local Core = exports.core:GetCoreObject()

local Inventory = { Loaded = {}, OpenSecondary = {}, Busy = {}, Drops = {} }
local dropCounter = 0

-- ---------------------------------------------------------------------
-- helpers
-- ---------------------------------------------------------------------
local function computeWeight(inv)
    local total = 0
    for _, stack in pairs(inv.slots) do
        local def = GetItemDefinition(stack.item)
        total = total + ((def and def.weight or 0) * stack.amount)
    end
    return total
end

local function firstFreeSlot(inv)
    for i = 1, inv.maxSlots do
        if not inv.slots[i] then return i end
    end
    return nil
end

local function loadInventory(ownerId, ownerType, maxWeight, maxSlots)
    if Inventory.Loaded[ownerId] then return Inventory.Loaded[ownerId] end

    local inv = { slots = {}, maxWeight = maxWeight, maxSlots = maxSlots, ownerType = ownerType, dirty = false }
    local rows = Core.DB.All('SELECT slot, item, amount, metadata FROM inventories WHERE owner_id = ?', { ownerId })
    for _, row in ipairs(rows) do
        inv.slots[row.slot] = { item = row.item, amount = row.amount, metadata = Core.Utils.FromJson(row.metadata, {}) }
    end
    Inventory.Loaded[ownerId] = inv

    if ownerType == 'player' and #rows == 0 then
        -- brand-new character: starter kit
        inv.slots[1] = { item = 'id_card', amount = 1, metadata = {} }
        inv.slots[2] = { item = 'water_bottle', amount = 2, metadata = {} }
        inv.slots[3] = { item = 'sandwich', amount = 2, metadata = {} }
        inv.dirty = true
    end

    return inv
end

local function saveInventory(ownerId)
    local inv = Inventory.Loaded[ownerId]
    if not inv then return end
    Core.DB.Execute('DELETE FROM inventories WHERE owner_id = ?', { ownerId })
    for slot, stack in pairs(inv.slots) do
        Core.DB.Insert('INSERT INTO inventories (owner_id, owner_type, slot, item, amount, metadata) VALUES (?, ?, ?, ?, ?, ?)',
            { ownerId, inv.ownerType, slot, stack.item, stack.amount, Core.Utils.ToJson(stack.metadata) })
    end
    inv.dirty = false
end

local function serialize(inv)
    if not inv then return { slots = {}, maxWeight = 0, maxSlots = 0, weight = 0 } end
    local out = {}
    for slot, stack in pairs(inv.slots) do
        local def = GetItemDefinition(stack.item)
        out[tostring(slot)] = {
            slot = slot, item = stack.item, amount = stack.amount, metadata = stack.metadata,
            label = def and def.label or stack.item,
            weight = def and def.weight or 0,
            type = def and def.type or 'item',
        }
    end
    return { slots = out, maxWeight = inv.maxWeight, maxSlots = inv.maxSlots, weight = computeWeight(inv) }
end

local function pushState(src, ownerId, secondaryOwnerId, secondaryLabel)
    local playerInv = Inventory.Loaded[ownerId]
    local payload = { owner = serialize(playerInv), ownerId = ownerId }
    if secondaryOwnerId then
        payload.secondary = serialize(Inventory.Loaded[secondaryOwnerId])
        payload.secondaryId = secondaryOwnerId
        payload.secondaryLabel = secondaryLabel
    end
    TriggerClientEvent('inventory:client:state', src, payload)
end

-- ---------------------------------------------------------------------
-- core mutation primitives (all other functions build on these two)
-- ---------------------------------------------------------------------

--- Adds `amount` of `item` to ownerId's inventory. Returns true/false.
--- metadata-bearing (non-stackable) items are always split into
--- individual slots, one unit each.
local function addItem(ownerId, itemName, amount, metadata)
    local def = GetItemDefinition(itemName)
    if not def or not Core.Utils.IsValidAmount(amount, 10000) then return false end

    local inv = Inventory.Loaded[ownerId]
    if not inv then return false end

    if computeWeight(inv) + (def.weight * amount) > inv.maxWeight then
        return false
    end

    if def.stackable and not metadata then
        for slot, stack in pairs(inv.slots) do
            if stack.item == itemName and next(stack.metadata) == nil then
                stack.amount = stack.amount + amount
                inv.dirty = true
                return true, slot
            end
        end
        local slot = firstFreeSlot(inv)
        if not slot then return false end
        inv.slots[slot] = { item = itemName, amount = amount, metadata = {} }
        inv.dirty = true
        return true, slot
    else
        -- non-stackable (or metadata-bearing): one slot per unit
        local placed = 0
        for _ = 1, amount do
            local slot = firstFreeSlot(inv)
            if not slot then break end
            inv.slots[slot] = { item = itemName, amount = 1, metadata = metadata or {} }
            placed = placed + 1
        end
        inv.dirty = placed > 0
        return placed == amount
    end
end

--- Removes `amount` of `item` from ownerId's inventory (across slots if
--- needed). Returns true only if the FULL amount could be removed —
--- otherwise nothing is removed (all-or-nothing to avoid partial-charge bugs).
local function removeItem(ownerId, itemName, amount)
    local inv = Inventory.Loaded[ownerId]
    if not inv or not Core.Utils.IsValidAmount(amount, 10000) then return false end

    local available = 0
    for _, stack in pairs(inv.slots) do
        if stack.item == itemName then available = available + stack.amount end
    end
    if available < amount then return false end

    local remaining = amount
    for slot, stack in pairs(inv.slots) do
        if remaining <= 0 then break end
        if stack.item == itemName then
            local take = math.min(stack.amount, remaining)
            stack.amount = stack.amount - take
            remaining = remaining - take
            if stack.amount <= 0 then inv.slots[slot] = nil end
        end
    end
    inv.dirty = true
    return true
end

local function removeFromSlot(ownerId, slot, amount)
    local inv = Inventory.Loaded[ownerId]
    if not inv then return false, nil end
    local stack = inv.slots[slot]
    if not stack or amount > stack.amount or amount <= 0 then return false, nil end

    local item, metadata = stack.item, stack.metadata
    stack.amount = stack.amount - amount
    if stack.amount <= 0 then inv.slots[slot] = nil end
    inv.dirty = true
    return true, item, metadata
end

local function getItemCount(ownerId, itemName)
    local inv = Inventory.Loaded[ownerId]
    if not inv then return 0 end
    local total = 0
    for _, stack in pairs(inv.slots) do
        if stack.item == itemName then total = total + stack.amount end
    end
    return total
end

-- ---------------------------------------------------------------------
-- ownership / access validation
-- ---------------------------------------------------------------------
local function ownerAllowed(src, ownerId)
    local pd = Core.Functions.GetPlayer(src)
    if not pd then return false end
    if ownerId == pd.citizenid then return true end
    if Inventory.OpenSecondary[src] == ownerId then return true end
    return false
end

-- ---------------------------------------------------------------------
-- player load / unload
-- ---------------------------------------------------------------------
AddEventHandler('core:playerLoaded', function(src, pd)
    local inv = loadInventory(pd.citizenid, 'player', Config.PlayerMaxWeight, Config.PlayerMaxSlots)
    if inv.dirty then saveInventory(pd.citizenid) end
    pushState(src, pd.citizenid)
end)

AddEventHandler('playerDropped', function()
    local src = source
    local pd = Core.Functions.GetPlayer(src)
    if pd then
        local inv = Inventory.Loaded[pd.citizenid]
        if inv and inv.dirty then saveInventory(pd.citizenid) end
    end
    Inventory.OpenSecondary[src] = nil
end)

CreateThread(function()
    while true do
        Wait(5 * 60 * 1000)
        for ownerId, inv in pairs(Inventory.Loaded) do
            if inv.dirty then saveInventory(ownerId) end
        end
    end
end)

-- ---------------------------------------------------------------------
-- net events (client intents)
-- ---------------------------------------------------------------------
RegisterNetEvent('inventory:server:useItem', function(slot)
    local src = source
    local pd = Core.Functions.GetPlayer(src)
    if not pd or type(slot) ~= 'number' then return end
    local inv = Inventory.Loaded[pd.citizenid]
    if not inv then return end
    local stack = inv.slots[slot]
    if not stack then return end
    local def = GetItemDefinition(stack.item)
    if not def or not def.usable then return end
    if def.jobRestricted and pd.job.name ~= def.jobRestricted then return end

    local ok = removeFromSlot(pd.citizenid, slot, 1)
    if not ok then return end

    if def.effect then
        if def.effect.cash then
            Core.Functions.AddMoney(src, 'cash', def.effect.cash, 'item_use')
        end
        local clientEffect = { hunger = def.effect.hunger, thirst = def.effect.thirst, health = def.effect.health }
        if clientEffect.hunger or clientEffect.thirst or clientEffect.health then
            TriggerClientEvent('inventory:client:consumeEffect', src, clientEffect)
        end
    end

    pushState(src, pd.citizenid, Inventory.OpenSecondary[src])
end)

RegisterNetEvent('inventory:server:transferItem', function(fromOwner, slot, amount, toOwner)
    local src = source
    local pd = Core.Functions.GetPlayer(src)
    if not pd then return end
    if Inventory.Busy[src] then return end
    if not ownerAllowed(src, fromOwner) or not ownerAllowed(src, toOwner) then return end
    if type(slot) ~= 'number' or not Core.Utils.IsValidAmount(amount, 10000) then return end

    Inventory.Busy[src] = true
    local ok, item, metadata = removeFromSlot(fromOwner, slot, amount)
    if ok then
        local added = addItem(toOwner, item, amount, next(metadata) and metadata or nil)
        if not added then
            -- rollback: put it back where it came from
            addItem(fromOwner, item, amount, next(metadata) and metadata or nil)
        end
    end
    Inventory.Busy[src] = false

    pushState(src, pd.citizenid, Inventory.OpenSecondary[src])
end)

RegisterNetEvent('inventory:server:dropItem', function(slot, amount)
    local src = source
    local pd = Core.Functions.GetPlayer(src)
    if not pd or type(slot) ~= 'number' then return end

    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)

    local ok, item, metadata = removeFromSlot(pd.citizenid, slot, amount or 1)
    if not ok then return end

    dropCounter = dropCounter + 1
    local dropId = 'drop-' .. dropCounter
    Inventory.Drops[dropId] = {
        coords = { x = coords.x, y = coords.y, z = coords.z },
        item = item, amount = amount or 1, metadata = metadata,
        createdAt = GetGameTimer(),
    }

    TriggerClientEvent('inventory:client:syncDrops', -1, Inventory.Drops)
    pushState(src, pd.citizenid, Inventory.OpenSecondary[src])

    SetTimeout(Config.DropDespawnMs, function()
        if Inventory.Drops[dropId] then
            Inventory.Drops[dropId] = nil
            TriggerClientEvent('inventory:client:syncDrops', -1, Inventory.Drops)
        end
    end)
end)

RegisterNetEvent('inventory:server:pickupDrop', function(dropId)
    local src = source
    local pd = Core.Functions.GetPlayer(src)
    if not pd or type(dropId) ~= 'string' then return end
    local drop = Inventory.Drops[dropId]
    if not drop then return end

    local ped = GetPlayerPed(src)
    local dist = #(GetEntityCoords(ped) - vector3(drop.coords.x, drop.coords.y, drop.coords.z))
    if dist > Config.MaxDropDistance then return end

    local added = addItem(pd.citizenid, drop.item, drop.amount, next(drop.metadata or {}) and drop.metadata or nil)
    if added then
        Inventory.Drops[dropId] = nil
        TriggerClientEvent('inventory:client:syncDrops', -1, Inventory.Drops)
        pushState(src, pd.citizenid)
    end
end)

Core.Functions.CreateCallback('inventory:requestState', function(src, cb)
    local pd = Core.Functions.GetPlayer(src)
    if not pd then cb(nil) return end
    cb(serialize(Inventory.Loaded[pd.citizenid]), Inventory.OpenSecondary[src])
end)

RegisterNetEvent('inventory:server:closeSecondary', function()
    local src = source
    local ownerId = Inventory.OpenSecondary[src]
    if ownerId then saveInventory(ownerId) end
    Inventory.OpenSecondary[src] = nil
end)

-- ---------------------------------------------------------------------
-- exports (used by vehicles/housing/jobs/shops/drugs resources)
-- ---------------------------------------------------------------------
exports('AddItem', function(ownerId, item, amount, metadata)
    if not Inventory.Loaded[ownerId] then
        loadInventory(ownerId, 'player', Config.PlayerMaxWeight, Config.PlayerMaxSlots)
    end
    return addItem(ownerId, item, amount, metadata)
end)

exports('RemoveItem', function(ownerId, item, amount)
    if not Inventory.Loaded[ownerId] then return false end
    return removeItem(ownerId, item, amount)
end)

exports('GetItemCount', function(ownerId, item)
    if not Inventory.Loaded[ownerId] then return 0 end
    return getItemCount(ownerId, item)
end)

exports('HasItem', function(ownerId, item, amount)
    return getItemCount(ownerId, item) >= (amount or 1)
end)

--- Called by vehicles/housing to open a trunk/glovebox/stash for `src`.
exports('OpenSecondary', function(src, ownerId, ownerType, maxWeight, maxSlots, label)
    local pd = Core.Functions.GetPlayer(src)
    if not pd then return false end
    loadInventory(ownerId, ownerType, maxWeight, maxSlots)
    Inventory.OpenSecondary[src] = ownerId
    pushState(src, pd.citizenid, ownerId, label)
    return true
end)

exports('CloseSecondary', function(src)
    local ownerId = Inventory.OpenSecondary[src]
    if ownerId then saveInventory(ownerId) end
    Inventory.OpenSecondary[src] = nil
end)

exports('EnsureLoaded', function(ownerId, ownerType, maxWeight, maxSlots)
    loadInventory(ownerId, ownerType, maxWeight, maxSlots)
end)

exports('GetItemDefinition', function(name)
    return GetItemDefinition(name)
end)

--- Read-only snapshot of any inventory (used by police search / admin tools).
exports('GetSnapshot', function(ownerId)
    return serialize(Inventory.Loaded[ownerId])
end)

exports('GetInventoryWeight', function(ownerId)
    local inv = Inventory.Loaded[ownerId]
    if not inv then return 0 end
    return computeWeight(inv)
end)
