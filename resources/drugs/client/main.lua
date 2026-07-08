local Core = exports.core:GetCoreObject()

local function nearPoint(point, radius)
    return #(GetEntityCoords(PlayerPedId()) - vector3(point.x, point.y, point.z)) < (radius or DrugsConfig.InteractDistance)
end

local function nearAny(points, radius)
    for _, p in ipairs(points) do
        if nearPoint(p, radius) then return true end
    end
    return false
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

        if nearAny(DrugsConfig.WeedFields) then
            promptHelp('~INPUT_CONTEXT~ Récolter du cannabis', function()
                TriggerServerEvent('drugs:server:pick')
            end)
        end

        if nearPoint(DrugsConfig.ProcessSpot, 4.0) then
            promptHelp('~INPUT_CONTEXT~ Conditionner (2x brut -> 1x conditionné)', function()
                local ped = PlayerPedId()
                TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_HAMMERING', 0, true)
                Wait(DrugsConfig.ProcessDurationMs)
                ClearPedTasks(ped)
                Core.Functions.TriggerCallback('drugs:process', function() end)
            end)
        end

        if nearPoint(DrugsConfig.SellSpot, 4.0) then
            promptHelp('~INPUT_CONTEXT~ Vendre (/sell <objet> <quantité>)', function() end)
        end

        ::continue::
    end
end)

RegisterCommand('sell', function(_, args)
    local item, amount = args[1], tonumber(args[2]) or 1
    if not item then return end
    TriggerServerEvent('drugs:server:sell', item, amount)
end, false)

RegisterCommand('gangstash', function()
    TriggerServerEvent('drugs:server:openGangStash')
end, false)
