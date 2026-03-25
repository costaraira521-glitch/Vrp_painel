-- ╔════════════════════════════════════════════════════════════════════╗
-- ║         VRP ADMIN PANEL - SQL SCHEMA COMPLETO (VRPex)              ║
-- ║  Schema otimizado para FiveM + vRP/vRPex com todas as tabelas      ║
-- ║  necessárias para funcionamento completo do painel                  ║
-- ╚════════════════════════════════════════════════════════════════════╝

-- ═══════════════════════════════════════════════════════════════════
-- 1. TABELA DE ADMINS (Credenciais e Permissões)
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `vrp_admin_panel_admins` (
  `user_id` INT NOT NULL PRIMARY KEY,
  `senha` VARCHAR(255) NOT NULL,
  `cargo` VARCHAR(50) NOT NULL DEFAULT 'admin',
  `criado_em` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `atualizado_em` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_cargo` (`cargo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════════
-- 2. TABELA DE WHITELIST (Controle de Acesso Inicial)
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `vrp_admin_panel_whitelist` (
  `user_id` INT NOT NULL PRIMARY KEY,
  `aprovado` TINYINT(1) NOT NULL DEFAULT 0,
  `aprovado_em` TIMESTAMP NULL,
  `aprovado_por` INT NULL,
  `tentativas` INT DEFAULT 0,
  `ultima_tentativa` TIMESTAMP NULL,
  INDEX `idx_aprovado` (`aprovado`),
  INDEX `idx_aprovado_por` (`aprovado_por`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════════
-- 3. TABELA DE LOGS (Auditoria Completa de Ações Admin)
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `vrp_admin_panel_logs` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `tipo` VARCHAR(64) NOT NULL COMMENT 'LOGIN, KICK, HEAL, REVIVE, BAN, UNBAN, TELEPORT, GRUPO_SET, etc',
  `admin_id` INT NOT NULL COMMENT 'ID do admin que executou',
  `target_id` INT NULL COMMENT 'ID do alvo (se aplicável)',
  `mensagem` TEXT NOT NULL,
  `detalhes` JSON NULL COMMENT 'Dados adicionais em JSON',
  `ip_admin` VARCHAR(45) NULL,
  `criado_em` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_tipo` (`tipo`),
  INDEX `idx_admin_id` (`admin_id`),
  INDEX `idx_target_id` (`target_id`),
  INDEX `idx_criado_em` (`criado_em`),
  INDEX `idx_tipo_criado` (`tipo`, `criado_em`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════════
-- 4. TABELA DE BANS (Controle de Proibições)
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `vrp_admin_panel_bans` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `banido_por` INT NOT NULL COMMENT 'Admin que baniu',
  `motivo` TEXT NOT NULL,
  `banido_em` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `expira_em` TIMESTAMP NULL COMMENT 'NULL = banimento permanente',
  `ativo` TINYINT(1) DEFAULT 1,
  `removido_por` INT NULL,
  `removido_em` TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  INDEX `idx_user_id` (`user_id`),
  INDEX `idx_ativo` (`ativo`),
  INDEX `idx_expira_em` (`expira_em`),
  INDEX `idx_banido_por` (`banido_por`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════════
-- 5. TABELA DE REPORTS (Sistema de denúncias)
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `vrp_admin_panel_reports` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `reported_id` INT NOT NULL,
  `reporter_id` INT NOT NULL,
  `motivo` TEXT NOT NULL,
  `status` VARCHAR(50) NOT NULL DEFAULT 'aberto',
  `criado_em` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `atualizado_em` TIMESTAMP NULL,
  INDEX `idx_reported_id` (`reported_id`),
  INDEX `idx_reporter_id` (`reporter_id`),
  INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════════
-- 6. TABELA DE HISTÓRICO DE GRUPOS (Auditoria de Mudanças de Grupo)
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `vrp_admin_panel_group_history` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `grupo_anterior` VARCHAR(50) NULL,
  `grupo_novo` VARCHAR(50) NOT NULL,
  `alterado_por` INT NOT NULL COMMENT 'Admin que alterou',
  `alterado_em` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `motivo` TEXT NULL,
  INDEX `idx_user_id` (`user_id`),
  INDEX `idx_alterado_por` (`alterado_por`),
  INDEX `idx_alterado_em` (`alterado_em`),
  INDEX `idx_user_alterado` (`user_id`, `alterado_em`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════════
-- 6. TABELA DE COMANDOS EXECUTADOS (Histórico Detalhado)
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `vrp_admin_panel_commands` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `admin_id` INT NOT NULL,
  `comando` VARCHAR(100) NOT NULL COMMENT 'kick, heal, revive, teleport, freeze, etc',
  `target_id` INT NULL,
  `sucesso` TINYINT(1) DEFAULT 1,
  `motivo` TEXT NULL,
  `executado_em` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_admin_id` (`admin_id`),
  INDEX `idx_comando` (`comando`),
  INDEX `idx_target_id` (`target_id`),
  INDEX `idx_executado_em` (`executado_em`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════════
-- 7. TABELA DE SESSÕES ADMIN (Rastreamento de Login/Logout)
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `vrp_admin_panel_sessions` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `admin_id` INT NOT NULL,
  `login_em` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `logout_em` TIMESTAMP NULL,
  `ip` VARCHAR(45) NULL,
  `duracao_minutos` INT NULL,
  PRIMARY KEY (`id`),
  INDEX `idx_admin_id` (`admin_id`),
  INDEX `idx_login_em` (`login_em`),
  INDEX `idx_logout_em` (`logout_em`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════════
-- 8. TABELA DE TENTATIVAS DE LOGIN (Segurança)
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `vrp_admin_panel_login_attempts` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `ip` VARCHAR(45) NOT NULL,
  `sucesso` TINYINT(1) DEFAULT 0,
  `tentado_em` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_user_id` (`user_id`),
  INDEX `idx_ip` (`ip`),
  INDEX `idx_tentado_em` (`tentado_em`),
  INDEX `idx_user_ip_hora` (`user_id`, `ip`, `tentado_em`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════════
-- 9. TABELA DE AVISOS (Sistema de Warnings para Jogadores)
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `vrp_admin_panel_warnings` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `avisos` INT DEFAULT 0,
  `limite_avisos` INT DEFAULT 3,
  `criado_em` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `atualizado_em` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_user` (`user_id`),
  INDEX `idx_avisos` (`avisos`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════════
-- 10. TABELA DE AVISOS DETALHADOS (Log de Cada Aviso)
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `vrp_admin_panel_warning_logs` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `admin_id` INT NOT NULL,
  `motivo` TEXT NOT NULL,
  `momento` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_user_id` (`user_id`),
  INDEX `idx_admin_id` (`admin_id`),
  INDEX `idx_momento` (`momento`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════════
-- 11. TABELA DE CHAT DOS ADMINS (Comunicação Entre Admins)
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `vrp_admin_panel_admin_chat` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `admin_id` INT NOT NULL,
  `mensagem` TEXT NOT NULL,
  `tipo` VARCHAR(50) DEFAULT 'normal' COMMENT 'normal, aviso, alerta, importante',
  `enviado_em` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `lido` TINYINT(1) DEFAULT 0,
  INDEX `idx_admin_id` (`admin_id`),
  INDEX `idx_tipo` (`tipo`),
  INDEX `idx_enviado_em` (`enviado_em`),
  INDEX `idx_lido` (`lido`),
  INDEX `idx_admin_enviado` (`admin_id`, `enviado_em`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════════
-- 12. TABELA DE AVISOS DO SISTEMA (Broadcasts para Admins)
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `vrp_admin_panel_system_announcements` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `titulo` VARCHAR(255) NOT NULL,
  `mensagem` TEXT NOT NULL,
  `tipo` VARCHAR(50) DEFAULT 'info' COMMENT 'info, warning, critical, success',
  `criado_por` INT NOT NULL,
  `criado_em` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `ativo` TINYINT(1) DEFAULT 1,
  PRIMARY KEY (`id`),
  INDEX `idx_tipo` (`tipo`),
  INDEX `idx_ativo` (`ativo`),
  INDEX `idx_criado_em` (`criado_em`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════════
-- DADOS INICIAIS / INSERTS OPCIONAIS
-- ═══════════════════════════════════════════════════════════════════

-- Descomente e edite para adicionar admin padrão (garanta que o user_id existe em vrp_users)
-- INSERT INTO `vrp_admin_panel_admins` (`user_id`, `senha`, `cargo`) 
-- VALUES (1, 'admin123', 'dono') 
-- ON DUPLICATE KEY UPDATE `cargo`='dono';

-- ═══════════════════════════════════════════════════════════════════
-- VIEWS ÚTEIS PARA ANÁLISES
-- ═══════════════════════════════════════════════════════════════════

-- View: Adquirir estatísticas de ações por admin
CREATE OR REPLACE VIEW `vw_admin_Statistics` AS
SELECT 
  admin_id,
  COUNT(*) as total_acoes,
  COUNT(DISTINCT DATE(criado_em)) as dias_ativo,
  MAX(criado_em) as ultima_acao
FROM vrp_admin_panel_logs
WHERE criado_em >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY admin_id;

-- View: Bans ativos e informações
CREATE OR REPLACE VIEW `vw_bans_ativos` AS
SELECT 
  b.id,
  b.user_id,
  b.motivo,
  b.banido_em,
  b.expira_em,
  CASE 
    WHEN b.expira_em IS NULL THEN 'Permanente'
    WHEN b.expira_em > NOW() THEN CONCAT(DATEDIFF(b.expira_em, NOW()), ' dias')
    ELSE 'Expirado'
  END as duracao
FROM vrp_admin_panel_bans b
WHERE b.ativo = 1;

-- ═══════════════════════════════════════════════════════════════════
-- COMENTÁRIOS E NOTAS
-- ═══════════════════════════════════════════════════════════════════
/*
INSTRUÇÕES DE USO:

1. EXECUTAR NO MYSQL:
   - Copie todo o conteúdo deste arquivo
   - Abra o phpMyAdmin ou seu cliente MySQL
   - Selecione o banco de dados VRP
   - Cole o conteúdo na aba SQL e execute

2. TABELAS PRINCIPAIS:
   - vrp_admin_panel_admins: Credenciais dos admins
   - vrp_admin_panel_whitelist: Controle de WL
   - vrp_admin_panel_logs: Auditoria completa
   - vrp_admin_panel_bans: Banimentos ativos
   - vrp_admin_panel_group_history: Histórico de mudança de grupos

3. ÍNDICES:
   - Todos otimizados para queries frequentes
   - Use EXPLAIN para analisar performance

4. RELACIONAMENTOS:
   - user_id referencia a tabela vrp_users do vRP
   - admin_id também referencia vrp_users
   - Manter integridade referencial

5. LIMPEZA DE DADOS ANTIGOS:
   -- Remover logs com mais de 90 dias
   DELETE FROM vrp_admin_panel_logs WHERE criado_em < DATE_SUB(NOW(), INTERVAL 90 DAY);
   
   -- Remover tentativas de login antigas
   DELETE FROM vrp_admin_panel_login_attempts WHERE tentado_em < DATE_SUB(NOW(), INTERVAL 30 DAY);

6. PERFORMANCE:
   - Banco está otimizado com índices apropriados
   - Runs de queries pesadas no período off-peak
   - Considere usar arquivamento para logs antigos
*/

