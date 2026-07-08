-- Multi-character lifecycle: list / create / select / save / delete.
-- Core.Players[source] only exists AFTER a character has been selected.
-- Nothing (inventory, jobs, hud...) should assume it exists before that.

local function rowToPlayerData(src, row)
    return {
        source      = src,
        identifier  = row.identifier,
        citizenid   = row.citizenid,
        charinfo    = {
            firstname   = row.firstname,
            lastname    = row.lastname,
            birthdate   = row.birthdate,
            gender      = row.gender,
            nationality = row.nationality,
            phone       = row.phone_number,
        },
        money = {
            cash = tonumber(row.cash) or 0,
            bank = tonumber(row.bank) or 0,
        },
        job = {
            name    = row.job,
            grade   = tonumber(row.job_grade) or 0,
            onduty  = row.job_onduty == 1,
        },
        gang = {
            name  = row.gang,
            grade = tonumber(row.gang_grade) or 0,
        },
        position = Utils.FromJson(row.position, Config.DefaultSpawn),
        metadata = Utils.FromJson(row.metadata, {
            health = 200, armor = 0, hunger = 100, thirst = 100,
            stress = 0, isdead = false, injail = 0, wanted = 0,
        }),
        skin = Utils.FromJson(row.skin, {}),
    }
end

--- Client-safe projection: never leak other players' identifiers etc.
--- (kept identical to server copy today, but centralizing this means we
--- can redact fields later without hunting every TriggerClientEvent).
local function toClientSafe(pd)
    return pd
end

function Core.Functions.GetPlayer(src)
    return Core.Players[tonumber(src)]
end

