const RESOURCE = typeof window.GetParentResourceName === 'function'
    ? window.GetParentResourceName()
    : 'rp_tablet';

const tablet = document.getElementById('tablet');
const navItems = Array.from(document.querySelectorAll('.nav-item'));
const panels = Array.from(document.querySelectorAll('.panel'));
const transferForm = document.getElementById('transferForm');
const transferBtn = document.getElementById('transferBtn');
const feedback = document.getElementById('transferFeedback');
const targetIdInput = document.getElementById('targetId');
const amountInput = document.getElementById('amount');

let profile = null;
let serverInfo = null;
let sending = false;

/* ------------------------------------------------------------ Hilfen */

function money(value) {
    return `$${Number(value || 0).toLocaleString('de-DE')}`;
}

function setText(id, value) {
    const element = document.getElementById(id);
    if (element) element.textContent = value;
}

function genderLabel(gender) {
    if (gender === 'f') return 'Weiblich';
    if (gender === 'm') return 'Männlich';
    return '-';
}

function post(name, data) {
    return fetch(`https://${RESOURCE}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data || {}),
    });
}

/* ------------------------------------------------------------ Navigation */

function switchApp(app) {
    navItems.forEach((item) => item.classList.toggle('active', item.dataset.app === app));
    panels.forEach((panel) => panel.classList.toggle('active', panel.dataset.panel === app));
}

navItems.forEach((item) => {
    item.addEventListener('click', () => switchApp(item.dataset.app));
});

document.getElementById('closeBtn').addEventListener('click', () => {
    post('close');
});

/* ------------------------------------------------------------ Daten anzeigen */

function renderProfile(data) {
    profile = data;
    if (!data) return;

    const fullName = `${data.firstName || ''} ${data.lastName || ''}`.trim();

    setText('welcome', fullName ? `Willkommen zurück, ${data.firstName}.` : 'Willkommen zurück.');

    setText('ovCash', money(data.cash));
    setText('ovBank', money(data.bank));
    setText('ovJob', data.job || 'Arbeitslos');
    setText('ovId', data.serverId ?? '-');
    setText('ovName', fullName || '-');
    setText('ovBirth', data.birthdate || '-');
    setText('ovGender', genderLabel(data.gender));

    setText('trBank', money(data.bank));

    setText('chFirst', data.firstName || '-');
    setText('chLast', data.lastName || '-');
    setText('chBirth', data.birthdate || '-');
    setText('chGender', genderLabel(data.gender));
    setText('chJob', data.job || 'Arbeitslos');
    setText('chId', data.serverId ?? '-');
}

function renderServerInfo(data) {
    serverInfo = data;
    if (!data) return;

    setText('brandName', data.name || 'Los Santos Life');
    setText('svName', data.name || '-');
    setText('svPlayers', `${data.players ?? 0} / ${data.max ?? 32}`);
    setText('onlineBadge', `${data.players ?? 0} / ${data.max ?? 32} online`);
}

/* ------------------------------------------------------------ Überweisung */

document.getElementById('quickAmounts').addEventListener('click', (event) => {
    const button = event.target.closest('button[data-amount]');
    if (!button) return;
    amountInput.value = button.dataset.amount;
    amountInput.focus();
});

function showFeedback(ok, message) {
    feedback.textContent = message || '';
    feedback.classList.toggle('error', !ok);

    sending = false;
    transferBtn.disabled = false;
    transferBtn.textContent = 'Überweisung senden';
}

transferForm.addEventListener('submit', (event) => {
    event.preventDefault();
    if (sending) return;

    const targetId = Number.parseInt(targetIdInput.value, 10);
    const amount = Number.parseInt(amountInput.value, 10);

    if (!Number.isFinite(targetId) || targetId < 1) {
        showFeedback(false, 'Bitte eine gültige Server-ID eingeben.');
        return;
    }
    if (!Number.isFinite(amount) || amount < 1) {
        showFeedback(false, 'Bitte einen gültigen Betrag eingeben.');
        return;
    }
    if (profile && amount > Number(profile.bank || 0)) {
        showFeedback(false, 'So viel Geld liegt nicht auf der Bank.');
        return;
    }

    sending = true;
    transferBtn.disabled = true;
    transferBtn.textContent = 'Wird gesendet...';
    showFeedback(true, '');

    post('transfer', { targetId, amount }).catch(() => {
        showFeedback(false, 'Verbindung zum Server fehlgeschlagen.');
    });
});

/* ------------------------------------------------------------ Nachrichten aus dem Spiel */

window.addEventListener('message', (event) => {
    const data = event.data || {};

    if (data.action === 'open') {
        tablet.classList.remove('hidden');
        switchApp('overview');
        showFeedback(true, '');
        amountInput.value = '';
        targetIdInput.value = '';
    }

    if (data.action === 'close') {
        tablet.classList.add('hidden');
    }

    if (data.action === 'profile') {
        renderProfile(data.data);
    }

    if (data.action === 'serverInfo') {
        renderServerInfo(data.data);
    }

    if (data.action === 'feedback') {
        const payload = data.data || {};
        showFeedback(payload.ok !== false, payload.message);
    }
});

document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        event.preventDefault();
        post('close');
    }
});
