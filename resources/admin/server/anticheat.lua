local Core = exports.core:GetCoreObject()

local lastReport = {}   -- [src] = { coords = vector3, time = ms }
local grace = {}        -- [src] = ms until which flags are suppressed
local flagCount = {}    -- [src] = { count, windowStart }

local BANNED_WEAPON_HASHES = {
    [`WEAPON_RPG`] = true,
    [`WEAPON_MINIGUN`] = true,
    [`WEAPON_RAILGUN`] = true,
    [`WEAPON_RAYPISTOL`] = true,
    [`WEAPON_RAYCARBINE`] = true,
    [`WEAPON_RAYMINIGUN`] = true,
}

--- Other resources call this right before a legitimate server-driven
--- teleport (jail, hospital respawn, admin /goto) to avoid a false flag.
exports('SetTeleportGrace', function(src)
    grace[src] = GetGameTimer() + AdminConfig.AntiCheat.TeleportGraceMs
end)

local function logFlag(src, type, details)
    local pd = Core.Functions.GetPlayer(src)
    Core.DB.Insert('INSERT INTO anticheat_flags (identifier, citizenid, type, details) VALUES (?, ?, ?, ?)',
        { Core.GetIdentifier(src), pd and pd.citizenid or nil, type, details or '' })

    for _, entry in ipairs(Core.Functions.GetPlayers()) do
        if IsPlayerAceAllowed(entry.source, AdminConfig.AcePermission) then
            TriggerClientEvent('chat:addMessage', entry.source, {
                color = { 255, 80, 80 },
                args = { '[ANTICHEAT]', ('%s — %s (%s)'):format(GetPlayerName(src) or src, type, details or '') },
            })
        end
    end

    if not AdminConfig.AntiCheat.AutoKick then return end
    local now = GetGameTimer()
    local bucket = flagCount[src]
    if not bucket or (now - bucket.windowStart) > AdminConfig.AntiCheat.FlagWindowMs then
        bucket = { count = 0, windowStart = now }
        flagCount[src] = bucket
    end
    bucket.count = bucket.count + 1
    if bucket.count >= AdminConfig.AntiCheat.MaxFlags then
        DropPlayer(src, 'Déconnecté automatiquement: activité suspecte répétée détectée par l\'anti-cheat.')
    end
end

RegisterNetEvent('admin:server:posReport', function(coords, reportedSpeedKmh)
    local src = source
    if not AdminConfig.AntiCheat.Enabled then return end
    if not Core.Functions.GetPlayer(src) then return end

    local now = GetGameTimer()
    local inGrace = grace[src] and now < grace[src]

    local prev = lastReport[src]
    lastReport[src] = { coords = coords, time = now }

    if not prev or inGrace then return end

    local dt = (now - prev.time) / 1000.0
    if dt <= 0 then return end
    local dist = #(vector3(coords.x, coords.y, coords.z) - vector3(prev.coords.x, prev.coords.y, prev.coords.z))
    local speedKmh = (dist / dt) * 3.6

    if speedKmh > (Core.Config.AntiCheat.maxSpeedKmh or 400) then
        logFlag(src, 'speed_or_teleport', ('%.0f km/h implicite'):format(speedKmh))
    end

    if reportedSpeedKmh and reportedSpeedKmh > (Core.Config.AntiCheat.maxSpeedKmh or 400) + 50 then
        logFlag(src, 'speed', ('vitesse véhicule signalée: %.0f km/h'):format(reportedSpeedKmh))
    end
end)

RegisterNetEvent('admin:server:weaponReport', function(weaponHash)
    local src = source
    if not AdminConfig.AntiCheat.Enabled then return end
    if BANNED_WEAPON_HASHES[weaponHash] then
        logFlag(src, 'weapon', 'arme interdite détectée: ' .. tostring(weaponHash))
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    lastReport[src] = nil
    grace[src] = nil
    flagCount[src] = nil
end)
