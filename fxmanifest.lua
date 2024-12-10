fx_version 'cerulean'
game 'gta5'

author 'Talha'
description 'AI Support System'
version '1.0.0'

lua54 'yes'
use_experimental_fxv2_oal 'yes'

ui_page 'html/index.html'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/blips.lua',
    'client/main.lua'
}

server_scripts {
    'server/main.lua',
    'server/chatHistory.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}


ui_page_preload 'yes'