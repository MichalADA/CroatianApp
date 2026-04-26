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
