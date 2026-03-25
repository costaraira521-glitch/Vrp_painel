local Tunnel = module('vrp', 'lib/Tunnel')
local Proxy = module('vrp', 'lib/Proxy')

vRP = Proxy.getInterface('vRP')
vRPclient = Tunnel.getInterface('vRP')

local config = require('config')
local activeAdmins = {}

-- Helpers for SQL (ghmattimysql / mysql-async)
local function sqlQuery(query, params, cb)
  params = params or {}
  if not config.sql or not config.sql.enabled then
    if cb then cb({}) end
    return
  end

  if config.sql.driver == 'ghmattimysql' and exports['ghmattimysql'] then
    exports['ghmattimysql']:execute(query, params, function(result)
      if cb then cb(result) end
    end)
    return
  end

  if config.sql.driver == 'mysql-async' and MySQL and MySQL.Async then
    MySQL.Async.fetchAll(query, params, function(result)
      if cb then cb(result) end
    end)
    return
  end

  -- Fallback
  if MySQL and MySQL.Async then
    MySQL.Async.fetchAll(query, params, function(result)
      if cb then cb(result) end
    end)
    return
  end

  if cb then cb({}) end
end

local function sqlExec(query, params, cb)
  params = params or {}
  if not config.sql or not config.sql.enabled then
    if cb then cb() end
    return
  end

  if config.sql.driver == 'ghmattimysql' and exports['ghmattimysql'] then
    exports['ghmattimysql']:execute(query, params, function(result)
      if cb then cb(result) end
    end)
    return
  end

  if config.sql.driver == 'mysql-async' and MySQL and MySQL.Async then
    MySQL.Async.execute(query, params, function(result)
      if cb then cb(result) end
    end)
    return
  end

  if MySQL and MySQL.Async then
    MySQL.Async.execute(query, params, function(result)
      if cb then cb(result) end
    end)
    return
  end

  if cb then cb() end
end

local function ensureSqlTables()
  if not config.sql or not config.sql.enabled then return end

  sqlExec([[
    CREATE TABLE IF NOT EXISTS vrp_admin_panel_admins (
      user_id INT PRIMARY KEY,
      senha VARCHAR(255) NOT NULL,
      cargo VARCHAR(50) NOT NULL
    );
  ]])

  sqlExec([[
    CREATE TABLE IF NOT EXISTS vrp_admin_panel_whitelist (
      user_id INT PRIMARY KEY,
      approved TINYINT(1) NOT NULL DEFAULT 1
    );
  ]])

  sqlExec([[
    CREATE TABLE IF NOT EXISTS vrp_admin_panel_logs (
      id INT AUTO_INCREMENT PRIMARY KEY,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      message TEXT NOT NULL
    );
  ]])

  sqlExec([[
    CREATE TABLE IF NOT EXISTS vrp_admin_panel_bans (
      id INT AUTO_INCREMENT PRIMARY KEY,
      user_id INT NOT NULL,
      banido_por INT NOT NULL,
      motivo VARCHAR(255) NOT NULL,
      banido_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      expira_em TIMESTAMP NULL,
      ativo TINYINT(1) NOT NULL DEFAULT 1,
      INDEX (user_id),
      INDEX (banido_por),
      INDEX (ativo)
    );
  ]])

  sqlExec([[
    CREATE TABLE IF NOT EXISTS vrp_admin_panel_reports (
      id INT AUTO_INCREMENT PRIMARY KEY,
      reported_id INT NOT NULL,
      reporter_id INT NOT NULL,
      motivo TEXT NOT NULL,
      status VARCHAR(50) NOT NULL DEFAULT 'aberto',
      criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      atualizado_em TIMESTAMP NULL,
      INDEX (reported_id),
      INDEX (reporter_id),
      INDEX (status)
    );
  ]])

  sqlExec([[
    CREATE TABLE IF NOT EXISTS vrp_admin_panel_admin_chat (
      id INT AUTO_INCREMENT PRIMARY KEY,
      admin_id INT NOT NULL,
      mensagem TEXT NOT NULL,
      tipo VARCHAR(50) NOT NULL DEFAULT 'normal',
      enviado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      INDEX (admin_id),
      INDEX (enviado_em)
    );
  ]])

  sqlExec([[
    CREATE TABLE IF NOT EXISTS vrp_admin_panel_system_announcements (
      id INT AUTO_INCREMENT PRIMARY KEY,
      titulo VARCHAR(255) NOT NULL,
      mensagem TEXT NOT NULL,
      tipo VARCHAR(50) NOT NULL DEFAULT 'info',
      criado_por INT NOT NULL,
      criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      ativo TINYINT(1) NOT NULL DEFAULT 1,
      INDEX (tipo),
      INDEX (ativo),
      INDEX (criado_por)
    );
  ]])
end

local function getSqlAdmins()
  sqlQuery('SELECT user_id, senha, cargo FROM vrp_admin_panel_admins', {}, function(result)
    if #result > 0 then
      local tableAdmins = {}
      for _, r in ipairs(result) do
        tableAdmins[tonumber(r.user_id)] = { senha = r.senha, cargo = r.cargo }
      end
      config.admins = tableAdmins
      saveAdmins() -- sync to file
    end
  end)
end

local function getSqlWhitelist()
  sqlQuery('SELECT user_id, approved FROM vrp_admin_panel_whitelist WHERE approved = 1', {}, function(result)
    if #result > 0 then
      whitelist = {}
      for _, r in ipairs(result) do
        whitelist[tonumber(r.user_id)] = true
      end
      saveWhitelist()
    end
  end)
end

local function persistAdminDb(user_id, senha, cargo)
  if not config.sql or not config.sql.enabled then return end
  sqlExec('REPLACE INTO vrp_admin_panel_admins (user_id, senha, cargo) VALUES (@user_id, @senha, @cargo)',
    { ['@user_id']=user_id, ['@senha']=senha, ['@cargo']=cargo })
