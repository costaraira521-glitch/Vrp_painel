# 📋 Guia Completo de Instalação - VRP Admin Panel

## ✅ Requisitos Pré-requisitos

- FiveM Server rodando
- vRP / vRPex instalado e funcionando
- MySQL/MariaDB configurado
- Permissão de execução de arquivos SQL

---

## 🚀 Instalação Passo a Passo

### **Passo 1: Preparar o SQL**

1. Abra seu **phpMyAdmin** ou **MySQL Workbench**
2. Selecione o banco de dados **`vrp`** (ou o nome do seu banco)
3. Vá até a aba **SQL**
4. **Copie todo o conteúdo** do arquivo `sql_schema.sql`
5. **Cole** na área SQL e clique em **Executar**
6. Aguarde a mensagem de sucesso ✓

```sql
-- Verificar se as tabelas foram criadas:
SHOW TABLES LIKE 'vrp_admin_panel_%';
```

**Resultado esperado:**
```
vrp_admin_panel_admins
vrp_admin_panel_bans
vrp_admin_panel_commands
vrp_admin_panel_group_history
vrp_admin_panel_login_attempts
vrp_admin_panel_logs
vrp_admin_panel_sessions
vrp_admin_panel_warnings
vrp_admin_panel_warning_logs
vrp_admin_panel_whitelist
```

---

### **Passo 2: Copiar Resource para o Servidor**

1. Copie a pasta `vrp_admin_panel` para:
   ```
   seu_servidor/resources/
   ```

2. Certifique-se de que a estrutura está correta:
   ```
   resources/vrp_admin_panel/
   ├── client.lua
   ├── server.lua
   ├── config.lua
   ├── fxmanifest.lua
   ├── sql_schema.sql
   └── html/
       ├── index.html
       ├── app.js
       └── styles.css
   ```

---

### **Passo 3: Adicionar no server.cfg**

Abra seu `server.cfg` e adicione a linha:

```cfg
ensure vrp_admin_panel
```

**Certifique-se de que vRP está carregado ANTES:**

```cfg
ensure vRP
ensure vrp_admin_panel  # DEPOIS de vRP
```

---

### **Passo 4: Configurar o Banco de Dados**

Edite o arquivo `config.lua`:

```lua
database = {
  enabled = true,
  driver = 'ghmattimysql', -- ou 'mysql-async'
  host = '127.0.0.1',       -- seu host
  database = 'vrp',         -- seu banco
  username = 'root',        -- seu usuário
  password = '',            -- sua senha
  port = 3306,              -- sua porta
},
```

---

### **Passo 5: Criar Primeiro Admin**

**Opção A: Pelo SQL (Direto)**

```sql
INSERT INTO vrp_admin_panel_admins (user_id, senha, cargo) 
VALUES (1, 'sua_senha_aqui', 'dono');
```

> Replace `1` com seu `user_id` no vRP!

**Opção B: Pelo Arquivo JSON (se banco desabilitado)**

Crie/edite `vrp_admin_panel/admins.json`:

```json
{
  "1": {"senha": "admin123", "cargo": "dono"},
  "2": {"senha": "adm1", "cargo": "admin"},
  "3": {"senha": "adm2", "cargo": "superadmin"}
}
```

---

### **Passo 6: Configurar Grupos (Opcional)**

Edite em `config.lua`:

```lua
groups = {
  'user',
  'moderador',
  'admin',
  'vip',
  'vip_gold',
  'suporte',
  'builder'
}
```

Adicione/remova conforme necessário.

---

### **Passo 7: Configurar Discord Webhook (Opcional)**

Se quiser receber logs no Discord:

```lua
webhook = {
  enabled = true,
  url = 'https://discord.com/api/webhooks/SEU_WEBHOOK_URL_AQUI',
  channel_name = 'admin-log'
}
```

---

### **Passo 8: Iniciar o Servidor**

```bash
./run.cmd  # Windows
```

**Procure pela mensagem:**
```
[VRP Admin Panel] Server loaded successfully!
```

---

## 🎮 Usando o Painel

### **Abrir o Painel**

```
/paineladm
ou
/adminlog
```

### **Login**

- **Usuário:** seu `user_id` (número)
- **Senha:** a senha que configurou

