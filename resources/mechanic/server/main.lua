local Core = exports.core:GetCoreObject()

local function isOnDutyMechanic(src)
    local pd = Core.Functions.GetPlayer(src)
    return pd and pd.job.name == MechanicConfig.JobName and pd.job.onduty
end

RegisterNetEvent('mechanic:server:toggleDuty', function()
    local src = source
    local pd = Core.Functions.GetPlayer(src)
    if not pd or pd.job.name ~= MechanicConfig.JobName then return end
    Core.Functions.SetDuty(src, not pd.job.onduty)
    TriggerClientEvent('core:client:notify', src, 'info', pd.job.onduty and 'En service.' or 'Hors service.')
end)

Core.Functions.CreateCallback('mechanic:repairVehicle', function(src, cb)
    if not isOnDutyMechanic(src) then cb(false) return end
    local pd = Core.Functions.GetPlayer(src)

    if not exports.inventory:HasItem(pd.citizenid, 'repairkit', 1) then
        TriggerClientEvent('core:client:notify', src, 'error', 'Vous n\'avez pas de kit de réparation.')
        cb(false)
        return
    end

    exports.inventory:RemoveItem(pd.citizenid, 'repairkit', 1)
    Core.Functions.AddMoney(src, 'bank', MechanicConfig.RepairPayout, 'salary')
    cb(true)
end)
