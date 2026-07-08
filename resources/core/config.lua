Config = {}

-- =====================================================================
-- GENERAL
-- =====================================================================
Config.ServerName        = 'Track-IA RP'
Config.Locale            = 'fr'
Config.MaxCharacterSlots = 3

-- Starting money for a brand-new character
Config.StartingCash      = 500
Config.StartingBank      = 2500

-- Default spawn (Legion Square, Los Santos) used for first-time spawn only
Config.DefaultSpawn      = { x = 195.62, y = -933.84, z = 30.69, heading = 0.0 }

-- =====================================================================
-- SESSION / SAVE
-- =====================================================================
Config.AutosaveIntervalMs = 5 * 60 * 1000   -- autosave every 5 minutes
Config.KickOnDbFailure    = true            -- refuse join if DB unreachable (data-loss guard)

-- =====================================================================
-- WHITELIST / ACCESS (toggle when you go live vs. during closed testing)
-- =====================================================================
Config.WhitelistEnabled  = false
Config.RequireDiscord    = true             -- deferrals fail if no discord identifier present

-- =====================================================================
-- ANTI-CHEAT THRESHOLDS (used by the admin resource, exposed here so
-- every resource shares one source of truth)
-- =====================================================================
Config.AntiCheat = {
    maxSpeedKmh          = 400,   -- flag if a vehicle exceeds this (super car top end ~350)
    maxHealthRegenPerSec = 5,
    teleportDistanceFlag = 150.0, -- studs moved between two ticks without a known trigger
}

-- =====================================================================
-- MONETIZATION HOOKS (read by shop / donator perks resources)
-- =====================================================================
Config.DonatorPerks = {
    [1] = { label = 'Bronze', extraCharSlot = 1, weightBonus = 0 },
    [2] = { label = 'Silver', extraCharSlot = 2, weightBonus = 5 },
    [3] = { label = 'Gold',   extraCharSlot = 3, weightBonus = 10, vehicleSlotBonus = 2 },
}
