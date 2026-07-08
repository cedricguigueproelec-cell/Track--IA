const CIRCUMFERENCE = 2 * Math.PI * 19;

const hud = document.getElementById('hud');
const rings = {
  health: document.querySelector('.ring-health'),
  armor: document.querySelector('.ring-armor'),
  hunger: document.querySelector('.ring-hunger'),
  thirst: document.querySelector('.ring-thirst'),
  stamina: document.querySelector('.ring-stamina'),
};
const voiceIndicator = document.getElementById('voice-indicator');
const vehicleHud = document.getElementById('vehicle-hud');
const speedVal = document.getElementById('speed-val');
const gearVal = document.getElementById('gear-val');
const fuelFill = document.getElementById('fuel-fill');
const beltIndicator = document.getElementById('belt-indicator');
const cashVal = document.getElementById('cash-val');
const bankVal = document.getElementById('bank-val');
const toasts = document.getElementById('toasts');

function setRing(el, pct) {
  const clamped = Math.max(0, Math.min(100, pct));
  el.style.strokeDashoffset = CIRCUMFERENCE * (1 - clamped / 100);
}

function money(n) {
  return (n || 0).toLocaleString('fr-FR') + ' $';
}

function showToast(kind, message) {
  const el = document.createElement('div');
  el.className = `toast ${kind || 'info'}`;
  el.textContent = message;
  toasts.appendChild(el);
  setTimeout(() => el.remove(), 4000);
}

window.addEventListener('message', (event) => {
  const data = event.data;

  switch (data.action) {
    case 'show':
      hud.classList.remove('hidden');
      break;

    case 'stats':
      setRing(rings.health, data.health);
      setRing(rings.armor, data.armor);
      setRing(rings.hunger, data.hunger);
      setRing(rings.thirst, data.thirst);
      setRing(rings.stamina, data.stamina);

      voiceIndicator.classList.toggle('hidden', !data.talking);

      if (data.vehicle) {
        vehicleHud.classList.remove('hidden');
        speedVal.textContent = data.vehicle.speed;
        gearVal.textContent = data.vehicle.gear;
        fuelFill.style.width = `${Math.max(0, Math.min(100, data.vehicle.fuel))}%`;
        beltIndicator.textContent = data.vehicle.seatbelt ? 'CEINTURE OK' : 'CEINTURE';
        beltIndicator.classList.toggle('on', !!data.vehicle.seatbelt);
      } else {
        vehicleHud.classList.add('hidden');
      }
      break;

    case 'money':
      cashVal.textContent = money(data.cash);
      bankVal.textContent = money(data.bank);
      break;

    case 'notify':
      showToast(data.kind, data.message);
      break;
  }
});
