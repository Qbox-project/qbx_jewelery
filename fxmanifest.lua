fx_version 'cerulean'
game 'gta5'

description 'https://github.com/QBCore-Remastered'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@qb-core/shared/locale.lua',
    'locale/en.lua',
    'locale/*.lua',
    'config.lua'
}

client_script 'client.lua'

server_script 'server.lua'

lua54 'yes'
