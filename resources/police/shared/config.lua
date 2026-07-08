PoliceConfig = {
    JobName = 'police',

    Grades = {
        [0] = 'Cadet',
        [1] = 'Officier',
        [2] = 'Sergent',
        [3] = 'Lieutenant',
        [4] = 'Chef de la Police',
    },
    BossGrade = 4, -- can hire/fire/manage the roster

    Station = { x = 425.1, y = -979.5, z = 30.7, heading = 90.0 },
    DutyMarker = { x = 452.6, y = -980.0, z = 30.7 },
    ArmoryMarker = { x = 462.5, y = -984.0, z = 30.7 },
    VehicleSpawn = { x = 441.9, y = -1017.0, z = 28.6, heading = 0.0 },

    JailCoords = { x = 1846.0, y = 2585.0, z = 45.6, heading = 90.0 },
    JailReleaseCoords = { x = 1857.0, y = 2585.0, z = 45.6, heading = 270.0 },

    ArmoryItems = {
        { item = 'weapon_nightstick', label = 'Matraque' },
        { item = 'weapon_pistol', label = 'Pistolet de service' },
        { item = 'weapon_combatpistol', label = 'Pistolet de combat (Sergent+)', minGrade = 2 },
        { item = 'weapon_pumpshotgun', label = 'Fusil à pompe (Lieutenant+)', minGrade = 3 },
        { item = 'weapon_smg', label = 'Mitraillette (Lieutenant+)', minGrade = 3 },
        { item = 'ammo_9mm', label = 'Munitions 9mm', amount = 60 },
        { item = 'ammo_shotgun', label = 'Cartouches', amount = 20 },
        { item = 'handcuffs', label = 'Menottes', amount = 3 },
        { item = 'evidence_kit', label = 'Kit de scène de crime' },
    },

    Vehicles = {
        { label = 'Police Cruiser', model = 'police', minGrade = 0 },
        { label = 'Police Buffalo', model = 'police2', minGrade = 1 },
        { label = 'FIB Interceptor', model = 'police3', minGrade = 3 },
    },

    PayPerCycle = 85,       -- paid while on duty, see server pay loop
    PayCycleMs = 15 * 60 * 1000,
}
