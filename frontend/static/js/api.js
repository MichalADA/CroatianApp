const API = window.API_URL || 'http://localhost:8000';
const TOKEN_KEY = 'chorwacki_token';
const THEME_KEY = 'chorwacki_theme';
const FOCUS_KEY = 'focusModeEnabled';

// ─── Theme ──────────────────────────────────────────────────────────────────
// Stosowane ZARAZ przy ładowaniu skryptu — dzięki temu motyw nie miga
// na chwilę domyślnym ciemnym, gdy user ma jasny.
function applyTheme(theme) {
  const t = theme === 'light' ? 'light' : 'dark';
  document.documentElement.classList.toggle('theme-light', t === 'light');
  localStorage.setItem(THEME_KEY, t);
}
applyTheme(localStorage.getItem(THEME_KEY) || 'dark');

// ─── Focus mode ─────────────────────────────────────────────────────────────
// Tylko localStorage — backend nie wie nic o focus mode (świadoma decyzja:
// to ustawienie urządzenia, nie konta).
function isFocusModeEnabled() {
  return localStorage.getItem(FOCUS_KEY) === '1';
}
function setFocusMode(enabled) {
  if (enabled) localStorage.setItem(FOCUS_KEY, '1');
  else localStorage.removeItem(FOCUS_KEY);
  applyFocusModeClass();
}
function applyFocusModeClass() {
  if (document.body) {
    document.body.classList.toggle('focus-mode', isFocusModeEnabled());
  }
}
// CSS reaguje na klasę na <body>, którą dorzucamy najwcześniej jak się da.
document.addEventListener('DOMContentLoaded', applyFocusModeClass);

// ─── Token helpers ──────────────────────────────────────────────────────────
const auth = {
  getToken() { return localStorage.getItem(TOKEN_KEY); },
  setToken(t) { localStorage.setItem(TOKEN_KEY, t); },
  clearToken() { localStorage.removeItem(TOKEN_KEY); },
  isLoggedIn() { return !!this.getToken(); },
  logout() {
    this.clearToken();
    location.href = '/static/pages/login.html';
  },
};

// ─── HTTP wrapper ───────────────────────────────────────────────────────────
async function request(path, opts = {}) {
  const headers = Object.assign({}, opts.headers || {});
  const token = auth.getToken();
  if (token) headers['Authorization'] = 'Bearer ' + token;
  if (opts.body && !headers['Content-Type']) headers['Content-Type'] = 'application/json';

  const r = await fetch(API + path, Object.assign({}, opts, { headers }));

  // 401 → token wygasł lub brak — wywal na ekran logowania
  if (r.status === 401) {
    auth.clearToken();
    if (!location.pathname.endsWith('/login.html')) {
      location.href = '/static/pages/login.html';
    }
    throw new Error('unauthorized');
  }

  if (!r.ok) {
    let msg = 'Błąd ' + r.status;
    try {
      const j = await r.json();
      if (typeof j.detail === 'string') {
        msg = j.detail;
      } else if (Array.isArray(j.detail)) {
        // Pydantic validation: [{ loc: [...], msg: '...', type: '...' }, ...]
        msg = j.detail.map(d => {
          const field = Array.isArray(d.loc) ? d.loc[d.loc.length - 1] : '';
          const txt = d.msg || d.type || 'błąd';
          return field ? `${field}: ${txt}` : txt;
        }).join(' • ');
      } else if (j.detail) {
        msg = JSON.stringify(j.detail);
      }
    } catch {}
    throw new Error(msg);
  }

  if (r.status === 204) return null;
  return r.json();
}

