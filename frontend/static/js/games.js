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
  { id: 'scramble', label: 'Rozsypanka', start: startScrambleGame },
  { id: 'hangman',  label: 'Wisielec',   start: startHangmanGame },
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

// ─── SCRAMBLE (Rozsypanka) ───────────────────────────────────────────────────
//
// Gra: pokaż słowo źródłowe (np. "kawa") + rozsypane litery slowa docelowego.
// User klika litery, wskoczą do najbliższego pustego slotu. Po wypełnieniu
// wszystkich slotów następuje auto-sprawdzenie. Runda = 5 słów.
//
// Filtrujemy jedno-wyrazowe słowa o sensownej długości (3-10 znaków),
// żeby gra była grywalna i niezależna od języka — dla każdego języka
// to są zwykle te same kryteria.

function startScrambleGame(container, items) {
  const ROUND_SIZE = 5;
  const candidates = items.filter(i =>
    i.targetText &&
    i.targetText.length >= 3 &&
    i.targetText.length <= 10 &&
    !/\s/.test(i.targetText)
  );

  if (!candidates.length) {
    container.innerHTML = `
      <div class="empty-state">
        <div class="empty-icon">📭</div>
        <p>Brak słów odpowiednich do rozsypanki w tym zakresie<br>
        (potrzebne pojedyncze wyrazy długości 3–10 znaków).</p>
      </div>`;
    return;
  }

  const round = shuffle(candidates).slice(0, Math.min(ROUND_SIZE, candidates.length));

  const state = {
    idx: 0,         // który aktualnie rozwiązujemy
    score: 0,       // ile poprawnie ułożonych
    tiles: [],      // [{char, used}]
    placed: [],     // sloty: indeks tile'a albo null
    locked: false,
    wrong: false,
    correct: false, // chwilowy zielony flash po poprawnym słowie
  };

  function startWord() {
    const word = round[state.idx].targetText;
    state.tiles = shuffle(word.split('')).map(ch => ({ char: ch, used: false }));
    state.placed = new Array(word.length).fill(null);
    state.locked = false;
    state.wrong = false;
    state.correct = false;
    render();
  }

  function currentBuiltWord() {
    return state.placed.map(ti => (ti == null ? '' : state.tiles[ti].char)).join('');
  }

  function render() {
    const item = round[state.idx];
    const total = round.length;
    // Tile'e użyte znikają z DOM — pozostałe zwijają się przez flex-wrap.
    const tilesHtml = state.tiles.map((t, i) =>
      t.used ? '' :
      `<button class="scramble-tile" data-tile="${i}" ${state.locked ? 'disabled' : ''}>${t.char}</button>`
    ).join('');
    const slotsHtml = state.placed.map((ti, i) => {
      const ch = ti == null ? '' : state.tiles[ti].char;
      let cls = 'scramble-slot';
      if (ti == null) cls += ' empty';
      if (state.wrong) cls += ' wrong';
      if (state.correct) cls += ' correct';
      const dis = (ti == null || state.locked) ? 'disabled' : '';
      return `<button class="${cls}" data-slot="${i}" ${dis}>${ch || ''}</button>`;
    }).join('');

    container.innerHTML = `
      <div class="scr-header">
        <div class="match-progress">Słowo <strong>${state.idx + 1}</strong> / ${total} · Wynik: <strong>${state.score}</strong></div>
        <button class="btn" id="scr-restart">↻ Nowa runda</button>
      </div>
      <div class="scr-card">
        <div class="scr-source-label">Polski</div>
        <div class="scr-source">${item.sourceText}</div>
        <div class="scramble-slots">${slotsHtml}</div>
        <div class="scramble-letters">${tilesHtml}</div>
      </div>
    `;
    container.querySelectorAll('.scramble-tile').forEach(b => {
      b.addEventListener('click', () => onTile(parseInt(b.dataset.tile, 10)));
    });
    container.querySelectorAll('.scramble-slot').forEach(b => {
      b.addEventListener('click', () => onSlot(parseInt(b.dataset.slot, 10)));
    });
    container.querySelector('#scr-restart').addEventListener('click', () => runCurrentGame());
  }

  function onTile(tileIdx) {
    if (state.locked) return;
    const t = state.tiles[tileIdx];
    if (!t || t.used) return;
    const slot = state.placed.indexOf(null);
    if (slot === -1) return;
    state.placed[slot] = tileIdx;
    t.used = true;

    // Wszystkie sloty wypełnione → sprawdzaj
    if (state.placed.indexOf(null) === -1) {
      const built = currentBuiltWord();
      const target = round[state.idx].targetText;
      if (built === target) {
        state.score++;
        state.correct = true;   // zielony flash slotów
        state.locked = true;
        const last = state.idx === round.length - 1;
        if (last) {
          playUiSound('complete');
          toast('Dobrze! Wszystkie słowa rozwiązane!', 3000);
          render();
          setTimeout(() => {
            container.innerHTML = `
              <div class="match-done">🎉 Świetnie! Ułożyłeś/aś ${state.score} / ${round.length} słów.</div>
              <div style="text-align:center;margin-top:1rem">
                <button class="btn primary" id="scr-again">↻ Nowa runda</button>
              </div>`;
            container.querySelector('#scr-again').addEventListener('click', () => runCurrentGame());
          }, 900);
          return;
        } else {
          playUiSound('correct');
          toast('Dobrze!', 1000);
          render();
          setTimeout(() => { state.idx++; startWord(); }, 800);
          return;
        }
      } else {
        playUiSound('wrong');
        toast('Nie ten układ', 900);
        state.wrong = true;
        state.locked = true;
        render();
        setTimeout(() => {
          // Czyść sloty, oznacz wszystkie tile'y jako wolne
          state.tiles.forEach(t => t.used = false);
          state.placed.fill(null);
          state.wrong = false;
          state.locked = false;
          render();
        }, 700);
        return;
      }
    }
    render();
  }

  function onSlot(slotIdx) {
    if (state.locked) return;
    const tileIdx = state.placed[slotIdx];
    if (tileIdx == null) return;
    state.tiles[tileIdx].used = false;
    state.placed[slotIdx] = null;
    render();
  }

  startWord();
}

