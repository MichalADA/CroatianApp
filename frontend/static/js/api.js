const API = window.API_URL || '';
const TOKEN_KEY = 'chorwacki_token';
const THEME_KEY = 'chorwacki_theme';

function setAppTheme(theme) {
  const safeTheme = theme === 'light' ? 'light' : 'dark';
  document.documentElement.setAttribute('data-theme', safeTheme);
  if (document.body) document.body.setAttribute('data-theme', safeTheme);
  localStorage.setItem(THEME_KEY, safeTheme);
  return safeTheme;
}

function getSavedTheme() {
  return localStorage.getItem(THEME_KEY);
}

// Włącz motyw od razu po załadowaniu skryptu (zanim dojdzie odpowiedź z API).
const initialTheme = getSavedTheme();
if (initialTheme) setAppTheme(initialTheme);

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
  async updateMe(data) {
    try {
      return await request('/auth/me', { method: 'PATCH', body: JSON.stringify(data) });
    } catch (err) {
      // Fallback dla środowisk/proxy, które nie przepuszczają PATCH.
      const msg = (err && err.message) || '';
      if (msg.includes('Failed to fetch') || msg.includes('Błąd 405')) {
        try {
          return await request('/auth/me', { method: 'PUT', body: JSON.stringify(data) });
        } catch (err2) {
          if (((err2 && err2.message) || '').includes('Błąd 405')) {
            return request('/auth/me/update', { method: 'POST', body: JSON.stringify(data) });
          }
          throw err2;
        }
      }
      throw err;
    }
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
};

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

window.setAppTheme = setAppTheme;
window.getSavedTheme = getSavedTheme;

function statusDotClass(s) {
  return (s || 'nowe').replace(/\s/g, '-').replace(/ę/g, 'ę');
}

function statusLabel(s) {
  const map = { 'nowe': 'nowe', 'uczę się': 'uczę się', 'znam': '✓ znam', 'trudne': '✗ trudne', 'do powtórki': '⏰ powtórka' };
  return map[s] || s;
}
