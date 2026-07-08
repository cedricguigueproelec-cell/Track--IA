-- Bootstraps the client on join: freezes the player in a black loading
-- screen, asks the server for the character list, then (once the
-- `multichar` resource reports a selection) spawns the ped at the
-- character's saved position.

local spawned = false

local function freezePlayer(state)
    local ped = PlayerPedId()
    SetEntityVisible(ped, not state, false)
    FreezeEntityPosition(ped, state)
    SetPlayerControl(PlayerId(), not state, 0)
    DisplayRadar(not state)
end

local function applyOutfit(ped, skin)
    if not skin or not skin.components then return end
    for _, c in ipairs(skin.components) do
        SetPedComponentVariation(ped, c.component_id, c.drawable, c.texture or 0, 2)
    end
    if skin.props then
        for _, p in ipairs(skin.props) do
            SetPedPropIndex(ped, p.prop_id, p.drawable, p.texture or 0, true)
        end
    end
end

RegisterNetEvent('core:client:updateSkin', function(skin)
    applyOutfit(PlayerPedId(), skin)
end)

local function applyPedModel(gender)
    local model = gender == 1 and `mp_f_freemode_01` or `mp_m_freemode_01`
    RequestModel(model)
    local tries = 0
    while not HasModelLoaded(model) and tries < 200 do
        Wait(10)
        tries = tries + 1
    end
    if HasModelLoaded(model) then
        SetPlayerModel(PlayerId(), model)
        SetModelAsNoLongerNeeded(model)
    end
end

CreateThread(function()
    Wait(500)
    freezePlayer(true)
    DoScreenFadeOut(0)
    TriggerServerEvent('core:server:requestCharacters')
end)

RegisterNetEvent('core:client:receiveCharacters', function(characters, maxSlots)
    TriggerEvent('multichar:client:openUI', characters, maxSlots)
end)

RegisterNetEvent('core:client:playerLoaded', function(pd)
    CreateThread(function()
        applyPedModel(pd.charinfo.gender)

        local ped = PlayerPedId()
        local pos = pd.position or Config.DefaultSpawn
        SetEntityCoordsNoOffset(ped, pos.x, pos.y, pos.z, false, false, false)
        SetEntityHeading(ped, pos.heading or 0.0)

        local meta = pd.metadata or {}
        SetEntityHealth(ped, meta.health or 200)
        SetPedArmour(ped, meta.armor or 0)

        NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z, pos.heading or 0.0, true, false)
        ClearPedTasksImmediately(ped)
        applyOutfit(ped, pd.skin)

        Wait(300)
        freezePlayer(false)
        DoScreenFadeIn(500)
        TriggerEvent('multichar:client:closeUI')
        spawned = true
    end)
end)

-- Re-enter multichar flow if the resource restarts mid-session (dev convenience)
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() and spawned then
        freezePlayer(false)
    end
end)