### **Abas Disponíveis**

| Aba | Função | Permissão Mín |
|-----|--------|---------------|
| Home | Dashboard com gráficos | Admin |
| Buscar Player | Info de jogador | Admin |
| Comandos | Kick, Heal, Revive | Admin |
| Logs ADM | Ver ações admin | Admin |
| Logs Dono | Ver ações dono | Dono |
| Whitelist | Gerenciar WL | Superadmin |
| Gestão Admin | Criar/editar admins | Dono |
| Grupos | Definir grupos | Superadmin |

---

## 📊 Estrutura do Banco de Dados

### **Tabela: vrp_admin_panel_admins**
```sql
user_id (INT) | senha (VARCHAR) | cargo (VARCHAR) | criado_em | atualizado_em
```

### **Tabela: vrp_admin_panel_whitelist**
```sql
user_id | aprovado | aprovado_em | aprovado_por | tentativas | ultima_tentativa
```

### **Tabela: vrp_admin_panel_logs**
```sql
id | tipo | admin_id | target_id | mensagem | detalhes | ip_admin | criado_em
```

### **Tabela: vrp_admin_panel_bans**
```sql
id | user_id | banido_por | motivo | banido_em | expira_em | ativo | removido_por | removido_em
```

### **Tabela: vrp_admin_panel_group_history**
```sql
id | user_id | grupo_anterior | grupo_novo | alterado_por | alterado_em | motivo
```

---

## 🔐 Sistema de Permissões

### **Cargos Disponíveis**

#### **DONO**
- ✅ Gerenciar todos os admins
- ✅ Chutar/Curar/Reviver jogadores
- ✅ Ver logs do dono
- ✅ Gerenciar whitelist
- ✅ Definir grupos
- ✅ Tudo

#### **SUPERADMIN**
- ✅ Chutar/Curar/Reviver
- ✅ Gerenciar whitelist
- ✅ Definir grupos
- ✅ Ver logs admin
- ❌ Criar novos admins

#### **ADMIN**
- ✅ Chutar/Curar/Reviver
- ✅ Ver logs
- ✅ Definir grupos
- ❌ Gerenciar WL
- ❌ Criar admins

---

## 🛠️ Troubleshooting

### **Erro: "Acesso negado ao painel"**
- Certifique-se de que seu `user_id` está em `vrp_admin_panel_admins`
- Verifique a senha

### **Banco de dados não conecta**
- Teste credenciais no `config.lua`
- Verifique se MySQL está rodando
- Confirme host/porta/password

### **Whitelist não funciona**
- Certifique-se de que `whitelist.enabled = true`
- Limpe o arquivo `whitelist.json`

### **Grupos não aparecem**
- Confirme que vRP `addUserGroup` existe
- Verifique se o grupo existe em vRP

---

## 📝 Queries Úteis

**Listar todos os admins:**
```sql
SELECT * FROM vrp_admin_panel_admins;
```

**Ver últimas ações:**
```sql
SELECT * FROM vrp_admin_panel_logs 
ORDER BY criado_em DESC LIMIT 50;
```

**Ver bans ativos:**
```sql
SELECT * FROM vrp_admin_panel_bans 
WHERE ativo = 1;
```

**Remover admin:**
```sql
DELETE FROM vrp_admin_panel_admins WHERE user_id = 5;
```

**Limpar logs antigos (90 dias):**
```sql
DELETE FROM vrp_admin_panel_logs 
WHERE criado_em < DATE_SUB(NOW(), INTERVAL 90 DAY);
```

---

## 🎯 Próximas Melhorias

- [ ] Sistema de advertências (warnings)
- [ ] Kick automático em X avisos
- [ ] Integração com ban system
- [ ] Estatísticas avançadas
- [ ] API pública para terceiros
- [ ] Sistema de permissões customizáveis

---

## 📞 Suporte

Para problemas ou dúvidas:

1. Verifique o console do servidor (`/cl` no painel)
2. Procure por erros nos logs
3. Confirme que o resource está `ensure`d no server.cfg
4. Teste direto no banco de dados

---

**Última atualização:** 25 de março de 2026
**Versão:** 2.0 - VRPex Compatible
