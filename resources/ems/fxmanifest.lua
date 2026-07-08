fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'ems'
author 'Track-IA'
version '1.0.0'
description 'Métier EMS: service, réanimation, soins, ambulances'

shared_scripts { 'shared/config.lua' }

server_scripts {
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
