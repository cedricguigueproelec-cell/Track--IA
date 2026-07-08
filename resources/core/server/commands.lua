-- Core roleplay utility commands available to every player.
-- Admin-only commands live in the `admin` resource (separate permission layer).

local RP_RADIUS = 15.0

local function getNearbyPlayers(src, radius)
    local ped = GetPlayerPed(src)
    if ped == 0 then return {} end
    local origin = GetEntityCoords(ped)
    local nearby = {}
    for _, playerId in ipairs(GetPlayers()) do
        local targetPed = GetPlayerPed(playerId)
        if targetPed ~= 0 then
            local dist = #(origin - GetEntityCoords(targetPed))
            if dist <= radius then
                nearby[#nearby + 1] = tonumber(playerId)
            end
        end
    end
    return nearby
end

local function sanitize(text)
    if type(text) ~= 'string' then return '' end
    text = text:gsub('<', '&lt;'):gsub('>', '&gt;')
    return text:sub(1, 200)
end

RegisterCommand('me', function(src, args)
    if src == 0 then return end
    local pd = Core.Functions.GetPlayer(src)
    if not pd then return end
    local msg = sanitize(table.concat(args, ' '))
    if msg == '' then return end

    local text = ('* %s %s'):format(pd.charinfo.firstname .. ' ' .. pd.charinfo.lastname, msg)
    for _, target in ipairs(getNearbyPlayers(src, RP_RADIUS)) do
        TriggerClientEvent('chat:addMessage', target, { color = { 200, 200, 200 }, args = { text } })
    end
end, false)

RegisterCommand('do', function(src, args)
    if src == 0 then return end
    local pd = Core.Functions.GetPlayer(src)
    if not pd then return end
    local msg = sanitize(table.concat(args, ' '))
    if msg == '' then return end

    local text = ('* %s (%s)'):format(msg, pd.charinfo.firstname .. ' ' .. pd.charinfo.lastname)
    for _, target in ipairs(getNearbyPlayers(src, RP_RADIUS)) do
        TriggerClientEvent('chat:addMessage', target, { color = { 160, 160, 220 }, args = { text } })
    end
end, false)

RegisterCommand('ooc', function(src, args)
    if src == 0 then return end
    local msg = sanitize(table.concat(args, ' '))
    if msg == '' then return end
    local text = ('[OOC] %s'):format(msg)
    for _, target in ipairs(getNearbyPlayers(src, RP_RADIUS * 2)) do
        TriggerClientEvent('chat:addMessage', target, { color = { 120, 120, 120 }, args = { text } })
    end
end, false)

RegisterCommand('id', function(src)
    if src == 0 then return end
    local pd = Core.Functions.GetPlayer(src)
    if not pd then return end
    TriggerClientEvent('chat:addMessage', src, {
        color = { 80, 200, 255 },
        args = { 'Système', ('ID serveur: %d | CitizenID: %s | Tel: %s'):format(src, pd.citizenid, pd.charinfo.phone) }
    })
end, false)
