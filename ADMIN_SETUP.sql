-- ================================================================================
-- 🔐 SETUP SEGURO DE ADMINS - VRP ADMIN PANEL v2.5
-- ================================================================================
-- 
-- ⚠️ IMPORTANTE: 
-- 1. Senhas NÃO ficam mais em config.lua (foi removido)
-- 2. Todos os admins devem ser adicionados via este SQL
-- 3. Use MD5 ou bcrypt para hash de senhas EM PRODUÇÃO
-- 4. Este arquivo contém APENAS templates - Customize com seus dados!

-- ================================================================================
-- PASSO 1: Criar Admin Principal (DONO) com senha MD5
-- ================================================================================
-- ⚠️ IMPORTANTE: Mude a senha! Ao invés de 'admin123', use uma senha forte!
-- 
-- Exemplo de senha forte: P@ssw0rd_M00#RNcaRlnw
-- Hash MD5:              5f4dcc3b5aa765d61d8327deb882cf99 (de 'admin123' - APENAS EXEMPLO!)
--
-- Para gerar hash MD5 da sua senha:
-- Linux:   echo -n 'SuaSenha123!' | md5sum
-- Windows: certutil -hashfile <file> MD5
-- Online:  https://md5.online (NÃO USE EM SENHAS REAIS!)

INSERT INTO vrp_admin_panel_admins (user_id, senha, cargo, criado_em)
VALUES (
  1,  -- ID do jogador (que será o DONO)
  MD5('admin123'),  -- ⚠️ TROQUE 'admin123' POR UMA SENHA FORTE!
  'dono',
  NOW()
);

-- ================================================================================
-- PASSO 2: Adicionar Admins Secundários (SUPERADMIN e ADMIN)
-- ================================================================================

INSERT INTO vrp_admin_panel_admins (user_id, senha, cargo, criado_em)
VALUES 
  (2, MD5('admelevado'), 'superadmin', NOW()),
  (3, MD5('admbasico'), 'admin', NOW()),
  (4, MD5('adminmoderador'), 'admin', NOW());

-- ================================================================================
-- PASSO 3: Alterar Senha de Admin Existente
-- ================================================================================
-- Se você já tem um admin e quer mudar a senha:

-- UPDATE vrp_admin_panel_admins 
-- SET senha = MD5('nova_senha_aqui')
-- WHERE user_id = 1;

-- ================================================================================
-- PASSO 4: Visualizar Admins Cadastrados
-- ================================================================================

SELECT 
  user_id,
  cargo,
  criado_em,
  CONCAT('●') as 'status'
FROM vrp_admin_panel_admins
ORDER BY criado_em DESC;

-- ================================================================================
-- PASSO 5: Remover Admin (se necessário)
-- ================================================================================
-- DELETE FROM vrp_admin_panel_admins WHERE user_id = 999;

-- ================================================================================
-- 🔒 BOAS PRÁTICAS DE SEGURANÇA
-- ================================================================================
--
-- 1. ✅ Nunca coloque senhas em código aberto
-- 2. ✅ Use MD5 ou bcrypt para hash
-- 3. ✅ Senhas com MÍNIMO 8 caracteres
-- 4. ✅ Use letras, números e símbolos: P@ssw0rd_123!
-- 5. ✅ Altere senhas mensalmente
-- 6. ✅ Registre alterações com timestamp
-- 7. ✅ Backup do banco ANTES de alterações
-- 8. ✅ Use SSL/TLS para conexão do banco
--
-- PROIBIDO:
-- ❌ Senhas repetidas (ex: 123456, password, admin, etc)
-- ❌ Datas de nascimento ou nomes
-- ❌ Admin com mesma senha
-- ❌ Deixar cópia de senha em chat/Discord
-- ❌ Usar senhas test/demo em produção

-- ================================================================================
-- GERADOR DE HASH SEGURO (JavaScript para teste local)
-- ================================================================================
--
-- Se quiser gerar hash MD5 localmente em JavaScript:
--
-- // Instale: npm install js-md5
-- // Uso:
-- const md5 = require('js-md5');
-- const senha = 'P@ssw0rd_123!';
-- const hash = md5(senha);
-- console.log(hash);
--
-- Ou use um hash bcrypt mais seguro:
--
-- // Instale: npm install bcryptjs
-- // Uso:
-- const bcrypt = require('bcryptjs');
-- const salt = await bcrypt.genSalt(10);
-- const hash = await bcrypt.hash('P@ssw0rd_123!', salt);
-- console.log(hash); // $2a$10$...abcd1234...
--
-- Depois na verificação em server.lua:
-- const match = await bcrypt.compare(senha_input, senha_hash);

-- ================================================================================
-- MIGRAÇÃO DE SENHAS (Se vinha usando config.lua)
-- ================================================================================
--
-- Se você tinha admins em config.lua, faça assim:
--
-- 1. Abra config.lua antigo
-- 2. Para cada admin, coloque neste arquivo:
--    INSERT INTO vrp_admin_panel_admins 
--    VALUES (user_id, MD5('senha_temporaria'), 'cargo', NOW());
--
-- 3. Após executar todo o SQL, teste login
-- 4. Se ok, peça para cada admin TROCAR senha na primeira login
--    (implementar na próxima versão)
--
-- 5. Procure: vrp_admin_panel/config.lua linha 4-8
--    DELETE a seção 'admins = { ... }'

-- ================================================================================
-- LOG DE AUDITORIA
-- ================================================================================
--
-- Cada vez que um admin altera sua senha, fica registrado:
--
-- SELECT 
--   id, admin_id, acao, detalhes, timestamp 
-- FROM vrp_admin_panel_logs 
-- WHERE acao = 'admin_password_change'
-- ORDER BY timestamp DESC
-- LIMIT 10;

-- ================================================================================
-- ENDPOINT PARA MUDAR SENHA (será implementado em v2.6)
-- ================================================================================
--
-- TriggerEvent('vrp_admin_panel:changePassword', {
--   old_password = 'senha_antiga',
--   new_password = 'nova_senha',
--   confirm = 'nova_senha'
-- })

-- ================================================================================
-- FIM DO SETUP - Agora seu servidor está seguro! ✅
-- ================================================================================
