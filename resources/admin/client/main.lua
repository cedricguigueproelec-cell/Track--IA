local noclipEnabled = false

RegisterNetEvent('admin:client:teleport', function(coords)
    local ped = PlayerPedId()
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
end)

RegisterNetEvent('admin:client:toggleNoclip', function()
    noclipEnabled = not noclipEnabled
    local ped = PlayerPedId()
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, not noclipEnabled, true)
    FreezeEntityPosition(ped, false)
end)

CreateThread(function()
    while true do
        Wait(0)
        if noclipEnabled then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local speed = 1.0
            if IsControlPressed(0, 21) then speed = 3.0 end -- sprint = faster

            local forward, right = 0.0, 0.0
            if IsControlPressed(0, 32) then forward = 1.0 end   -- W
            if IsControlPressed(0, 33) then forward = -1.0 end  -- S
            if IsControlPressed(0, 34) then right = -1.0 end    -- A
            if IsControlPressed(0, 35) then right = 1.0 end     -- D
            local up = 0.0
            if IsControlPressed(0, 44) then up = 1.0 end        -- Q
            if IsControlPressed(0, 20) then up = -1.0 end       -- C

            local rot = GetEntityRotation(ped, 2)
            local heading = GetEntityHeading(ped)
            local rad = math.rad(heading)
            local dx = (-math.sin(rad) * forward + math.cos(rad) * right) * speed * 0.3
            local dy = (math.cos(rad) * forward + math.sin(rad) * right) * speed * 0.3

            SetEntityCoords(ped, coords.x + dx, coords.y + dy, coords.z + up * speed * 0.3, false, false, false, false)
            SetEntityVelocity(ped, 0.0, 0.0, 0.0)
        else
            Wait(400)
        end
    end
end)

-- ---------------------------------------------------------------------
-- anti-cheat client reporting (position + weapon)
-- ---------------------------------------------------------------------
CreateThread(function()
    while true do
        Wait(3000)
        if not IsPlayerLoaded then goto continue end
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local speedKmh = nil
        if IsPedInAnyVehicle(ped, false) then
            speedKmh = GetEntitySpeed(GetVehiclePedIsIn(ped, false)) * 3.6
        end
        TriggerServerEvent('admin:server:posReport', { x = coords.x, y = coords.y, z = coords.z }, speedKmh)

        local weapon = GetSelectedPedWeapon(ped)
        if weapon and weapon ~= `WEAPON_UNARMED` then
            TriggerServerEvent('admin:server:weaponReport', weapon)
        end

        ::continue::
    end
end)
