local uiOpen = false

RegisterNetEvent('multichar:client:openUI', function(characters, maxSlots)
    uiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        characters = characters,
        maxSlots = maxSlots,
    })
end)

RegisterNetEvent('multichar:client:closeUI', function()
    if not uiOpen then return end
    uiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end)

RegisterNUICallback('selectCharacter', function(data, cb)
    TriggerServerEvent('core:server:selectCharacter', data.citizenid)
    cb('ok')
end)

RegisterNUICallback('createCharacter', function(data, cb)
    TriggerServerEvent('core:server:createCharacter', data)
    cb('ok')
end)

RegisterNUICallback('deleteCharacter', function(data, cb)
    TriggerServerEvent('core:server:deleteCharacter', data.citizenid)
    cb('ok')
end)
