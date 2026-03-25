# VRP Painel Admin (FiveM)

Painel completo de administração para VRP com NUI (login, abas, busca por ID, comandos de kick/heal, logs de admin e logs do dono).

## Instalação

1. Copie a pasta `vrp_admin_panel` para o `resources` do servidor.
2. No `server.cfg`, adicione:

   ensure vrp_admin_panel

3. Reinicie o servidor.

## Como usar

- Comando para abrir o painel: `/paineladm` ou `/adminlog`.
- Login: preencha usuário (ID do admin/NUI) e senha do `config.lua`.
- Acesso por cargo:
  - `dono`: vê logs de administrador e logs de dono.
  - `admin`, `superadmin`: vê logs de administrador.

## Configuração de admins

Em `vrp_admin_panel/config.lua`:

- `admins[user_id] = { senha = '...', cargo = 'admin|superadmin|dono' }`

Exemplo:

```
[1] = { senha = 'admin123', cargo = 'dono' }
[2] = { senha = 'adm1', cargo = 'admin' }
```

## Funcionalidades do Painel

- Login com validação e gravação de logs.
- Aba "Home": status de admins e usuário logado.
- Aba "Buscar Player": busca dados do jogador por user_id.
- Aba "Comandos": kick/heal via NUI.
- Aba "Logs ADM": contém ações de admins.
- Aba "Logs Dono": conteúdo exclusivo para dono.
- Aba "Whitelist": gerencia jogadores aprovados pela pergunta.

## Whitelist no servidor

1. Quando um jogador entra pela primeira vez, o painel de WL abre automaticamente com uma pergunta.
2. O jogador deve responder corretamente (configurável no `config.lua` em `whitelist_question`/`whitelist_answer`).
3. Acertando, o jogador é marcado como liberado e removido do fluxo de WL.
4. O painel ADM mostra a lista de IDs `whitelisted` em `Whitelist` (admin com permissão `manage_wl`).

## Métricas e gráficos

- A aba `Home` agora exibe um gráfico de atividade em tempo real para ações do admin.
- O gráfico é atualizado com eventos de comandos, WL e ações em tempo real.

## SQL/MySQL (integração completa)

- Configure em `config.lua`:

```lua
sql = {
  enabled = true,
  driver = 'ghmattimysql', -- ou 'mysql-async'
  host = '127.0.0.1',
  database = 'vrp',
  username = 'root',
  password = '',
  port = 3306,
}
```

- O script cria tabelas automaticamente em `onResourceStart`:
  - `vrp_admin_panel_admins`
  - `vrp_admin_panel_whitelist`
  - `vrp_admin_panel_logs`

- Use tabela para manter credenciais sempre persistentes.
- Logs também vão para `vrp_admin_panel_logs` (query via painel).

### SQL schema manual

Agora há um arquivo pronto para importação: `vrp_admin_panel/sql_schema.sql`.

- Execute esse arquivo no seu banco MySQL para criar as tabelas necessárias.
- Ele cria tabelas:
  - `vrp_admin_panel_admins` (admins, identificador, cargo, nome)
  - `vrp_admin_panel_whitelist` (identificador, nome, whitelisted)
  - `vrp_admin_panel_logs` (logs de ação)

Opcional: edite o insert do dono dentro desse `sql_schema.sql` com seu `steam:` real.

- Se preferir usar vRPex `mysql-async`, ajusta `config.lua` driver para `'mysql-async'`, mantendo `enabled = true`.


## Discord Webhook

- Ative em `config.lua`:

```lua
webhook = {
  enabled = true,
  url = 'https://discord.com/api/webhooks/XXXX/XXXX',
  channel_name = 'admin-log'
}
```

- Ações de admin (login, kick, heal, WL, admin-set) são enviadas ao webhook quando ativado.

## Melhorias por categoria (implementadas)

### 1) Segurança / Autenticação
- Login com usuário + senha por ID (controle por `config.admins` + JSON persistente via `admins.json`).
- Validação de login com lock + logs de tentativas.
- Sistema de whitelist no player spawn (requisição de pergunta de acesso).

