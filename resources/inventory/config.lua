Config = Config or {}

Config.PlayerMaxWeight = 30000  -- grams (30kg)
Config.PlayerMaxSlots  = 41

Config.TrunkMaxWeight = { default = 60000, van = 120000, suv = 90000 }
Config.TrunkMaxSlots  = 40

Config.GloveboxMaxWeight = 5000
Config.GloveboxMaxSlots  = 5

Config.DropDespawnMs = 10 * 60 * 1000 -- ground items disappear after 10 min
Config.MaxDropDistance = 2.5          -- studs, server-side proximity check