end

local function persistWhitelistDb(user_id)
  if not config.sql or not config.sql.enabled then return end
  sqlExec('REPLACE INTO vrp_admin_panel_whitelist (user_id, approved) VALUES (@user_id,1)', { ['@user_id']=user_id })
end

local function persistLogDb(message)
  if not config.sql or not config.sql.enabled then return end
  sqlExec('INSERT INTO vrp_admin_panel_logs (message) VALUES (@message)', { ['@message']=message })
end

local function getSqlLogs(cb)
  if not config.sql or not config.sql.enabled then
    if cb then cb(nil) end
    return
  end

  sqlQuery('SELECT created_at, message FROM vrp_admin_panel_logs ORDER BY id DESC LIMIT 500', {}, function(result)
    if cb then cb(result) end
  end)
end

local function getUserId(source)
  if not source then return nil end

  local user_id = nil
  if vRP.getUserId then
    local status, val = pcall(vRP.getUserId, source)
    if status and val then
      user_id = val
    end
  end

  if not user_id and vRP.getUserId then
    local status, val = pcall(vRP.getUserId, {source})
    if status and val then
      user_id = val
    end
  end

  return user_id
end

local function getUserSource(user_id)
  if not user_id then return nil end

  local source = nil
  if vRP.getUserSource then
    local status, val = pcall(vRP.getUserSource, user_id)
    if status and val then source = val end
  end
  if not source and vRP.getUserSource then
    local status, val = pcall(vRP.getUserSource, {user_id})
    if status and val then source = val end
  end

  return source
end

local function getUserIdentity(user_id)
  if not user_id then return nil end
  local data = nil
  if vRP.getUserIdentity then
    local ok, val = pcall(vRP.getUserIdentity, user_id)
    if ok and val then return val end
  end
  if vRP.getUserIdentity then
    local ok, val = pcall(vRP.getUserIdentity, {user_id})
    if ok and val then return val end
  end
  return data
end

local function isAdmin(user_id)
  return config.admins[user_id] ~= nil
end

local function isDonor(user_id)
  local entry = config.admins[user_id]
  return entry and entry.cargo == 'dono'
end

local function hasPermission(user_id, perm)
  local entry = config.admins[user_id]
  if not entry then return false end
  local rolePerms = config.roles[entry.cargo]
  return rolePerms and rolePerms[perm]
end

local whitelist = {}

local function loadWhitelist()
  local path = ('%s/%s'):format(GetResourcePath(GetCurrentResourceName()), config.whitelist_file)
  local f = io.open(path, 'r')
  if f then
    local data = f:read('*a')
    f:close()
    if data and data ~= '' then
      local ok, parsed = pcall(json.decode, data)
      if ok and type(parsed) == 'table' then
        whitelist = parsed
      end
    end
  end
end

local function saveWhitelist()
  local path = ('%s/%s'):format(GetResourcePath(GetCurrentResourceName()), config.whitelist_file)
  local f = io.open(path, 'w+')
  if f then
    f:write(json.encode(whitelist))
    f:close()
  end
end

local function isWhitelisted(user_id)
  return whitelist[user_id] == true
end

local function setWhitelisted(user_id)
  whitelist[user_id] = true
  saveWhitelist()
  persistWhitelistDb(user_id)
end

local function loadAdmins()
  if config.sql and config.sql.enabled then
    getSqlAdmins()
    return
  end

  local path = ('%s/%s'):format(GetResourcePath(GetCurrentResourceName()), config.admins_file)
  local f = io.open(path, 'r')
  if f then
    local data = f:read('*a')
    f:close()
    if data and data ~= '' then
      local ok, parsed = pcall(json.decode, data)
      if ok and type(parsed) == 'table' then
        config.admins = parsed
      end
    end
  end
end

local function saveAdmins()
  if config.sql and config.sql.enabled then
    for id, info in pairs(config.admins) do
      persistAdminDb(id, info.senha, info.cargo)
    end
  end

  local path = ('%s/%s'):format(GetResourcePath(GetCurrentResourceName()), config.admins_file)
  local f = io.open(path, 'w+')
  if f then
    f:write(json.encode(config.admins))
    f:close()
  end
end

local function applySafeAdminData(user_id, data)
  if not user_id or type(data) ~= 'table' then return false end
  if not data.senha or not data.cargo then return false end
  config.admins[user_id] = { senha = data.senha, cargo = data.cargo }
  saveAdmins()
  return true
end

local function writeLog(file, text)
  local path = ('%s/%s'):format(GetResourcePath(GetCurrentResourceName()), file)
  local f = io.open(path, 'a+')
  if f then
    f:write(text .. '\n')
    f:close()
  end
  persistLogDb(text)
end

local function sendWebhook(message)
  if not config.webhook or not config.webhook.enabled then
    return
  end
  PerformHttpRequest(config.webhook.url, function(err, text, headers) end, 'POST', json.encode({
    username = config.webhook.channel_name or 'AdminLog',
    content = message
  }), { ['Content-Type'] = 'application/json' })
end

RegisterNetEvent('vrp_admin_panel:checkWhitelist')
AddEventHandler('vrp_admin_panel:checkWhitelist', function()
  local src = source
  local user_id = getUserId(src)
  if not user_id then return end

  if not isWhitelisted(user_id) then
    TriggerClientEvent('vrp_admin_panel:openWL', src, config.whitelist_question)
    if vRPclient and vRPclient.notify then
      vRPclient.notify(src, {'~y~Responda a whitelist para obter acesso.'})
    end
  end
end)

