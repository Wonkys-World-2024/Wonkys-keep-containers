fx_version 'cerulean'
game 'gta5'

author 'Swkeep / Qbox conversion'
version '1.2.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',

    'shared/containers.lua',
    'config.lua',
    'shared/util.lua'
}

client_scripts {
    'client/lib.lua',
    'client/actions.lua',
    'client/creator.lua',

    'client/targets/functions.lua',
    'client/targets/qtarget.lua',
    'client/targets/qbtarget.lua',
    'client/targets/oxtarget.lua',

    'client/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/lib.lua',
    'server/server.lua'
}

dependencies {
    'ox_lib',
    'oxmysql',
    'ox_inventory',
    'ox_target',
    'qbx_core'
}