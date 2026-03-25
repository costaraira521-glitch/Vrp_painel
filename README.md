# 🔐 VRP Admin Panel - Sistema Completo de Administração

**Versão:** 2.0 | **Compatível com:** FiveM + vRP/vRPex | **Banco:** MySQL/MariaDB

Painel admin profissional com NUI modernizada, sistema de whitelist, gerenciamento de grupos, logging completo e múltiplas funcionalidades de administração.

---

## 🎯 Características Principais

### ✨ **Interface Moderna**
- Dark theme profissional com gradientes
- Responsiva e intuitiva
- Abas organizadas por funcionalidade
- Feedback visual instantâneo

### 🔐 **Sistema de Autenticação**
- Login seguro com user_id + senha
- Proteção contra força bruta (múltiplas tentativas)
- Rastreamento de sessões
- Histórico de tentativas de acesso

### 👥 **Gerenciamento de Admins**
- Criar/editar/deletar administradores
- 3 níveis de cargo: **Dono**, **Superadmin**, **Admin**
- Permissões granulares por cargo
- Log de alterações

### ⚪ **Sistema de Whitelist**
- Pergunta de acesso para novos jogadores
- Aprovação manual ou automática
- Histórico de aprovações
- Bloqueio de múltiplas tentativas

### 👫 **Gerenciamento de Grupos**
- Definir grupo de qualquer jogador
- Lista configurável de grupos
- Histórico completo de mudanças
- Integração total com vRP

### 📊 **Comandos Admin**
| Comando | O que faz | Permissão |
|---------|----------|-----------|
| **Kick** | Expulsa jogador | `kick` |
| **Heal** | Cura jogador (200 HP) | `heal` |
| **Revive** | Revive + Armadura | `revive` |
| **Teleport** | Teletransporta até jogador | `teleport` |
| **Freeze** | Congela/descongela | `freeze` |
| **Grupo** | Define grupo do jogador | `manage_groups` |

### 📋 **Sistema de Logs**
- Log completo de TODAS as ações
- Separação: Admin Logs + Owner Logs
- Filtros avançados por tipo/data
- Rastreamento de IP
- Integração com Discord Webhook

### 🗄️ **Banco de Dados Robusto**
- 10 tabelas otimizadas
- Índices de performance
- Views para relatórios
- Suporte a queries complexas

---

## 📁 Estrutura do Projeto

```
vrp_admin_panel/
├── fxmanifest.lua              # Metadata do recurso
├── client.lua                  # Scripts do lado cliente
├── server.lua                  # Scripts do lado servidor (460+ linhas)
├── config.lua                  # Configurações principais
├── sql_schema.sql              # Schema SQL completo (250+ linhas)
│
├── html/
│   ├── index.html              # Interface NUI
│   ├── app.js                  # Lógica frontend (350+ linhas)
│   └── styles.css              # Estilos (300+ linhas)
│
├── INSTALACAO.md               # Guia passo-a-passo
├── QUERIES_MANUTENCAO.sql      # Queries úteis para BD
└── README.md                   # Este arquivo
```

---

## 🗄️ Tabelas SQL (10 no Total)

| Tabela | Função | Registros |
|--------|--------|-----------|
| `vrp_admin_panel_admins` | Credenciais de admins | ~10 |
| `vrp_admin_panel_whitelist` | Controle de acesso | Dinâmico |
| `vrp_admin_panel_logs` | Auditoria de ações | ~100K |
| `vrp_admin_panel_bans` | Banimentos ativos | ~1K |
| `vrp_admin_panel_group_history` | Histórico de grupos | ~10K |
| `vrp_admin_panel_commands` | Ações executadas | ~100K |
| `vrp_admin_panel_sessions` | Login/Logout | ~10K |
| `vrp_admin_panel_login_attempts` | Tentativas de acesso | ~50K |
| `vrp_admin_panel_warnings` | Avisos de jogadores | Dinâmico |
| `vrp_admin_panel_warning_logs` | Histórico de avisos | ~10K |

**Total Espaço:** ~50-100MB (dependendo da idade do servidor)

---

## 🚀 Instalação Rápida

### 1️⃣ **Banco de Dados**
```bash
# Abra seu cliente MySQL e execute:
source /caminho/para/sql_schema.sql
```

### 2️⃣ **Arquivo no Servidor**
```bash
# Copie para:
seu_servidor/resources/vrp_admin_panel/
```

### 3️⃣ **server.cfg**
```lua
ensure vrp
ensure vrp_admin_panel
```

### 4️⃣ **Adicionar Admin**
```sql
INSERT INTO vrp_admin_panel_admins (user_id, senha, cargo) 
VALUES (1, 'admin123', 'dono');
```

### 5️⃣ **Verificar**
```
/paineladm  ou  /adminlog
```

> 👉 **Guia completo em** [INSTALACAO.md](INSTALACAO.md)

---

## 🎮 Como Usar

### Abrir Painel
```
/paineladm
/adminlog
```

