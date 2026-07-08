DrugsConfig = {
    WeedFields = {
        { x = 2201.0, y = 5576.0, z = 53.5 },
        { x = 2214.0, y = 5589.0, z = 53.6 },
    },
    PickCooldownMs = 20000,
    PickYieldMin = 1,
    PickYieldMax = 3,
    PickAlertChance = 5, -- % chance a pickup triggers a passive police alert

    ProcessSpot = { x = 1000.0, y = -3190.0, z = -39.0 }, -- underground / low-traffic
    ProcessDurationMs = 8000,
    ProcessRatio = 2, -- N raw -> 1 processed

    SellSpot = { x = 1091.0, y = -3159.0, z = -39.0 },
    SellAlertChance = 15,

    GangStashMaxWeight = 80000,
    GangStashMaxSlots = 50,

    InteractDistance = 3.0,
}
