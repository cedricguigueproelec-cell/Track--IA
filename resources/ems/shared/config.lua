EmsConfig = {
    JobName = 'ems',
    Grades = { [0] = 'Stagiaire', [1] = 'Ambulancier', [2] = 'Infirmier', [3] = 'Médecin', [4] = 'Médecin-Chef' },
    BossGrade = 4,

    Station = { x = 295.5, y = -584.9, z = 43.2, heading = 340.0 },
    DutyMarker = { x = 308.0, y = -595.0, z = 43.2 },
    SupplyMarker = { x = 316.0, y = -600.0, z = 43.2 },
    VehicleSpawn = { x = 294.6, y = -604.0, z = 43.2, heading = 70.0 },

    SupplyItems = {
        { item = 'bandage', label = 'Bandage', amount = 5 },
        { item = 'medkit', label = 'Kit médical', amount = 2 },
    },

    Vehicles = {
        { label = 'Ambulance', model = 'ambulance', minGrade = 0 },
    },

    RevivePrice = 0,           -- EMS revives are free for the patient (paid via hospital bill in `medical`)
    PayPerCycle = 90,
    PayCycleMs = 15 * 60 * 1000,
}
