const RESOURCE = 'multichar';

const root = document.getElementById('root');
const viewList = document.getElementById('view-list');
const viewCreate = document.getElementById('view-create');
const slotsEl = document.getElementById('slots');
const createForm = document.getElementById('create-form');

let maxSlots = 3;
let genderValue = 0;

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

function initials(first, last) {
  return ((first || '?')[0] + (last || '?')[0]).toUpperCase();
}

function renderSlots(characters) {
  slotsEl.innerHTML = '';
  const byExisting = characters || [];

  byExisting.forEach((c) => {
    const card = document.createElement('div');
    card.className = 'slot-card';
    card.innerHTML = `
      <div class="slot-delete" title="Supprimer">✕</div>
      <div class="slot-avatar">${initials(c.firstname, c.lastname)}</div>
      <div class="slot-name">${c.firstname} ${c.lastname}</div>
      <div class="slot-meta">${c.job || 'Sans emploi'}</div>
      <div class="slot-money">${money(c.cash)} liquide · ${money(c.bank)} banque</div>
    `;
    card.addEventListener('click', (e) => {
      if (e.target.classList.contains('slot-delete')) {
        e.stopPropagation();
        if (confirm(`Supprimer définitivement ${c.firstname} ${c.lastname} ?`)) {
          post('deleteCharacter', { citizenid: c.citizenid });
        }
        return;
      }
      post('selectCharacter', { citizenid: c.citizenid });
    });
    slotsEl.appendChild(card);
  });

  const remaining = maxSlots - byExisting.length;
  for (let i = 0; i < remaining; i++) {
    const card = document.createElement('div');
    card.className = 'slot-card empty';
    card.innerHTML = `<div class="plus">+</div><div class="slot-name">Nouveau personnage</div>`;
    card.addEventListener('click', () => showCreate());
    slotsEl.appendChild(card);
  }
}

function showCreate() {
  viewList.classList.add('hidden');
  viewCreate.classList.remove('hidden');
}

function showList() {
  viewCreate.classList.add('hidden');
  viewList.classList.remove('hidden');
  createForm.reset();
}

document.getElementById('cancel-create').addEventListener('click', showList);

document.querySelectorAll('.seg-btn').forEach((btn) => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.seg-btn').forEach((b) => b.classList.remove('active'));
    btn.classList.add('active');
    genderValue = parseInt(btn.dataset.value, 10);
  });
});

createForm.addEventListener('submit', (e) => {
  e.preventDefault();
  const fd = new FormData(createForm);
  const payload = {
    firstname: (fd.get('firstname') || '').trim(),
    lastname: (fd.get('lastname') || '').trim(),
    birthdate: fd.get('birthdate'),
    nationality: (fd.get('nationality') || 'USA').trim(),
    gender: genderValue,
  };
  if (payload.firstname.length < 2 || payload.lastname.length < 2) return;
  post('createCharacter', payload);
  showList();
});

window.addEventListener('message', (event) => {
  const data = event.data;
  if (data.action === 'open') {
    maxSlots = data.maxSlots || 3;
    root.classList.remove('hidden');
    showList();
    renderSlots(data.characters);
  } else if (data.action === 'close') {
    root.classList.add('hidden');
  }
});

// Allow ESC to cancel the create form (never closes the whole selector —
// a character must be picked before the player can play).
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && !viewCreate.classList.contains('hidden')) {
    showList();
  }
});
