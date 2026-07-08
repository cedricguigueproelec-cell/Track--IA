TaxiConfig = {
    JobName = 'taxi',
    Grades = { [0] = 'Chauffeur', [1] = 'Chauffeur Confirmé', [2] = 'Responsable Flotte' },
    BossGrade = 2,

    Depot = { x = 899.0, y = -180.0, z = 74.7, heading = 70.0 },
    DutyMarker = { x = 899.0, y = -186.0, z = 74.7 },
    VehicleSpawn = { x = 906.0, y = -180.0, z = 74.7, heading = 160.0 },
    VehicleModel = 'taxi',

    RatePerMeter = 1.35,   -- $ per meter traveled with meter running
    MaxFarePerTrip = 4000, -- server-side sanity clamp
}
