const overlay = document.getElementById('overlay');
const timerEl = document.getElementById('timer');
const respawnBtn = document.getElementById('respawn-btn');

let interval = null;

function post(endpoint, data) {
  return fetch(`https://medical/${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data || {}),
  }).catch(() => {});
}

function startTimer(seconds) {
  clearInterval(interval);
  let remaining = seconds;
  const render = () => {
    const m = Math.floor(remaining / 60).toString().padStart(2, '0');
    const s = Math.floor(remaining % 60).toString().padStart(2, '0');
    timerEl.textContent = `${m}:${s}`;
  };
  render();
  interval = setInterval(() => {
    remaining -= 1;
    if (remaining <= 0) { clearInterval(interval); }
    render();
  }, 1000);
}

window.addEventListener('message', (event) => {
  const data = event.data;
  if (data.action === 'downed') {
    overlay.classList.remove('hidden');
    respawnBtn.classList.add('hidden');
    startTimer(data.seconds);
  } else if (data.action === 'canRespawn') {
    respawnBtn.classList.remove('hidden');
  } else if (data.action === 'clear') {
    overlay.classList.add('hidden');
    clearInterval(interval);
  }
});

respawnBtn.addEventListener('click', () => post('requestRespawn'));
