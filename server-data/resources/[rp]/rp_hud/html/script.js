const hud = document.getElementById('hud');
const serverIdEl = document.getElementById('serverId');
const nameEl = document.getElementById('name');
const cashEl = document.getElementById('cash');
const bankEl = document.getElementById('bank');
const jobEl = document.getElementById('job');
const timeEl = document.getElementById('time');
const dateEl = document.getElementById('date');

function money(value) {
    return `$${Number(value || 0).toLocaleString('de-DE')}`;
}

function render(profile) {
    // Ohne erstellten Charakter bleibt das HUD versteckt
    if (!profile || !profile.created) {
        hud.classList.add('hidden');
        return;
    }

    hud.classList.remove('hidden');
    serverIdEl.textContent = profile.serverId ?? '-';
    nameEl.textContent = `${profile.firstName} ${profile.lastName}`.trim() || 'Unbekannt';
    cashEl.textContent = money(profile.cash);
    bankEl.textContent = money(profile.bank);
    jobEl.textContent = profile.job || 'Arbeitslos';
}

function updateClock() {
    const now = new Date();
    const hh = String(now.getHours()).padStart(2, '0');
    const mm = String(now.getMinutes()).padStart(2, '0');
    const dd = String(now.getDate()).padStart(2, '0');
    const mo = String(now.getMonth() + 1).padStart(2, '0');

    timeEl.textContent = `${hh}:${mm}`;
    dateEl.textContent = `${dd}.${mo}.${now.getFullYear()}`;
}

window.addEventListener('message', (event) => {
    const data = event.data || {};
    if (data.action === 'profile') {
        render(data.data);
    }
});

updateClock();
setInterval(updateClock, 1000);
