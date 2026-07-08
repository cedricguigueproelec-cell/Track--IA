fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'hud'
author 'Track-IA'
version '1.0.0'
description 'HUD (vie, armure, faim, soif, stamina, argent, voix, compteur véhicule) + notifications'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

client_scripts {
    'client/hud.lua'
}

exports {
    'AddHunger',
    'AddThirst',
    'Notify'
}

dependency '/core'
