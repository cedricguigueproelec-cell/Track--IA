local Core = exports.core:GetCoreObject()

local function nearPoint(coords, radius)
    return #(GetEntityCoords(PlayerPedId()) - vector3(coords.x, coords.y, coords.z)) < (radius or ShopsConfig.InteractDistance)
end

local function promptHelp(text, action)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
    if IsControlJustPressed(0, 38) then action() end
end

CreateThread(function()
    local function addBlip(coords, sprite, color, label)
        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(blip, sprite)
        SetBlipColour(blip, color)
        SetBlipScale(blip, 0.7)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(label)
        EndTextCommandSetBlipName(blip)
    end
    for _, s in ipairs(ShopsConfig.GeneralStores) do addBlip(s.coords, 52, 2, s.label) end
    for _, s in ipairs(ShopsConfig.WeaponShops) do addBlip(s.coords, 110, 1, s.label) end
    for _, s in ipairs(ShopsConfig.ClothingShops) do addBlip(s.coords, 73, 47, s.label) end
    for _, s in ipairs(ShopsConfig.GasStations) do addBlip(s.coords, 361, 5, s.label) end
end)

CreateThread(function()
    while true do
        Wait(300)
        if not IsPlayerLoaded then goto continue end

        for _, s in ipairs(ShopsConfig.GeneralStores) do
            if nearPoint(s.coords) then
                promptHelp('~INPUT_CONTEXT~ ' .. s.label, function()
                    SetNuiFocus(true, true)
                    SendNUIMessage({ action = 'openGeneral', items = ShopsConfig.GeneralStock, label = s.label })
                end)
            end
        end

        for _, s in ipairs(ShopsConfig.WeaponShops) do
            if nearPoint(s.coords) then
                promptHelp('~INPUT_CONTEXT~ ' .. s.label, function()
                    SetNuiFocus(true, true)
                    SendNUIMessage({ action = 'openWeapons', items = ShopsConfig.WeaponStock, label = s.label })
                end)
            end
        end

        for _, s in ipairs(ShopsConfig.ClothingShops) do
            if nearPoint(s.coords) then
                promptHelp('~INPUT_CONTEXT~ ' .. s.label, function()
                    local pd = Core.Functions.GetPlayerData()
                    local gender = pd.charinfo and pd.charinfo.gender or 0
                    local outfits = {}
                    for i, o in ipairs(ShopsConfig.Outfits) do
                        if o.gender == gender then outfits[#outfits + 1] = { index = i, label = o.label, price = o.price } end
                    end
                    SetNuiFocus(true, true)
                    SendNUIMessage({ action = 'openClothing', outfits = outfits, label = s.label })
                end)
            end
        end

        for _, s in ipairs(ShopsConfig.GasStations) do
            if nearPoint(s.coords, 4.0) then
                local ped = PlayerPedId()
                if IsPedInAnyVehicle(ped, false) then
                    promptHelp('~INPUT_CONTEXT~ Faire le plein', function()
                        local veh = GetVehiclePedIsIn(ped, false)
                        local missing = 100 - GetVehicleFuelLevel(veh)
                        if missing > 1 then
                            TriggerServerEvent('shops:server:refuel', missing)
                        end
                    end)
                end
            end
        end

        ::continue::
    end
end)

RegisterNetEvent('shops:client:refuelApproved', function(units)
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        local veh = GetVehiclePedIsIn(ped, false)
        SetVehicleFuelLevel(veh, math.min(100.0, GetVehicleFuelLevel(veh) + units))
    end
end)

RegisterNUICallback('close', function(_, cb) SetNuiFocus(false, false) cb('ok') end)
RegisterNUICallback('buyGeneralItem', function(data, cb) TriggerServerEvent('shops:server:buyGeneralItem', data.item) cb('ok') end)
RegisterNUICallback('buyWeapon', function(data, cb) TriggerServerEvent('shops:server:buyWeapon', data.item) cb('ok') end)
RegisterNUICallback('buyOutfit', function(data, cb) TriggerServerEvent('shops:server:buyOutfit', data.index) cb('ok') end)
RegisterNUICallback('previewOutfit', function(data, cb)
    local index = tonumber(data.index)
    local outfit = ShopsConfig.Outfits[index]
    if outfit then
        local ped = PlayerPedId()
        for _, c in ipairs(outfit.components) do
            SetPedComponentVariation(ped, c.component_id, c.drawable, c.texture or 0, 2)
        end
    end
    cb('ok')
end)
