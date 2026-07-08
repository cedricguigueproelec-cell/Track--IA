const RESOURCE = 'vehicles';
const app = document.getElementById('app');
const views = ['dealership', 'garage', 'impound'];

function post(endpoint, data) {
  return fetch(`https://${RESOURCE}/${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data || {}),
  }).catch(() => {});
}

function money(n) { return (n || 0).toLocaleString('fr-FR') + ' $'; }

function showView(name, title) {
  app.classList.remove('hidden');
  document.getElementById('panel-title').textContent = title;
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

  if (data.action === 'openDealership') {
    showView('dealership', 'Concession Automobile');
    const grid = document.getElementById('catalog-grid');
    grid.innerHTML = '';
    data.catalog.forEach((car) => {
      const card = document.createElement('div');
      card.className = 'car-card';
      card.innerHTML = `
        <div class="car-cat">${car.category}</div>
        <div class="car-name">${car.label}</div>
        <div class="car-price">${money(car.price)}</div>
        <div class="car-actions">
          <button class="btn btn-test">Essayer</button>
          <button class="btn btn-buy">Acheter</button>
        </div>
      `;
      card.querySelector('.btn-test').addEventListener('click', () => post('testDrive', { model: car.model }));
      card.querySelector('.btn-buy').addEventListener('click', () => post('buyVehicle', { model: car.model }));
      grid.appendChild(card);
    });
  }

  if (data.action === 'openGarage') {
    showView('garage', data.garage);
    const list = document.getElementById('garage-list');
    list.innerHTML = '';
    if ((data.vehicles || []).length === 0) list.innerHTML = '<div class="list-item">Aucun véhicule ici.</div>';
    data.vehicles.forEach((v) => {
      const row = document.createElement('div');
      row.className = 'list-item';
      row.innerHTML = `
        <div><div>${v.model} <span class="state-badge ${v.state}">${v.state}</span></div><div class="meta">${v.plate}</div></div>
        <button class="btn btn-buy">Sortir</button>
      `;
      row.querySelector('.btn-buy').addEventListener('click', () => post('spawnOwned', { id: v.id, garage: data.garage }));
      list.appendChild(row);
    });
  }

  if (data.action === 'openImpound') {
    showView('impound', 'Fourrière');
    const list = document.getElementById('impound-list');
    list.innerHTML = '';
    if ((data.vehicles || []).length === 0) list.innerHTML = '<div class="list-item">Aucun véhicule en fourrière.</div>';
    data.vehicles.forEach((v) => {
      const row = document.createElement('div');
      row.className = 'list-item';
      row.innerHTML = `
        <div><div>${v.model}</div><div class="meta">${v.plate} — Amende: ${money(v.impound_fee)}</div></div>
        <button class="btn btn-buy">Payer & récupérer</button>
      `;
      row.querySelector('.btn-buy').addEventListener('click', () => post('spawnOwned', { id: v.id, payImpound: true }));
      list.appendChild(row);
    });
  }
});
