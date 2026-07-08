local Core = exports.core:GetCoreObject()

local jailTimers = {} -- [src] = seconds remaining

local function isOnDutyPolice(src)
    local pd = Core.Functions.GetPlayer(src)
    return pd and pd.job.name == PoliceConfig.JobName and pd.job.onduty
end

RegisterNetEvent('police:server:toggleDuty', function()
    local src = source
    local pd = Core.Functions.GetPlayer(src)
    if not pd or pd.job.name ~= PoliceConfig.JobName then return end
    Core.Functions.SetDuty(src, not pd.job.onduty)
    TriggerClientEvent('core:client:notify', src, 'info', pd.job.onduty and 'En service.' or 'Hors service.')
end)

-- ---------------------------------------------------------------------
-- cuffing (state bag driven, see client/main.lua)
-- ---------------------------------------------------------------------
RegisterNetEvent('police:server:cuff', function(targetId)
    local src = source
    if not isOnDutyPolice(src) then return end
    targetId = tonumber(targetId)
    if not targetId or not GetPlayerName(targetId) then return end

    local ped, targetPed = GetPlayerPed(src), GetPlayerPed(targetId)
    if ped == 0 or targetPed == 0 then return end
    if #(GetEntityCoords(ped) - GetEntityCoords(targetPed)) > 3.0 then return end

    local current = Player(targetId).state.cuffed
    Player(targetId).state:set('cuffed', not current, true)
    TriggerClientEvent('core:client:notify', targetId, 'info', not current and 'Vous êtes menotté.' or 'Vous êtes libéré des menottes.')
end)

-- ---------------------------------------------------------------------
-- search / seize
-- ---------------------------------------------------------------------
Core.Functions.CreateCallback('police:searchPlayer', function(src, cb, targetId)
    if not isOnDutyPolice(src) then cb(nil) return end
    local targetPd = Core.Functions.GetPlayer(tonumber(targetId))
    if not targetPd then cb(nil) return end

    local ped, targetPed = GetPlayerPed(src), GetPlayerPed(tonumber(targetId))
    if #(GetEntityCoords(ped) - GetEntityCoords(targetPed)) > 3.0 then cb(nil) return end

    cb(exports.inventory:GetSnapshot(targetPd.citizenid), targetPd.charinfo)
end)

RegisterNetEvent('police:server:seizeItem', function(targetId, slot)
    local src = source
    if not isOnDutyPolice(src) then return end
    local targetPd = Core.Functions.GetPlayer(tonumber(targetId))
    if not targetPd then return end

    local snapshot = exports.inventory:GetSnapshot(targetPd.citizenid)
    local stack = snapshot.slots[tostring(slot)]
    if not stack then return end

    if exports.inventory:RemoveItem(targetPd.citizenid, stack.item, stack.amount) then
        exports.inventory:AddItem('evidence-pd', stack.item, stack.amount)
        TriggerClientEvent('core:client:notify', targetId, 'error', ('%s saisi par la police.'):format(stack.label))
        TriggerClientEvent('core:client:notify', src, 'success', 'Objet saisi et placé sous scellé.')
    end
end)

-- ---------------------------------------------------------------------
-- jail
-- ---------------------------------------------------------------------
RegisterNetEvent('police:server:jail', function(targetId, minutes)
    local src = source
    if not isOnDutyPolice(src) then return end
    targetId = tonumber(targetId)
    minutes = Core.Utils.Clamp(tonumber(minutes) or 5, 1, 240)
    if not targetId or not GetPlayerName(targetId) then return end

    Player(targetId).state:set('cuffed', false, true)
    if GetResourceState('admin') == 'started' then exports.admin:SetTeleportGrace(targetId) end
    jailTimers[targetId] = minutes * 60
    Core.Functions.SetMetaData(targetId, 'injail', jailTimers[targetId])
    TriggerClientEvent('police:client:jailed', targetId, PoliceConfig.JailCoords, minutes)
    TriggerClientEvent('core:client:notify', src, 'success', ('Suspect incarcéré pour %d minute(s).'):format(minutes))
end)

CreateThread(function()
    while true do
        Wait(1000)
        for src, remaining in pairs(jailTimers) do
            remaining = remaining - 1
            if remaining <= 0 or not GetPlayerName(src) then
                jailTimers[src] = nil
                if GetPlayerName(src) then
                    Core.Functions.SetMetaData(src, 'injail', 0)
                    if GetResourceState('admin') == 'started' then exports.admin:SetTeleportGrace(src) end
                    TriggerClientEvent('police:client:released', src, PoliceConfig.JailReleaseCoords)
                end
            else
                jailTimers[src] = remaining
            end
        end
    end
end)

-- ---------------------------------------------------------------------
-- armory
-- ---------------------------------------------------------------------
RegisterNetEvent('police:server:getArmoryItem', function(itemName)
    local src = source
    local pd = Core.Functions.GetPlayer(src)
    if not isOnDutyPolice(src) then return end

    local entry
    for _, e in ipairs(PoliceConfig.ArmoryItems) do
        if e.item == itemName then entry = e break end
    end
    if not entry then return end
    if entry.minGrade and pd.job.grade < entry.minGrade then
        TriggerClientEvent('core:client:notify', src, 'error', Core.Translate('no_permission'))
        return
    end

    if exports.inventory:AddItem(pd.citizenid, entry.item, entry.amount or 1) then
        TriggerClientEvent('core:client:notify', src, 'success', ('%s récupéré à l\'armurerie.'):format(entry.label))
    else
        TriggerClientEvent('core:client:notify', src, 'error', Core.Translate('inventory_full'))
    end
end)

-- ---------------------------------------------------------------------
-- MDT (light): citizen + plate lookup
-- ---------------------------------------------------------------------
Core.Functions.CreateCallback('police:mdtSearchCitizen', function(src, cb, query)
    if not isOnDutyPolice(src) then cb({}) return end
    query = '%' .. tostring(query or ''):sub(1, 40) .. '%'
    local rows = Core.DB.All(
        [[SELECT citizenid, firstname, lastname, job, phone_number, metadata FROM characters
          WHERE (firstname LIKE ? OR lastname LIKE ? OR citizenid LIKE ?) AND deleted = 0 LIMIT 15]],
        { query, query, query })
    cb(rows)
end)

Core.Functions.CreateCallback('police:mdtSearchPlate', function(src, cb, plate)
    if not isOnDutyPolice(src) then cb(nil) return end
    plate = tostring(plate or ''):upper():sub(1, 12)
    local row = Core.DB.Single(
        [[SELECT v.plate, v.model, v.state, c.firstname, c.lastname, c.citizenid FROM vehicles v
          JOIN characters c ON c.citizenid = v.citizenid WHERE v.plate = ?]],
        { plate })
    cb(row)
end)

-- ---------------------------------------------------------------------
-- on-duty salary
-- ---------------------------------------------------------------------
CreateThread(function()
    while true do
        Wait(PoliceConfig.PayCycleMs)
        for _, entry in ipairs(Core.Functions.GetPlayers()) do
            if entry.pd.job.name == PoliceConfig.JobName and entry.pd.job.onduty then
                Core.Functions.AddMoney(entry.source, 'bank', PoliceConfig.PayPerCycle, 'salary')
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    jailTimers[source] = nil
end)
