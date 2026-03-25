-- ╔════════════════════════════════════════════════════════════════════╗
-- ║        VRP ADMIN PANEL - QUERIES DE MANUTENÇÃO E DIAGNÓSTICO       ║
-- ║              Útil para gerenciar e verificar o banco               ║
-- ╚════════════════════════════════════════════════════════════════════╝

-- ═══════════════════════════════════════════════════════════════════
-- 1. VERIFICAÇÃO DE INTEGRIDADE
-- ═══════════════════════════════════════════════════════════════════

-- Verificar se todas as tabelas existem
SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'vrp' 
AND TABLE_NAME LIKE 'vrp_admin_panel_%'
ORDER BY TABLE_NAME;

-- Tamanho de cada tabela (em MB)
SELECT 
  TABLE_NAME,
  ROUND(((data_length + index_length) / 1024 / 1024), 2) AS Size_MB
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'vrp' 
AND TABLE_NAME LIKE 'vrp_admin_panel_%'
ORDER BY (data_length + index_length) DESC;

-- ═══════════════════════════════════════════════════════════════════
-- 2. GERENCIAR ADMINS
-- ═══════════════════════════════════════════════════════════════════

-- Ver todos os admins cadastrados
SELECT 
  user_id,
  cargo,
  'HIDDEN' AS senha,
  criado_em,
  atualizado_em
FROM vrp_admin_panel_admins
ORDER BY cargo DESC, user_id;

-- Adicionar novo admin
INSERT INTO vrp_admin_panel_admins (user_id, senha, cargo) 
VALUES (5, 'senha_segura_123', 'admin')
ON DUPLICATE KEY UPDATE cargo='admin', atualizado_em=NOW();

-- Trocar cargo de admin
UPDATE vrp_admin_panel_admins 
SET cargo = 'superadmin' 
WHERE user_id = 2;

-- Remover admin
DELETE FROM vrp_admin_panel_admins 
WHERE user_id = 5;

-- ═══════════════════════════════════════════════════════════════════
-- 3. GERENCIAR WHITELIST
-- ═══════════════════════════════════════════════════════════════════

-- Ver jogadores na whitelist
SELECT 
  user_id,
  CASE WHEN aprovado = 1 THEN '✓ Aprovado' ELSE '✗ Pendente' END AS Status,
  aprovado_em,
  aprovado_por
FROM vrp_admin_panel_whitelist
WHERE aprovado = 1
ORDER BY aprovado_em DESC;

-- Ver pendências de whitelist
SELECT 
  user_id,
  tentativas,
  ultima_tentativa
FROM vrp_admin_panel_whitelist
WHERE aprovado = 0
ORDER BY ultima_tentativa DESC;

-- Aprovar jogador na whitelist
UPDATE vrp_admin_panel_whitelist 
SET aprovado = 1, aprovado_em = NOW(), aprovado_por = 1
WHERE user_id = 10;

-- Remover de whitelist
DELETE FROM vrp_admin_panel_whitelist 
WHERE user_id = 10;

-- ═══════════════════════════════════════════════════════════════════
-- 4. VISUALIZAR LOGS
-- ═══════════════════════════════════════════════════════════════════

-- Últimas 50 ações de qualquer tipo
SELECT 
  id,
  tipo,
  admin_id,
  target_id,
  SUBSTRING(mensagem, 1, 60) AS mensagem_resumo,
  criado_em
FROM vrp_admin_panel_logs
ORDER BY criado_em DESC
LIMIT 50;

-- Log por tipo de ação
SELECT 
  tipo,
  COUNT(*) AS total,
  MAX(criado_em) AS ultima_acao
FROM vrp_admin_panel_logs
GROUP BY tipo
ORDER BY total DESC;

-- Ações de um admin específico
SELECT 
  criado_em,
  tipo,
  target_id,
  mensagem
FROM vrp_admin_panel_logs
WHERE admin_id = 1
ORDER BY criado_em DESC
LIMIT 20;

-- Ações contra um jogador específico
SELECT 
  criado_em,
  tipo,
  admin_id,
  mensagem
FROM vrp_admin_panel_logs
WHERE target_id = 5
ORDER BY criado_em DESC
LIMIT 20;

-- Atividade por data
SELECT 
  DATE(criado_em) AS data,
  COUNT(*) AS total_acoes,
  COUNT(DISTINCT admin_id) AS admins_ativos,
  COUNT(DISTINCT tipo) AS tipos_acao
FROM vrp_admin_panel_logs
GROUP BY DATE(criado_em)
ORDER BY data DESC
LIMIT 30;