// ─── HANGMAN (Wisielec) ──────────────────────────────────────────────────────
//
// Gra: jedno słowo, klawiatura ekranowa (litery wyciągnięte z dostępnych słów
// w zakresie — language-agnostic). 6 błędów = porażka. Pełne odsłonięcie = wygrana.
// Spacje i myślniki w słowie zostają widoczne.

// ASCII rysunek wisielca — indeks = liczba błędów (0..6).
// Indeks 6 = pełna postać = porażka.
const HANGMAN_STATES = [
  // 0 — sama szubienica
  "  +---+\n" +
  "  |   |\n" +
  "      |\n" +
  "      |\n" +
  "      |\n" +
  "      |\n" +
  "=========",
  // 1 — głowa
  "  +---+\n" +
  "  |   |\n" +
  "  O   |\n" +
  "      |\n" +
  "      |\n" +
  "      |\n" +
  "=========",
  // 2 — tułów
  "  +---+\n" +
  "  |   |\n" +
  "  O   |\n" +
  "  |   |\n" +
  "      |\n" +
  "      |\n" +
  "=========",
  // 3 — lewa ręka
  "  +---+\n" +
  "  |   |\n" +
  "  O   |\n" +
  " /|   |\n" +
  "      |\n" +
  "      |\n" +
  "=========",
  // 4 — prawa ręka
  "  +---+\n" +
  "  |   |\n" +
  "  O   |\n" +
  " /|\\  |\n" +
  "      |\n" +
  "      |\n" +
  "=========",
  // 5 — lewa noga
  "  +---+\n" +
  "  |   |\n" +
  "  O   |\n" +
  " /|\\  |\n" +
  " /    |\n" +
  "      |\n" +
  "=========",
  // 6 — prawa noga (game over)
  "  +---+\n" +
  "  |   |\n" +
  "  O   |\n" +
  " /|\\  |\n" +
  " / \\  |\n" +
  "      |\n" +
  "=========",
];