RegisterNUICallback('whitelistAnswer', function(data, cb)
  local src = source
  local user_id = getUserId(src)
  if not user_id then cb({success=false, error='Sem user_id'}); return end

  local answer = tostring(data.answer or '')
  if answer:lower() == tostring(config.whitelist_answer):lower() then
    setWhitelisted(user_id)
    local logMsg = os.date('%Y-%m-%d %H:%M:%S') .. string.format(' [WL APROVADO] user_id=%d', user_id)
    writeLog(config.logs_path, logMsg)
    sendWebhook(logMsg)
    TriggerClientEvent('vrp_admin_panel:wlResult', source, true, 'Aprovado! Bem-vindo ao servidor.')
  else
    local logMsg = os.date('%Y-%m-%d %H:%M:%S') .. string.format(' [WL FALHA] user_id=%d resposta=%s', user_id, answer)
    writeLog(config.logs_path, logMsg)
    sendWebhook(logMsg)
    TriggerClientEvent('vrp_admin_panel:wlResult', source, false, 'Resposta incorreta. Tente novamente.')
  end
  cb({success=true})
end)

RegisterNUICallback('getAdmins', function(data, cb)
  local source = source
  local user_id = getUserId(source)
  if not user_id or not hasPermission(user_id, 'manage_admins') then
    cb({ success = false, error = 'Permissão negada.' })
    return
  end

  local list = {}
  for id, info in pairs(config.admins) do
    list[#list+1] = { user_id = id, cargo = info.cargo, senha = '****' }
  end

  cb({ success = true, admins = list })
end)

RegisterNUICallback('setAdmin', function(data, cb)
  local src = source
  local user_id = getUserId(src)
  if not user_id or not hasPermission(user_id, 'manage_admins') then
    cb({ success = false, error = 'Permissão negada.' })
    return
  end

  local targetId = tonumber(data.user_id)
  if not targetId then
    cb({ success = false, error = 'ID de admin inválido.' })
    return
  end

  local ok = applySafeAdminData(targetId, { senha = tostring(data.senha), cargo = tostring(data.cargo) })
  if not ok then
    cb({ success = false, error = 'Dados inválidos.' })
    return
  end

  local msg = os.date('%Y-%m-%d %H:%M:%S') .. string.format(' [ADMIN SET] operador=%d alterou=%d cargo=%s', user_id, targetId, data.cargo)
  writeLog(config.logs_path, msg)
  sendWebhook(msg)

  cb({ success = true })
end)

RegisterNUICallback('getWhitelist', function(data, cb)
  local src = source
  local user_id = getUserId(src)
  if not user_id or not hasPermission(user_id, 'manage_wl') then
    cb({ success = false, error = 'Permissão negada.' })
    return
  end

  local list = {}
  for id, ok in pairs(whitelist) do
    if ok then table.insert(list, id) end
  end
  cb({ success = true, whitelist = list })
end)

RegisterNUICallback('toggleNameTag', function(data, cb)
  local src = source
  local user_id = getUserId(src)
  if not user_id or not isAdmin(user_id) then
    cb({ success = false, error = 'Permissão negada.' })
    return
  end

  local enable = data.enable == true
  TriggerClientEvent('vrp_admin_panel:setDrawTag', src, enable)
  writeLog(config.logs_path, os.date('%Y-%m-%d %H:%M:%S') .. string.format(' [NAMETAG] admin=%d ativo=%s', user_id, tostring(enable)))
  sendWebhook('[NAMETAG] admin=' .. user_id .. ' active=' .. tostring(enable))
  cb({ success = true })
end)

RegisterCommand('paineladm', function(source)
  local user_id = getUserId(source)
  if not user_id or not isAdmin(user_id) then
    if vRPclient and vRPclient.notify then
      vRPclient.notify(source, {'~r~Acesso negado: você não é admin.'})
    end
    return
  end
  TriggerClientEvent('vrp_admin_panel:open', source)
end)

RegisterCommand('revive', function(source, args)
  local user_id = getUserId(source)
  if not user_id or not hasPermission(user_id, 'revive') then
    if vRPclient and vRPclient.notify then
      vRPclient.notify(source, {'~r~Sem permissão para revive.'})
    end
    return
  end
  local targetId = tonumber(args[1])
  if not targetId then
    if vRPclient and vRPclient.notify then
      vRPclient.notify(source, {'~r~Uso: /revive <player_id>'})
    end
    return
  end
  TriggerEvent('vrp_admin_panel:cmdRevive', targetId)
end)

RegisterNUICallback('login', function(data, cb)
  local src = source
  local user_id = getUserId(src)
  local username = data.username and tostring(data.username) or ''
  local password = data.password and tostring(data.password) or ''

  if not user_id or not isAdmin(user_id) then
    cb({ success = false, error = 'Acesso negado ao painel.' })
    return
  end

  local adminData = config.admins[user_id]
  if not adminData then
    cb({ success = false, error = 'Usuário não configurado como admin.' })
    return
  end

  if password ~= adminData.senha then
    local msg = os.date('%Y-%m-%d %H:%M:%S') .. string.format(' [FALHA LOGIN] user_id=%d username=%s (tentativa de senha incorreta)', user_id, username)
    writeLog(config.logs_path, msg)
    sendWebhook(msg)
    cb({ success = false, error = 'Senha incorreta.' })
    return
  end

  activeAdmins[user_id] = { source = source, cargo = adminData.cargo, username = username }
  local logMsg = os.date('%Y-%m-%d %H:%M:%S') .. string.format(' [LOGIN] user_id=%d username=%s cargo=%s', user_id, username, adminData.cargo)
  writeLog(config.logs_path, logMsg)
  sendWebhook(logMsg)
  if isDonor(user_id) then
    local ownerMsg = os.date('%Y-%m-%d %H:%M:%S') .. string.format(' [DONO LOGIN] user_id=%d username=%s', user_id, username)
    writeLog(config.logs_owner_path, ownerMsg)
    sendWebhook(ownerMsg)
  end

  cb({ success = true, cargo = adminData.cargo, permissions = config.roles[adminData.cargo] or {} })
end)

RegisterNUICallback('logout', function(data, cb)
  local src = source
  local user_id = getUserId(src)
  if user_id then
    activeAdmins[user_id] = nil
    local msg = os.date('%Y-%m-%d %H:%M:%S') .. string.format(' [LOGOUT] user_id=%d', user_id)
    writeLog(config.logs_path, msg)
    sendWebhook(msg)
  end
  SetTimeout(0, function() end) -- no-op
  cb({ success = true })
end)

RegisterNUICallback('getPlayerInfo', function(data, cb)
  local src = source
  local user_id = getUserId(src)
  local targetId = tonumber(data.targetId)

  if not user_id or not isAdmin(user_id) then
    cb({ success = false, error = 'Acesso negado.' })
    return
  end

  if not targetId then
    cb({ success = false, error = 'ID de jogador inválido.' })
    return
  end

  local targetSource = getUserSource(targetId)
  if not targetSource then
    cb({ success = false, error = 'Jogador não encontrado.' })
    return
  end

  local identity = getUserIdentity(targetId)
  local playerPos = vRPclient.getPosition({targetSource})

  local info = {
    user_id = targetId,
    nome = identity and identity.name or 'N/A',
    sobrenome = identity and identity.firstname or 'N/A',
    telefone = identity and identity.phone or 'N/A',
    carteira = vRP.getMoney({targetId}),
    identificacao = playerPos and ('x=%.2f y=%.2f z=%.2f'):format(playerPos.x, playerPos.y, playerPos.z) or 'N/A'
  }

  writeLog(config.logs_path, os.date('%Y-%m-%d %H:%M:%S') .. string.format(' [BUSCA JOGADOR] admin=%d target=%d', user_id, targetId))
  if isDonor(user_id) then
    writeLog(config.logs_owner_path, os.date('%Y-%m-%d %H:%M:%S') .. string.format(' [DONO BUSCA] admin=%d target=%d', user_id, targetId))
  end

  cb({ success = true, info = info })
end)

RegisterNUICallback('getLogs', function(data, cb)
  local src = source
  local user_id = getUserId(src)
  if not user_id or not hasPermission(user_id, 'view_logs') then
    cb({ success = false, error = 'Sem permissão.' })
    return
  end

  if config.sql and config.sql.enabled then
    getSqlLogs(function(result)
      if not result or #result == 0 then
        cb({ success = true, logs = 'Nenhum log encontrado.' })
        return
      end
      local lines = {}
      for _, row in ipairs(result) do
        table.insert(lines, ('[%s] %s'):format(row.created_at, row.message))
      end
      cb({ success = true, logs = table.concat(lines, '\n') })
    end)
    return
  end

  local path = ('%s/%s'):format(GetResourcePath(GetCurrentResourceName()), config.logs_path)
  local content = 'Nenhum log encontrado.'
  local f = io.open(path, 'r')
  if f then content = f:read('*a') or 'Nenhum log encontrado.'; f:close() end

  cb({ success = true, logs = content })
end)

RegisterNetEvent('vrp_admin_panel:cmdKick')
AddEventHandler('vrp_admin_panel:cmdKick', function(targetId)
  local src = source
  local user_id = getUserId(src)
  if not user_id or not hasPermission(user_id, 'kick') then
    TriggerClientEvent('vrp_admin_panel:commandResult', source, false, 'Sem permissão de kick.')
    return
  end
  local tId = tonumber(targetId)
  if not tId then
    TriggerClientEvent('vrp_admin_panel:commandResult', source, false, 'ID inválido.')
    return
  end
  local targetSource = getUserSource(tId)
  if not targetSource then
    TriggerClientEvent('vrp_admin_panel:commandResult', src, false, 'Jogador não encontrado.')
    return
  end
  if vRP.kick then
    vRP.kick({targetSource, 'Expulso pelo painel admin.'})
  elseif vRPclient.kick then
    vRPclient.kick(targetSource, {'Expulso pelo painel admin.'})
  end
  local logMsg = os.date('%Y-%m-%d %H:%M:%S') .. string.format(' [KICK] admin=%d target=%d', user_id, tId)
  writeLog(config.logs_path, logMsg)
  sendWebhook(logMsg)
  TriggerClientEvent('vrp_admin_panel:commandResult', src, true, 'Jogador expulso com sucesso.')
end)

RegisterNetEvent('vrp_admin_panel:cmdHeal')
AddEventHandler('vrp_admin_panel:cmdHeal', function(targetId)
  local src = source
  local user_id = getUserId(src)
  if not user_id or not hasPermission(user_id, 'heal') then
    TriggerClientEvent('vrp_admin_panel:commandResult', src, false, 'Sem permissão de heal.')
    return
  end
  local tId = tonumber(targetId)
  if not tId then
    TriggerClientEvent('vrp_admin_panel:commandResult', src, false, 'ID inválido.')
    return
  end
  local targetSource = getUserSource(tId)
  if not targetSource then
    TriggerClientEvent('vrp_admin_panel:commandResult', src, false, 'Jogador não encontrado.')
    return
  end
  if vRPclient.setHealth then
    vRPclient.setHealth(targetSource, {200})
  elseif vRP.setHunger then -- fallback for vRPex style
    vRP.setHunger({targetId, 0})
  end
  local logMsg = os.date('%Y-%m-%d %H:%M:%S') .. string.format(' [HEAL] admin=%d target=%d', user_id, tId)
  writeLog(config.logs_path, logMsg)
  sendWebhook(logMsg)
  TriggerClientEvent('vrp_admin_panel:commandResult', src, true, 'Jogador curado com sucesso.')
end)

RegisterNetEvent('vrp_admin_panel:cmdRevive')
AddEventHandler('vrp_admin_panel:cmdRevive', function(targetId)
  local src = source
  local user_id = getUserId(src)
  if not user_id or not hasPermission(user_id, 'revive') then
    TriggerClientEvent('vrp_admin_panel:commandResult', src, false, 'Sem permissão de revive.')
    return
  end
  local tId = tonumber(targetId)
  if not tId then
    TriggerClientEvent('vrp_admin_panel:commandResult', src, false, 'ID inválido.')
    return
  end
  local targetSource = getUserSource(tId)
  if not targetSource then
    TriggerClientEvent('vrp_admin_panel:commandResult', src, false, 'Jogador não encontrado.')
    return
  end
  if vRPclient.setHealth then
    vRPclient.setHealth(targetSource, {200})
  end
  if vRPclient.setArmour then
    vRPclient.setArmour(targetSource, {100})
  end
  local logMsg = os.date('%Y-%m-%d %H:%M:%S') .. string.format(' [REVIVE] admin=%d target=%d', user_id, tId)
  writeLog(config.logs_path, logMsg)
  sendWebhook(logMsg)
  TriggerClientEvent('vrp_admin_panel:commandResult', src, true, 'Jogador revivido com sucesso.')
end)

-- ═══════════════════════════════════════════════════════════════════
-- SISTEMA DE GRUPOS
-- ═══════════════════════════════════════════════════════════════════

RegisterNUICallback('getAvailableGroups', function(data, cb)
  local src = source
  local user_id = getUserId(src)
  if not user_id or not hasPermission(user_id, 'manage_groups') then
    cb({ success = false, error = 'Sem permissão.' })
    return
  end
  
  cb({ success = true, groups = config.groups or {} })
end)

RegisterNUICallback('getPlayerGroup', function(data, cb)
  local src = source
  local user_id = getUserId(src)
  if not user_id or not hasPermission(user_id, 'manage_groups') then
    cb({ success = false, error = 'Sem permissão.' })
    return
  end
  
  local targetId = tonumber(data.targetId)
  if not targetId then
    cb({ success = false, error = 'ID inválido.' })
    return
  end
  
  local targetSource = getUserSource(targetId)
  if not targetSource then
    cb({ success = false, error = 'Jogador não encontrado.' })
    return
  end
  
  -- Pega o grupo do jogador usando vRP
  local playerGroup = 'user'
  if vRP.getUserGroup then
    local ok, result = pcall(vRP.getUserGroup, targetId)
    if ok and result then
      playerGroup = result
    else
      ok, result = pcall(vRP.getUserGroup, {targetId})
      if ok and result then
        playerGroup = result
      end
    end
  end
  
  writeLog(config.logs_path, os.date('%Y-%m-%d %H:%M:%S') .. string.format(' [INFO GRUPO] admin=%d consultou grupo de=%d', user_id, targetId))
  
  cb({ success = true, group = playerGroup })
end)

RegisterNUICallback('setPlayerGroup', function(data, cb)
  local src = source
  local user_id = getUserId(src)
  if not user_id or not hasPermission(user_id, 'manage_groups') then
    cb({ success = false, error = 'Sem permissão.' })
    return
  end
  
  local targetId = tonumber(data.targetId)
  local newGroup = tostring(data.group or '')
  
  if not targetId or targetId <= 0 then
    cb({ success = false, error = 'ID inválido.' })
    return
  end
  
  if newGroup == '' then
    cb({ success = false, error = 'Grupo inválido.' })
    return
  end
  
  -- Valida se o grupo existe na config
  local groupExists = false
  for _, g in ipairs(config.groups or {}) do
    if g == newGroup then
      groupExists = true
      break
    end
  end
  
  if not groupExists then
    cb({ success = false, error = 'Grupo não encontrado na configuração.' })
    return
  end
  
  local targetSource = getUserSource(targetId)
  if not targetSource then
    cb({ success = false, error = 'Jogador não encontrado.' })
    return
  end
  
  -- Define o novo grupo através de vRP
  if vRP.addUserGroup then
    pcall(vRP.addUserGroup, targetId, newGroup)
  else
    pcall(vRP.addUserGroup, {targetId, newGroup})
  end
  
  local logMsg = os.date('%Y-%m-%d %H:%M:%S') .. string.format(' [GRUPO SET] admin=%d alterou jogador=%d novo_grupo=%s', user_id, targetId, newGroup)
  writeLog(config.logs_path, logMsg)
  sendWebhook(logMsg)
  
  if isDonor(user_id) then
    local ownerLog = os.date('%Y-%m-%d %H:%M:%S') .. string.format(' [DONO: GRUPO SET] admin=%d alterou jogador=%d novo_grupo=%s', user_id, targetId, newGroup)
    writeLog(config.logs_owner_path, ownerLog)
  end
  
  cb({ success = true, message = 'Grupo alterado com sucesso para: ' .. newGroup })
end)

RegisterNUICallback('getOwnerLogs', function(data, cb)
  local src = source
  local user_id = getUserId(src)
  if not user_id or not isDonor(user_id) then
    cb({ success = false, error = 'Somente dono.' })
    return
  end

  local path = ('%s/%s'):format(GetResourcePath(GetCurrentResourceName()), config.logs_owner_path)
  local content = 'Nenhum log encontrado.'
  local f = io.open(path, 'r')
  if f then content = f:read('*a') or 'Nenhum log encontrado.'; f:close() end

  cb({ success = true, logs = content })
end)

-- Funções de ferramentas extras (Ideias 1 a 8)

local function isPlayerOnline(user_id)
  return getUserSource(user_id) ~= nil
end

-- 1) Localizador / Teleporte rápido
RegisterNUICallback('getPlayerCoords', function(data, cb)
  local src = source
  local user_id = getUserId(src)
  if not user_id or not hasPermission(user_id, 'teleport') then
    cb({ success = false, error = 'Permissão negada.' })
    return
  end

  local targetId = tonumber(data.targetId)
  if not targetId then cb({ success = false, error = 'ID inválido.' }); return end

  local targetSource = getUserSource(targetId)
  if not targetSource then cb({ success = false, error = 'Jogador não está online.' }); return end

  if vRPclient.getPosition then
    vRPclient.getPosition(targetSource, {}, function(x, y, z)
      cb({ success = true, coords = { x = x, y = y, z = z } })
    end)
  else
    cb({ success = false, error = 'Função de coordenada não suportada.' })
  end
end)