-- ═══════════════════════════════════════════════════════════════════
-- 5. GERENCIAR BANS
-- ═══════════════════════════════════════════════════════════════════

-- Ver todos os bans ativos
SELECT 
  id,
  user_id,
  motivo,
  banido_em,
  CASE 
    WHEN expira_em IS NULL THEN 'PERMANENTE'
    WHEN expira_em > NOW() THEN CONCAT(DATEDIFF(expira_em, NOW()), ' dias')
    ELSE 'EXPIRADO'
  END AS duracao,
  banido_por
FROM vrp_admin_panel_bans
WHERE ativo = 1
ORDER BY banido_em DESC;

-- Bans que expiram nos próximos 7 dias
SELECT 
  id,
  user_id,
  DATEDIFF(expira_em, NOW()) AS dias_restantes,
  expira_em
FROM vrp_admin_panel_bans
WHERE ativo = 1 
AND expira_em IS NOT NULL
AND expira_em BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 7 DAY)
ORDER BY expira_em;

-- Banir um jogador (permanente)
INSERT INTO vrp_admin_panel_bans (user_id, banido_por, motivo, expira_em)
VALUES (10, 1, 'Hack/Exploit detectado', NULL);

-- Banir com expiração (7 dias)
INSERT INTO vrp_admin_panel_bans (user_id, banido_por, motivo, expira_em)
VALUES (11, 1, 'Spam no chat', DATE_ADD(NOW(), INTERVAL 7 DAY));

-- Desbanir jogador
UPDATE vrp_admin_panel_bans
SET ativo = 0, removido_por = 1, removido_em = NOW()
WHERE user_id = 10 AND ativo = 1;

-- Limpar bans expirados
UPDATE vrp_admin_panel_bans
SET ativo = 0
WHERE expira_em < NOW() AND ativo = 1;

-- ═══════════════════════════════════════════════════════════════════
-- 6. HISTÓRICO DE GRUPOS
-- ═══════════════════════════════════════════════════════════════════

-- Ver mudanças de grupo de um jogador
SELECT 
  alterado_em,
  CONCAT(grupo_anterior, ' → ', grupo_novo) AS mudanca,
  alterado_por,
  motivo
FROM vrp_admin_panel_group_history
WHERE user_id = 5
ORDER BY alterado_em DESC;

-- Últimas mudanças de grupo (servidor inteiro)
SELECT 
  user_id,
  grupo_anterior,
  grupo_novo,
  alterado_por,
  alterado_em
FROM vrp_admin_panel_group_history
ORDER BY alterado_em DESC
LIMIT 30;

-- Grupos mais promovidos/alterados
SELECT 
  grupo_novo,
  COUNT(*) AS total_promovidos,
  MAX(alterado_em) AS ultima_alteracao
FROM vrp_admin_panel_group_history
GROUP BY grupo_novo
ORDER BY total_promovidos DESC;

-- ═══════════════════════════════════════════════════════════════════
-- 7. SESSÕES DE ADMIN
-- ═══════════════════════════════════════════════════════════════════

-- Ver sessões de admin hoje
SELECT 
  admin_id,
  login_em,
  logout_em,
  duracao_minutos,
  ip
FROM vrp_admin_panel_sessions
WHERE DATE(login_em) = CURDATE()
ORDER BY login_em DESC;

-- Tempo total de admin online (últimos 30 dias)
SELECT 
  admin_id,
  COUNT(*) AS sessoes,
  SEC_TO_TIME(SUM(duracao_minutos * 60)) AS tempo_total
FROM vrp_admin_panel_sessions
WHERE login_em >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY admin_id
ORDER BY SUM(duracao_minutos) DESC;

-- ═══════════════════════════════════════════════════════════════════
-- 8. SEGURANÇA - TENTATIVAS DE LOGIN
-- ═══════════════════════════════════════════════════════════════════

-- Tentativas de login falhadas (últimas 24h)
SELECT 
  user_id,
  ip,
  COUNT(*) AS tentativas_falhadas,
  MAX(tentado_em) AS ultima_tentativa
FROM vrp_admin_panel_login_attempts
WHERE sucesso = 0
AND tentado_em >= DATE_SUB(NOW(), INTERVAL 1 DAY)
GROUP BY user_id, ip
HAVING tentativas_falhadas > 3
ORDER BY tentativas_falhadas DESC;

-- IPs suspeitos (múltiplas tentativas)
SELECT 
  ip,
  COUNT(DISTINCT user_id) AS usuarios_diferentes,
  COUNT(*) AS total_tentativas,
  MAX(tentado_em) AS ultima_tentativa
