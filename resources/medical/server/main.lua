local Core = exports.core:GetCoreObject()

local Medical = { BleedTimers = {}, Downed = {} }

local function setDowned(src, state)
    Medical.Downed[src] = state or nil
    Core.Functions.SetMetaData(src, 'isdead', state)
end

RegisterNetEvent('medical:server:playerDowned', function()
    local src = source
    local pd = Core.Functions.GetPlayer(src)
    if not pd or Medical.Downed[src] then return end

    setDowned(src, true)
    Medical.BleedTimers[src] = GetGameTimer() + (MedicalConfig.BleedOutSeconds * 1000)

    TriggerEvent('medical:playerDowned', src, pd) -- dispatch resource hooks this to alert EMS
    TriggerClientEvent('medical:client:downed', src, MedicalConfig.BleedOutSeconds)
end)

RegisterNetEvent('medical:server:reviveRequest', function(targetId, usedItem)
    local src = source
    targetId = tonumber(targetId)
    if not targetId or not Medical.Downed[targetId] then return end

    local rescuerPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(targetId)
    if rescuerPed == 0 or targetPed == 0 then return end
    if #(GetEntityCoords(rescuerPed) - GetEntityCoords(targetPed)) > MedicalConfig.RescueDistance then return end

    if usedItem then
        local removed = exports.inventory:RemoveItem(Core.Functions.GetPlayer(src) and Core.Functions.GetPlayer(src).citizenid, usedItem, 1)
        if not removed then
            TriggerClientEvent('core:client:notify', src, 'error', 'Objet de soin manquant.')
            return
        end
    end

    setDowned(targetId, false)
    Medical.BleedTimers[targetId] = nil
    TriggerClientEvent('medical:client:revived', targetId, MedicalConfig.ReviveHealAmount)
    TriggerClientEvent('core:client:notify', targetId, 'success', 'Vous avez été secouru.')
    TriggerClientEvent('core:client:notify', src, 'success', 'Réanimation réussie.')
end)

RegisterNetEvent('medical:server:respawnAtHospital', function()
    local src = source
    local pd = Core.Functions.GetPlayer(src)
    if not pd then return end

    setDowned(src, false)
    Medical.BleedTimers[src] = nil

    if Core.Functions.GetMoney(src, 'bank') >= MedicalConfig.HospitalBill then
        Core.Functions.RemoveMoney(src, 'bank', MedicalConfig.HospitalBill, 'invoice')
    end

    if GetResourceState('admin') == 'started' then exports.admin:SetTeleportGrace(src) end
    local hospital = MedicalConfig.Hospitals[1]
    TriggerClientEvent('medical:client:hospitalRespawn', src, hospital.coords, MedicalConfig.HospitalRespawnHealth)
end)

CreateThread(function()
    while true do
        Wait(2000)
        local now = GetGameTimer()
        for src, expireAt in pairs(Medical.BleedTimers) do
            if now >= expireAt and GetPlayerName(src) then
                Medical.BleedTimers[src] = nil
                setDowned(src, false)
                if Core.Functions.GetMoney(src, 'bank') >= MedicalConfig.HospitalBill then
                    Core.Functions.RemoveMoney(src, 'bank', MedicalConfig.HospitalBill, 'invoice')
                end
                if GetResourceState('admin') == 'started' then exports.admin:SetTeleportGrace(src) end
                local hospital = MedicalConfig.Hospitals[1]
                TriggerClientEvent('medical:client:hospitalRespawn', src, hospital.coords, MedicalConfig.HospitalRespawnHealth)
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    Medical.BleedTimers[src] = nil
    Medical.Downed[src] = nil
end)

exports('IsDowned', function(target) return Medical.Downed[target] == true end)

--- Free, instant, full revive — used by EMS job and admin commands.
exports('Revive', function(target)
    if not Medical.Downed[target] then return false end
    Medical.Downed[target] = nil
    Medical.BleedTimers[target] = nil
    Core.Functions.SetMetaData(target, 'isdead', false)
    TriggerClientEvent('medical:client:revived', target, 200)
    TriggerClientEvent('core:client:notify', target, 'success', 'Un médecin vous a réanimé.')
    return true
end)
