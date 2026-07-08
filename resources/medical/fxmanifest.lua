fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'medical'
author 'Track-IA'
version '1.0.0'
description 'Etat "à terre" / saignement / réanimation / respawn hôpital'

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

exports {
    'Revive', 'IsDowned'
}

dependency '/core'
