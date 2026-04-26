/* ──────────────────────────────────────────────────────────────────────────
   games.js — moduł gier oparty o znormalizowane słowa (language-agnostic).
   Cały kod gier korzysta wyłącznie z pól: sourceText, targetText, languageCode,
   languageName, status, category, roomId. Nigdzie nie wywołujemy `croatian`
   ani innych nazw językowych — backend może w przyszłości zwracać `target`
   pod każdym kodem językowym, a gry zostaną nietknięte.

   Punkt wejścia z room.html: `initGamesPanel(ctx)` gdzie ctx = { roomId, lang }.
   ────────────────────────────────────────────────────────────────────────── */

// ─── Normalizacja danych ─────────────────────────────────────────────────────

// Mapuje słowo z API na obiekt używany przez gry.
// Backend ma historyczne pole `croatian` (alias dla "słowa w języku docelowym").
// W przyszłości może dojść `target`. Bierzemy pierwsze dostępne.
function normalizeWordForGame(word, lang) {
  return {
    id: word.id,
    sourceText: word.polish,
    targetText: word.target || word.croatian || word.text_hr || '',
    category: word.category || null,
    status: word.status || 'nowe',
    roomId: word.room_id,
    languageCode: lang ? lang.code : null,
    languageName: lang ? lang.name : null,
  };
}

// Pobiera słowa z aktualnego pokoju i normalizuje je do formatu gier.
async function getGameItemsForRoom(roomId, lang) {
  const words = await api.getWords(roomId);
  return words.map(w => normalizeWordForGame(w, lang)).filter(i => i.sourceText && i.targetText);
}

