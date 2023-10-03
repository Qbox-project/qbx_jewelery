fx_version 'cerulean'
game 'gta5'

description 'QBX-Jewelry'
repository 'https://github.com/Qbox-project/qbx_jewelery'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/import.lua',
    '@qbx_core/shared/locale.lua',
    'locale/en.lua',
    'locale/*.lua',
    'configs/default.lua'
}

client_script 'client.lua'

server_script 'server.lua'

modules {'qbx_core:utils'}

lua54 'yes'
use_experimental_fxv2_oal 'yes'