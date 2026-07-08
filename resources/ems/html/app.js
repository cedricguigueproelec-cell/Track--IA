const RESOURCE = 'ems';
const app = document.getElementById('app');

function post(endpoint, data) {
  return fetch(`https://${RESOURCE}/${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data || {}),
  }).catch(() => {});
}

function showView(name) {
  app.classList.remove('hidden');
  ['supply', 'garage'].forEach((v) => document.getElementById(`view-${v}`).classList.toggle('hidden', v !== name));
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
  if (data.action === 'openSupply') {
    showView('supply');
    const list = document.getElementById('supply-list');
    list.innerHTML = '';
    data.items.forEach((it) => {
      const row = document.createElement('div');
      row.className = 'list-item';
      row.innerHTML = `<span>${it.label}</span><button class="btn">Prendre</button>`;
      row.querySelector('.btn').addEventListener('click', () => post('getSupplyItem', { item: it.item }));
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
});
