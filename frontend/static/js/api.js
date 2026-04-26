const API = window.API_URL || 'http://localhost:8000';
const TOKEN_KEY = 'chorwacki_token';
const THEME_KEY = 'chorwacki_theme';

// ─── Theme ──────────────────────────────────────────────────────────────────
// Stosowane ZARAZ przy ładowaniu skryptu — dzięki temu motyw nie miga
// na chwilę domyślnym ciemnym, gdy user ma jasny.
function applyTheme(theme) {
  const t = theme === 'light' ? 'light' : 'dark';
  document.documentElement.classList.toggle('theme-light', t === 'light');
  localStorage.setItem(THEME_KEY, t);
}
applyTheme(localStorage.getItem(THEME_KEY) || 'dark');

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

// ─── Avatar helper (legacy fallback dla miejsc, które nadal renderują tekst) ─
function avatarFor(user) {
  if (user && user.avatar && user.avatar.trim()) return user.avatar.trim();
  return ((user && user.username && user.username[0]) || '?').toUpperCase();
}

// ─── Settings modal ────────────────────────────────────────────────────────
// Wstrzykiwany dynamicznie — dostępny z każdej strony, która ładuje api.js.
// Zależy od ui.js (AVAILABLE_AVATARS, DEFAULT_AVATAR, avatarUrl, renderUserAvatar).
function openSettingsModal(user) {
  // Usuń poprzedni, jeśli był otwarty
  const existing = document.getElementById('settings-modal');
  if (existing) existing.remove();

  // Domyślnie podświetlamy default-1.png, jeśli user nie ma avatara
  // albo ma starą wartość (emoji) niewystępującą na liście plików.
  const startAvatar = (user && user.avatar && AVAILABLE_AVATARS.indexOf(user.avatar) !== -1)
    ? user.avatar
    : DEFAULT_AVATAR;

  const overlay = document.createElement('div');
  overlay.id = 'settings-modal';
  overlay.className = 'modal-overlay';
  overlay.innerHTML = `
    <div class="modal" style="max-width:480px">
      <h3>Ustawienia</h3>

      <div class="form-group">
        <label>Motyw</label>
        <div class="theme-toggle">
          <button type="button" class="theme-opt" data-theme="dark">🌙 Ciemny</button>
          <button type="button" class="theme-opt" data-theme="light">☀️ Jasny</button>
        </div>
      </div>

      <div class="form-group">
        <label>Twój avatar</label>
        <div class="avatar-grid" id="set-avatar-grid">
          ${AVAILABLE_AVATARS.map(name => `
            <button type="button" class="avatar-option" data-avatar="${name}" title="${name}">
              <img src="${avatarUrl(name)}" alt="${name}">
            </button>
          `).join('')}
        </div>
        <div style="font-size:11px;color:var(--text3);margin-top:8px">
          Wybierz z dostępnych obrazków. Brak wyboru = ${DEFAULT_AVATAR}.
        </div>
      </div>

      <div class="form-group">
        <label>Konto</label>
        <div style="background:var(--surface2);padding:10px 12px;border-radius:8px;font-size:13px;color:var(--text2)">
          <div><strong style="color:var(--text)">${user.username}</strong></div>
          <div style="font-size:12px">${user.email}</div>
        </div>
      </div>

      <div class="modal-actions">
        <button class="btn" id="set-cancel">Anuluj</button>
        <button class="btn primary" id="set-save">Zapisz</button>
      </div>
    </div>
  `;
  document.body.appendChild(overlay);
  overlay.style.display = 'flex';

  // Stan
  let chosenTheme = user.theme === 'light' ? 'light' : 'dark';
  let chosenAvatar = startAvatar;

  const grid = overlay.querySelector('#set-avatar-grid');

  function refreshAvatarGrid() {
    grid.querySelectorAll('.avatar-option').forEach(b => {
      b.classList.toggle('selected', b.dataset.avatar === chosenAvatar);
    });
  }
  refreshAvatarGrid();

  grid.querySelectorAll('.avatar-option').forEach(b => {
    b.addEventListener('click', () => {
      chosenAvatar = b.dataset.avatar;
      refreshAvatarGrid();
    });
  });

  function setActiveTheme() {
    overlay.querySelectorAll('.theme-opt').forEach(b => {
      b.classList.toggle('active', b.dataset.theme === chosenTheme);
    });
    // Live preview motywu
    applyTheme(chosenTheme);
  }
  setActiveTheme();

  overlay.querySelectorAll('.theme-opt').forEach(b => {
    b.addEventListener('click', () => { chosenTheme = b.dataset.theme; setActiveTheme(); });
  });

  overlay.addEventListener('click', e => {
    if (e.target === overlay) closeModal(true);
  });

  function closeModal(revert) {
    if (revert) {
      // przywróć motyw zapisany na serwerze, jeśli user anulował
      applyTheme(user.theme || 'dark');
    }
    overlay.remove();
  }

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
      // Zaktualizuj topbar (jeśli istnieje) bez pełnego reloadu — używamy
      // wspólnego helpera z ui.js, więc jeden punkt prawdy.
      document.querySelectorAll('[data-user-avatar]').forEach(el => {
        renderUserAvatar(el, updated);
      });
      toast('Zapisano ustawienia');
      // Zaktualizuj cache obiektu user — tak by kolejne otwarcie miało świeże dane
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
