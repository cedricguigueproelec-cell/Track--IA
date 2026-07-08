local Core = exports.core:GetCoreObject()

local function logAdmin(src, action, details)
    Core.DB.Insert('INSERT INTO admin_logs (admin_identifier, target_identifier, action, details) VALUES (?, ?, ?, ?)',
        { Core.GetIdentifier(src), nil, action, details or '' })
end

RegisterCommand('kick', function(src, args)
    local targetId = tonumber(args[1])
    local reason = table.concat(args, ' ', 2) or 'Aucune raison précisée.'
    if not targetId or not GetPlayerName(targetId) then return end
    logAdmin(src, 'kick', ('#%d: %s'):format(targetId, reason))
    DropPlayer(targetId, ('Expulsé par un administrateur: %s'):format(reason))
end, true)

RegisterCommand('ban', function(src, args)
    local targetId = tonumber(args[1])
    local reason = table.concat(args, ' ', 2) or 'Aucune raison précisée.'
    if not targetId or not GetPlayerName(targetId) then return end

    local identifier = Core.GetIdentifier(targetId)
    Core.DB.Update('UPDATE players SET banned = 1, ban_reason = ?, ban_expire = NULL WHERE identifier = ?', { reason, identifier })
    logAdmin(src, 'ban', ('%s: %s'):format(identifier, reason))
    DropPlayer(targetId, ('Vous êtes banni: %s'):format(reason))
end, true)

RegisterCommand('tempban', function(src, args)
    local targetId = tonumber(args[1])
    local minutes = tonumber(args[2])
    local reason = table.concat(args, ' ', 3) or 'Aucune raison précisée.'
    if not targetId or not minutes or not GetPlayerName(targetId) then return end

    local identifier = Core.GetIdentifier(targetId)
    Core.DB.Update('UPDATE players SET banned = 1, ban_reason = ?, ban_expire = DATE_ADD(NOW(), INTERVAL ? MINUTE) WHERE identifier = ?',
        { reason, minutes, identifier })
    logAdmin(src, 'tempban', ('%s: %d min - %s'):format(identifier, minutes, reason))
    DropPlayer(targetId, ('Vous êtes banni temporairement (%d min): %s'):format(minutes, reason))
end, true)

RegisterCommand('unban', function(src, args)
    local identifier = args[1]
    if not identifier then return end
    Core.DB.Update('UPDATE players SET banned = 0, ban_reason = NULL, ban_expire = NULL WHERE identifier = ?', { identifier })
    logAdmin(src, 'unban', identifier)
    TriggerClientEvent('chat:addMessage', src, { args = { 'Admin', 'Joueur débanni: ' .. identifier } })
end, true)

RegisterCommand('setjob', function(src, args)
    local targetId, jobName, grade = tonumber(args[1]), args[2], tonumber(args[3]) or 0
    if not targetId or not jobName or not GetPlayerName(targetId) then return end
    Core.Functions.SetJob(targetId, jobName, grade)
    logAdmin(src, 'setjob', ('#%d -> %s (%d)'):format(targetId, jobName, grade))
    TriggerClientEvent('core:client:notify', targetId, 'info', Core.Translate('job_set'))
end, true)

RegisterCommand('setgang', function(src, args)
    local targetId, gangName, grade = tonumber(args[1]), args[2], tonumber(args[3]) or 0
    local pd = Core.Functions.GetPlayer(targetId)
    if not pd or not gangName then return end
    pd.gang = { name = gangName, grade = grade }
    logAdmin(src, 'setgang', ('#%d -> %s (%d)'):format(targetId, gangName, grade))
end, true)

RegisterCommand('givemoney', function(src, args)
    local targetId, moneyType, amount = tonumber(args[1]), args[2], tonumber(args[3])
    if not targetId or not amount or (moneyType ~= 'cash' and moneyType ~= 'bank') then return end
    Core.Functions.AddMoney(targetId, moneyType, amount, 'admin')
    logAdmin(src, 'givemoney', ('#%d +%d %s'):format(targetId, amount, moneyType))
end, true)

RegisterCommand('giveitem', function(src, args)
    local targetId, item, amount = tonumber(args[1]), args[2], tonumber(args[3]) or 1
    local pd = Core.Functions.GetPlayer(targetId)
    if not pd or not item then return end
    exports.inventory:AddItem(pd.citizenid, item, amount)
    logAdmin(src, 'giveitem', ('#%d %sx%d'):format(targetId, item, amount))
end, true)

RegisterCommand('revive', function(src, args)
    local targetId = tonumber(args[1]) or src
    if GetResourceState('medical') == 'started' then
        exports.medical:Revive(targetId)
    end
    logAdmin(src, 'revive', tostring(targetId))
end, true)

RegisterCommand('goto', function(src, args)
    local targetId = tonumber(args[1])
    if not targetId or not GetPlayerName(targetId) then return end
    local targetPed = GetPlayerPed(targetId)
    local coords = GetEntityCoords(targetPed)
    exports.admin:SetTeleportGrace(src)
    TriggerClientEvent('admin:client:teleport', src, coords)
end, true)

RegisterCommand('bring', function(src, args)
    local targetId = tonumber(args[1])
    if not targetId or not GetPlayerName(targetId) then return end
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    exports.admin:SetTeleportGrace(targetId)
    TriggerClientEvent('admin:client:teleport', targetId, coords)
end, true)

RegisterCommand('announce', function(src, args)
    local message = table.concat(args, ' ')
    if message == '' then return end
    TriggerClientEvent('chat:addMessage', -1, {
        color = { 255, 200, 40 },
        args = { '[ANNONCE]', message },
    })
    logAdmin(src, 'announce', message)
end, true)

RegisterCommand('noclip', function(src)
    TriggerClientEvent('admin:client:toggleNoclip', src)
end, true)
