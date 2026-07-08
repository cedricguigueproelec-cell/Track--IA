Utils = {}

--- Cryptographically-uninteresting but collision-safe short ID generator.
--- Used for citizenids ("ABC12345") and phone numbers.
function Utils.RandomString(len, alphabet)
    alphabet = alphabet or 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local out = {}
    for i = 1, len do
        local idx = math.random(1, #alphabet)
        out[i] = alphabet:sub(idx, idx)
    end
    return table.concat(out)
end

function Utils.GeneratePhoneNumber()
    return '555' .. Utils.RandomString(7, '0123456789')
end

function Utils.GeneratePlate()
    return Utils.RandomString(2, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ') .. Utils.RandomString(3, '0123456789') .. Utils.RandomString(2, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')
end

function Utils.Round(value, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(value * mult + 0.5) / mult
end

function Utils.DeepCopy(orig)
    if type(orig) ~= 'table' then return orig end
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = Utils.DeepCopy(v)
    end
    return copy
end

--- Clamp a numeric value into [min, max]. Used everywhere we trust
--- client input (money amounts, slot indexes, stat values) to prevent
--- underflow/overflow exploits.
function Utils.Clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

function Utils.IsValidAmount(value, max)
    return type(value) == 'number' and value == math.floor(value) and value > 0 and value <= (max or 1000000000)
end

--- JSON-encodes a table safely for storage in a JSON DB column.
function Utils.ToJson(tbl)
    return json.encode(tbl or {})
end

function Utils.FromJson(str, default)
    if not str or str == '' then return default or {} end
    local ok, decoded = pcall(json.decode, str)
    if ok and decoded ~= nil then return decoded end
    return default or {}
end
