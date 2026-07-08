const RESOURCE = 'housing';
const app = document.getElementById('app');

function post(endpoint, data) {
  return fetch(`https://${RESOURCE}/${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data || {}),
  }).catch(() => {});
}

function money(n) { return (n || 0).toLocaleString('fr-FR') + ' $'; }

function close() {
  post('close');
  app.classList.add('hidden');
}

document.getElementById('close-btn').addEventListener('click', close);
document.addEventListener('keydown', (e) => { if (e.key === 'Escape') close(); });

window.addEventListener('message', (event) => {
  const data = event.data;
  const actions = document.getElementById('actions');
  actions.innerHTML = '';

  if (data.action === 'openForSale') {
    app.classList.remove('hidden');
    document.getElementById('prop-label').textContent = data.property.label;
    document.getElementById('prop-price').textContent = `Prix: ${money(data.property.price)}`;
    const buyBtn = document.createElement('button');
    buyBtn.className = 'btn btn-buy';
    buyBtn.textContent = 'Acheter';
    buyBtn.addEventListener('click', () => { post('buyProperty', { id: data.property.id }); app.classList.add('hidden'); });
    actions.appendChild(buyBtn);
  }

  if (data.action === 'openOwned') {
    app.classList.remove('hidden');
    document.getElementById('prop-label').textContent = data.property.label;
    document.getElementById('prop-price').textContent = 'Votre propriété';

    const stashBtn = document.createElement('button');
    stashBtn.className = 'btn btn-stash';
    stashBtn.textContent = 'Ouvrir le coffre';
    stashBtn.addEventListener('click', () => { post('openStash', { id: data.property.id }); app.classList.add('hidden'); });
    actions.appendChild(stashBtn);

    const sellBtn = document.createElement('button');
    sellBtn.className = 'btn btn-sell';
    sellBtn.textContent = 'Vendre (60% remboursé)';
    sellBtn.addEventListener('click', () => { post('sellProperty', { id: data.property.id }); app.classList.add('hidden'); });
    actions.appendChild(sellBtn);
  }
});
