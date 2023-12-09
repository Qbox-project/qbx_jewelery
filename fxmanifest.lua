fx_version 'cerulean'
game 'gta5'

description 'qbx_jewelery'
repository 'https://github.com/Qbox-project/qbx_jewelery'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/utils.lua',
    '@qbx_core/shared/locale.lua',
    'locale/en.lua',
    'locale/*.lua',
}

client_script 'client/main.lua'

server_script 'server/main.lua'

files {
    'config/client.lua',
    'config/shared.lua',
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'