RegisterNUICallback('teleportPlayer', function(data, cb)
  local src = source
  local user_id = getUserId(src)
  if not user_id or not hasPermission(user_id, 'teleport') then
    cb({ success = false, error = 'Permissão negada.' })
    return
  end

  local targetId = tonumber(data.targetId)
  local x, y, z = tonumber(data.x), tonumber(data.y), tonumber(data.z)
  if not targetId or not x or not y or not z then cb({ success = false, error = 'Dados inválidos.' }); return end

  local targetSource = getUserSource(targetId)
  if not targetSource then cb({ success = false, error = 'Jogador não está online.' }); return end

  if vRPclient.teleport then
    vRPclient.teleport(targetSource, {x, y, z})
  elseif vRP.teleport then
    vRP.teleport({targetId, x, y, z})
  end

  local logMsg = os.date('%Y-%m-%d %H:%M:%S') .. string.format(' [TELEPORT] admin=%d target=%d to=%.2f,%.2f,%.2f', user_id, targetId, x, y, z)
  writeLog(config.logs_path, logMsg)
  sendWebhook(logMsg)
  cb({ success = true })
end)

-- 2) Ban / Unban
RegisterNUICallback('getBans', function(data, cb)
  if not data then data = {} end
  local src = source
  local user_id = getUserId(src)
  if not user_id or not hasPermission(user_id, 'ban') then
    cb({ success = false, error = 'Permissão negada.' })
    return
  end

  sqlQuery('SELECT * FROM vrp_admin_panel_bans ORDER BY banido_em DESC LIMIT 50', {}, function(result)
    cb({ success = true, bans = result or {} })
  end)
end)