function startHangmanGame(container, items) {
  const MAX_WRONGS = 6;
  const candidates = items.filter(i =>
    i.targetText && i.targetText.length >= 3 && i.targetText.length <= 12
  );

  if (!candidates.length) {
    container.innerHTML = `
      <div class="empty-state">
        <div class="empty-icon">📭</div>
        <p>Brak słów odpowiednich do wisielca w tym zakresie.</p>
      </div>`;
    return;
  }

  // Klawiatura = wszystkie unikalne litery z puli słów (posortowane).
  // Tym sposobem dla HR dostaniemy č/š/ž, dla ES — ñ, dla EL — alfabet grecki itd.
  const keyboardLetters = (() => {
    const set = new Set();
    candidates.forEach(it => {
      it.targetText.toLowerCase().split('').forEach(c => {
        if (c !== ' ' && c !== '-' && c !== "'") set.add(c);
      });
    });
    return Array.from(set).sort();
  })();

  const item = shuffle(candidates)[0];
  const target = item.targetText;
  const targetLower = target.toLowerCase();

  const state = {
    used: new Set(),       // litery klikane
    wrongs: 0,
    finished: false,       // win albo lose
    won: false,
  };

  function maskedWord() {
    return target.split('').map(c => {
      if (c === ' ') return '  '; // dwa nbsp dla widocznej spacji
      if (c === '-' || c === "'") return c;
      return state.used.has(c.toLowerCase()) ? c : '_';
    }).join(' ');
  }

  function isWordRevealed() {
    return target.split('').every(c => {
      if (c === ' ' || c === '-' || c === "'") return true;
      return state.used.has(c.toLowerCase());
    });
  }

  function render() {
    const livesHtml = '●'.repeat(MAX_WRONGS - state.wrongs) + '○'.repeat(state.wrongs);
    const word = maskedWord();
    const keyboardHtml = keyboardLetters.map(l => {
      let cls = 'hng-key';
      if (state.used.has(l)) {
        cls += targetLower.includes(l) ? ' hit' : ' miss';
      }
      const dis = state.used.has(l) || state.finished ? 'disabled' : '';
      return `<button class="${cls}" data-letter="${l}" ${dis}>${l}</button>`;
    }).join('');

    let footer = '';
    if (state.finished) {
      footer = state.won
        ? `<div class="match-done">🎉 Słowo odgadnięte!</div>`
        : `<div class="hng-lose">Koniec gry. Słowo: <strong>${target}</strong></div>`;
    }

    const drawing = HANGMAN_STATES[Math.min(state.wrongs, HANGMAN_STATES.length - 1)];

    container.innerHTML = `
      <div class="match-header">
        <div class="match-progress">Błędy: <strong>${state.wrongs}</strong> / ${MAX_WRONGS} · Życia: <span class="hng-lives">${livesHtml}</span></div>
        <button class="btn" id="hng-new">↻ Nowe słowo</button>
      </div>
      <div class="hng-card">
        <pre class="hng-drawing">${drawing}</pre>
        <div class="scr-source-label">Polski</div>
        <div class="scr-source">${item.sourceText}</div>
        <div class="hng-word">${word}</div>
        <div class="hng-keyboard">${keyboardHtml}</div>
        ${footer}
      </div>
    `;
    container.querySelectorAll('.hng-key').forEach(b => {
      b.addEventListener('click', () => onLetter(b.dataset.letter));
    });
    container.querySelector('#hng-new').addEventListener('click', () => runCurrentGame());
  }

  function onLetter(letter) {
    if (state.finished) return;
    if (state.used.has(letter)) return;
    state.used.add(letter);
    if (targetLower.includes(letter)) {
      if (isWordRevealed()) {
        state.finished = true;
        state.won = true;
        playUiSound('complete');
        toast('Słowo odgadnięte!', 2500);
      }
    } else {
      state.wrongs++;
      if (state.wrongs >= MAX_WRONGS) {
        state.finished = true;
        state.won = false;
        playUiSound('wrong');
        toast('Niestety — słowo: ' + target, 3000);
      } else {
        playUiSound('wrong');
      }
    }
    render();
  }

  render();
}
