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