local function applyBan(targetId, adminId, reason, duration)
  local expiry = nil
  if duration and tonumber(duration) and tonumber(duration) > 0 then
    expiry = os.date('%Y-%m-%d %H:%M:%S', os.time() + tonumber(duration))
  end

  sqlExec('INSERT INTO vrp_admin_panel_bans (user_id, banido_por, motivo, banido_em, expira_em, ativo) VALUES (?, ?, ?, NOW(), ?, 1)',
    {targetId, adminId, reason, expiry})

  if vRP.kick then
    local trg = getUserSource(targetId)
    if trg then vRP.kick(trg, reason or 'Banned by admin panel') end
  end
end

RegisterNUICallback('banPlayer', function(data, cb)
  local src = source
  local user_id = getUserId(src)
  if not user_id or not hasPermission(user_id, 'ban') then
    cb({ success = false, error = 'Permissão negada.' })
    return
  end
  local targetId = tonumber(data.targetId)
  local reason = tostring(data.reason or 'Banido por sistema de admin').sub(data.reason or '', 1, 255)
  local duration = tonumber(data.duration)
  if not targetId then cb({ success = false, error = 'ID inválido.' }); return end

  applyBan(targetId, user_id, reason, duration)
  writeLog(config.logs_path, os.date('%Y-%m-%d %H:%M:%S') .. string.format(' [BAN] admin=%d target=%d reason=%s duration=%s', user_id, targetId, reason, tostring(duration)))
  sendWebhook('[BAN] admin=' .. user_id .. ' target=' .. targetId)
  cb({ success = true })
end)

