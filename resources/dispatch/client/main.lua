RegisterCommand('911', function(_, args)
    local message = table.concat(args, ' ')
    if message == '' then return end
    TriggerServerEvent('dispatch:server:call911', message)
end, false)

local BLIP_SETTINGS = {
    ['911']     = { sprite = 60, color = 1, label = '911' },
    ['medical'] = { sprite = 61, color = 1, label = 'Urgence médicale' },
    ['crime']   = { sprite = 161, color = 1, label = 'Alerte' },
}

RegisterNetEvent('dispatch:client:alert', function(data)
    local settings = BLIP_SETTINGS[data.type] or BLIP_SETTINGS['crime']

    TriggerEvent('core:client:notify', 'error', ('%s%s'):format(data.title, data.extra ~= '' and (' — ' .. data.extra) or ''))
    PlaySoundFrontend(-1, 'Text_Arrive_Tone', 'Phone_SoundSet_Default', true)

    local blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
    SetBlipSprite(blip, settings.sprite)
    SetBlipColour(blip, settings.color)
    SetBlipScale(blip, 1.0)
    SetBlipFlashes(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(settings.label)
    EndTextCommandSetBlipName(blip)

    SetTimeout(90000, function()
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end)
end)
