const RESOURCE = 'inventory';

const ICONS = {
  food: '🍔', drink: '🥤', medical: '🩹', tool: '🔧', document: '🪪',
  weapon: '🔫', ammo: '🧿', drug: '🌿', valuable: '💎', item: '📦',
};

const hotbarEl = document.getElementById('hotbar');
const panelEl = document.getElementById('panel');
const playerGridEl = document.getElementById('player-grid');
const secondarySection = document.getElementById('secondary-section');
const secondaryGridEl = document.getElementById('secondary-grid');
const playerWeightFill = document.getElementById('player-weight-fill');
const playerWeightLabel = document.getElementById('player-weight-label');
const secondaryWeightFill = document.getElementById('secondary-weight-fill');
const secondaryWeightLabel = document.getElementById('secondary-weight-label');
const secondaryTitle = document.getElementById('secondary-title');
const actionBar = document.getElementById('action-bar');
const actionItemLabel = document.getElementById('action-item-label');
const actionAmount = document.getElementById('action-amount');

let lastPayload = null;
let selection = null; // { owner, slot, item, label, amount }

function post(endpoint, data) {
  return fetch(`https://${RESOURCE}/${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data || {}),
  }).catch(() => {});
}

function kg(grams) {
  return (grams / 1000).toFixed(1);
}

function clearSelection() {
  selection = null;
  actionBar.classList.add('hidden');
  document.querySelectorAll('.slot.selected').forEach((el) => el.classList.remove('selected'));
}

function selectSlot(owner, slotNum, stack, el) {
  document.querySelectorAll('.slot.selected').forEach((n) => n.classList.remove('selected'));
  el.classList.add('selected');
  selection = { owner, slot: slotNum, item: stack.item, label: stack.label, amount: stack.amount };

  actionItemLabel.textContent = `${stack.label} x${stack.amount}`;
  actionAmount.max = stack.amount;
  actionAmount.value = 1;
  actionBar.classList.remove('hidden');

  const isSecondaryOpen = lastPayload && lastPayload.secondaryId;
  document.getElementById('action-transfer').classList.toggle('hidden', !isSecondaryOpen);
}

function renderGrid(el, slotsObj, maxSlots, ownerId) {
  el.innerHTML = '';
  for (let i = 1; i <= maxSlots; i++) {
    const stack = slotsObj[String(i)];
    const cell = document.createElement('div');
    cell.className = 'slot' + (stack ? '' : ' empty') + (stack && stack.type === 'drug' ? ' illegal' : '');

    if (stack) {
      const icon = ICONS[stack.type] || ICONS.item;
      cell.innerHTML = `
        <div class="icon">${icon}</div>
        <div class="item-label">${stack.label}</div>
        <div class="amount-badge">${stack.amount > 1 ? 'x' + stack.amount : ''}</div>
      `;
      cell.addEventListener('click', () => selectSlot(ownerId, i, stack, cell));
    }

    el.appendChild(cell);
  }
}

function renderHotbar(slotsObj) {
  hotbarEl.innerHTML = '';
  hotbarEl.classList.remove('hidden');
  for (let i = 1; i <= 5; i++) {
    const stack = slotsObj[String(i)];
    const cell = document.createElement('div');
    cell.className = 'hotbar-slot';
    cell.innerHTML = `<span class="num">${i}</span>`;
    if (stack) {
      const icon = ICONS[stack.type] || ICONS.item;
      cell.innerHTML += `<div class="icon">${icon}</div><span class="amt">${stack.amount > 1 ? stack.amount : ''}</span>`;
    }
    hotbarEl.appendChild(cell);
  }
}

function render(payload) {
  lastPayload = payload;
  renderHotbar(payload.owner.slots);

  renderGrid(playerGridEl, payload.owner.slots, payload.owner.maxSlots, payload.ownerId);
  playerWeightFill.style.width = `${Math.min(100, (payload.owner.weight / payload.owner.maxWeight) * 100)}%`;
  playerWeightLabel.textContent = `${kg(payload.owner.weight)} / ${kg(payload.owner.maxWeight)} kg`;

  if (payload.secondary) {
    secondarySection.classList.remove('hidden');
    secondaryTitle.textContent = payload.secondaryLabel || 'Coffre';
    renderGrid(secondaryGridEl, payload.secondary.slots, payload.secondary.maxSlots, payload.secondaryId);
    secondaryWeightFill.style.width = `${Math.min(100, (payload.secondary.weight / payload.secondary.maxWeight) * 100)}%`;
    secondaryWeightLabel.textContent = `${kg(payload.secondary.weight)} / ${kg(payload.secondary.maxWeight)} kg`;
  } else {
    secondarySection.classList.add('hidden');
  }
}

document.getElementById('action-use').addEventListener('click', () => {
  if (!selection) return;
  post('useItem', { slot: selection.slot });
  clearSelection();
});

document.getElementById('action-drop').addEventListener('click', () => {
  if (!selection) return;
  post('dropItem', { slot: selection.slot, amount: parseInt(actionAmount.value, 10) || 1 });
  clearSelection();
});

document.getElementById('action-transfer').addEventListener('click', () => {
  if (!selection || !lastPayload) return;
  const toOwner = selection.owner === lastPayload.ownerId ? lastPayload.secondaryId : lastPayload.ownerId;
  if (!toOwner) return;
  post('transferItem', { fromOwner: selection.owner, slot: selection.slot, amount: parseInt(actionAmount.value, 10) || 1, toOwner });
  clearSelection();
});

document.getElementById('action-cancel').addEventListener('click', clearSelection);

window.addEventListener('message', (event) => {
  const data = event.data;
  if (data.action === 'open') {
    panelEl.classList.remove('hidden');
  } else if (data.action === 'close') {
    panelEl.classList.add('hidden');
    clearSelection();
  } else if (data.action === 'state') {
    render(data.payload);
  }
});

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && !panelEl.classList.contains('hidden')) {
    post('close');
    panelEl.classList.add('hidden');
    clearSelection();
  }
});
