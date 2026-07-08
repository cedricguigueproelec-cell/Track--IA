local Core = exports.core:GetCoreObject()
local properties = {}
local blips = {}

local function money(n) return (n or 0) end

local function refreshBlips()
    for _, b in ipairs(blips) do RemoveBlip(b) end
    blips = {}
    local pd = Core.Functions.GetPlayerData()

    for _, p in ipairs(properties) do
        local blip = AddBlipForCoord(p.coords.x, p.coords.y, p.coords.z)
        SetBlipSprite(blip, 40)
        SetBlipColour(blip, (p.owner_citizenid and (pd and p.owner_citizenid == pd.citizenid and 2 or 1)) or 3)
        SetBlipScale(blip, 0.7)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(p.label)
        EndTextCommandSetBlipName(blip)
        blips[#blips + 1] = blip
    end
end

local function loadProperties()
    Core.Functions.TriggerCallback('housing:getProperties', function(rows)
        properties = rows
        refreshBlips()
    end)
end

RegisterNetEvent('core:client:onPlayerLoaded', function() loadProperties() end)
RegisterNetEvent('housing:client:refresh', function() loadProperties() end)

local function nearPoint(coords, radius)
    return #(GetEntityCoords(PlayerPedId()) - vector3(coords.x, coords.y, coords.z)) < (radius or HousingConfig.InteractDistance)
end

local function promptHelp(text, action)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
    if IsControlJustPressed(0, 38) then action() end
end

CreateThread(function()
    while true do
        Wait(300)
        if not IsPlayerLoaded then goto continue end
        local pd = Core.Functions.GetPlayerData()

        for _, p in ipairs(properties) do
            if nearPoint(p.coords) then
                if p.owner_citizenid == pd.citizenid then
                    promptHelp('~INPUT_CONTEXT~ ' .. p.label, function()
                        SetNuiFocus(true, true)
                        SendNUIMessage({ action = 'openOwned', property = p })
                    end)
                elseif not p.owner_citizenid then
                    promptHelp('~INPUT_CONTEXT~ Visiter: ' .. p.label, function()
                        SetNuiFocus(true, true)
                        SendNUIMessage({ action = 'openForSale', property = p })
                    end)
                end
            end
        end

        ::continue::
    end
end)

RegisterNUICallback('close', function(_, cb) SetNuiFocus(false, false) cb('ok') end)
RegisterNUICallback('buyProperty', function(data, cb)
    TriggerServerEvent('housing:server:buyProperty', data.id)
    SetNuiFocus(false, false)
    cb('ok')
end)
RegisterNUICallback('sellProperty', function(data, cb)
    TriggerServerEvent('housing:server:sellProperty', data.id)
    SetNuiFocus(false, false)
    cb('ok')
end)
RegisterNUICallback('openStash', function(data, cb)
    SetNuiFocus(false, false)
    TriggerServerEvent('housing:server:openStash', data.id)
    cb('ok')
end)
