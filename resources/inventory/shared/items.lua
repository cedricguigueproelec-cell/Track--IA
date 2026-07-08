-- Central item catalogue. Every other resource (jobs, shops, drugs...)
-- references items by this `name` key — never invent an item inline.

Items = {
    -- consumables
    water_bottle = { label = 'Bouteille d\'eau',   weight = 400,  stackable = true, type = 'drink', usable = true, effect = { thirst = 40 } },
    sandwich     = { label = 'Sandwich',           weight = 250,  stackable = true, type = 'food',  usable = true, effect = { hunger = 40 } },
    burger       = { label = 'Burger',             weight = 300,  stackable = true, type = 'food',  usable = true, effect = { hunger = 55 } },
    bandage      = { label = 'Bandage',            weight = 100,  stackable = true, type = 'medical', usable = true, effect = { health = 25 } },
    medkit       = { label = 'Kit médical',        weight = 800,  stackable = true, type = 'medical', usable = true, effect = { health = 100 } },

    -- tools
    repairkit    = { label = 'Kit de réparation',  weight = 2000, stackable = true, type = 'tool', usable = true },
    lockpick     = { label = 'Crochet',            weight = 150,  stackable = true, type = 'tool', usable = true },
    handcuffs    = { label = 'Menottes',           weight = 300,  stackable = true, type = 'tool', usable = false, jobRestricted = 'police' },
    evidence_kit = { label = 'Kit de scène de crime', weight = 500, stackable = true, type = 'tool', usable = false, jobRestricted = 'police' },

    -- documents
    id_card         = { label = 'Carte d\'identité', weight = 10, stackable = false, type = 'document', usable = false },
    driver_license  = { label = 'Permis de conduire', weight = 10, stackable = false, type = 'document', usable = false },

    -- weapons (mapped to GTA weapon hashes at use-time by the weapon shop / police armory)
    weapon_pistol        = { label = 'Pistolet',            weight = 1200, stackable = false, type = 'weapon' },
    weapon_combatpistol   = { label = 'Pistolet de combat',  weight = 1300, stackable = false, type = 'weapon' },
    weapon_pumpshotgun    = { label = 'Fusil à pompe',       weight = 3200, stackable = false, type = 'weapon' },
    weapon_smg            = { label = 'Mitraillette',        weight = 2500, stackable = false, type = 'weapon' },
    weapon_carbinerifle   = { label = 'Fusil d\'assaut',     weight = 3600, stackable = false, type = 'weapon' },
    weapon_nightstick      = { label = 'Matraque',           weight = 900,  stackable = false, type = 'weapon' },

    ammo_9mm     = { label = 'Munitions 9mm',   weight = 50, stackable = true, type = 'ammo' },
    ammo_shotgun = { label = 'Cartouches',       weight = 80, stackable = true, type = 'ammo' },
    ammo_rifle   = { label = 'Munitions fusil',  weight = 60, stackable = true, type = 'ammo' },

    -- illegal economy
    weed_seed      = { label = 'Graine de cannabis', weight = 20,  stackable = true, type = 'drug', usable = false },
    weed_raw       = { label = 'Cannabis brut',      weight = 100, stackable = true, type = 'drug', usable = false, illegal = true },
    weed_processed = { label = 'Cannabis conditionné', weight = 50, stackable = true, type = 'drug', usable = false, illegal = true, sellPrice = 85 },
    coke_brick     = { label = 'Brique de cocaïne',  weight = 500, stackable = true, type = 'drug', usable = false, illegal = true, sellPrice = 950 },
    meth_bag       = { label = 'Sachet de méthamphétamine', weight = 80, stackable = true, type = 'drug', usable = false, illegal = true, sellPrice = 180 },

    -- valuables / heist loot
    gold_bar = { label = 'Lingot d\'or', weight = 1000, stackable = true, type = 'valuable', usable = false, sellPrice = 5200 },
    rolex    = { label = 'Montre de luxe', weight = 200, stackable = true, type = 'valuable', usable = false, sellPrice = 1800 },
    cash_bundle = { label = 'Liasse de billets', weight = 100, stackable = true, type = 'valuable', usable = true, effect = { cash = 500 } },
}

function GetItemDefinition(name)
    return Items[name]
end
