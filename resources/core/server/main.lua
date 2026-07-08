-- Session bootstrap: connecting deferrals (ban/whitelist/DB health),
-- identifier resolution, autosave loop, graceful shutdown save.

math.randomseed(GetGameTimer())

local identifiers = {} -- [source] = license identifier, cached for the session

function Core.GetIdentifier(src)
    return identifiers[tonumber(src)]
end

-- ---------------------------------------------------------------------
-- Connection flow
-- ---------------------------------------------------------------------
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    deferrals.defer()

    Wait(0) -- required by FiveM before defer messages can be sent

    local license, discord, steam
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:find('license:') then license = id end
        if id:find('discord:') then discord = id end
        if id:find('steam:') then steam = id end
    end

    if not license then
        deferrals.done('Impossible de récupérer votre identifiant Rockstar (license). Reconnectez-vous via le launcher Rockstar Games.')
        return
    end

    if Config.RequireDiscord and not discord then
        deferrals.done('Discord introuvable. Liez votre compte Discord à FiveM (Paramètres > Liaisons de compte Rockstar/Réseaux sociaux) puis reconnectez-vous.')
        return
    end

    deferrals.update('Vérification de votre compte...')

    if not DB.Ping() then
        if Config.KickOnDbFailure then
            deferrals.done(_T('db_unreachable'))
            return
        end
    end

    local row = DB.Single('SELECT * FROM players WHERE identifier = ?', { license })
    if row then
        local activeBan = DB.Scalar(
            'SELECT COUNT(*) FROM players WHERE identifier = ? AND banned = 1 AND (ban_expire IS NULL OR ban_expire > NOW())',
            { license })
        if activeBan and activeBan > 0 then
            deferrals.done(_T('banned') .. (row.ban_reason and (' Raison: ' .. row.ban_reason) or ''))
            return
        elseif row.banned == 1 then
            -- ban expired: clear the flag so we don't re-check every join
            DB.Update('UPDATE players SET banned = 0, ban_reason = NULL, ban_expire = NULL WHERE identifier = ?', { license })
        end
        if Config.WhitelistEnabled and row.whitelisted ~= 1 then
            deferrals.done(_T('whitelist_closed'))
            return
        end
        DB.Update('UPDATE players SET name = ?, discord = ?, steam = ?, last_seen = NOW() WHERE identifier = ?',
            { name, discord, steam, license })
    else
        if Config.WhitelistEnabled then
            deferrals.done(_T('whitelist_closed'))
            return
        end
        DB.Insert('INSERT INTO players (identifier, discord, steam, name) VALUES (?, ?, ?, ?)',
            { license, discord, steam, name })
    end

    identifiers[src] = license
    deferrals.done()
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    Core.Functions.SavePlayer(src)
    Core.Players[src] = nil
    identifiers[src] = nil
end)

-- ---------------------------------------------------------------------
-- Autosave
-- ---------------------------------------------------------------------
CreateThread(function()
    while true do
        Wait(Config.AutosaveIntervalMs)
        Core.Functions.SaveAllPlayers()
    end
end)

-- Save everyone if the resource restarts or the server shuts down
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    Core.Functions.SaveAllPlayers()
end)

AddEventHandler('txAdmin:events:serverShuttingDown', function()
    Core.Functions.SaveAllPlayers()
end)

-- ---------------------------------------------------------------------
-- Boot-time DB health check (log loudly, don't crash the resource)
-- ---------------------------------------------------------------------
CreateThread(function()
    Wait(1000)
    if DB.Ping() then
        print('^2[core]^7 Connexion base de données OK.')
    else
        print('^1[core] ERREUR: impossible de joindre la base de données. Vérifiez oxmysql / mysql_connection_string dans server.cfg.^7')
    end
end)

exports('GetCoreObject', function()
    return Core
end)