// Fisher-Yates shuffle, nie mutuje wejścia.
function shuffle(arr) {
  const a = arr.slice();
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

// ─── Rejestr gier ────────────────────────────────────────────────────────────
// Dodanie nowej gry = dopisanie wpisu z `start: function(container, items)`.
const GAME_TYPES = [
  { id: 'matching', label: 'Dopasowanie', start: startMatchingGame },
  { id: 'scramble', label: 'Rozsypanka', start: null /* TODO */ },
  { id: 'hangman',  label: 'Wisielec',   start: null /* TODO */ },
];

// Rejestr zakresów. `fetch(ctx)` ma zwrócić tablicę game items.
// `enabled: false` = pokazuje pill ale klik niczego nie robi (UI placeholder).
const GAME_SCOPES = [
  {
    id: 'current-room', label: 'Ten pokój', enabled: true,
    fetch: (ctx) => getGameItemsForRoom(ctx.roomId, ctx.lang),
  },
  {
    id: 'previous-rooms', label: 'Poprzednie pokoje', enabled: false,
    fetch: null /* TODO: fetch room list, take rooms with id < ctx.roomId */,
  },
  {
    id: 'all-unlocked', label: 'Wszystkie odblokowane', enabled: false,
    fetch: null /* TODO: definicja "odblokowany" do uzgodnienia */,
  },
  {
    id: 'hard', label: 'Trudne', enabled: true,
    fetch: async (ctx) => {
      const items = await getGameItemsForRoom(ctx.roomId, ctx.lang);
      return items.filter(i => i.status === 'trudne');
    },
  },
  {
    id: 'review', label: 'Do powtórki', enabled: false,
    fetch: null /* TODO: użyć api.getReviews(roomId), zmapować na game items */,
  },
];

// ─── Stan panelu ─────────────────────────────────────────────────────────────
const gamesState = {
  ctx: null,
  selectedType: 'matching',
  selectedScope: 'current-room',
};

// ─── Init / sterowanie ───────────────────────────────────────────────────────

async function initGamesPanel(ctx) {
  // ctx = { roomId, lang: { code, name, ... } }
  gamesState.ctx = ctx;
  renderGameTypePills();
  renderGameScopePills();
  await runCurrentGame();
}

function renderGameTypePills() {
  const el = document.getElementById('game-type-pills');
  if (!el) return;
  el.innerHTML = GAME_TYPES.map(t => {
    const cls = t.id === gamesState.selectedType ? 'games-pill active' : 'games-pill';
    const disabled = !t.start;
    const suffix = disabled ? ' <span class="games-soon">wkrótce</span>' : '';
    return `<button class="${cls}" ${disabled ? 'disabled' : ''} data-type="${t.id}">${t.label}${suffix}</button>`;
  }).join('');
  el.querySelectorAll('button[data-type]').forEach(b => {
    b.addEventListener('click', () => selectGameType(b.dataset.type));
  });
}

function renderGameScopePills() {
  const el = document.getElementById('game-scope-pills');
  if (!el) return;
  el.innerHTML = GAME_SCOPES.map(s => {
    const cls = s.id === gamesState.selectedScope ? 'games-pill active' : 'games-pill';
    const disabled = !s.enabled || !s.fetch;
    const suffix = disabled ? ' <span class="games-soon">wkrótce</span>' : '';
    return `<button class="${cls}" ${disabled ? 'disabled' : ''} data-scope="${s.id}">${s.label}${suffix}</button>`;
  }).join('');
  el.querySelectorAll('button[data-scope]').forEach(b => {
    b.addEventListener('click', () => selectGameScope(b.dataset.scope));
  });
}

function selectGameType(id) {
  const t = GAME_TYPES.find(x => x.id === id);
  if (!t || !t.start) return;
  gamesState.selectedType = id;
  renderGameTypePills();
  runCurrentGame();
}

function selectGameScope(id) {
  const s = GAME_SCOPES.find(x => x.id === id);
  if (!s || !s.enabled || !s.fetch) return;
  gamesState.selectedScope = id;
  renderGameScopePills();
  runCurrentGame();
}

async function runCurrentGame() {
  const render = document.getElementById('games-render');
  if (!render) return;

  const type = GAME_TYPES.find(x => x.id === gamesState.selectedType);
  const scope = GAME_SCOPES.find(x => x.id === gamesState.selectedScope);
  if (!type || !type.start) {
    render.innerHTML = `<div class="empty-state"><p>Ta gra jeszcze niedostępna.</p></div>`;
    return;
  }
  if (!scope || !scope.fetch) {
    render.innerHTML = `<div class="empty-state"><p>Ten zakres jeszcze niedostępny.</p></div>`;
    return;
  }

  render.innerHTML = `<div class="empty-state"><p>Ładowanie…</p></div>`;
  let items;
  try {
    items = await scope.fetch(gamesState.ctx);
  } catch (e) {
    render.innerHTML = `<div class="empty-state"><div class="empty-icon">⚠️</div><p>Nie udało się pobrać słów: ${e.message || e}</p></div>`;
    return;
  }
  if (!items || !items.length) {
    render.innerHTML = `<div class="empty-state"><div class="empty-icon">📭</div><p>Brak słów dla wybranego zakresu.</p></div>`;
    return;
  }
  type.start(render, items);
}

// ─── MATCHING (MVP) ──────────────────────────────────────────────────────────

function startMatchingGame(container, items) {
  const ROUND_SIZE = 6;
  const round = shuffle(items).slice(0, Math.min(ROUND_SIZE, items.length));

  // Niezależnie tasowane kolumny, żeby lewa i prawa nie zgadzały się indeksami.
  let sources = shuffle(round.map(i => ({ id: i.id, text: i.sourceText })));
  let targets = shuffle(round.map(i => ({ id: i.id, text: i.targetText })));

  const state = {
    solved: new Set(),
    pickedSrc: null,   // id wybranego po lewej
    pickedTgt: null,   // id wybranego po prawej
    wrongSrc: null,    // id chwilowo zaznaczonego jako błąd
    wrongTgt: null,
    locked: false,     // blokada klików w trakcie animacji "wrong"
  };

  function btn(side, item) {
    const id = item.id;
    let cls = 'match-item';
    if (state.solved.has(id)) cls += ' solved';
    if ((side === 'src' && state.pickedSrc === id) ||
        (side === 'tgt' && state.pickedTgt === id)) cls += ' picked';
    if ((side === 'src' && state.wrongSrc === id) ||
        (side === 'tgt' && state.wrongTgt === id)) cls += ' wrong';
    const disabled = state.solved.has(id) || state.locked ? 'disabled' : '';
    return `<button class="${cls}" ${disabled} data-side="${side}" data-id="${id}">${item.text}</button>`;
  }

  function render() {
    const done = state.solved.size === round.length;
    container.innerHTML = `
      <div class="match-header">
        <div class="match-progress">Dopasowane: <strong>${state.solved.size}</strong> / ${round.length}</div>
        <button class="btn" id="match-restart">↻ Nowa runda</button>
      </div>
      <div class="match-grid">
        <div class="match-col" data-col="src">
          ${sources.map(s => btn('src', s)).join('')}
        </div>
        <div class="match-col" data-col="tgt">
          ${targets.map(t => btn('tgt', t)).join('')}
        </div>
      </div>
      ${done ? `<div class="match-done">🎉 Wszystkie pary dopasowane!</div>` : ''}
    `;
    container.querySelectorAll('.match-item').forEach(b => {
      b.addEventListener('click', () => onPick(b.dataset.side, parseInt(b.dataset.id, 10)));
    });
    const restart = container.querySelector('#match-restart');
    if (restart) restart.addEventListener('click', () => runCurrentGame());
  }

  function onPick(side, id) {
    if (state.locked) return;
    if (state.solved.has(id)) return;

    if (side === 'src') state.pickedSrc = state.pickedSrc === id ? null : id;
    else                state.pickedTgt = state.pickedTgt === id ? null : id;

    if (state.pickedSrc != null && state.pickedTgt != null) {
      if (state.pickedSrc === state.pickedTgt) {
        state.solved.add(state.pickedSrc);
        state.pickedSrc = null;
        state.pickedTgt = null;
        const done = state.solved.size === round.length;
        // Feedback: ostatnia para → tylko "complete", w przeciwnym razie "correct"
        if (done) {
          playUiSound('complete');
          toast('Wszystkie pary dopasowane!', 3000);
        } else {
          playUiSound('correct');
          toast('Dobra para!', 1200);
        }
      } else {
        playUiSound('wrong');
        toast('To nie ta para', 1000);
        state.wrongSrc = state.pickedSrc;
        state.wrongTgt = state.pickedTgt;
        state.pickedSrc = null;
        state.pickedTgt = null;
        state.locked = true;
        render();
        setTimeout(() => {
          state.wrongSrc = null;
          state.wrongTgt = null;
          state.locked = false;
          render();
        }, 600);
        return;
      }
    }
    render();
  }

  render();
}

// ─── TODO: Scramble ──────────────────────────────────────────────────────────
// function startScrambleGame(container, items) { ... }
// Pomysł:
//   - wybierz losowe słowo
//   - rozsyp litery item.targetText
//   - user składa litery klikając kafle
//   - sprawdzaj wynik, daj podpowiedź item.sourceText
// Dopisz do GAME_TYPES: { id:'scramble', label:'Rozsypanka', start: startScrambleGame }

// ─── TODO: Hangman ───────────────────────────────────────────────────────────
// function startHangmanGame(container, items) { ... }
// Pomysł:
//   - wybierz losowe słowo, ukryj item.targetText jako _ _ _ _
//   - user zgaduje litery z klawiatury ekranowej
//   - po N błędach koniec
// Dopisz do GAME_TYPES: { id:'hangman', label:'Wisielec', start: startHangmanGame }
