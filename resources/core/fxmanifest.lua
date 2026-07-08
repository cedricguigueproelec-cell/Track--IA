fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'core'
author 'Track-IA'
version '1.0.0'
description 'Track-IA RP - Core Framework (sessions, characters, economy, callbacks)'

shared_scripts {
    'config.lua',
    'shared/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/db.lua',
    'server/callbacks.lua',
    'server/economy.lua',
    'server/characters.lua',
    'server/commands.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua',
    'client/spawn.lua'
}

exports {
    'GetCoreObject'
}

-- Server dependency: oxmysql must be started BEFORE this resource.
-- See server.cfg ordering.

dependency '/oxmysql'
