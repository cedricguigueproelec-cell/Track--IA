fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'multichar'
author 'Track-IA'
version '1.0.0'
description 'Character selection / creation UI'

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
