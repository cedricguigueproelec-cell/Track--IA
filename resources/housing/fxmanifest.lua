fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'housing'
author 'Track-IA'
version '1.0.0'
description 'Logements: achat, vente, coffre personnel (stash)'

shared_scripts { 'shared/config.lua' }

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

client_scripts {
    'client/main.lua'
}

dependency '/core'
