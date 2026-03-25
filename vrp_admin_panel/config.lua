-- CONFIGURAÇÕES
local config = {
  admins = {
    -- user_id = {senha = 'senha123', cargo = 'admin'}
    [1] = { senha = 'admin123', cargo = 'dono' },
    [2] = { senha = 'adm1', cargo = 'admin' },
    [3] = { senha = 'adm2', cargo = 'superadmin' }
  },

  admins_file = 'admins.json',

  roles = {
    dono = { kick=true, heal=true, revive=true, view_logs=true, manage_wl=true, view_owner_logs=true, manage_admins=true },
    superadmin = { kick=true, heal=true, revive=true, view_logs=true, manage_wl=true },
    admin = { kick=true, heal=true, revive=true, view_logs=true }
  },

  whitelist_question = 'Qual o nome do servidor? (resposta exata: VIP)',
  whitelist_answer = 'VIP',
  whitelist_file = 'whitelist.json',
  admins_file = 'admins.json',

  sql = {
    enabled = true,
    -- Supported drivers: 'ghmattimysql', 'mysql-async'
    driver = 'ghmattimysql',
    host = '127.0.0.1',
    database = 'vrp',
    username = 'root',
    password = '',
    port = 3306,
  },

  webhook = {
    enabled = false,
    url = 'https://discord.com/api/webhooks/XXXX/XXXX',
    channel_name = 'admin-log'
  },

  logs_path = 'admin_logs.txt',
  logs_owner_path = 'owner_admin_logs.txt'
}

return config