RegisterNUICallback('unbanPlayer', function(data, cb)
  local src = source
  local user_id = getUserId(src)
  if not user_id or not hasPermission(user_id, 'ban') then
    cb({ success = false, error = 'Permissão negada.' })
    return
  end
  local targetId = tonumber(data.targetId)
  if not targetId then cb({ success = false, error = 'ID inválido.' }); return end

  sqlExec('UPDATE vrp_admin_panel_bans SET ativo = 0 WHERE user_id = ? AND ativo = 1', {targetId})
  writeLog(config.logs_path, os.date('%Y-%m-%d %H:%M:%S') .. string.format(' [UNBAN] admin=%d target=%d', user_id, targetId))
  sendWebhook('[UNBAN] admin=' .. user_id .. ' target=' .. targetId)
  cb({ success = true })
end)

-- 3) Reports
RegisterNUICallback('createReport', function(data, cb)
  local src = source
  local user_id = getUserId(src)
  if not user_id or not hasPermission(user_id, 'manage_reports') then
    cb({ success = false, error = 'Permissão negada.' })
    return
  end

  local reportedId = tonumber(data.reportedId)
  local motivo = tostring(data.reason or '')
  if not reportedId or motivo == '' then cb({ success = false, error = 'Dados inválidos.' }); return end

  sqlExec('INSERT INTO vrp_admin_panel_reports (reported_id, reporter_id, motivo, status, criado_em) VALUES (?, ?, ?, "aberto", NOW())',
    {reportedId, user_id, motivo})

  writeLog(config.logs_path, os.date('%Y-%m-%d %H:%M:%S') .. string.format(' [REPORT] reporter=%d target=%d reason=%s', user_id, reportedId, motivo))
  cb({ success = true })
end)