function Core.Functions.GetPlayers()
    local list = {}
    for src, pd in pairs(Core.Players) do
        list[#list + 1] = { source = src, pd = pd }
    end
    return list
end

function Core.Functions.GetPlayerByCitizenId(citizenid)
    for _, pd in pairs(Core.Players) do
        if pd.citizenid == citizenid then return pd end
    end
    return nil
end

function Core.Functions.SavePlayer(src)
    local pd = Core.Players[src]
    if not pd then return end

    local ped = GetPlayerPed(src)
    if ped and ped ~= 0 then
        local coords = GetEntityCoords(ped)
        pd.position = { x = coords.x, y = coords.y, z = coords.z, heading = GetEntityHeading(ped) }
    end

    DB.Update([[
        UPDATE characters SET
            cash = ?, bank = ?, job = ?, job_grade = ?, job_onduty = ?,
            gang = ?, gang_grade = ?, position = ?, metadata = ?, skin = ?,
            phone_number = ?, last_seen = NOW()
        WHERE citizenid = ?
    ]], {
        pd.money.cash, pd.money.bank, pd.job.name, pd.job.grade, pd.job.onduty and 1 or 0,
        pd.gang.name, pd.gang.grade, Utils.ToJson(pd.position), Utils.ToJson(pd.metadata), Utils.ToJson(pd.skin),
        pd.charinfo.phone, pd.citizenid,
    })
end

function Core.Functions.SaveAllPlayers()
    for src, _ in pairs(Core.Players) do
        Core.Functions.SavePlayer(src)
    end
end

-- ---------------------------------------------------------------------
-- List characters for the connecting identity
-- ---------------------------------------------------------------------
RegisterNetEvent('core:server:requestCharacters', function()
    local src = source
    local identifier = Core.GetIdentifier(src)
    if not identifier then return end

    local rows = DB.All('SELECT citizenid, firstname, lastname, job, cash, bank, slot FROM characters WHERE identifier = ? AND deleted = 0 ORDER BY slot ASC', { identifier })
    TriggerClientEvent('core:client:receiveCharacters', src, rows, Config.MaxCharacterSlots)
end)

-- ---------------------------------------------------------------------
-- Create a new character
-- ---------------------------------------------------------------------
RegisterNetEvent('core:server:createCharacter', function(data)
    local src = source
    local identifier = Core.GetIdentifier(src)
    if not identifier then return end

    if type(data) ~= 'table' then return end
    local firstname = tostring(data.firstname or ''):sub(1, 50)
    local lastname  = tostring(data.lastname or ''):sub(1, 50)
    local birthdate = tostring(data.birthdate or '2000-01-01'):sub(1, 10)
    local gender    = tonumber(data.gender) == 1 and 1 or 0
    local nationality = tostring(data.nationality or 'USA'):sub(1, 50)

    if firstname == '' or lastname == '' or #firstname < 2 or #lastname < 2 then
        TriggerClientEvent('core:client:notify', src, 'error', 'Prénom / nom invalide.')
        return
    end

    local count = DB.Scalar('SELECT COUNT(*) FROM characters WHERE identifier = ? AND deleted = 0', { identifier })
    if count >= Config.MaxCharacterSlots then
        TriggerClientEvent('core:client:notify', src, 'error', _T('max_characters'))
        return
    end

    -- generate a unique citizenid (retry on rare collision)
    local citizenid
    repeat
        citizenid = Utils.RandomString(3, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ') .. Utils.RandomString(5, '0123456789')
        local exists = DB.Scalar('SELECT COUNT(*) FROM characters WHERE citizenid = ?', { citizenid })
    until exists == 0 or exists == nil

    local phone
    repeat
        phone = Utils.GeneratePhoneNumber()
        local exists = DB.Scalar('SELECT COUNT(*) FROM characters WHERE phone_number = ?', { phone })
    until exists == 0 or exists == nil

    DB.Insert([[
        INSERT INTO characters
            (citizenid, identifier, slot, firstname, lastname, birthdate, gender, nationality, phone_number, cash, bank, position, metadata)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        citizenid, identifier, (count + 1), firstname, lastname, birthdate, gender, nationality, phone,
        Config.StartingCash, Config.StartingBank,
        Utils.ToJson(Config.DefaultSpawn),
        Utils.ToJson({ health = 200, armor = 0, hunger = 100, thirst = 100, stress = 0, isdead = false, injail = 0, wanted = 0 }),
    })

    -- stash for the future property system is created lazily, no row needed here
    TriggerClientEvent('core:client:notify', src, 'success', _T('character_created'))
    TriggerEvent('core:server:requestCharacters', src)
    TriggerClientEvent('core:client:receiveCharacters', src,
        DB.All('SELECT citizenid, firstname, lastname, job, cash, bank, slot FROM characters WHERE identifier = ? AND deleted = 0 ORDER BY slot ASC', { identifier }),
        Config.MaxCharacterSlots)
end)

-- ---------------------------------------------------------------------
-- Select / load a character into the world
-- ---------------------------------------------------------------------
RegisterNetEvent('core:server:selectCharacter', function(citizenid)
    local src = source
    local identifier = Core.GetIdentifier(src)
    if not identifier or type(citizenid) ~= 'string' then return end

    local row = DB.Single('SELECT * FROM characters WHERE citizenid = ? AND identifier = ? AND deleted = 0', { citizenid, identifier })
    if not row then
        TriggerClientEvent('core:client:notify', src, 'error', _T('item_not_found'))
        return
    end

    local pd = rowToPlayerData(src, row)
    Core.Players[src] = pd

    TriggerClientEvent('core:client:playerLoaded', src, toClientSafe(pd))
    TriggerEvent('core:playerLoaded', src, pd) -- other server resources hook this
end)

-- ---------------------------------------------------------------------
-- Delete (soft) a character
-- ---------------------------------------------------------------------
RegisterNetEvent('core:server:deleteCharacter', function(citizenid)
    local src = source
    local identifier = Core.GetIdentifier(src)
    if not identifier or type(citizenid) ~= 'string' then return end

    DB.Update('UPDATE characters SET deleted = 1 WHERE citizenid = ? AND identifier = ?', { citizenid, identifier })
    TriggerClientEvent('core:client:notify', src, 'success', _T('character_deleted'))
    TriggerClientEvent('core:client:receiveCharacters', src,
        DB.All('SELECT citizenid, firstname, lastname, job, cash, bank, slot FROM characters WHERE identifier = ? AND deleted = 0 ORDER BY slot ASC', { identifier }),
        Config.MaxCharacterSlots)
end)

Core.Functions.CreateCallback('core:getPlayerData', function(src, cb)
    cb(Core.Players[src])
end)

-- ---------------------------------------------------------------------
-- Generic metadata mutation (hunger, thirst, stress, health snapshot...)
-- Whitelisted keys only — this is the one place other resources are
-- allowed to touch pd.metadata so we can validate ranges centrally.
-- ---------------------------------------------------------------------
local META_RANGES = {
    health  = { 0, 200 },
    armor   = { 0, 100 },
    hunger  = { 0, 100 },
    thirst  = { 0, 100 },
    stress  = { 0, 100 },
    wanted  = { 0, 5 },
    injail  = { 0, 999999 }, -- jail time remaining, in seconds
}

function Core.Functions.SetMetaData(src, key, value)
    local pd = Core.Players[src]
    if not pd then return false end
    local range = META_RANGES[key]
    if range and type(value) == 'number' then
        pd.metadata[key] = Utils.Clamp(value, range[1], range[2])
    elseif key == 'isdead' then
        pd.metadata.isdead = value and true or false
    else
        return false
    end
    TriggerClientEvent('core:client:updateMetadata', src, pd.metadata)
    return true
end

function Core.Functions.SetJob(src, jobName, grade)
    local pd = Core.Players[src]
    if not pd then return false end
    if type(jobName) ~= 'string' or #jobName == 0 or #jobName > 50 then return false end
    grade = tonumber(grade) or 0

    pd.job = { name = jobName, grade = grade, onduty = pd.job.onduty or false }
    TriggerClientEvent('core:client:updateJob', src, pd.job)
    TriggerEvent('core:playerJobChanged', src, pd)
    return true
end

function Core.Functions.SetSkin(src, skinTable)
    local pd = Core.Players[src]
    if not pd or type(skinTable) ~= 'table' then return false end
    pd.skin = skinTable
    TriggerClientEvent('core:client:updateSkin', src, pd.skin)
    return true
end

function Core.Functions.SetDuty(src, state)
    local pd = Core.Players[src]
    if not pd then return false end
    pd.job.onduty = state and true or false
    TriggerClientEvent('core:client:updateJob', src, pd.job)
    return true
end

RegisterNetEvent('core:server:setMetaData', function(key, value)
    local src = source
    -- clients may only nudge their own hunger/thirst via consumables;
    -- health/wanted/injail are set server-side by the owning resource only
    if key ~= 'hunger' and key ~= 'thirst' then return end
    Core.Functions.SetMetaData(src, key, value)
end)
