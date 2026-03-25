-- SQL schema for vrp_admin_panel (FiveM vRP/vRPex)
-- Execute in your MySQL database (e.g. using phpMyAdmin, MySQL client, etc.)

CREATE TABLE IF NOT EXISTS vrp_admin_panel_admins (
  id INT AUTO_INCREMENT PRIMARY KEY,
  identifier VARCHAR(255) NOT NULL UNIQUE,
  role VARCHAR(64) NOT NULL,
  name VARCHAR(255) NULL,
  added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS vrp_admin_panel_whitelist (
  id INT AUTO_INCREMENT PRIMARY KEY,
  identifier VARCHAR(255) NOT NULL UNIQUE,
  name VARCHAR(255),
  whitelisted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS vrp_admin_panel_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  type VARCHAR(64) NOT NULL,
  source_id VARCHAR(128),
  target_id VARCHAR(128),
  message TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Optional: Insere admin principal (dono) já definido no config.lua
-- Substitua 'steam:123...' pelo seu identificador real do dono
INSERT INTO vrp_admin_panel_admins (identifier, role, name) VALUES
('steam:1234567890abcdef', 'dono', 'Proprietário');