### 2) Permissões e gestão
- Papéis `dono`, `superadmin`, `admin` com conjunto de permissões no `config.roles`:
  - `manage_wl`, `view_logs`, `view_owner_logs`, `manage_admins`, `kick`, `heal`.
- Aba de gestão de admins (`Manage Admin`) para adicionar/editar credenciais via NUI.
- Permissões controlam visibilidade de abas: Whitelist, Logs Dono, Gestão de Admin.

### 3) Interface / UX
- UI NUI moderna: abas, card, overlay, painel de ação e mensagens instantâneas.
- Gráfico de atividade em tempo real (`Chart.js`) na aba Home.
- Filtros de log no painel de logs para busca rápida.
- Modal de whitelist com validação e bloqueio visual.

### 4) Logs / Auditoria
- Logs armazenados em `admin_logs.txt` e `owner_admin_logs.txt`.
- Logs de WL e ações de admin com timestamps e IDs explícitos.
- Hook opcional de Discord `webhook` com mensagens em tempo real.
- Log de comando kick/heal com metadata (admin, alvo, horário).

### 5) Compatibilidade VRPex
- Ajustes de chamadas para suportar `vRP.getUserId(source)` e `vRP.getUserSource(user_id)` com fallback de argumentos em table.
- `playerSpawned` em client para ativar fluxo de whitelist.
- Uso de API vRPx e vRP (tunnels e proxy) com validações seguras.

## Permissões por cargo

Em `config.lua.role`, configure as permissões para cada cargo:

- `manage_wl`: gerenciar WL
- `view_logs`: ver logs ADM
- `view_owner_logs`: ver logs dona
- `kick`: kickar jogadores
- `heal`: curar jogadores
- `manage_admins`: criar/editar admins

Exemplo:

```
roles = {
  dono = {...},
  superadmin = {...},
  admin = {...}
}
```

## Estrutura do resource

- `fxmanifest.lua` - metadata do recurso.
- `config.lua` - definição de admins e caminhos de log.
- `server.lua` - lógica de login, validação e API NUI.
- `client.lua` - evento para abrir painel e comandos NUI.
- `html/` - frontend do painel (NUI): `index.html`, `styles.css`, `app.js`.

## Melhoria futura sugerida

- Integração com banco de dados (MySQL / vRPMySQL) para logs persistentes.
- Gráficos com Chart.js ou ApexCharts em tempo real.
- Sistema de permissão por funções detalhadas (coordenador, moderador, suporte).
- Notificação de ações via Discord webhook.

## Uso passo-a-passo (realme/servidor)

1. Inicie recurso:
   - `ensure vrp_admin_panel`.
2. Crie admins em `config.lua` e opcionalmente `admins.json` (é carregado no startup).
3. Use `/paineladm` ou `/adminlog` como admin autorizado.
4. Painel abre à esquerda: se quiser foco, clique `Minimizar` e o painel fica pequeno no canto.
5. Na aba `Comandos` há `Mostrar nametags`; ativa desenhar nomes acima da cabeça dos jogadores proximos (ate 25m) e mostra seu último set como label.
6. Para cada player prox, ver os dados de ID, nome, set no HUD.
7. Com `Whitelist`, ver IDs liberados e usar pergunta de onboarding no primeiro login.
8. Aba `Gestão Admin` permite `getAdmins` e `setAdmin` (para cargo/senha) se você tem permissão `manage_admins`.
9. Lembre-se de habilitar webhook em `config.lua` para replicar logs realtime no Discord.

## GIT / devolução final de código

1. Confirme localmente com servidor de testes (VRPex).
2. Commit:
   - `git add .`
   - `git commit -m "Add vrp_admin_panel with whilte list, roles, nametag and realme guide"`
   - `git push origin main`
3. Abra pull request no GitHub, inclua no título/descrição que a feature é painel admin com NUI, whitelist inicial, controle por cargo e log Discord.

