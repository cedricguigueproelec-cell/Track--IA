local Core = exports.core:GetCoreObject()

local function isOnDutyEms(src)
    local pd = Core.Functions.GetPlayer(src)
    return pd and pd.job.name == EmsConfig.JobName and pd.job.onduty
end

RegisterNetEvent('ems:server:toggleDuty', function()
    local src = source
    local pd = Core.Functions.GetPlayer(src)
    if not pd or pd.job.name ~= EmsConfig.JobName then return end
    Core.Functions.SetDuty(src, not pd.job.onduty)
    TriggerClientEvent('core:client:notify', src, 'info', pd.job.onduty and 'En service.' or 'Hors service.')
end)

RegisterNetEvent('ems:server:revive', function(targetId)
    local src = source
    if not isOnDutyEms(src) then return end
    targetId = tonumber(targetId)
    if not targetId then return end

    local ped, targetPed = GetPlayerPed(src), GetPlayerPed(targetId)
    if ped == 0 or targetPed == 0 then return end
    if #(GetEntityCoords(ped) - GetEntityCoords(targetPed)) > 3.0 then return end

    local ok = exports.medical:Revive(targetId)
    if ok then
        Core.Functions.AddMoney(src, 'bank', 150, 'salary')
        TriggerClientEvent('core:client:notify', src, 'success', 'Patient stabilisé.')
    else
        TriggerClientEvent('core:client:notify', src, 'error', "Ce joueur n'est pas à terre.")
    end
end)

RegisterNetEvent('ems:server:heal', function(targetId)
    local src = source
    if not isOnDutyEms(src) then return end
    targetId = tonumber(targetId)
    if not targetId or not GetPlayerName(targetId) then return end

    local ped, targetPed = GetPlayerPed(src), GetPlayerPed(targetId)
    if #(GetEntityCoords(ped) - GetEntityCoords(targetPed)) > 3.0 then return end

    TriggerClientEvent('ems:client:heal', targetId)
    Core.Functions.AddMoney(src, 'bank', 60, 'salary')
    TriggerClientEvent('core:client:notify', src, 'success', 'Patient soigné.')
end)

RegisterNetEvent('ems:server:getSupplyItem', function(itemName)
    local src = source
    local pd = Core.Functions.GetPlayer(src)
    if not isOnDutyEms(src) then return end

    local entry
    for _, e in ipairs(EmsConfig.SupplyItems) do
        if e.item == itemName then entry = e break end
    end
    if not entry then return end

    if exports.inventory:AddItem(pd.citizenid, entry.item, entry.amount or 1) then
        TriggerClientEvent('core:client:notify', src, 'success', ('%s récupéré.'):format(entry.label))
    else
        TriggerClientEvent('core:client:notify', src, 'error', Core.Translate('inventory_full'))
    end
end)

CreateThread(function()
    while true do
        Wait(EmsConfig.PayCycleMs)
        for _, entry in ipairs(Core.Functions.GetPlayers()) do
            if entry.pd.job.name == EmsConfig.JobName and entry.pd.job.onduty then
                Core.Functions.AddMoney(entry.source, 'bank', EmsConfig.PayPerCycle, 'salary')
            end
        end
    end
end)
