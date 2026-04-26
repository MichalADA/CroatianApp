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
