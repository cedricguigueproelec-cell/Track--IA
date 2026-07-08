local Core = exports.core:GetCoreObject()

local MAX_TRANSFER = 2000000

Core.Functions.CreateCallback('banking:getAccountInfo', function(src, cb)
    local pd = Core.Functions.GetPlayer(src)
    if not pd then cb(nil) return end

    local transactions = Core.DB.All(
        'SELECT type, amount, balance_after, note, created_at FROM bank_transactions WHERE citizenid = ? ORDER BY created_at DESC LIMIT 25',
        { pd.citizenid })

    cb({
        cash = pd.money.cash,
        bank = pd.money.bank,
        iban = 'TIA' .. pd.citizenid,
        transactions = transactions,
    })
end)

RegisterNetEvent('banking:server:deposit', function(amount)
    local src = source
    amount = tonumber(amount)
    if not Core.Utils.IsValidAmount(amount, MAX_TRANSFER) then return end

    if Core.Functions.GetMoney(src, 'cash') < amount then
        TriggerClientEvent('core:client:notify', src, 'error', Core.Translate('not_enough_cash'))
        return
    end

    if Core.Functions.RemoveMoney(src, 'cash', amount, 'deposit') then
        Core.Functions.AddMoney(src, 'bank', amount, 'deposit')
        TriggerClientEvent('core:client:notify', src, 'success', ('Dépôt de %s$ effectué.'):format(amount))
        TriggerClientEvent('banking:client:refresh', src)
    end
end)

RegisterNetEvent('banking:server:withdraw', function(amount)
    local src = source
    amount = tonumber(amount)
    if not Core.Utils.IsValidAmount(amount, MAX_TRANSFER) then return end

    if Core.Functions.GetMoney(src, 'bank') < amount then
        TriggerClientEvent('core:client:notify', src, 'error', Core.Translate('not_enough_bank'))
        return
    end

    if Core.Functions.RemoveMoney(src, 'bank', amount, 'withdraw') then
        Core.Functions.AddMoney(src, 'cash', amount, 'withdraw')
        TriggerClientEvent('core:client:notify', src, 'success', ('Retrait de %s$ effectué.'):format(amount))
        TriggerClientEvent('banking:client:refresh', src)
    end
end)

RegisterNetEvent('banking:server:transfer', function(targetPhone, amount)
    local src = source
    local pd = Core.Functions.GetPlayer(src)
    if not pd then return end
    amount = tonumber(amount)
    if not Core.Utils.IsValidAmount(amount, MAX_TRANSFER) then return end
    if type(targetPhone) ~= 'string' or #targetPhone < 5 then return end

    local targetRow = Core.DB.Single('SELECT citizenid FROM characters WHERE phone_number = ? AND deleted = 0', { targetPhone })
    if not targetRow then
        TriggerClientEvent('core:client:notify', src, 'error', 'Numéro de téléphone inconnu.')
        return
    end

    local ok, err = Core.Functions.TransferBankByCitizenId(pd.citizenid, targetRow.citizenid, amount)
    if ok then
        TriggerClientEvent('core:client:notify', src, 'success', ('Virement de %s$ envoyé.'):format(amount))
        TriggerClientEvent('banking:client:refresh', src)
    else
        local messages = {
            insufficient_funds = Core.Translate('not_enough_bank'),
            same_account = "Vous ne pouvez pas vous virer de l'argent à vous-même.",
            recipient_not_found = 'Destinataire introuvable.',
            invalid_amount = 'Montant invalide.',
        }
        TriggerClientEvent('core:client:notify', src, 'error', messages[err] or 'Virement impossible.')
    end
end)
