fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'banking'
author 'Track-IA'
version '1.0.0'
description 'Comptes bancaires, ATM, virements, historique de transactions'

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
    'OpenBankApp'
}

dependency '/core'
