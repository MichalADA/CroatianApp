const API = window.API_URL || 'http://localhost:8000';
const TOKEN_KEY = 'chorwacki_token';

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
    try { const j = await r.json(); if (j.detail) msg = j.detail; } catch {}
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

function statusDotClass(s) {
  return (s || 'nowe').replace(/\s/g, '-').replace(/ę/g, 'ę');
}

function statusLabel(s) {
  const map = { 'nowe': 'nowe', 'uczę się': 'uczę się', 'znam': '✓ znam', 'trudne': '✗ trudne', 'do powtórki': '⏰ powtórka' };
  return map[s] || s;
}
