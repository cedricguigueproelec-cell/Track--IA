local Core = exports.core:GetCoreObject()

local ATM_MODELS = {
    `prop_atm_01`, `prop_atm_02`, `prop_atm_03`, `prop_fleeca_atm`,
}

local isOpen = false

local function openUI()
    if isOpen or not IsPlayerLoaded then return end
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
    Core.Functions.TriggerCallback('banking:getAccountInfo', function(data)
        SendNUIMessage({ action = 'state', data = data })
    end)
end

local function closeUI()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

exports('OpenBankApp', openUI)

RegisterNetEvent('banking:client:refresh', function()
    if not isOpen then return end
    Core.Functions.TriggerCallback('banking:getAccountInfo', function(data)
        SendNUIMessage({ action = 'state', data = data })
    end)
end)

RegisterNUICallback('close', function(_, cb) closeUI() cb('ok') end)
RegisterNUICallback('deposit', function(data, cb) TriggerServerEvent('banking:server:deposit', tonumber(data.amount)) cb('ok') end)
RegisterNUICallback('withdraw', function(data, cb) TriggerServerEvent('banking:server:withdraw', tonumber(data.amount)) cb('ok') end)
RegisterNUICallback('transfer', function(data, cb) TriggerServerEvent('banking:server:transfer', tostring(data.phone), tonumber(data.amount)) cb('ok') end)

CreateThread(function()
    while true do
        Wait(500)
        if not IsPlayerLoaded then goto continue end

        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local found = false

        for _, model in ipairs(ATM_MODELS) do
            local obj = GetClosestObjectOfType(coords.x, coords.y, coords.z, 1.5, model, false, false, false)
            if obj ~= 0 then
                found = true
                break
            end
        end

        if found then
            BeginTextCommandDisplayHelp('STRING')
            AddTextComponentSubstringPlayerName('~INPUT_CONTEXT~ Utiliser le distributeur')
            EndTextCommandDisplayHelp(0, false, true, -1)
            if IsControlJustPressed(0, 38) then
                openUI()
            end
        end

        ::continue::
    end
end)

