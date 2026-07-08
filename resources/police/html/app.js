const RESOURCE = 'police';
const app = document.getElementById('app');
const views = ['armory', 'garage', 'search', 'mdt'];

function post(endpoint, data) {
  return fetch(`https://${RESOURCE}/${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data || {}),
  }).then((r) => r.json()).catch(() => null);
}

function showView(name) {
  app.classList.remove('hidden');
  views.forEach((v) => document.getElementById(`view-${v}`).classList.toggle('hidden', v !== name));
}

document.getElementById('close-btn').addEventListener('click', () => {
  post('close');
  app.classList.add('hidden');
});
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && !app.classList.contains('hidden')) {
    post('close');
    app.classList.add('hidden');
  }
});

window.addEventListener('message', (event) => {
  const data = event.data;
  document.getElementById('panel-title').textContent = 'Police';

  if (data.action === 'openArmory') {
    showView('armory');
    const list = document.getElementById('armory-list');
    list.innerHTML = '';
    data.items.forEach((it) => {
      const row = document.createElement('div');
      row.className = 'list-item';
      row.innerHTML = `<span>${it.label}</span><button class="btn">Prendre</button>`;
      row.querySelector('.btn').addEventListener('click', () => post('getArmoryItem', { item: it.item }));
      list.appendChild(row);
    });
  }

  if (data.action === 'openGarage') {
    showView('garage');
    const list = document.getElementById('garage-list');
    list.innerHTML = '';
    data.vehicles.forEach((v) => {
      const row = document.createElement('div');
      row.className = 'list-item';
      row.innerHTML = `<span>${v.label}</span><button class="btn">Faire sortir</button>`;
      row.querySelector('.btn').addEventListener('click', () => post('spawnVehicle', { model: v.model }));
      list.appendChild(row);
    });
  }

  if (data.action === 'openSearch') {
    showView('search');
    document.getElementById('search-name').textContent = `Fouille: ${data.name}`;
    const list = document.getElementById('search-list');
    list.innerHTML = '';
    const slots = data.snapshot.slots || {};
    const keys = Object.keys(slots);
    if (keys.length === 0) {
      list.innerHTML = '<div class="subtitle">Inventaire vide.</div>';
    }
    keys.forEach((k) => {
      const stack = slots[k];
      const row = document.createElement('div');
      row.className = 'list-item';
      row.innerHTML = `<span>${stack.label} x${stack.amount}</span><button class="btn">Saisir</button>`;
      row.querySelector('.btn').addEventListener('click', () => {
        post('seizeItem', { targetId: data.targetId, slot: stack.slot });
        row.remove();
      });
      list.appendChild(row);
    });
  }

  if (data.action === 'openMdt') {
    showView('mdt');
  }
});

document.querySelectorAll('.mdt-tab').forEach((tab) => {
  tab.addEventListener('click', () => {
    document.querySelectorAll('.mdt-tab').forEach((t) => t.classList.remove('active'));
    tab.classList.add('active');
    document.getElementById('mdt-citizen').classList.toggle('hidden', tab.dataset.tab !== 'citizen');
    document.getElementById('mdt-plate').classList.toggle('hidden', tab.dataset.tab !== 'plate');
  });
});

let citizenDebounce = null;
document.getElementById('mdt-citizen-input').addEventListener('input', (e) => {
  clearTimeout(citizenDebounce);
  const query = e.target.value;
  citizenDebounce = setTimeout(async () => {
    const rows = await post('mdtSearchCitizen', { query });
    const list = document.getElementById('mdt-citizen-results');
    list.innerHTML = '';
    (rows || []).forEach((c) => {
      const row = document.createElement('div');
      row.className = 'list-item';
      row.innerHTML = `<span>${c.firstname} ${c.lastname} — ${c.job}</span><span>${c.citizenid}</span>`;
      list.appendChild(row);
    });
  }, 300);
});

document.getElementById('mdt-plate-btn').addEventListener('click', async () => {
  const plate = document.getElementById('mdt-plate-input').value;
  const row = await post('mdtSearchPlate', { plate });
  const result = document.getElementById('mdt-plate-result');
  result.innerHTML = '';
  if (!row) {
    result.innerHTML = '<div class="subtitle">Aucun résultat.</div>';
    return;
  }
  const el = document.createElement('div');
  el.className = 'list-item';
  el.innerHTML = `<span>${row.plate} — ${row.model}</span><span>${row.firstname} ${row.lastname}</span>`;
  result.appendChild(el);
});
