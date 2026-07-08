fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'vehicles'
author 'Track-IA'
version '1.0.0'
description 'Concession, garages, fourrière — véhicules appartenant aux joueurs'

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

exports { 'ImpoundVehicle' }

dependency '/core'
