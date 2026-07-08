const RESOURCE = 'banking';
const app = document.getElementById('app');

function post(endpoint, data) {
  return fetch(`https://${RESOURCE}/${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data || {}),
  }).catch(() => {});
}

function money(n) {
  return (n || 0).toLocaleString('fr-FR') + ' $';
}

document.querySelectorAll('.tab').forEach((tab) => {
  tab.addEventListener('click', () => {
    document.querySelectorAll('.tab').forEach((t) => t.classList.remove('active'));
    document.querySelectorAll('.tab-panel').forEach((p) => p.classList.add('hidden'));
    tab.classList.add('active');
    document.getElementById(`tab-${tab.dataset.tab}`).classList.remove('hidden');
  });
});

function renderHistory(transactions) {
  const list = document.getElementById('history-list');
  list.innerHTML = '';
  const labels = {
    deposit: 'Dépôt', withdraw: 'Retrait', transfer_in: 'Virement reçu',
    transfer_out: 'Virement envoyé', salary: 'Salaire', fine: 'Amende',
    invoice: 'Facture', admin: 'Ajustement admin', item_use: 'Objet utilisé',
  };
  const positive = ['deposit', 'transfer_in', 'salary'];

  (transactions || []).forEach((tx) => {
    const el = document.createElement('div');
    el.className = 'history-item';
    const sign = positive.includes(tx.type) ? '+' : '-';
    el.innerHTML = `
      <div>
        <div>${labels[tx.type] || tx.type}</div>
        <div class="meta">${tx.created_at || ''}${tx.note ? ' · ' + tx.note : ''}</div>
      </div>
      <div class="amt ${positive.includes(tx.type) ? 'positive' : 'negative'}">${sign}${money(tx.amount)}</div>
    `;
    list.appendChild(el);
  });
}

function renderState(data) {
  if (!data) return;
  document.getElementById('cash-val').textContent = money(data.cash);
  document.getElementById('bank-val').textContent = money(data.bank);
  document.getElementById('iban').textContent = data.iban;
  renderHistory(data.transactions);
}

document.getElementById('deposit-btn').addEventListener('click', () => {
  const amount = parseInt(document.getElementById('deposit-amount').value, 10);
  if (!amount || amount <= 0) return;
  post('deposit', { amount });
});

document.getElementById('withdraw-btn').addEventListener('click', () => {
  const amount = parseInt(document.getElementById('withdraw-amount').value, 10);
  if (!amount || amount <= 0) return;
  post('withdraw', { amount });
});

document.getElementById('transfer-btn').addEventListener('click', () => {
  const phone = document.getElementById('transfer-phone').value.trim();
  const amount = parseInt(document.getElementById('transfer-amount').value, 10);
  if (!phone || !amount || amount <= 0) return;
  post('transfer', { phone, amount });
});

document.getElementById('close-btn').addEventListener('click', () => {
  post('close');
  app.classList.add('hidden');
});

window.addEventListener('message', (event) => {
  const data = event.data;
  if (data.action === 'open') {
    app.classList.remove('hidden');
  } else if (data.action === 'close') {
    app.classList.add('hidden');
  } else if (data.action === 'state') {
    renderState(data.data);
  }
});

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && !app.classList.contains('hidden')) {
    post('close');
    app.classList.add('hidden');
  }
});
