fx_version 'cerulean'
game 'gta5'

author 'Copilot'
description 'Painel Admin VRP - FiveM (NUI)'
version '2.6.0'

-- Dependências garantidas
dependency 'vrp'
-- mysql-async ou ghmattimysql, ambos suportados pelo script
dependency 'mysql-async'

ui_page 'html/index.html'

files {
  'html/index.html',
  'html/styles.css',
  'html/app.js'
}

server_script 'server.lua'
client_script 'client.lua'

-- Se quiser garantir compatibilidade com formatos de proxima versão:
-- this_is_a_map 'yes'  (se for usar assets 3D internos)

