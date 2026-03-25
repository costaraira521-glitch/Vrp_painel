const state = { logged: false, cargo: null }; 

const loginPanel = document.getElementById('loginPanel');
const dashboardPanel = document.getElementById('dashboardPanel');
const loginError = document.getElementById('login-error');

let activityChart = null;
const activityData = {
  labels: [],
  values: []
};

function setTab(tabName) {
  document.querySelectorAll('.tab').forEach(btn => btn.classList.toggle('active', btn.dataset.tab === tabName));
  document.querySelectorAll('.tab-content').forEach(sec => sec.style.display = sec.id === tabName ? 'block' : 'none');
}

function initActivityChart() {
  const ctx = document.getElementById('activityChart');
  if (!ctx) return;
  activityChart = new Chart(ctx, {
    type: 'line',
    data: {
      labels: activityData.labels,
      datasets: [{
        label: 'Ações/seg',
        data: activityData.values,
        borderColor: '#60a5fa',
        backgroundColor: 'rgba(96,165,250,0.35)',
        fill: true,
        tension: 0.2,
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      scales: {
        x: { display: true, title: { display: true, text: 'Tempo' } },
        y: { display: true, beginAtZero: true }
      }
    }
  });
}

function addActivityPoint(value) {
  const now = new Date().toLocaleTimeString();
  if (activityData.labels.length > 20) {
    activityData.labels.shift();
    activityData.values.shift();
  }
  activityData.labels.push(now);
  activityData.values.push(value);
  if (activityChart) activityChart.update();
}

function openPanel() {
  document.getElementById('overlay').style.display = 'block';
  document.getElementById('app').style.display = 'block';
  loginPanel.style.display = 'block';
  dashboardPanel.style.display = 'none';
  closeWLPanel();
  setTab('tab-home');
  initActivityChart();
}

function closePanel() {
  document.getElementById('overlay').style.display = 'none';
  document.getElementById('app').style.display = 'none';
  loginPanel.style.display = 'block';
  dashboardPanel.style.display = 'none';
  closeWLPanel();
  state.logged = false;
  state.cargo = null;
}

const resourceName = 'vrp_admin_panel';

// ✅ SEGURANÇA: Sanitizar HTML para prevenir XSS
function sanitizeHTML(str) {
  if (!str || typeof str !== 'string') return '';
  const div = document.createElement('div');
  div.textContent = str;
  return div.innerHTML;
}

function fetchNui(action, payload = {}) {
  return new Promise(resolve => {
    fetch(`https://${resourceName}/${action}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(payload)
    }).then(resp => resp.json()).then(resolve).catch(err => resolve({ success: false, error: err.message }))
  })
}

window.addEventListener('message', (event) => {
  const data = event.data;
  if (data.action === 'open') openPanel();
  if (data.action === 'openWL') openWLPanel(data.question);
  if (data.action === 'wlResult') {
    document.getElementById('wl-error').textContent = data.message;
    if (data.success) closeWLPanel();
    addActivityPoint(data.success ? 2 : 0.5);
  }
  if (data.action === 'commandResult') {
    document.getElementById('cmd-message').textContent = data.message;
    addActivityPoint(1);
  }
});

function openWLPanel(question) {
  document.getElementById('wlPanel').style.display = 'grid';
  document.getElementById('wl-question').textContent = question;
  document.getElementById('wl-error').textContent = '';
}

function closeWLPanel() {
  document.getElementById('wlPanel').style.display = 'none';
  document.getElementById('wl-answer').value = '';
}

document.getElementById('wl-submit').addEventListener('click', async () => {
  const answer = document.getElementById('wl-answer').value.trim();
  if (!answer) {
    document.getElementById('wl-error').textContent = 'Digite uma resposta.';
    return;
  }
  const res = await fetchNui('whitelistAnswer', { answer });
  if (!res.success) {
    document.getElementById('wl-error').textContent = res.error;
  }
});

document.getElementById('wl-cancel').addEventListener('click', () => {
  closeWLPanel();
});

document.getElementById('login-btn').addEventListener('click', async () => {
  const username = document.getElementById('login-username').value.trim();
  const password = document.getElementById('login-password').value;
  const res = await fetchNui('login', { username, password });
  if (!res.success) {
    loginError.textContent = res.error;
    return;
  }
  state.logged = true;
  state.cargo = res.cargo;

  document.getElementById('status-admin').textContent = `Logado como ${username} (${res.cargo})`;
  document.getElementById('admin-name').textContent = username;
  document.getElementById('admin-count').textContent = '1+';

  const canManageWL = res.permissions && res.permissions.manage_wl;
  const canViewOwner = res.permissions && res.permissions.view_owner_logs;
  const canManageAdmins = res.permissions && res.permissions.manage_admins;

  const wlTab = document.querySelector('[data-tab="tab-whitelist"]');
  const ownerTab = document.querySelector('[data-tab="tab-owner"]');
  const adminTab = document.querySelector('[data-tab="tab-admins"]');
  if (wlTab) wlTab.style.display = canManageWL ? 'inline-flex' : 'none';
  if (ownerTab) ownerTab.style.display = canViewOwner ? 'inline-flex' : 'none';
  if (adminTab) adminTab.style.display = canManageAdmins ? 'inline-flex' : 'none';

  loginError.textContent = '';

  loginPanel.style.display = 'none';
  dashboardPanel.style.display = 'block';
  setTab('tab-home');
});

document.getElementById('logout-btn').addEventListener('click', async () => {
  await fetchNui('logout', {});
  closePanel();
});

document.querySelectorAll('.tab').forEach(el => el.addEventListener('click', () => setTab(el.dataset.tab)));

document.getElementById('player-search-btn').addEventListener('click', async () => {
  const targetId = parseInt(document.getElementById('player-id').value, 10);
  if (!targetId) {
    document.getElementById('player-info').textContent = 'Digite um ID válido.';
    return;
  }
  const res = await fetchNui('getPlayerInfo', { targetId });
  if (!res.success) {
    document.getElementById('player-info').textContent = res.error;
    return;
  }
  document.getElementById('player-info').textContent = JSON.stringify(res.info, null, 2);
});

async function handleCommand(action, msgElement) {
  const targetId = parseInt(document.getElementById('cmd-player-id').value, 10);
  if (!targetId) { msgElement.textContent = 'Informe ID do jogador.'; return; }
  const res = await fetchNui(action, { targetId });
  msgElement.textContent = res.success ? res.message : res.message || res.error;
}

document.getElementById('cmd-kick').addEventListener('click', () => handleCommand('cmdKick', document.getElementById('cmd-message')));
document.getElementById('cmd-heal').addEventListener('click', () => handleCommand('cmdHeal', document.getElementById('cmd-message')));
document.getElementById('cmd-toggle-tag').addEventListener('click', async () => {
  const active = document.getElementById('cmd-toggle-tag').dataset.active === 'true';
  const next = !active;
  document.getElementById('cmd-toggle-tag').dataset.active = next ? 'true' : 'false';
  document.getElementById('cmd-toggle-tag').textContent = next ? 'Ocultar nametags' : 'Mostrar nametags';
  await fetchNui('toggleNameTag', { enable: next });
});

document.getElementById('toggle-panel-btn').addEventListener('click', () => {
  const app = document.querySelector('.app')
  app.classList.toggle('minimized')
  document.getElementById('toggle-panel-btn').textContent = app.classList.contains('minimized') ? 'Expandir' : 'Minimizar'
})

let logsCache = '';

function setLogsText(text) {
  logsCache = text;
  document.getElementById('logs-content').textContent = text;
}

function filterLogs() {
  const filter = document.getElementById('log-filter-input').value.trim().toLowerCase();
  if (!filter) {
    setLogsText(logsCache);
    return;
  }
  const filtered = logsCache.split('\n').filter(line => line.toLowerCase().includes(filter)).join('\n');
  document.getElementById('logs-content').textContent = filtered || 'Sem resultados para filtro.';
}

document.getElementById('log-refresh-btn').addEventListener('click', async () => {
  const res = await fetchNui('getLogs', {});
  if (!res.success) {
    setLogsText(res.error);
    return;
  }
  setLogsText(res.logs);
});

document.getElementById('log-filter-btn').addEventListener('click', filterLogs);
document.getElementById('log-reset-btn').addEventListener('click', () => {
  document.getElementById('log-filter-input').value = '';
  setLogsText(logsCache);
});

document.getElementById('wl-refresh-btn').addEventListener('click', async () => {
  const res = await fetchNui('getWhitelist', {});
  if (!res.success) {
    document.getElementById('wl-content').textContent = res.error;
    return;
  }
  document.getElementById('wl-content').textContent = res.whitelist.length > 0 ? res.whitelist.join('\n') : 'Nenhum jogador na whitelist';
});

document.getElementById('admin-refresh-btn').addEventListener('click', async () => {
  const res = await fetchNui('getAdmins', {});
  if (!res.success) {
    document.getElementById('admin-list').textContent = res.error;
    return;
  }
  document.getElementById('admin-list').textContent = res.admins.map(a => `ID: ${a.user_id} - Cargo: ${a.cargo}`).join('\n');
});

document.getElementById('admin-save-btn').addEventListener('click', async () => {
  const user_id = parseInt(document.getElementById('admin-id').value, 10);
  const senha = document.getElementById('admin-password').value.trim();
  const cargo = document.getElementById('admin-role').value;

  if (!user_id || !senha || !cargo) {
    document.getElementById('admin-message').textContent = 'Informe ID, senha e cargo.';
    return;
  }

  const res = await fetchNui('setAdmin', { user_id, senha, cargo });
  document.getElementById('admin-message').textContent = res.success ? 'Admin salvo com sucesso.' : res.error;
  if (res.success) {
    document.getElementById('admin-id').value = '';
    document.getElementById('admin-password').value = '';
    document.getElementById('admin-refresh-btn').click();
  }
});

document.getElementById('owner-log-refresh-btn').addEventListener('click', async () => {
  const res = await fetchNui('getOwnerLogs', {});
  document.getElementById('owner-logs-content').textContent = res.success ? res.logs : res.error;
});

// ═══════════════════════════════════════════════════════════════════
// SISTEMA DE GRUPOS
// ═══════════════════════════════════════════════════════════════════

async function loadAvailableGroups() {
  const res = await fetchNui('getAvailableGroups', {});
  if (!res.success) {
    console.error('Erro ao carregar grupos:', res.error);
    return [];
  }
  return res.groups || [];
}

async function populateGroupSelect() {
  const groups = await loadAvailableGroups();
  const select = document.getElementById('group-select');
  
  // Limpa opções, mantém a primeira
  while (select.options.length > 1) {
    select.remove(1);
  }
  
  // Adiciona grupos
  groups.forEach(group => {
    const option = document.createElement('option');
    option.value = group;
    option.textContent = group.charAt(0).toUpperCase() + group.slice(1);
    select.appendChild(option);
  });
}

document.getElementById('group-search-btn').addEventListener('click', async () => {
  const playerId = parseInt(document.getElementById('group-player-id').value, 10);
  
  if (!playerId || playerId <= 0) {
    showGroupMessage('Digite um ID válido', 'error');
    return;
  }
  
  // Busca o grupo do jogador
  const res = await fetchNui('getPlayerGroup', { targetId: playerId });
  
  if (!res.success) {
    showGroupMessage(res.error || 'Erro ao buscar grupo', 'error');
    document.getElementById('group-info').style.display = 'none';
    document.getElementById('group-selector').style.display = 'none';
    return;
  }
  
  // Mostra informações
  document.getElementById('group-player-display').textContent = playerId;
  document.getElementById('group-current').textContent = res.group || 'desconhecido';
  document.getElementById('group-info').style.display = 'block';
  
  // Carrega seletor de grupos
  await populateGroupSelect();
  document.getElementById('group-selector').style.display = 'flex';
  
  showGroupMessage('Jogador encontrado. Selecione um novo grupo.', 'success');
});

document.getElementById('group-set-btn').addEventListener('click', async () => {
  const playerId = parseInt(document.getElementById('group-player-id').value, 10);
  const newGroup = document.getElementById('group-select').value;
  
  if (!playerId || playerId <= 0) {
    showGroupMessage('ID inválido', 'error');
    return;
  }
  
  if (!newGroup) {
    showGroupMessage('Selecione um grupo', 'error');
    return;
  }
  
  // Envia para o servidor
  const res = await fetchNui('setPlayerGroup', { targetId: playerId, group: newGroup });
  
  if (!res.success) {
    showGroupMessage(res.error || 'Erro ao definir grupo', 'error');
    return;
  }
  
  // Sucesso
  document.getElementById('group-current').textContent = newGroup;
  showGroupMessage('✓ ' + (res.message || 'Grupo alterado com sucesso!'), 'success');
});

function showGroupMessage(text, type = 'info') {
  const msgEl = document.getElementById('group-message');
  msgEl.textContent = text;
  msgEl.className = type;
  
  setTimeout(() => {
    msgEl.textContent = '';
    msgEl.className = '';
  }, 5000);
}

// Carrega grupos quando a aba é aberta
const origSetTab = window.setTab;
window.setTab = function(tabName) {
  origSetTab(tabName);
  if (tabName === 'tab-groups') {
    populateGroupSelect();
  }
  if (tabName === 'tab-announcements') {
    loadAnnouncements();
  }
};

// ═══════════════════════════════════════════════════════════════════
// SISTEMA DE AVISOS
// ═══════════════════════════════════════════════════════════════════

async function loadAnnouncements() {
  const res = await fetchNui('getAnnouncements', {});
  const list = document.getElementById('announcements-list');
  
  if (!res.success || !res.announcements || res.announcements.length === 0) {
    list.innerHTML = '<p>Nenhum aviso no momento...</p>';
    return;
  }
  
  list.innerHTML = '';
  res.announcements.forEach(ann => {
    const item = document.createElement('div');
    item.className = `announcement-item ${ann.tipo}`;
    
    const iconMap = {
      'info': 'ℹ️',
      'warning': '⚠️',
      'critical': '🚨',
      'success': '✅'
    };
    
    // ✅ SEGURANÇA: Sanitizar título e mensagem do servidor
    item.innerHTML = `
      <h4>${iconMap[ann.tipo] || '•'} ${sanitizeHTML(ann.titulo)}</h4>
      <p>${sanitizeHTML(ann.mensagem)}</p>
      <div class="time">${new Date(ann.criado_em).toLocaleString()}</div>
    `;
    list.appendChild(item);
  });
}

document.getElementById('announcements-refresh-btn').addEventListener('click', loadAnnouncements);

document.getElementById('announcement-send-btn').addEventListener('click', async () => {
  const titulo = document.getElementById('announcement-title').value.trim();
  const mensaje = document.getElementById('announcement-message').value.trim();
  const tipo = document.getElementById('announcement-type').value;
  
  if (!titulo || !mensaje) {
    showAnnouncementMessage('Preencha título e mensagem', 'error');
    return;
  }
  
  const res = await fetchNui('createAnnouncement', { titulo, mensaje, tipo });
  
  if (!res.success) {
    showAnnouncementMessage(res.error || 'Erro ao criar aviso', 'error');
    return;
  }
  
  showAnnouncementMessage('✓ Aviso criado com sucesso!', 'success');
  document.getElementById('announcement-title').value = '';
  document.getElementById('announcement-message').value = '';
  
  setTimeout(loadAnnouncements, 500);
});

function showAnnouncementMessage(text, type = 'info') {
  const msgEl = document.getElementById('announcement-message-response');
  msgEl.textContent = text;
  msgEl.className = type;
  msgEl.style.display = 'block';
  
  setTimeout(() => {
    msgEl.textContent = '';
    msgEl.className = '';
  }, 4000);
}

// ═══════════════════════════════════════════════════════════════════
// SISTEMA DE CHAT PARA ADMINS
// ═══════════════════════════════════════════════════════════════════

let chatVisible = false;
let chatMinimized = false;

function initAdminChat() {
  const chatContainer = document.getElementById('admin-chat-container');
  if (!chatContainer) return;
  
  chatContainer.style.display = 'block';
  chatVisible = true;
  loadAdminChat();
}

document.getElementById('chat-minimize-btn').addEventListener('click', () => {
  const container = document.getElementById('admin-chat-container');
  chatMinimized = !chatMinimized;
  container.classList.toggle('minimized');
  document.getElementById('chat-minimize-btn').textContent = chatMinimized ? '□' : '−';
});

async function loadAdminChat() {
  const res = await fetchNui('getAdminChat', {});
  const messagesDiv = document.getElementById('chat-messages');
  
  if (!res.success || !res.messages || res.messages.length === 0) {
    messagesDiv.innerHTML = '<div class="system-message">Nenhuma mensagem ainda</div>';
    return;
  }
  
  messagesDiv.innerHTML = '';
  res.messages.forEach(msg => {
    addChatMessageToUI(msg.admin_id, msg.mensagem, msg.tipo, msg.enviado_em);
  });
  
  // Scroll para baixo
  messagesDiv.scrollTop = messagesDiv.scrollHeight;
}

function addChatMessageToUI(adminId, message, type = 'normal', time = null) {
  const messagesDiv = document.getElementById('chat-messages');
  const msgEl = document.createElement('div');
  
  const isOwn = false; // Você teria que rastrear isso
  msgEl.className = `chat-message ${type === 'aviso' ? 'system' : 'received'}`;
  
  const timestamp = time ? new Date(time).toLocaleTimeString() : new Date().toLocaleTimeString();
  // ✅ SEGURANÇA: Sanitizar mensagem do servidor
  msgEl.innerHTML = `${sanitizeHTML(message)}<span class="timestamp">${timestamp}</span>`;
  
  messagesDiv.appendChild(msgEl);
  messagesDiv.scrollTop = messagesDiv.scrollHeight;
}

document.getElementById('chat-send-btn').addEventListener('click', async () => {
  const input = document.getElementById('chat-input');
  const message = input.value.trim();
  
  if (!message) return;
  
  const res = await fetchNui('sendAdminMessage', { message, type: 'normal' });
  
  if (!res.success) {
    console.error('Erro ao enviar mensagem:', res.error);
    return;
  }
  
  addChatMessageToUI(0, message);
  input.value = '';
});

document.getElementById('chat-input').addEventListener('keypress', (e) => {
  if (e.key === 'Enter' && !e.shiftKey) {
    e.preventDefault();
    document.getElementById('chat-send-btn').click();
  }
});

// Novos eventos de mensagens
window.addEventListener('message', (event) => {
  const data = event.data;
  if (data.action === 'newAdminMessage') {
    if (!chatVisible) initAdminChat();
    addChatMessageToUI(data.data.admin_id, data.data.mensagem, data.data.tipo, data.data.enviado_em);
  }
  if (data.action === 'newAnnouncement') {
    // Exibe notificação visual
    console.log('Novo aviso:', data.data);
    // Poderia animar ou mostrar toast notification
  }
});

// Mostrar chat quando fizer login
const origLoginBtn = document.getElementById('login-btn');
if (origLoginBtn) {
  origLoginBtn.addEventListener('click', () => {
    setTimeout(initAdminChat, 500);
  });
}
