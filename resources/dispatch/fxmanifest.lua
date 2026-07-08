fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'dispatch'
author 'Track-IA'
version '1.0.0'
description 'Dispatch / 911 / CAD léger — alerte police & EMS avec blip carte'

server_scripts { 'server/main.lua' }
client_scripts { 'client/main.lua' }

exports { 'SendAlert' }

dependency '/core'