const api = {
  // ─── auth ────────────────────────────────────────────────────────────────
  async register(data) {
    const r = await request('/auth/register', { method: 'POST', body: JSON.stringify(data) });
    if (r.access_token) auth.setToken(r.access_token);
    return r;
  },
  async login(data) {
    const r = await request('/auth/login', { method: 'POST', body: JSON.stringify(data) });
    if (r.access_token) auth.setToken(r.access_token);
    return r;
  },
  async me() { return request('/auth/me'); },

  // ─── languages ───────────────────────────────────────────────────────────
  async getLanguages() { return request('/languages'); },
  async getMyLanguage() { return request('/me/language'); },
  async setMyLanguage(code) {
    return request('/me/language', { method: 'POST', body: JSON.stringify({ language: code }) });
  },

  // ─── rooms / words / verbs ───────────────────────────────────────────────
  async getRooms() { return request('/rooms'); },
  async getRoom(id) { return request(`/rooms/${id}`); },
  async getWords(roomId, q = '', cat = '') {
    const p = new URLSearchParams();
    if (q) p.set('q', q);
    if (cat && cat !== 'wszystkie') p.set('category', cat);
    return request(`/rooms/${roomId}/words?${p}`);
  },
  async getWordCategories(roomId) { return request(`/rooms/${roomId}/words/categories`); },
  async getVerbs(roomId, q = '') {
    const p = new URLSearchParams();
    if (q) p.set('q', q);
    return request(`/rooms/${roomId}/verbs?${p}`);
  },

  // ─── reviews / learning / progress ───────────────────────────────────────
  async getReviews(roomId) { return request(`/rooms/${roomId}/reviews`); },
  async getLearningSession(roomId, limit = 20) {
    return request(`/rooms/${roomId}/learning-session?limit=${limit}`);
  },
  async postProgress(data) {
    return request('/progress', { method: 'POST', body: JSON.stringify(data) });
  },
  async startLearning(data) {
    return request('/progress/start', { method: 'POST', body: JSON.stringify(data) });
  },

  // ─── sentences ───────────────────────────────────────────────────────────
  async getSentences(roomId) { return request(`/rooms/${roomId}/sentences`); },
  async postSentence(data) {
    return request('/sentences', { method: 'POST', body: JSON.stringify(data) });
  },
  async deleteSentence(id) {
    return request(`/sentences/${id}`, { method: 'DELETE' });
  },

  // ─── dashboard ───────────────────────────────────────────────────────────
  async getDashboard() { return request('/dashboard'); },

  // ─── settings (theme, avatar) ────────────────────────────────────────────
  async updateSettings(data) {
    return request('/me/settings', { method: 'PATCH', body: JSON.stringify(data) });
  },
};

// ─── Avatar helper ─────────────────────────────────────────────────────────
function avatarFor(user) {
  if (user && user.avatar && user.avatar.trim()) return user.avatar.trim();
  return ((user && user.username && user.username[0]) || '?').toUpperCase();
}

