-- Thin wrapper around oxmysql so the rest of the codebase never touches
-- the raw export directly. Centralizing this means we can swap the SQL
-- driver later without touching 20 resources.

-- Core is the shared framework table. Declared here because db.lua is
-- the first file loaded server-side (see fxmanifest.lua load order).
Core = {
    Players = {},      -- [source] = character table (in-memory, authoritative cache)
    Functions = {},
    Version = '1.0.0',
}

DB = {}

function DB.Scalar(query, params)
    return exports.oxmysql:scalar_async(query, params or {})
end

function DB.Single(query, params)
    return exports.oxmysql:single_async(query, params or {})
end

function DB.All(query, params)
    return exports.oxmysql:query_async(query, params or {})
end

function DB.Insert(query, params)
    return exports.oxmysql:insert_async(query, params or {})
end

function DB.Update(query, params)
    return exports.oxmysql:update_async(query, params or {})
end

function DB.Execute(query, params)
    return exports.oxmysql:execute_async(query, params or {})
end

--- Synchronous-style ready check used at boot to refuse to start serving
--- players if the database is unreachable (avoids silent data loss).
function DB.Ping()
    local ok, result = pcall(function()
        return DB.Scalar('SELECT 1')
    end)
    return ok and result ~= nil
end

-- Expose DB/Utils/Locale on the Core table so OTHER resources (which only
-- receive `Core` through exports.core:GetCoreObject()) can reach them —
-- bare `DB` / `Utils` globals only exist inside this resource's own Lua
-- environment, they are NOT visible cross-resource.
Core.DB = DB
Core.Utils = Utils
Core.Locale = Locale
Core.Translate = _T
Core.Config = Config