RegisterNUICallback('getReports', function(data, cb)
  local src = source
  local user_id = getUserId(src)
  if not user_id or not hasPermission(user_id, 'manage_reports') then
    cb({ success = false, error = 'Permissão negada.' })
    return
  end

  sqlQuery('SELECT * FROM vrp_admin_panel_reports ORDER BY criado_em DESC LIMIT 100', {}, function(result)
    cb({ success = true, reports = result or {} })
  end)
end)

RegisterNUICallback('resolveReport', function(data, cb)
  local src = source
  local user_id = getUserId(src)
  if not user_id or not hasPermission(user_id, 'manage_reports') then
    cb({ success = false, error = 'Permissão negada.' })
    return
  end

  local reportId = tonumber(data.reportId)
  if not reportId then cb({ success = false, error = 'ID inválido.' }); return end

  sqlExec('UPDATE vrp_admin_panel_reports SET status = ?, atualizado_em = NOW() WHERE id = ?', {tostring(data.status or 'resolvido'), reportId})
  cb({ success = true })
end)

-- 4) Dashboard de Saúde do servidor
RegisterNUICallback('getServerStats', function(data, cb)
  local stats = {
    players = #GetPlayers(),
    uptime = os.time() - (GetConvarInt('server_start_time', os.time()) or os.time()),
    memory = collectgarbage('count'),
    fps = GetConvarInt('onesync_framerate', 0),
    cpu = GetConvarInt('server_cpu', 0)
  }
  cb({ success = true, stats = stats })
end)

-- 5) Controle dinâmico de permissões (Admin roles)
RegisterNUICallback('setRolePermission', function(data, cb)
  local src = source
  local user_id = getUserId(src)
  if not user_id or not isDonor(user_id) then
    cb({ success = false, error = 'Apenas dono.' })
    return
  end

  local role = tostring(data.role or '')
  local perm = tostring(data.permission or '')
  local value = data.value == true
  if config.roles[role] == nil then cb({ success = false, error = 'Cargo inválido.' }); return end

  config.roles[role][perm] = value
  saveAdmins()
  cb({ success = true })
end)

RegisterNUICallback('getRoles', function(data, cb)
  local src = source
  local user_id = getUserId(src)
  if not user_id or not hasPermission(user_id, 'manage_admins') then
    cb({ success = false, error = 'Permissão negada.' })
    return
  end
  cb({ success = true, roles = config.roles })
end)

-- 6) Economia
RegisterNUICallback('getPlayerMoney', function(data, cb)
  local src = source
  local user_id = getUserId(src)
  if not user_id or not hasPermission(user_id, 'manage_economy') then
    cb({ success = false, error = 'Permissão negada.' })
    return
  end

  local targetId = tonumber(data.targetId)
  if not targetId then cb({ success = false, error = 'ID inválido.' }); return end

  if vRP.getBankMoney then
    local money = vRP.getBankMoney({targetId})
    cb({ success = true, money = money or 0 })
  else
    cb({ success = false, error = 'Função de economia não disponível.' })
  end
end)

RegisterNUICallback('setPlayerMoney', function(data, cb)
  local src = source
  local user_id = getUserId(src)
  if not user_id or not hasPermission(user_id, 'manage_economy') then
    cb({ success = false, error = 'Permissão negada.' })
    return
  end

  local targetId = tonumber(data.targetId)
  local amount = tonumber(data.amount)
  if not targetId or amount == nil then cb({ success = false, error = 'Dados inválidos.' }); return end

  if vRP.setBankMoney then
    vRP.setBankMoney({targetId, amount})
    writeLog(config.logs_path, os.date('%Y-%m-%d %H:%M:%S') .. string.format(' [ECONOMIA] admin=%d target=%d amount=%d', user_id, targetId, amount))
    cb({ success = true })
  else
    cb({ success = false, error = 'Função de economia não disponível.' })
  end
end)

-- 7) Clima e hora
RegisterNUICallback('setWeather', function(data, cb)
  local src = source
  local user_id = getUserId(src)
  if not user_id or not hasPermission(user_id, 'manage_weather') then
    cb({ success = false, error = 'Permissão negada.' })
    return
  end

  local weather = tostring(data.weather or '')
  if weather == '' then cb({ success = false, error = 'Tempo inválido.' }); return end

  TriggerClientEvent('vrp_admin_panel:setWeather', -1, weather)
  writeLog(config.logs_path, os.date('%Y-%m-%d %H:%M:%S') .. string.format(' [WEATHER] admin=%d weather=%s', user_id, weather))
  cb({ success = true })
end)

RegisterNUICallback('setTime', function(data, cb)
  local src = source
  local user_id = getUserId(src)
  if not user_id or not hasPermission(user_id, 'manage_weather') then
    cb({ success = false, error = 'Permissão negada.' })
    return
  end

  local hour = tonumber(data.hour)
  local minute = tonumber(data.minute)
  if not hour or not minute or hour < 0 or hour > 23 or minute < 0 or minute > 59 then
    cb({ success = false, error = 'Hora inválida.' }); return
  end

  TriggerClientEvent('vrp_admin_panel:setTime', -1, hour, minute)
  writeLog(config.logs_path, os.date('%Y-%m-%d %H:%M:%S') .. string.format(' [TIME] admin=%d hora=%02d:%02d', user_id, hour, minute))
  cb({ success = true })
end)