// ─── Settings modal ────────────────────────────────────────────────────────
// Wstrzykiwany dynamicznie — dostępny z każdej strony, która ładuje api.js.
function openSettingsModal(user) {
  // Usuń poprzedni, jeśli był otwarty
  const existing = document.getElementById('settings-modal');
  if (existing) existing.remove();

  const initials = (user.username[0] || '?').toUpperCase();

  const overlay = document.createElement('div');
  overlay.id = 'settings-modal';
  overlay.className = 'modal-overlay';
  overlay.innerHTML = `
    <div class="modal settings-modal">
      <header class="settings-header">
        <h3>Ustawienia</h3>
        <button type="button" class="settings-close" id="set-close" aria-label="Zamknij">×</button>
      </header>

      <div class="settings-body">

        <section class="settings-section">
          <div class="settings-section-head">
            <div class="settings-section-title">Motyw</div>
            <div class="settings-section-desc">Kolorystyka interfejsu.</div>
          </div>
          <div class="theme-toggle">
            <button type="button" class="theme-opt" data-theme="dark">🌙 Ciemny</button>
            <button type="button" class="theme-opt" data-theme="light">☀️ Jasny</button>
          </div>
        </section>

        <section class="settings-section">
          <div class="settings-section-head">
            <div class="settings-section-title">Tryb skupienia</div>
            <div class="settings-section-desc">Ukrywa elementy rozpraszające podczas nauki.</div>
          </div>
          <label class="switch">
            <input type="checkbox" id="set-focus-toggle">
            <span class="switch-track"><span class="switch-thumb"></span></span>
          </label>
        </section>

        <section class="settings-section settings-section--col">
          <div class="settings-section-head">
            <div class="settings-section-title">Twój avatar</div>
            <div class="settings-section-desc">Emoji albo 1–3 znaki. Puste = inicjał z nicku (${initials}).</div>
          </div>
          <div class="avatar-row">
            <span class="user-avatar settings-avatar-preview" id="set-avatar-preview">?</span>
            <input type="text" id="set-avatar-input" maxlength="16"
                   placeholder="np. 🐉  albo  M  albo  PL">
          </div>
        </section>

        <section class="settings-section settings-section--col">
          <div class="settings-section-head">
            <div class="settings-section-title">Konto</div>
          </div>
          <div class="settings-account">
            <div class="settings-account-name">${user.username}</div>
            <div class="settings-account-email">${user.email}</div>
          </div>
        </section>

      </div>

      <footer class="settings-footer">
        <button class="btn" id="set-cancel">Anuluj</button>
        <button class="btn primary" id="set-save">Zapisz zmiany</button>
      </footer>
    </div>
  `;
  document.body.appendChild(overlay);
  overlay.style.display = 'flex';

  // ── Stan
  let chosenTheme = user.theme === 'light' ? 'light' : 'dark';
  let chosenAvatar = user.avatar || '';
  let chosenFocus = isFocusModeEnabled();

  // Snapshot startu — do cofnięcia, gdy user kliknie Anuluj.
  const initialFocus = chosenFocus;

  const previewEl = overlay.querySelector('#set-avatar-preview');
  const inputEl = overlay.querySelector('#set-avatar-input');
  const focusToggle = overlay.querySelector('#set-focus-toggle');
  inputEl.value = chosenAvatar;
  previewEl.textContent = avatarFor(user);
  focusToggle.checked = chosenFocus;

  function updatePreview() {
    previewEl.textContent = avatarFor({
      username: user.username,
      avatar: chosenAvatar,
    });
  }

  function setActiveTheme() {
    overlay.querySelectorAll('.theme-opt').forEach(b => {
      b.classList.toggle('active', b.dataset.theme === chosenTheme);
    });
    applyTheme(chosenTheme); // live preview
  }
  setActiveTheme();

  overlay.querySelectorAll('.theme-opt').forEach(b => {
    b.addEventListener('click', () => { chosenTheme = b.dataset.theme; setActiveTheme(); });
  });

  inputEl.addEventListener('input', e => {
    chosenAvatar = e.target.value;
    updatePreview();
  });

  focusToggle.addEventListener('change', e => {
    chosenFocus = e.target.checked;
    // live preview — od razu pokaż jak strona wygląda w trybie skupienia
    setFocusMode(chosenFocus);
  });

  function closeModal(revert) {
    if (revert) {
      applyTheme(user.theme || 'dark');
      setFocusMode(initialFocus);
    }
    overlay.remove();
  }

  overlay.addEventListener('click', e => { if (e.target === overlay) closeModal(true); });
  overlay.querySelector('#set-close').onclick = () => closeModal(true);
  overlay.querySelector('#set-cancel').onclick = () => closeModal(true);

  overlay.querySelector('#set-save').onclick = async () => {
    const btn = overlay.querySelector('#set-save');
    btn.disabled = true;
    try {
      const updated = await api.updateSettings({
        theme: chosenTheme,
        avatar: chosenAvatar,
      });
      applyTheme(updated.theme);
      setFocusMode(chosenFocus); // utrwal w localStorage
      const avEls = document.querySelectorAll('[data-user-avatar]');
      avEls.forEach(el => { el.textContent = avatarFor(updated); });
      toast('Zapisano ustawienia');
      Object.assign(user, updated);
      overlay.remove();
    } catch (e) {
      toast(e.message || 'Nie udało się zapisać');
      btn.disabled = false;
    }
  };
}

// ─── Bramka: jeśli brak tokena → na login (oprócz samej strony login) ──────
function requireAuth() {
  if (!auth.isLoggedIn()) {
    location.href = '/static/pages/login.html';
    return false;
  }
  return true;
}

function toast(msg, duration = 2500) {
  const el = document.createElement('div');
  el.className = 'toast';
  el.textContent = msg;
  document.body.appendChild(el);
  setTimeout(() => el.remove(), duration);
}

function statusDotClass(s) {
  return (s || 'nowe').replace(/\s/g, '-').replace(/ę/g, 'ę');
}

function statusLabel(s) {
  const map = { 'nowe': 'nowe', 'uczę się': 'uczę się', 'znam': '✓ znam', 'trudne': '✗ trudne', 'do powtórki': '⏰ powtórka' };
  return map[s] || s;
}
