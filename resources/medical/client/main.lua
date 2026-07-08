local isDowned = false
local canRespawn = false

local function goDowned()
    if isDowned then return end
    isDowned = true
    LocalPlayer.state:set('downed', true, true)
    local ped = PlayerPedId()
    SetEntityHealth(ped, 105) -- keep just above the game's own death threshold, we own the state now
    ClearPedTasksImmediately(ped)
    SetPedToRagdoll(ped, 5000, 5000, 0, false, false, false)
    TriggerServerEvent('medical:server:playerDowned')
    SendNUIMessage({ action = 'downed', seconds = MedicalConfig.BleedOutSeconds })
end

CreateThread(function()
    while true do
        Wait(500)
        if IsPlayerLoaded and not isDowned then
            local ped = PlayerPedId()
            if not IsEntityDead(ped) and GetEntityHealth(ped) <= 105 and GetEntityHealth(ped) > 0 then
                goDowned()
            elseif IsEntityDead(ped) then
                goDowned()
            end
        elseif isDowned then
            -- keep the ped ragdolled/incapacitated while downed
            local ped = PlayerPedId()
            if not IsPedRagdoll(ped) and not IsEntityPlayingAnim(ped, 'dead', 'dead_a', 3) then
                SetPedToRagdoll(ped, 1500, 1500, 0, false, false, false)
            end
            DisableControlAction(0, 21, true)  -- sprint
            DisableControlAction(0, 24, true)  -- attack
            DisableControlAction(0, 25, true)  -- aim
            DisableControlAction(0, 47, true)  -- weapon
            DisableControlAction(0, 58, true)  -- weapon
        end
    end
end)

RegisterNetEvent('medical:client:downed', function(seconds)
    isDowned = true
    canRespawn = false
    SendNUIMessage({ action = 'downed', seconds = seconds })
    SetTimeout(seconds * 1000, function()
        canRespawn = true
        SendNUIMessage({ action = 'canRespawn' })
    end)
end)

RegisterNetEvent('medical:client:revived', function(healAmount)
    isDowned = false
    canRespawn = false
    LocalPlayer.state:set('downed', false, true)
    local ped = PlayerPedId()
    ClearPedTasksImmediately(ped)
    SetEntityHealth(ped, math.min(200, 100 + healAmount))
    SendNUIMessage({ action = 'clear' })
end)

RegisterNetEvent('medical:client:hospitalRespawn', function(coords, health)
    isDowned = false
    canRespawn = false
    LocalPlayer.state:set('downed', false, true)
    local ped = PlayerPedId()
    DoScreenFadeOut(400)
    Wait(500)
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, coords.heading or 0.0, true, false)
    SetEntityHealth(ped, health)
    ClearPedTasksImmediately(ped)
    Wait(300)
    DoScreenFadeIn(500)
    SendNUIMessage({ action = 'clear' })
    TriggerServerEvent('core:server:setMetaData', 'hunger', 60)
end)

RegisterNUICallback('requestRespawn', function(_, cb)
    if canRespawn then
        TriggerServerEvent('medical:server:respawnAtHospital')
    end
    cb('ok')
end)

-- ---------------------------------------------------------------------
-- rescuing a nearby downed player
-- ---------------------------------------------------------------------
CreateThread(function()
    while true do
        Wait(400)
        if isDowned or not IsPlayerLoaded then goto continue end

        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local closest, closestDist = nil, MedicalConfig.RescueDistance

        for _, playerId in ipairs(GetActivePlayers()) do
            if playerId ~= PlayerId() then
                local targetPed = GetPlayerPed(playerId)
                local dist = #(coords - GetEntityCoords(targetPed))
                local sid = GetPlayerServerId(playerId)
                if dist < closestDist and Player(sid).state.downed then
                    closest, closestDist = playerId, dist
                end
            end
        end

        if closest then
            BeginTextCommandDisplayHelp('STRING')
            AddTextComponentSubstringPlayerName('~INPUT_CONTEXT~ Secourir avec un bandage')
            EndTextCommandDisplayHelp(0, false, true, -1)
            if IsControlJustPressed(0, 38) then
                TriggerServerEvent('medical:server:reviveRequest', GetPlayerServerId(closest), 'bandage')
            end
        end

        ::continue::
    end
end)
