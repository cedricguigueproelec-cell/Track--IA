local Core = exports.core:GetCoreObject()

Core.Functions.CreateCallback('phone:getProfile', function(src, cb)
    local pd = Core.Functions.GetPlayer(src)
    if not pd then cb(nil) return end
    cb({ number = pd.charinfo.phone, name = pd.charinfo.firstname .. ' ' .. pd.charinfo.lastname })
end)

Core.Functions.CreateCallback('phone:getContacts', function(src, cb)
    local pd = Core.Functions.GetPlayer(src)
    if not pd then cb({}) return end
    cb(Core.DB.All('SELECT id, name, number FROM phone_contacts WHERE citizenid = ? ORDER BY name ASC', { pd.citizenid }))
end)

RegisterNetEvent('phone:server:addContact', function(name, number)
    local src = source
    local pd = Core.Functions.GetPlayer(src)
    if not pd then return end
    name = tostring(name or ''):sub(1, 60)
    number = tostring(number or ''):sub(1, 15)
    if name == '' or number == '' then return end
    Core.DB.Insert('INSERT INTO phone_contacts (citizenid, name, number) VALUES (?, ?, ?)', { pd.citizenid, name, number })
    TriggerClientEvent('phone:client:refreshContacts', src)
end)

RegisterNetEvent('phone:server:removeContact', function(id)
    local src = source
    local pd = Core.Functions.GetPlayer(src)
    if not pd then return end
    Core.DB.Execute('DELETE FROM phone_contacts WHERE id = ? AND citizenid = ?', { id, pd.citizenid })
    TriggerClientEvent('phone:client:refreshContacts', src)
end)

Core.Functions.CreateCallback('phone:getConversations', function(src, cb)
    local pd = Core.Functions.GetPlayer(src)
    if not pd or not pd.charinfo.phone then cb({}) return end
    local myNumber = pd.charinfo.phone

    local rows = Core.DB.All([[
        SELECT DISTINCT other FROM (
            SELECT CASE WHEN sender = ? THEN receiver ELSE sender END AS other
            FROM phone_messages WHERE sender = ? OR receiver = ?
        ) t
    ]], { myNumber, myNumber, myNumber })

    local contacts = Core.DB.All('SELECT name, number FROM phone_contacts WHERE citizenid = ?', { pd.citizenid })
    local nameByNumber = {}
    for _, c in ipairs(contacts) do nameByNumber[c.number] = c.name end

    local out = {}
    for _, row in ipairs(rows) do
        out[#out + 1] = { number = row.other, name = nameByNumber[row.other] or row.other }
    end
    cb(out)
end)

Core.Functions.CreateCallback('phone:getMessages', function(src, cb, withNumber)
    local pd = Core.Functions.GetPlayer(src)
    if not pd or not pd.charinfo.phone then cb({}) return end
    local myNumber = pd.charinfo.phone
    withNumber = tostring(withNumber or ''):sub(1, 15)

    local rows = Core.DB.All([[
        SELECT sender, receiver, message, sent_at FROM phone_messages
        WHERE (sender = ? AND receiver = ?) OR (sender = ? AND receiver = ?)
        ORDER BY sent_at ASC LIMIT 200
    ]], { myNumber, withNumber, withNumber, myNumber })
    cb(rows, myNumber)
end)

RegisterNetEvent('phone:server:sendMessage', function(toNumber, message)
    local src = source
    local pd = Core.Functions.GetPlayer(src)
    if not pd or not pd.charinfo.phone then return end
    toNumber = tostring(toNumber or ''):sub(1, 15)
    message = tostring(message or ''):sub(1, 500)
    if toNumber == '' or message == '' then return end

    Core.DB.Insert('INSERT INTO phone_messages (sender, receiver, message) VALUES (?, ?, ?)',
        { pd.charinfo.phone, toNumber, message })

    for _, entry in ipairs(Core.Functions.GetPlayers()) do
        if entry.pd.charinfo.phone == toNumber then
            TriggerClientEvent('phone:client:newMessage', entry.source, pd.charinfo.phone, message)
            break
        end
    end
end)
