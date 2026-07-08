const RESOURCE = 'shops';
const app = document.getElementById('app');
const views = ['general', 'weapons', 'clothing'];

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

document.getElementById('close-btn').addEventListener('click', () => { post('close'); app.classList.add('hidden'); });
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && !app.classList.contains('hidden')) { post('close'); app.classList.add('hidden'); }
});

window.addEventListener('message', (event) => {
  const data = event.data;

  if (data.action === 'openGeneral') {
    showView('general', data.label);
    const list = document.getElementById('general-list');
    list.innerHTML = '';
    data.items.filter((i) => !i.disabled).forEach((it) => {
      const row = document.createElement('div');
      row.className = 'list-item';
      row.innerHTML = `<span>${it.label} — ${money(it.price)}</span><button class="btn">Acheter</button>`;
      row.querySelector('.btn').addEventListener('click', () => post('buyGeneralItem', { item: it.item }));
      list.appendChild(row);
    });
  }

  if (data.action === 'openWeapons') {
    showView('weapons', data.label);
    const list = document.getElementById('weapons-list');
    list.innerHTML = '';
    data.items.forEach((it) => {
      const row = document.createElement('div');
      row.className = 'list-item';
      row.innerHTML = `<span>${it.label} — ${money(it.price)}</span><button class="btn">Acheter</button>`;
      row.querySelector('.btn').addEventListener('click', () => post('buyWeapon', { item: it.item }));
      list.appendChild(row);
    });
  }

  if (data.action === 'openClothing') {
    showView('clothing', data.label);
    const list = document.getElementById('clothing-list');
    list.innerHTML = '';
    data.outfits.forEach((o) => {
      const card = document.createElement('div');
      card.className = 'outfit-card';
      card.innerHTML = `
        <div class="outfit-name">${o.label}</div>
        <div class="outfit-price">${money(o.price)}</div>
        <button class="btn btn-ghost">Essayer</button>
        <button class="btn">Acheter</button>
      `;
      card.querySelector('.btn-ghost').addEventListener('click', () => post('previewOutfit', { index: o.index }));
      card.querySelectorAll('.btn')[1].addEventListener('click', () => post('buyOutfit', { index: o.index }));
      list.appendChild(card);
    });
  }
});
