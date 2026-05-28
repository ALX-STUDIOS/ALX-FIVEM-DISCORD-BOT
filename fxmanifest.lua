fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'ALX STUDIOS'
description 'Discord bot / ESX //// https://discord.gg/n99KjKFBXu '
version '2.1.0'

dependencies {
    'es_extended',
    'oxmysql',
}

shared_scripts {
    'shared/config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/utils.lua',
    'server/bridge.lua',
    'server/discord.lua',
    'server/commands.lua',
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}
