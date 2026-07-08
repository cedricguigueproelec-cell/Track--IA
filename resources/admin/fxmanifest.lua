fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'admin'
author 'Track-IA'
version '1.0.0'
description 'Commandes admin (ACE) + anti-cheat basique (vitesse, téléportation, argent, armes)'

shared_scripts { 'shared/config.lua' }

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/anticheat.lua'
}

client_scripts {
    'client/main.lua'
}

exports { 'SetTeleportGrace' }

dependency '/core'
