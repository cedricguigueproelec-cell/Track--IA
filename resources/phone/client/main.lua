local Core = exports.core:GetCoreObject()
local isOpen = false

local function openPhone()
    if isOpen or not IsPlayerLoaded then return end
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
    Core.Functions.TriggerCallback('phone:getProfile', function(profile)
        SendNUIMessage({ action = 'profile', data = profile })
    end)
end

local function closePhone()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterCommand('phone', function() openPhone() end, false)
RegisterKeyMapping('phone', 'Ouvrir/Fermer le téléphone', 'keyboard', 'M')

RegisterNUICallback('close', function(_, cb) closePhone() cb('ok') end)

RegisterNUICallback('getContacts', function(_, cb)
    Core.Functions.TriggerCallback('phone:getContacts', function(rows) cb(rows) end)
end)
RegisterNUICallback('addContact', function(data, cb)
    TriggerServerEvent('phone:server:addContact', data.name, data.number)
    cb('ok')
end)
RegisterNUICallback('removeContact', function(data, cb)
    TriggerServerEvent('phone:server:removeContact', data.id)
    cb('ok')
end)
RegisterNetEvent('phone:client:refreshContacts', function()
    Core.Functions.TriggerCallback('phone:getContacts', function(rows)
        SendNUIMessage({ action = 'contacts', data = rows })
    end)
end)

RegisterNUICallback('getConversations', function(_, cb)
    Core.Functions.TriggerCallback('phone:getConversations', function(rows) cb(rows) end)
end)
RegisterNUICallback('getMessages', function(data, cb)
    Core.Functions.TriggerCallback('phone:getMessages', function(rows, myNumber) cb({ rows = rows, myNumber = myNumber }) end, data.withNumber)
end)
RegisterNUICallback('sendMessage', function(data, cb)
    TriggerServerEvent('phone:server:sendMessage', data.to, data.message)
    cb('ok')
end)
RegisterNetEvent('phone:client:newMessage', function(fromNumber, message)
    SendNUIMessage({ action = 'incomingMessage', from = fromNumber, message = message })
    if GetResourceState('hud') == 'started' then
        exports.hud:Notify('info', 'Nouveau message de ' .. fromNumber)
    end
end)

RegisterNUICallback('openBank', function(_, cb)
    closePhone()
    if GetResourceState('banking') == 'started' then
        exports.banking:OpenBankApp()
    end
    cb('ok')
end)

RegisterNUICallback('call911', function(data, cb)
    TriggerServerEvent('dispatch:server:call911', data.message)
    cb('ok')
end)