### Login
- **Username:** Seu `user_id` do vRP
- **Senha:** Definida em `config.lua` ou banco

### Abas Principais

#### 🏠 **Home**
- Dashboard com estatísticas
- Gráfico de atividade em tempo real
- Status de admins online

#### 🔍 **Buscar Player**
- Procura jogador por ID
- Mostra dados (nome, telefone, dinheiro)
- Localização em tempo real

#### ⚙️ **Comandos**
- Aplicar kick, heal, revive
- Ativar/desativar nometags
- Feedback instantâneo

#### 📊 **Logs ADM**
- Ver todas as ações admin
- Filtrar por tipo/data
- Exportar relatórios

#### 🔑 **Logs Dono**
- Apenas para dono
- Ações sensíveis
- Relatórios executivos

#### ✅ **Whitelist**
- Ver jogadores aprovados
- Gerenciar requisições
- Histórico de aprovações

#### 👨‍💼 **Gestão Admin**
- Criar novo admin
- Editar cargo/senha
- Listar todos admins

#### 👫 **Grupos**
- Buscar jogador
- Ver grupo atual
- Definir novo grupo
- Histórico de mudanças

---

## 🔐 Sistema de Permissões

### **Cargo: DONO**
```
✅ Criar/editar admins
✅ Gerenciar whitelist
✅ Ver logs do dono
✅ Tudo mais
```

### **Cargo: SUPERADMIN**
```
✅ Kick/Heal/Revive
✅ Gerenciar whitelist
✅ Definir grupos
✅ Ver logs
❌ Criar admins
```

### **Cargo: ADMIN**
```
✅ Kick/Heal/Revive
✅ Definir grupos
✅ Ver logs básicos
❌ Administrativo
```

---

## ⚙️ Configuração

### `config.lua`

```lua
-- Cargos e permissões
roles = {
  dono = { manage_admins=true, ... },
  superadmin = { ... },
  admin = { ... }
}

-- Grupos disponíveis
groups = {'user', 'moderador', 'admin', 'vip', ...}

-- Banco de dados
database = {
  enabled = true,
  driver = 'ghmattimysql',
  host = '127.0.0.1',
  database = 'vrp',
  username = 'root',
  password = '',
  port = 3306,
}

-- Discord Webhook
webhook = {
  enabled = false,
  url = 'https://discord.com/api/webhooks/...',
}
```

---

## 📊 Queries SQL Úteis

**Ver todos os admins:**
```sql
SELECT * FROM vrp_admin_panel_admins;
```

**Últimas 50 ações:**
```sql
SELECT * FROM vrp_admin_panel_logs ORDER BY criado_em DESC LIMIT 50;
```

**Bans ativos:**
```sql
SELECT * FROM vrp_admin_panel_bans WHERE ativo = 1;
```

**Limpar logs antigos:**
```sql
DELETE FROM vrp_admin_panel_logs WHERE criado_em < DATE_SUB(NOW(), INTERVAL 90 DAY);
```

> 👉 Mais queries em [QUERIES_MANUTENCAO.sql](QUERIES_MANUTENCAO.sql)

---

## 🐛 Troubleshooting

| Problema | Solução |
|----------|---------|
| "Acesso negado" | Verifique user_id em `vrp_admin_panel_admins` |
| Banco não conecta | Teste credenciais no `config.lua` |
| Painel não abre | Certifique `ensure vrp_admin_panel` em server.cfg |
| Whitelist não funciona | Verifique `whitelist.enabled = true` |
| Grupos não aparecem | Confirme função `vRP.addUserGroup` existe |

---

## 📈 Performance

- **Índices:** 20+ índices otimizados
- **Views:** Para relatórios rápidos
- **Cache:** Dados em memória na startup
- **Queries:** Timeouts de 30s
- **Logs:** Rotação após 90 dias

---

## 🔒 Segurança

✅ **Validação de entrada completa**  
✅ **Proteção contra força bruta**  
✅ **Rastreamento de IP**  
✅ **Hashing de senhas**  
✅ **Logs auditáveis**  
✅ **Separação de permissões**  

---

## 🚀 Roadmap Futuro

- [ ] Ban system avançado
- [ ] Avisos automáticos
- [ ] Integração com Discord
- [ ] API pública
- [ ] Dashboard web externo
- [ ] Mobile app para admins
- [ ] Sistema de reports de jogadores
- [ ] Anti-cheat integrado

---

## 📞 Suporte

Para dúvidas ou problemas:

1. Leia [INSTALACAO.md](INSTALACAO.md)
2. Consulte [QUERIES_MANUTENCAO.sql](QUERIES_MANUTENCAO.sql)
3. Verifique logs do servidor
4. Teste banco de dados diretamente

---

## 📄 Licença

Livre para uso e modificação em FiveM.

---

## 👨‍💻 Desenvolvimento

**Versão:** 2.0  
**Atualizado:** 25 de março de 2026  
**Status:** ✅ Produção  
**Teste em:** VRPex Padrão  

---

**Made with ❤️ for FiveM Servers**

