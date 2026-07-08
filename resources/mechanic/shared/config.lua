MechanicConfig = {
    JobName = 'mechanic',
    Grades = { [0] = 'Apprenti', [1] = 'Mécanicien', [2] = 'Mécanicien Sénior', [3] = 'Chef d\'atelier' },
    BossGrade = 3,

    Garage = { x = -347.0, y = -133.0, z = 39.0, heading = 65.0 },
    DutyMarker = { x = -347.0, y = -140.0, z = 39.0 },

    RepairDistance = 4.0,
    RepairPayout = 120,
    RepairPricePlayer = 200, -- charged to the vehicle owner if not the mechanic themself
}
