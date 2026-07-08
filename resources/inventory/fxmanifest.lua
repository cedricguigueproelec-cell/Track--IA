fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'inventory'
author 'Track-IA'
version '1.0.0'
description 'Slot-based server-authoritative inventory (player, trunk, glovebox, stash, ground drops)'

shared_scripts {
    'shared/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

client_scripts {
    'config.lua',
    'client/main.lua'
}

exports {
    'AddItem', 'RemoveItem', 'GetItemCount', 'HasItem',
    'OpenSecondary', 'CloseSecondary', 'EnsureLoaded', 'GetInventoryWeight', 'GetSnapshot', 'GetItemDefinition'
}

dependency '/core'
