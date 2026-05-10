/* ──────────────────────────────────────────────────────────────────────────
   ui.js — wspólne helpery UI używane na index.html i room.html.
   Jedyny moduł odpowiedzialny za renderowanie avatara użytkownika.
   Ładowany PRZED api.js (api.js korzysta z renderUserAvatar w modalu Ustawień).
   ────────────────────────────────────────────────────────────────────────── */

// Katalog z plikami avatarów (statyczne pliki obsługiwane przez nginx).
const AVATAR_DIR = '/static/img/avatars/';

// Domyślny avatar gdy user nic nie wybrał albo wybór jest nieprawidłowy.
const DEFAULT_AVATAR = 'default-1.png';

// Lista dostępnych avatarów. Aby dodać nowy:
//   1) wrzuć plik PNG do frontend/static/img/avatars/
//   2) dopisz nazwę pliku do tablicy poniżej
//   (nazwy zachowuj krótkie — max 64 znaki, ale ~16 zdrowo)
const AVAILABLE_AVATARS = [
  'default-1.png',
  'avatar-1.png',
  'avatar-2.png',
  'avatar-3.png',
  'avatar-4.png',
  'avatar-5.png',
  'avatar-6.png',

];

// Heurystyka: ciąg znaków wyglądający jak nazwa pliku obrazka.
// Pozwala odróżnić nowe avatary-pliki od starych emoji/inicjałów,
// które mogą być zapisane w polu user.avatar (back-compat).
const _AVATAR_FILE_RE = /\.(png|jpe?g|gif|webp|svg)$/i;
function isAvatarFile(value) {
  return typeof value === 'string' && _AVATAR_FILE_RE.test(value);
}

function avatarUrl(filename) {
  return AVATAR_DIR + (filename && filename.trim() ? filename.trim() : DEFAULT_AVATAR);
}

// Wstawia avatar do podanego elementu (np. .user-avatar w topbarze).
// Reguły:
//   - user.avatar wygląda jak nazwa pliku obrazka → renderuje <img>
//   - user.avatar to emoji albo krótki tekst → renderuje tekst (back-compat)
//   - brak wartości → renderuje obrazek default-1.png
function renderUserAvatar(el, user) {
  if (!el) return;
  const val = user && user.avatar;
  if (isAvatarFile(val)) {
    el.innerHTML = `<img src="${avatarUrl(val)}" alt="">`;
    return;
  }
  if (val && String(val).trim()) {
    el.textContent = String(val).trim();
    return;
  }
  el.innerHTML = `<img src="${avatarUrl(DEFAULT_AVATAR)}" alt="">`;
}

/* ──────────────────────────────────────────────────────────────────────────
   UI sound effects — bardzo krótkie, subtelne sygnały zwrotne.
   Reguły:
   - odtwarzane TYLKO po interakcji usera (np. klik w karcie gry),
   - brak pliku → cicha awaria (catch),
   - brak autoplay,
   - kontrolowane przez localStorage (`ui_sounds_enabled`, domyślnie ON).

   Pliki kładziemy w frontend/static/audio/ui/. Konwencja:
     correct.mp3, wrong.mp3, complete.mp3
   Aby dodać kolejny: po prostu wrzuć plik i wywołaj playUiSound('jego_nazwa').

   TODO: dorzucić toggle "Dźwięki" do modala Ustawień
   (helpery są — wystarczy podpiąć checkbox na areUiSoundsEnabled/setUiSoundsEnabled).
   ────────────────────────────────────────────────────────────────────────── */

const _UI_SOUND_DIR = '/static/audio/ui/';
const _UI_SOUNDS_KEY = 'ui_sounds_enabled';
const _uiSoundCache = {};

function areUiSoundsEnabled() {
  // domyślnie włączone — dopiero jawne '0' wyłącza
  return localStorage.getItem(_UI_SOUNDS_KEY) !== '0';
}

