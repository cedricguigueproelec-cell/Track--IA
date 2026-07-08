fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'taxi'
author 'Track-IA'
version '1.0.0'
description 'Métier Taxi: service, compteur au kilomètre'

shared_scripts { 'shared/config.lua' }
server_scripts { 'server/main.lua' }
client_scripts { 'client/main.lua' }

dependency '/core'
