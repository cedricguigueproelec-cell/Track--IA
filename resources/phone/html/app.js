const RESOURCE = 'phone';
const phone = document.getElementById('phone');
let myNumber = null;
let currentThread = null;

function post(endpoint, data) {
  return fetch(`https://${RESOURCE}/${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data || {}),
  }).then((r) => r.json()).catch(() => null);
}

function showScreen(id) {
  document.querySelectorAll('.screen').forEach((s) => s.classList.add('hidden'));
  document.getElementById(id).classList.remove('hidden');
}

function updateClock() {
  const now = new Date();
  document.getElementById('clock').textContent =
    now.getHours().toString().padStart(2, '0') + ':' + now.getMinutes().toString().padStart(2, '0');
}
setInterval(updateClock, 10000);
updateClock();

// ---------------- home ----------------
document.querySelectorAll('.app').forEach((appEl) => {
  appEl.addEventListener('click', async () => {
    const app = appEl.dataset.app;
    if (app === 'messages') {
      showScreen('screen-messages');
      loadConversations();
    } else if (app === 'contacts') {
      showScreen('screen-contacts');
      loadContacts();
    } else if (app === 'bank') {
      post('openBank');
    } else if (app === 'emergency') {
      showScreen('screen-emergency');
    }
  });
});

document.querySelectorAll('.back-btn').forEach((b) => b.addEventListener('click', () => showScreen('screen-home')));
document.querySelector('.back-btn-thread').addEventListener('click', () => showScreen('screen-messages'));

// ---------------- messages ----------------
async function loadConversations() {
  const rows = await post('getConversations');
  const list = document.getElementById('conversation-list');
  list.innerHTML = '';
  (rows || []).forEach((c) => {
    const el = document.createElement('div');
    el.className = 'conv-item';
    el.innerHTML = `<span>${c.name}</span>`;
    el.addEventListener('click', () => openThread(c.number, c.name));
    list.appendChild(el);
  });
  const newRow = document.createElement('div');
  newRow.className = 'conv-item';
  newRow.innerHTML = `<input placeholder="Nouveau numéro..." style="background:transparent;border:none;color:white;outline:none;width:100%;">`;
  newRow.querySelector('input').addEventListener('keydown', (e) => {
    if (e.key === 'Enter' && e.target.value.trim()) {
      openThread(e.target.value.trim(), e.target.value.trim());
    }
  });
  list.appendChild(newRow);
}

async function openThread(number, label) {
  currentThread = number;
  document.getElementById('thread-title').textContent = label;
  showScreen('screen-thread');
  const res = await post('getMessages', { withNumber: number });
  myNumber = (res && res.myNumber) || myNumber;
  renderThread((res && res.rows) || []);
}

function renderThread(rows) {
  const el = document.getElementById('thread-messages');
  el.innerHTML = '';
  rows.forEach((m) => {
    const bubble = document.createElement('div');
    bubble.className = 'msg-bubble ' + (m.sender === myNumber ? 'mine' : 'theirs');
    bubble.textContent = m.message;
    el.appendChild(bubble);
  });
  el.scrollTop = el.scrollHeight;
}

document.getElementById('thread-send').addEventListener('click', async () => {
  const input = document.getElementById('thread-input-field');
  const message = input.value.trim();
  if (!message || !currentThread) return;
  await post('sendMessage', { to: currentThread, message });
  input.value = '';
  openThread(currentThread, document.getElementById('thread-title').textContent);
});

// ---------------- contacts ----------------
async function loadContacts() {
  const rows = await post('getContacts');
  const list = document.getElementById('contacts-list');
  list.innerHTML = '';
  (rows || []).forEach((c) => {
    const el = document.createElement('div');
    el.className = 'conv-item';
    el.innerHTML = `<span>${c.name} — ${c.number}</span><span class="del">✕</span>`;
    el.querySelector('.del').addEventListener('click', async (e) => {
      e.stopPropagation();
      await post('removeContact', { id: c.id });
      loadContacts();
    });
    el.addEventListener('click', () => openThread(c.number, c.name));
    list.appendChild(el);
  });
}

document.getElementById('add-contact-btn').addEventListener('click', async () => {
  const name = document.getElementById('new-contact-name').value.trim();
  const number = document.getElementById('new-contact-number').value.trim();
  if (!name || !number) return;
  await post('addContact', { name, number });
  document.getElementById('new-contact-name').value = '';
  document.getElementById('new-contact-number').value = '';
  loadContacts();
});

// ---------------- emergency ----------------
document.getElementById('emergency-send').addEventListener('click', () => {
  const message = document.getElementById('emergency-message').value.trim();
  if (!message) return;
  post('call911', { message });
  document.getElementById('emergency-message').value = '';
  showScreen('screen-home');
});

// ---------------- lifecycle ----------------
window.addEventListener('message', (event) => {
  const data = event.data;
  if (data.action === 'open') {
    phone.classList.remove('hidden');
    showScreen('screen-home');
  } else if (data.action === 'close') {
    phone.classList.add('hidden');
  } else if (data.action === 'profile') {
    myNumber = data.data.number;
    document.getElementById('home-name').textContent = data.data.name;
    document.getElementById('home-number').textContent = data.data.number;
  } else if (data.action === 'contacts') {
    loadContacts();
  } else if (data.action === 'incomingMessage') {
    if (currentThread === data.from) openThread(data.from, data.from);
  }
});

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && !phone.classList.contains('hidden')) {
    post('close');
    phone.classList.add('hidden');
  }
});