function setUiSoundsEnabled(on) {
  localStorage.setItem(_UI_SOUNDS_KEY, on ? '1' : '0');
}

function playUiSound(name) {
  if (!areUiSoundsEnabled()) return;
  try {
    let a = _uiSoundCache[name];
    if (!a) {
      a = new Audio(_UI_SOUND_DIR + name + '.mp3');
      a.volume = 0.45; // subtelnie
      _uiSoundCache[name] = a;
    }
    a.currentTime = 0;
    a.play().catch(() => { /* brak pliku albo autoplay block — cisza */ });
  } catch { /* cisza */ }
}

/* ──────────────────────────────────────────────────────────────────────────
   TTS — wymowa słów przez Web Speech API.
   Działa offline w przeglądarce, bez nagrywania plików.
   Mapowanie kodów językowych appki na BCP-47 dla SpeechSynthesis.
   ────────────────────────────────────────────────────────────────────────── */

const _TTS_LANG_MAP = {
  hr: 'hr-HR',
  es: 'es-ES',
  el: 'el-GR',
};

let _ttsVoiceCache = null;
function _ttsVoices() {
  if (!('speechSynthesis' in window)) return [];
  if (_ttsVoiceCache) return _ttsVoiceCache;
  _ttsVoiceCache = window.speechSynthesis.getVoices() || [];
  return _ttsVoiceCache;
}
if ('speechSynthesis' in window && typeof window.speechSynthesis.onvoiceschanged !== 'undefined') {
  window.speechSynthesis.onvoiceschanged = () => { _ttsVoiceCache = null; };
}

function ttsAvailable() {
  return 'speechSynthesis' in window && typeof SpeechSynthesisUtterance !== 'undefined';
}

// Mówi `text` w języku `langCode` (kod aplikacji: hr/es/el).
// Cicha awaria gdy brak głosu — user nie zobaczy nic poza brakiem dźwięku.
function speak(text, langCode) {
  if (!ttsAvailable() || !text) return;
  try {
    window.speechSynthesis.cancel(); // przerwij poprzednią wypowiedź
    const u = new SpeechSynthesisUtterance(String(text));
    const bcp47 = _TTS_LANG_MAP[langCode] || langCode || 'en-US';
    u.lang = bcp47;
    u.rate = 0.92;
    // Spróbuj dobrać konkretny głos dla danego języka, jeśli dostępny.
    const voices = _ttsVoices();
    const match = voices.find(v => v.lang && v.lang.toLowerCase().startsWith(bcp47.toLowerCase()))
               || voices.find(v => v.lang && v.lang.toLowerCase().startsWith(bcp47.split('-')[0]));
    if (match) u.voice = match;
    window.speechSynthesis.speak(u);
  } catch { /* cisza */ }
}

// Ikona głośnika do wstawienia obok słowa. Klik = speak() w danym języku.
// Używaj `data-tts-text` i `data-tts-lang`, żeby nie wstrzykiwać onclick.
function ttsButtonHtml(text, langCode, opts = {}) {
  if (!ttsAvailable() || !text) return '';
  const size = opts.size === 'sm' ? 'tts-btn-sm' : '';
  const safeText = String(text).replace(/"/g, '&quot;');
  return `<button type="button" class="tts-btn ${size}" title="Posłuchaj"
            data-tts-text="${safeText}" data-tts-lang="${langCode || ''}"
          >🔊</button>`;
}

// Globalne wpięcie: jakikolwiek klik w `.tts-btn` odpala speak() —
// nie trzeba pamiętać o ręcznym podpinaniu listenerów dla każdej dynamicznej karty.
document.addEventListener('click', (e) => {
  const btn = e.target.closest('.tts-btn');
  if (!btn) return;
  e.preventDefault();
  e.stopPropagation();
  speak(btn.getAttribute('data-tts-text'), btn.getAttribute('data-tts-lang'));
});