FROM vrp_admin_panel_login_attempts
WHERE sucesso = 0
AND tentado_em >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY ip
HAVING total_tentativas > 10
ORDER BY total_tentativas DESC;

-- ═══════════════════════════════════════════════════════════════════
-- 9. AVISOS/WARNINGS
-- ═══════════════════════════════════════════════════════════════════

-- Jogadores com avisos
SELECT 
  user_id,
  avisos,
  limite_avisos,
  CONCAT(ROUND((avisos/limite_avisos)*100, 0), '%') AS percentual
FROM vrp_admin_panel_warnings
WHERE avisos > 0
ORDER BY avisos DESC;

-- Histórico de avisos de um jogador
SELECT 
  admin_id,
  motivo,
  momento
FROM vrp_admin_panel_warning_logs
WHERE user_id = 5
ORDER BY momento DESC;

-- ═══════════════════════════════════════════════════════════════════
-- 10. LIMPEZA E MANUTENÇÃO
-- ═══════════════════════════════════════════════════════════════════

-- Remover logs com mais de 90 dias
DELETE FROM vrp_admin_panel_logs 
WHERE criado_em < DATE_SUB(NOW(), INTERVAL 90 DAY);

-- Remover tentativas de login com mais de 30 dias
DELETE FROM vrp_admin_panel_login_attempts 
WHERE tentado_em < DATE_SUB(NOW(), INTERVAL 30 DAY);

-- Limpar bans expirados
UPDATE vrp_admin_panel_bans
SET ativo = 0
WHERE expira_em < NOW() AND ativo = 1;

-- Otimizar todas as tabelas
OPTIMIZE TABLE vrp_admin_panel_admins;
OPTIMIZE TABLE vrp_admin_panel_whitelist;
OPTIMIZE TABLE vrp_admin_panel_logs;
OPTIMIZE TABLE vrp_admin_panel_bans;
OPTIMIZE TABLE vrp_admin_panel_group_history;
OPTIMIZE TABLE vrp_admin_panel_commands;
OPTIMIZE TABLE vrp_admin_panel_sessions;
OPTIMIZE TABLE vrp_admin_panel_login_attempts;
OPTIMIZE TABLE vrp_admin_panel_warnings;
OPTIMIZE TABLE vrp_admin_panel_warning_logs;

-- Verificar integridade das tabelas
CHECK TABLE vrp_admin_panel_admins;
CHECK TABLE vrp_admin_panel_logs;
CHECK TABLE vrp_admin_panel_bans;

-- ═══════════════════════════════════════════════════════════════════
-- 11. RELATÓRIOS E ANÁLISES
-- ═══════════════════════════════════════════════════════════════════

-- Admin mais ativo (últimos 30 dias)
SELECT 
  admin_id,
  COUNT(*) AS total_acoes,
  COUNT(DISTINCT DATE(criado_em)) AS dias_com_acoes,
  COUNT(DISTINCT tipo) AS tipos_acao
FROM vrp_admin_panel_logs
WHERE criado_em >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY admin_id
ORDER BY total_acoes DESC
LIMIT 10;

-- Ações mais comuns
SELECT 
  tipo,
  COUNT(*) AS total,
  ROUND(COUNT(*) * 100 / (SELECT COUNT(*) FROM vrp_admin_panel_logs), 2) AS percentual
FROM vrp_admin_panel_logs
WHERE criado_em >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY tipo
ORDER BY total DESC;

-- Jogadores mais "problemáticos" (mais ações contra eles)
SELECT 
  target_id,
  COUNT(*) AS total_acoes,
  COUNT(DISTINCT tipo) AS tipos_acao,
  MAX(criado_em) AS ultima_acao
FROM vrp_admin_panel_logs
WHERE target_id IS NOT NULL
AND criado_em >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY target_id
ORDER BY total_acoes DESC
LIMIT 20;

-- ═══════════════════════════════════════════════════════════════════
-- EXPORTS / BACKUP
-- ═══════════════════════════════════════════════════════════════════

-- Exportar logs em CSV (via aplicação)
SELECT 
  criado_em,
  tipo,
  admin_id,
  target_id,
  mensagem
FROM vrp_admin_panel_logs
WHERE criado_em >= '2026-01-01'
INTO OUTFILE '/tmp/admin_logs_export.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';

-- Backup completo (via linha de comando):
-- mysqldump -u root -p vrp vrp_admin_panel_* > backup_admin_panel.sql
