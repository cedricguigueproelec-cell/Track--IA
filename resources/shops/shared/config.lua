ShopsConfig = {
    GeneralStores = {
        { label = '24/7 Legion Square', coords = { x = 24.5, y = -1346.7, z = 29.5 } },
        { label = '24/7 Vespucci',      coords = { x = -1222.2, y = -906.8, z = 12.3 } },
    },
    GeneralStock = {
        { item = 'water_bottle', label = 'Bouteille d\'eau', price = 8 },
        { item = 'sandwich',     label = 'Sandwich',         price = 12 },
        { item = 'burger',       label = 'Burger',           price = 15 },
        { item = 'bandage',      label = 'Bandage',          price = 25 },
        { item = 'lockpick',     label = 'Crochet',          price = 60 },
        { item = 'phone',        label = 'Téléphone',        price = 0, disabled = true }, -- placeholder (already provisioned at char creation)
    },

    WeaponShops = {
        { label = 'Armurerie Ammu-Nation', coords = { x = 21.4, y = -1105.5, z = 29.8 } },
    },
    WeaponStock = {
        { item = 'weapon_pistol',       label = 'Pistolet',            price = 3500, ammoItem = 'ammo_9mm',     ammoAmount = 40 },
        { item = 'weapon_combatpistol', label = 'Pistolet de combat',  price = 5200, ammoItem = 'ammo_9mm',     ammoAmount = 40 },
        { item = 'weapon_pumpshotgun',  label = 'Fusil à pompe',       price = 9800, ammoItem = 'ammo_shotgun', ammoAmount = 16 },
        { item = 'ammo_9mm',            label = 'Munitions 9mm (x40)', price = 180 },
        { item = 'ammo_shotgun',        label = 'Cartouches (x16)',    price = 220 },
    },

    ClothingShops = {
        { label = 'Suburban', coords = { x = 123.6, y = -223.4, z = 54.6 } },
    },
    Outfits = {
        { label = 'Tenue Casual', price = 250, gender = 0,
          components = { { component_id = 11, drawable = 24, texture = 0 }, { component_id = 4, drawable = 12, texture = 0 } } },
        { label = 'Tenue Business', price = 650, gender = 0,
          components = { { component_id = 11, drawable = 39, texture = 0 }, { component_id = 4, drawable = 33, texture = 0 } } },
        { label = 'Tenue Casual', price = 250, gender = 1,
          components = { { component_id = 11, drawable = 14, texture = 0 }, { component_id = 4, drawable = 15, texture = 0 } } },
        { label = 'Tenue Soirée', price = 720, gender = 1,
          components = { { component_id = 11, drawable = 34, texture = 1 }, { component_id = 4, drawable = 8, texture = 0 } } },
    },

    GasStations = {
        { label = 'Station Route 68', coords = { x = 49.4, y = 2778.6, z = 58.0 } },
        { label = 'Station Grove St.', coords = { x = -70.0, y = -1761.0, z = 29.5 } },
    },
    GasPricePerUnit = 2.5,

    InteractDistance = 3.0,
}
