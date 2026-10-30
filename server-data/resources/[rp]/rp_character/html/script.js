const RESOURCE = typeof window.GetParentResourceName === 'function'
    ? window.GetParentResourceName()
    : 'rp_character';

const app = document.getElementById('app');
const form = document.getElementById('form');
const errorBox = document.getElementById('error');
const submitBtn = document.getElementById('submit');
const firstNameInput = document.getElementById('firstName');
const lastNameInput = document.getElementById('lastName');
const birthdateInput = document.getElementById('birthdate');
const genderButtons = Array.from(document.querySelectorAll('.gender-btn'));

let gender = 'm';
let sending = false;

/* ---------------------------------------------------------------- Hilfen */

function showError(message) {
    errorBox.textContent = message || '';
}

function setVisible(visible) {
    app.classList.toggle('hidden', !visible);
    if (visible) {
        showError('');
        sending = false;
        submitBtn.disabled = false;
        submitBtn.textContent = 'Charakter erstellen';
    }
}

function post(name, data) {
    return fetch(`https://${RESOURCE}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data || {}),
    });
}

/* ---------------------------------------------------------------- Geschlecht */

genderButtons.forEach((button) => {
    button.addEventListener('click', () => {
        gender = button.dataset.gender;
        genderButtons.forEach((other) => other.classList.toggle('active', other === button));
    });
});

/* ---------------------------------------------------------------- Geburtsdatum */

birthdateInput.addEventListener('input', () => {
    const digits = birthdateInput.value.replace(/\D/g, '').slice(0, 8);
    const parts = [digits.slice(0, 2), digits.slice(2, 4), digits.slice(4, 8)].filter(Boolean);
    birthdateInput.value = parts.join('.');
});

/* ---------------------------------------------------------------- Absenden */

function validate() {
    const firstName = firstNameInput.value.trim();
    const lastName = lastNameInput.value.trim();
    const birthdate = birthdateInput.value.trim();

    if (firstName.length < 2 || firstName.length > 24) {
        return { error: 'Bitte gib einen Vornamen mit 2 bis 24 Zeichen ein.' };
    }
    if (lastName.length < 2 || lastName.length > 24) {
        return { error: 'Bitte gib einen Nachnamen mit 2 bis 24 Zeichen ein.' };
    }
    if (!/^\d{2}\.\d{2}\.\d{4}$/.test(birthdate)) {
        return { error: 'Geburtsdatum bitte als TT.MM.JJJJ angeben.' };
    }

    return { firstName, lastName, birthdate };
}

form.addEventListener('submit', (event) => {
    event.preventDefault();
    if (sending) return;

    const result = validate();
    if (result.error) {
        showError(result.error);
        return;
    }

    showError('');
    sending = true;
    submitBtn.disabled = true;
    submitBtn.textContent = 'Wird erstellt...';

    post('submit', {
        firstName: result.firstName,
        lastName: result.lastName,
        birthdate: result.birthdate,
        gender,
    }).catch(() => {
        showError('Verbindung zum Server fehlgeschlagen.');
        sending = false;
        submitBtn.disabled = false;
        submitBtn.textContent = 'Charakter erstellen';
    });
});

/* ---------------------------------------------------------------- Nachrichten aus dem Spiel */

window.addEventListener('message', (event) => {
    const data = event.data || {};

    if (data.action === 'visibility') {
        setVisible(Boolean(data.value));
    }

    if (data.action === 'error') {
        showError(data.message);
        sending = false;
        submitBtn.disabled = false;
        submitBtn.textContent = 'Charakter erstellen';
    }
});

document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        event.preventDefault();
    }
});
