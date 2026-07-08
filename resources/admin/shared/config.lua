AdminConfig = {
    -- ACE permission checked outside of RegisterCommand's own restriction,
    -- e.g. for deciding who receives anti-cheat alerts.
    AcePermission = 'trackia.admin',

    AntiCheat = {
        Enabled = true,
        AutoKick = false,       -- if true, auto-kicks after MaxFlags within FlagWindowMs
        MaxFlags = 5,
        FlagWindowMs = 60000,
        SpeedCheckIntervalMs = 3000,
        TeleportGraceMs = 4000, -- suppress speed/teleport flags for a moment after a legit server-side teleport
    },
}
