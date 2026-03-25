-- CONFIGURAÇÕES COMPLETAS DO PAINEL ADMIN VRP
local config = {
  -- ⚠️ SEGURANÇA: Admins devem ser configurados APENAS no banco de dados!
  -- 🔒 NUNCA coloque senhas em texto plano no código aberto
  -- ✅ Script SQL para adicionar admin:
  -- INSERT INTO vrp_admin_panel_admins (user_id, senha, cargo, criado_em)
  -- VALUES (1, 'admin123', 'dono', NOW());
  --
  -- Para alterar senha:
  -- UPDATE vrp_admin_panel_admins SET senha = 'novaSenha' WHERE user_id = 1;
  --
  -- ⚠️ IMPORTANTE: O arquivo config.lua NÃO carrega admins daqui mais!
  -- Todos os admins são carregados do banco de dados ao iniciar o servidor.
  
  admins = {
    -- ❌ NÃO configure aqui! Use o banco de dados!
    -- Deixar vazio para maior segurança
  },

  -- Sistema de Cargos e Permissões
  roles = {
    dono = {
      -- Gerenciamento de Jogadores
      kick = true, heal = true, revive = true, ban = true, teleport = true, 
      freeze = true, god_mode = true, money = true, manage_groups = true,
      -- Gerenciamento de Admin
      manage_admins = true, manage_wl = true, manage_announcements = true,
      manage_reports = true, manage_economy = true, manage_weather = true, manage_db = true,
      -- Visualização
      view_logs = true, view_owner_logs = true, view_players = true,
      -- Chat
      access_admin_chat = true
    },
    superadmin = {
      kick = true, heal = true, revive = true, ban = true, teleport = true,
      freeze = true, god_mode = true, money = true, manage_groups = true,
      manage_wl = true, manage_reports = true, manage_economy = true,
      manage_weather = true, manage_db = false,
      view_logs = true, view_players = true,
      access_admin_chat = true
    },
    admin = {
      kick = true, heal = true, revive = true, manage_groups = true,
      view_logs = true, view_players = true,
      access_admin_chat = true,
      manage_reports = true,
      manage_economy = false,
      manage_weather = false,
      manage_db = false
    }
  },

  -- Grupos disponíveis no servidor
  groups = {
    'user',
    'moderador',
    'admin',
    'vip',
    'vip_gold',
    'suporte',
    'builder'
  },

  -- Whitelist Configuration
  whitelist = {
    enabled = true,
    question = 'Qual o nome do servidor? (resposta exata: VIP)',
    answer = 'VIP',
    file = 'whitelist.json'
  },

  -- Database Configuration
  database = {
    enabled = true,
    driver = 'ghmattimysql', -- 'ghmattimysql' ou 'mysql-async'
    host = '127.0.0.1',
    database = 'vrp',
    username = 'root',
    password = '',
    port = 3306,
  },

  -- Discord Webhook
  webhook = {
    enabled = false,
    url = 'https://discord.com/api/webhooks/XXXX/XXXX',
    channel_name = 'admin-log',
    mention_on_important = false -- menciona no ban/kick importante
  },

  -- Logging Configuration
  logging = {
    admins_file = 'admins.json',
    logs_path = 'admin_logs.txt',
    owner_logs_path = 'owner_admin_logs.txt',
    ban_logs_path = 'ban_logs.txt',
    max_log_lines = 1000 -- máximo de linhas no arquivo antes de rotação
  },

  -- Security & Anti-Exploit
  security = {
    enable_login_lock = true,
    max_login_attempts = 5,
    login_lock_duration = 600, -- segundos
    require_password_strength = true,
    min_password_length = 6,
    log_all_commands = true,
    validate_player_id = true,
    check_player_permissions_realtime = true
  },

  -- Notification & Messages
  messages = {
    kick_reason = 'Você foi expulso por um administrador',
    ban_duration = 'banido permanentemente',
    teleport_success = 'Teleportado com sucesso',
    permission_denied = 'Sem permissão para esta ação'
  },

  -- UI/UX Preferences
  ui = {
    auto_refresh_logs = true,
    auto_refresh_interval = 10000, -- milisegundos
    show_player_list_refresh = true,
    compact_mode = false
  }
}

return config
