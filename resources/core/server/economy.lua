-- All money mutation MUST go through these functions. Never let another
-- resource write Core.Players[src].money directly — this is the single
-- choke point where we validate amounts and keep the DB/transaction log
-- in sync, which is what prevents money-duplication exploits.

local MAX_WALLET = 5000000000

local function syncMoney(src)
    local pd = Core.Players[src]
    if not pd then return end
    TriggerClientEvent('core:client:updateMoney', src, pd.money)
end

--- @param moneytype 'cash' | 'bank'
function Core.Functions.GetMoney(src, moneytype)
    local pd = Core.Players[src]
    if not pd then return 0 end
    return pd.money[moneytype] or 0
end

function Core.Functions.AddMoney(src, moneytype, amount, reason)
    local pd = Core.Players[src]
    if not pd then return false end
    if not Utils.IsValidAmount(amount, MAX_WALLET) then return false end
    if moneytype ~= 'cash' and moneytype ~= 'bank' then return false end

    pd.money[moneytype] = Utils.Clamp((pd.money[moneytype] or 0) + amount, 0, MAX_WALLET)
    syncMoney(src)

    if moneytype == 'bank' then
        DB.Insert('INSERT INTO bank_transactions (citizenid, type, amount, balance_after, note) VALUES (?, ?, ?, ?, ?)',
            { pd.citizenid, reason or 'deposit', amount, pd.money.bank, reason or '' })
    end
    return true
end

function Core.Functions.RemoveMoney(src, moneytype, amount, reason)
    local pd = Core.Players[src]
    if not pd then return false end
    if not Utils.IsValidAmount(amount, MAX_WALLET) then return false end
    if moneytype ~= 'cash' and moneytype ~= 'bank' then return false end

    local current = pd.money[moneytype] or 0
    if current < amount then
        return false -- insufficient funds, refuse silently (caller should check + notify)
    end

    pd.money[moneytype] = current - amount
    syncMoney(src)

    if moneytype == 'bank' then
        local txType = reason == 'transfer' and 'transfer_out' or (reason or 'withdraw')
        DB.Insert('INSERT INTO bank_transactions (citizenid, type, amount, balance_after, note) VALUES (?, ?, ?, ?, ?)',
            { pd.citizenid, txType, amount, pd.money.bank, reason or '' })
    end
    return true
end

--- Atomic-ish transfer between two ONLINE or OFFLINE citizenids (bank only).
--- Offline transfers hit the DB directly since there's no in-memory cache.
function Core.Functions.TransferBankByCitizenId(fromCitizenId, toCitizenId, amount)
    if not Utils.IsValidAmount(amount, MAX_WALLET) then return false, 'invalid_amount' end
    if fromCitizenId == toCitizenId then return false, 'same_account' end

    local fromRow = DB.Single('SELECT bank FROM characters WHERE citizenid = ? AND deleted = 0', { fromCitizenId })
    if not fromRow then return false, 'sender_not_found' end
    if fromRow.bank < amount then return false, 'insufficient_funds' end

    local toRow = DB.Single('SELECT bank FROM characters WHERE citizenid = ? AND deleted = 0', { toCitizenId })
    if not toRow then return false, 'recipient_not_found' end

    local newFromBalance = fromRow.bank - amount
    local newToBalance = toRow.bank + amount

    DB.Update('UPDATE characters SET bank = ? WHERE citizenid = ?', { newFromBalance, fromCitizenId })
    DB.Update('UPDATE characters SET bank = ? WHERE citizenid = ?', { newToBalance, toCitizenId })

    DB.Insert('INSERT INTO bank_transactions (citizenid, type, amount, balance_after, note) VALUES (?, ?, ?, ?, ?)',
        { fromCitizenId, 'transfer_out', amount, newFromBalance, 'Vers ' .. toCitizenId })
    DB.Insert('INSERT INTO bank_transactions (citizenid, type, amount, balance_after, note) VALUES (?, ?, ?, ?, ?)',
        { toCitizenId, 'transfer_in', amount, newToBalance, 'De ' .. fromCitizenId })

    -- keep in-memory cache in sync if either player is currently online
    for _, pd in pairs(Core.Players) do
        if pd.citizenid == fromCitizenId then
            pd.money.bank = newFromBalance
            syncMoney(pd.source)
        elseif pd.citizenid == toCitizenId then
            pd.money.bank = newToBalance
            syncMoney(pd.source)
        end
    end

    return true
end

Core.Functions.CreateCallback('core:getMoney', function(src, cb, moneytype)
    cb(Core.Functions.GetMoney(src, moneytype))
end)
