const RESOURCE = typeof window.GetParentResourceName === 'function'
    ? window.GetParentResourceName()
    : 'rp_menu';

const SLOT_COUNT = 8;
const RING_RADIUS_PERCENT = 37.5; // Ring ist 400px gross, Abstand der Slots 150px
const FACTION_SHORT = {
    1: 'LSPD',
};

const menu = document.getElementById('menu');
const slotsContainer = document.getElementById('slots');
const hubShort = document.getElementById('hubShort');
const hubHint = document.getElementById('hubHint');

let hintTimer = null;

function post(name, data) {
    return fetch(`https://${RESOURCE}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data || {}),
    });
}

function showHint(message, isError) {
    hubHint.textContent = message;
    hubHint.classList.toggle('error', Boolean(isError));
    hubHint.classList.toggle('ok', isError === false);

    if (hintTimer) clearTimeout(hintTimer);
    hintTimer = setTimeout(() => {
        hubHint.textContent = 'Menü';
        hubHint.classList.remove('error');
        hubHint.classList.remove('ok');
    }, 2600);
}

/* ------------------------------------------------------------ Aufbau */

function slotPosition(index) {
    // 0 = 12 Uhr, dann im Uhrzeigersinn
    const angle = (-90 + (360 / SLOT_COUNT) * index) * (Math.PI / 180);
    return {
        left: `${50 + RING_RADIUS_PERCENT * Math.cos(angle)}%`,
        top: `${50 + RING_RADIUS_PERCENT * Math.sin(angle)}%`,
    };
}

function buildSlots(entries) {
    slotsContainer.replaceChildren();

    for (let i = 0; i < SLOT_COUNT; i += 1) {
        const entry = entries[i];
        const position = slotPosition(i);

        const element = document.createElement(entry ? 'button' : 'div');
        element.className = entry ? 'slot filled' : 'slot empty';
        element.style.left = position.left;
        element.style.top = position.top;

        if (entry) {
            element.type = 'button';
            element.textContent = entry.label;
            element.dataset.id = entry.id;
            element.addEventListener('click', () => {
                post('select', { id: entry.id }).catch(() => {
                    showHint('Verbindung fehlgeschlagen.', true);
                });
            });
        }

        slotsContainer.append(element);
    }
}

/* ------------------------------------------------------------ Nachrichten */

window.addEventListener('message', (event) => {
    const data = event.data || {};

    if (data.action === 'open') {
        const payload = data.data || {};
        const entries = Array.isArray(payload.entries) ? payload.entries : [];

        hubShort.textContent = FACTION_SHORT[payload.faction] || 'FRAKTION';
        hubHint.textContent = 'Menü';
        hubHint.classList.remove('error');
        hubHint.classList.remove('ok');

        buildSlots(entries);
        menu.classList.remove('hidden');
    }

    if (data.action === 'close') {
        menu.classList.add('hidden');
        slotsContainer.replaceChildren();
    }

    if (data.action === 'hint') {
        const payload = data.data || {};
        showHint(payload.message || 'Noch nicht verfügbar.', payload.error === true);
    }
});

document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        event.preventDefault();
        post('close');
    }
});

document.addEventListener('contextmenu', (event) => event.preventDefault());
