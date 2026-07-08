local Core = exports.core:GetCoreObject()

local function isOnDutyTaxi(src)
    local pd = Core.Functions.GetPlayer(src)
    return pd and pd.job.name == TaxiConfig.JobName and pd.job.onduty
end

RegisterNetEvent('taxi:server:toggleDuty', function()
    local src = source
    local pd = Core.Functions.GetPlayer(src)
    if not pd or pd.job.name ~= TaxiConfig.JobName then return end
    Core.Functions.SetDuty(src, not pd.job.onduty)
    TriggerClientEvent('core:client:notify', src, 'info', pd.job.onduty and 'En service.' or 'Hors service.')
end)

RegisterNetEvent('taxi:server:payout', function(distanceMeters)
    local src = source
    if not isOnDutyTaxi(src) then return end
    distanceMeters = tonumber(distanceMeters)
    if not distanceMeters or distanceMeters <= 0 or distanceMeters > 50000 then return end

    local fare = math.min(TaxiConfig.MaxFarePerTrip, math.floor(distanceMeters * TaxiConfig.RatePerMeter))
    if fare <= 0 then return end

    Core.Functions.AddMoney(src, 'bank', fare, 'salary')
    TriggerClientEvent('core:client:notify', src, 'success', ('Course terminée: %d$ encaissés.'):format(fare))
end)
