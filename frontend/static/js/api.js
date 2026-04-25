const API = window.API_URL || 'http://localhost:8000';

const api = {
  async getRooms() {
    const r = await fetch(`${API}/rooms`);
    return r.json();
  },
  async getRoom(id) {
    const r = await fetch(`${API}/rooms/${id}`);
    return r.json();
  },
  async getWords(roomId, q = '', cat = '') {
    const params = new URLSearchParams();
    if (q) params.set('q', q);
    if (cat && cat !== 'wszystkie') params.set('category', cat);
    const r = await fetch(`${API}/rooms/${roomId}/words?${params}`);
    return r.json();
  },
  async getWordCategories(roomId) {
    const r = await fetch(`${API}/rooms/${roomId}/words/categories`);
    return r.json();
  },
  async getVerbs(roomId, q = '') {
    const params = new URLSearchParams();
    if (q) params.set('q', q);
    const r = await fetch(`${API}/rooms/${roomId}/verbs?${params}`);
    return r.json();
  },
  async getReviews(roomId) {
    const r = await fetch(`${API}/rooms/${roomId}/reviews`);
    return r.json();
  },
  async getLearningSession(roomId, limit = 20) {
    const r = await fetch(`${API}/rooms/${roomId}/learning-session?limit=${limit}`);
    return r.json();
  },
  async postProgress(data) {
    const r = await fetch(`${API}/progress`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    return r.json();
  },
  async startLearning(data) {
    const r = await fetch(`${API}/progress/start`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    return r.json();
  },
  async getSentences(roomId) {
    const r = await fetch(`${API}/rooms/${roomId}/sentences`);
    return r.json();
  },
  async postSentence(data) {
    const r = await fetch(`${API}/sentences`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    return r.json();
  },
  async deleteSentence(id) {
    const r = await fetch(`${API}/sentences/${id}`, { method: 'DELETE' });
    return r.json();
  },
  async getDashboard() {
    const r = await fetch(`${API}/dashboard`);
    return r.json();
  },
};

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