-- 8) Limpeza / manutenção do banco
RegisterNUICallback('cleanupDatabase', function(data, cb)
  local src = source
  local user_id = getUserId(src)
  if not user_id or not isDonor(user_id) then
    cb({ success = false, error = 'Apenas dono.' })
    return
  end

  sqlExec('DELETE FROM vrp_admin_panel_logs WHERE created_at < DATE_SUB(NOW(), INTERVAL 90 DAY)')
  sqlExec('DELETE FROM vrp_admin_panel_admin_chat WHERE enviado_em < DATE_SUB(NOW(), INTERVAL 30 DAY)')
  sqlExec('DELETE FROM vrp_admin_panel_reports WHERE criado_em < DATE_SUB(NOW(), INTERVAL 90 DAY)')
  sqlExec('DELETE FROM vrp_admin_panel_bans WHERE expira_em IS NOT NULL AND expira_em < NOW()')

  writeLog(config.logs_path, os.date('%Y-%m-%d %H:%M:%S') .. string.format(' [CLEANUP] dono=%d', user_id))
  cb({ success = true, message = 'Limpeza realizada com sucesso.' })
end)

-- ═══════════════════════════════════════════════════════════════════
-- SISTEMA DE CHAT E AVISOS PARA ADMINS
-- ═══════════════════════════════════════════════════════════════════

RegisterNUICallback('getAdminChat', function(data, cb)
  local src = source
  local user_id = getUserId(src)
  
  if not user_id or not isAdmin(user_id) then
    cb({ success = false, error = 'Apenas admins podem acessar.' })
    return
  end
  
  sqlQuery('SELECT admin_id, mensagem, tipo, enviado_em FROM vrp_admin_panel_admin_chat ORDER BY enviado_em DESC LIMIT 50', {}, function(result)
    local messages = {}
    if result and #result > 0 then
      for i = #result, 1, -1 do
        table.insert(messages, {
          admin_id = result[i].admin_id,
          mensagem = result[i].mensagem,
          tipo = result[i].tipo,
          enviado_em = result[i].enviado_em
        })
      end
    end
    cb({ success = true, messages = messages })
  end)
end)

RegisterNUICallback('sendAdminMessage', function(data, cb)
  local src = source
  local user_id = getUserId(src)
  
  if not user_id or not isAdmin(user_id) then
    cb({ success = false, error = 'Sem permissão.' })
    return
  end
  
  local mensagem = tostring(data.message or ''):sub(1, 500)
  if mensagem == '' then
    cb({ success = false, error = 'Mensagem vazia.' })
    return
  end
  
  -- Salva no banco
  sqlExec('INSERT INTO vrp_admin_panel_admin_chat (admin_id, mensagem, tipo) VALUES (?, ?, ?)',
    {user_id, mensagem, data.type or 'normal'})
  
  -- Log da mensagem
  writeLog(config.logs_path, os.date('%Y-%m-%d %H:%M:%S') .. string.format(' [ADMIN CHAT] admin=%d mensagem=%s', user_id, mensagem))
  
  -- Notifica todos os admins online
  for adminId, adminData in pairs(activeAdmins) do
    TriggerClientEvent('vrp_admin_panel:newAdminMessage', adminData.source, {
      admin_id = user_id,
      mensagem = mensagem,
      tipo = data.type or 'normal',
      enviado_em = os.date('%H:%M:%S')
    })
  end
  
  cb({ success = true })
end)

RegisterNUICallback('getAnnouncements', function(data, cb)
  local src = source
  local user_id = getUserId(src)
  
  if not user_id or not isAdmin(user_id) then
    cb({ success = false, error = 'Sem permissão.' })
    return
  end
  
  sqlQuery('SELECT titulo, mensagem, tipo, criado_em FROM vrp_admin_panel_system_announcements WHERE ativo = 1 ORDER BY criado_em DESC LIMIT 20', {}, function(result)
    local announcements = {}
    if result and #result > 0 then
      for _, row in ipairs(result) do
        table.insert(announcements, {
          titulo = row.titulo,
          mensagem = row.mensagem,
          tipo = row.tipo,
          criado_em = row.criado_em
        })
      end
    end
    cb({ success = true, announcements = announcements })
  end)
end)

RegisterNUICallback('createAnnouncement', function(data, cb)
  local src = source
  local user_id = getUserId(src)
  
  if not user_id or not isDonor(user_id) then
    cb({ success = false, error = 'Apenas dono pode criar avisos.' })
    return
  end
  
  local titulo = tostring(data.titulo or ''):sub(1, 255)
  local mensagem = tostring(data.mensaje or ''):sub(1, 1000)
  local tipo = tostring(data.tipo or 'info')
  
  if titulo == '' or mensagem == '' then
    cb({ success = false, error = 'Título ou mensagem vazios.' })
    return
  end
  
  sqlExec('INSERT INTO vrp_admin_panel_system_announcements (titulo, mensagem, tipo, criado_por) VALUES (?, ?, ?, ?)',
    {titulo, mensagem, tipo, user_id})
  
  -- Notifica todos os admins
  for adminId, adminData in pairs(activeAdmins) do
    TriggerClientEvent('vrp_admin_panel:newAnnouncement', adminData.source, {
      titulo = titulo,
      mensagem = mensagem,
      tipo = tipo
    })
  end
  
  Logger.admin(string.format('[AVISO] dono=%d criou aviso: %s', user_id, titulo))
  
  cb({ success = true })
end)

AddEventHandler('playerDropped', function(reason)
  local src = source
  local user_id = getUserId(src)
  if user_id then
    activeAdmins[user_id] = nil
  end
end)

AddEventHandler('onResourceStart', function(resourceName)
  if resourceName == GetCurrentResourceName() then
    ensureSqlTables()
    loadAdmins()
    if config.sql and config.sql.enabled then
      getSqlWhitelist()
    else
      loadWhitelist()
    end

    local wlcount = 0
    for _, v in pairs(whitelist) do if v then wlcount = wlcount + 1 end end
    print(('[vrp_admin_panel] Whitelist carregada com %d players'):format(wlcount))
    local adminCount = 0
    for _ in pairs(config.admins) do adminCount = adminCount + 1 end
    print(('[vrp_admin_panel] Admins carregados: %d'):format(adminCount))
  end
end)
