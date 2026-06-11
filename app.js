/* ポケットモンスター ファイアレッド風ミニRPG (データ: PokeAPI) */

const API_BASE = "https://pokeapi.co/api/v2";
const SAVE_KEY = "firered-mini-save";

const TYPE_JA = {
  normal: "ノーマル", fire: "ほのお", water: "みず", grass: "くさ",
  electric: "でんき", ice: "こおり", fighting: "かくとう", poison: "どく",
  ground: "じめん", flying: "ひこう", psychic: "エスパー", bug: "むし",
  rock: "いわ", ghost: "ゴースト", dragon: "ドラゴン", dark: "あく",
  steel: "はがね", fairy: "フェアリー",
};

// 第3世代タイプ相性表（等倍以外のみ記載）
const TYPE_CHART = {
  normal: { rock: 0.5, ghost: 0, steel: 0.5 },
  fire: { fire: 0.5, water: 0.5, grass: 2, ice: 2, bug: 2, rock: 0.5, dragon: 0.5, steel: 2 },
  water: { fire: 2, water: 0.5, grass: 0.5, ground: 2, rock: 2, dragon: 0.5 },
  electric: { water: 2, electric: 0.5, grass: 0.5, ground: 0, flying: 2, dragon: 0.5 },
  grass: { fire: 0.5, water: 2, grass: 0.5, poison: 0.5, ground: 2, flying: 0.5, bug: 0.5, rock: 2, dragon: 0.5, steel: 0.5 },
  ice: { fire: 0.5, water: 0.5, grass: 2, ice: 0.5, ground: 2, flying: 2, dragon: 2, steel: 0.5 },
  fighting: { normal: 2, ice: 2, poison: 0.5, flying: 0.5, psychic: 0.5, bug: 0.5, rock: 2, ghost: 0, dark: 2, steel: 2 },
  poison: { grass: 2, poison: 0.5, ground: 0.5, rock: 0.5, ghost: 0.5, steel: 0 },
  ground: { fire: 2, electric: 2, grass: 0.5, poison: 2, flying: 0, bug: 0.5, rock: 2, steel: 2 },
  flying: { electric: 0.5, grass: 2, fighting: 2, bug: 2, rock: 0.5, steel: 0.5 },
  psychic: { fighting: 2, poison: 2, psychic: 0.5, dark: 0, steel: 0.5 },
  bug: { fire: 0.5, grass: 2, fighting: 0.5, poison: 0.5, flying: 0.5, psychic: 2, ghost: 0.5, dark: 2, steel: 0.5 },
  rock: { fire: 2, ice: 2, fighting: 0.5, ground: 0.5, flying: 2, bug: 2, steel: 0.5 },
  ghost: { normal: 0, psychic: 2, ghost: 2, dark: 0.5, steel: 0.5 },
  dragon: { dragon: 2, steel: 0.5 },
  dark: { fighting: 0.5, psychic: 2, ghost: 2, dark: 0.5, steel: 0.5 },
  steel: { fire: 0.5, water: 0.5, electric: 0.5, ice: 2, rock: 2, steel: 0.5 },
};

function effectiveness(moveType, defTypes) {
  return defTypes.reduce((m, t) => m * (TYPE_CHART[moveType]?.[t] ?? 1), 1);
}

// ---------- マップ ----------
// T=木(進入不可) .=道 g=草むら G=深い草むら W=水(進入不可) C=ポケモンセンター F=花
const MAP_W = 20;
const MAP_H = 15;
const BLOCKED = new Set(["T", "W"]);

const TILE_CLASS = {
  T: "tree", ".": "path", g: "grass", G: "tall",
  W: "water", C: "center", F: "flower",
};

const LOW_TABLE = [
  { id: 16, min: 2, max: 4 }, // ポッポ
  { id: 19, min: 2, max: 4 }, // コラッタ
  { id: 10, min: 3, max: 5 }, // キャタピー
  { id: 13, min: 3, max: 5 }, // ビードル
  { id: 21, min: 3, max: 5 }, // オニスズメ
];

const HIGH_TABLE = [
  { id: 25, min: 6, max: 10 }, // ピカチュウ
  { id: 43, min: 6, max: 10 }, // ナゾノクサ
  { id: 56, min: 6, max: 10 }, // マンキー
  { id: 29, min: 6, max: 10 }, // ニドラン♀
  { id: 32, min: 6, max: 10 }, // ニドラン♂
  { id: 23, min: 6, max: 10 }, // アーボ
];

const MAPS = {
  townA: {
    name: "ハジメタウン",
    town: true,
    spawn: { x: 9, y: 12 },
    flySpot: { x: 8, y: 5 },
    exits: { up: "route1" },
    encounters: {},
    src: [
      "TTTTTTTT..TTTTTTTTTT",
      "T..................T",
      "T..F...........F...T",
      "T......TTT.........T",
      "T......TCT.....TT..T",
      "T......T.T.....TT..T",
      "T..................T",
      "T....F.......F.....T",
      "T..................T",
      "T...TT.......TT....T",
      "T...TT..F....TT....T",
      "T..................T",
      "T..................T",
      "T..................T",
      "TTTTTTTTTTTTTTTTTTTT",
    ],
  },
  route1: {
    name: "1ばんどうろ",
    exits: { down: "townA", up: "townB" },
    encounters: { g: { rate: 0.18, table: LOW_TABLE } },
    src: [
      "TTTTTTTT..TTTTTTTTTT",
      "T......gg..........T",
      "T..ggggggg...F.....T",
      "T..ggggggg.........T",
      "T..................T",
      "T.....TT...ggggg...T",
      "T.....TT...ggggg...T",
      "T..........ggggg...T",
      "T..F...............T",
      "T........TT........T",
      "T.gggg...TT....F...T",
      "T.gggg.............T",
      "T.gggg.............T",
      "T..................T",
      "TTTTTTTT..TTTTTTTTTT",
    ],
  },
  townB: {
    name: "ミドリシティ",
    town: true,
    flySpot: { x: 9, y: 4 },
    exits: { down: "route1", right: "route2" },
    encounters: {},
    src: [
      "TTTTTTTTTTTTTTTTTTTT",
      "T..................T",
      "T..F....TTT....F...T",
      "T.......TCT........T",
      "T.......T.T........T",
      "T..................T",
      "T....TT......TT....T",
      "T....TT......TT.....",
      "T...................",
      "T..F..........F....T",
      "T..................T",
      "T....WWW...........T",
      "T....WWW...........T",
      "T..................T",
      "TTTTTTTT..TTTTTTTTTT",
    ],
  },
  route2: {
    name: "2ばんどうろ",
    exits: { left: "townB" },
    encounters: { G: { rate: 0.22, table: HIGH_TABLE } },
    src: [
      "TTTTTTTTTTTTTTTTTTTT",
      "T....GGGG......WWWWT",
      "T....GGGG......WWWWT",
      "T....GGGG.......WWWT",
      "T..................T",
      "T..TTT....GGGGG....T",
      "T..TTT....GGGGG....T",
      "...TTT....GGGGG....T",
      "..................FT",
      "T...GGGG...........T",
      "T...GGGG....TT.....T",
      "T...GGGG....TT..F..T",
      "T..................T",
      "T..................T",
      "TTTTTTTTTTTTTTTTTTTT",
    ],
  },
};

const START_MAP = "townA";

function currentMapData() {
  return MAPS[state.map];
}

const STARTERS = [1, 4, 7]; // フシギダネ・ヒトカゲ・ゼニガメ

// ---------- DOM ----------
const $ = (id) => document.getElementById(id);
const screens = {
  title: $("screen-title"),
  starter: $("screen-starter"),
  world: $("screen-world"),
  battle: $("screen-battle"),
};

// ---------- ゲーム状態 ----------
const state = {
  map: START_MAP,
  pos: { x: 9, y: 12 },
  visited: [START_MAP],
  lastHeal: { map: START_MAP, pos: { x: 8, y: 4 } },
  party: [],
  box: [],
  items: { ball: 10, potion: 5 },
  busy: false,
};

// ---------- ユーティリティ ----------
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const rand = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;

async function fetchJson(url) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`HTTP ${res.status}: ${url}`);
  return res.json();
}

function getJaName(names, fallback) {
  const ja =
    names.find((n) => n.language.name === "ja-Hrkt") ||
    names.find((n) => n.language.name === "ja");
  return ja ? ja.name : fallback;
}

function showLoading(on) {
  $("loading").hidden = !on;
}

function showScreen(name) {
  Object.entries(screens).forEach(([k, el]) => (el.hidden = k !== name));
}

// ---------- メッセージシステム ----------
let typing = false;
let skipType = false;
let advanceResolve = null;

function pressA() {
  if (typing) {
    skipType = true;
    return;
  }
  if (advanceResolve) {
    const r = advanceResolve;
    advanceResolve = null;
    $("msg-indicator").hidden = true;
    r();
  }
}

async function say(text) {
  const box = $("msgbox");
  const textEl = $("msg-text");
  box.hidden = false;
  $("msg-indicator").hidden = true;
  textEl.textContent = "";
  typing = true;
  skipType = false;
  for (const ch of text) {
    if (skipType) {
      textEl.textContent = text;
      break;
    }
    textEl.textContent += ch;
    await sleep(20);
  }
  typing = false;
  $("msg-indicator").hidden = false;
  await new Promise((r) => (advanceResolve = r));
}

function closeMsg() {
  $("msgbox").hidden = true;
}

// 入力待ちなしでテキストを表示し続ける（行動選択時のプロンプト用）
function promptText(text) {
  $("msgbox").hidden = false;
  $("msg-indicator").hidden = true;
  $("msg-text").textContent = text;
}

$("msgbox").addEventListener("click", pressA);
$("btn-a").addEventListener("click", pressA);

// ---------- PokeAPI キャッシュ ----------
const bundleCache = new Map(); // id => {pokemon, species}
const moveCache = new Map(); // url/id => move data

async function getBundle(id) {
  if (bundleCache.has(id)) return bundleCache.get(id);
  const [pokemon, species] = await Promise.all([
    fetchJson(`${API_BASE}/pokemon/${id}`),
    fetchJson(`${API_BASE}/pokemon-species/${id}`),
  ]);
  const bundle = { pokemon, species };
  bundleCache.set(id, bundle);
  return bundle;
}

async function getMove(urlOrId) {
  const key = String(urlOrId);
  if (moveCache.has(key)) return moveCache.get(key);
  const url = key.startsWith("http") ? key : `${API_BASE}/move/${key}`;
  const data = await fetchJson(url);
  const move = {
    id: data.id,
    nameJa: getJaName(data.names, data.name),
    power: data.power || 0,
    type: data.type.name,
    damageClass: data.damage_class.name,
    accuracy: data.accuracy, // null = 必中扱い
    maxPp: data.pp || 10,
  };
  moveCache.set(key, move);
  moveCache.set(String(data.id), move);
  return move;
}

function getFrSprites(pokemon) {
  const gen3 = pokemon.sprites.versions?.["generation-iii"]?.["firered-leafgreen"];
  return {
    front: gen3?.front_default || pokemon.sprites.front_default,
    back: gen3?.back_default || pokemon.sprites.back_default || pokemon.sprites.front_default,
  };
}

// FRLGのレベルアップ技リスト
function getLearnset(pokemon) {
  const list = [];
  for (const m of pokemon.moves) {
    for (const v of m.version_group_details) {
      if (
        v.version_group.name === "firered-leafgreen" &&
        v.move_learn_method.name === "level-up"
      ) {
        list.push({ id: null, url: m.move.url, level: v.level_learned_at });
      }
    }
  }
  list.sort((a, b) => a.level - b.level);
  return list;
}

// ---------- ステータス計算 ----------
function calcMaxHp(base, level) {
  return Math.floor((2 * base * level) / 100) + level + 10;
}

function calcStat(base, level) {
  return Math.floor((2 * base * level) / 100) + 5;
}

function expForLevel(level) {
  return level * level * level;
}

function buildStats(baseStats, level) {
  return {
    maxHp: calcMaxHp(baseStats.hp, level),
    atk: calcStat(baseStats.attack, level),
    def: calcStat(baseStats.defense, level),
    spa: calcStat(baseStats["special-attack"], level),
    spd: calcStat(baseStats["special-defense"], level),
    spe: calcStat(baseStats.speed, level),
  };
}

// ---------- ポケモン個体の生成 ----------
async function createInstance(id, level) {
  const { pokemon, species } = await getBundle(id);

  const baseStats = {};
  pokemon.stats.forEach((s) => (baseStats[s.stat.name] = s.base_stat));

  const learnset = getLearnset(pokemon);

  // 現レベル以下で覚える技のうち、威力のある技を新しい順に最大4つ
  const candidates = learnset.filter((m) => m.level <= level).reverse();
  const moves = [];
  for (const c of candidates) {
    if (moves.length >= 4) break;
    try {
      const mv = await getMove(c.url);
      if (mv.power > 0 && !moves.some((m) => m.id === mv.id)) {
        moves.push({ ...mv, pp: mv.maxPp });
      }
    } catch (e) {
      console.error(e);
    }
  }
  if (moves.length === 0) {
    const tackle = await getMove(33); // たいあたり
    moves.push({ ...tackle, pp: tackle.maxPp });
  }

  const stats = buildStats(baseStats, level);
  return {
    speciesId: id,
    nameJa: getJaName(species.names, pokemon.name),
    types: pokemon.types.map((t) => t.type.name),
    level,
    exp: expForLevel(level),
    hp: stats.maxHp,
    stats,
    baseStats,
    moves,
    learnset,
    sprites: getFrSprites(pokemon),
    baseExp: pokemon.base_experience || 60,
    captureRate: species.capture_rate,
  };
}

// ---------- セーブ ----------
function save() {
  const data = {
    map: state.map,
    pos: state.pos,
    visited: state.visited,
    lastHeal: state.lastHeal,
    party: state.party,
    box: state.box,
    items: state.items,
  };
  try {
    localStorage.setItem(SAVE_KEY, JSON.stringify(data));
  } catch (e) {
    console.error(e);
  }
}

function loadSave() {
  try {
    const raw = localStorage.getItem(SAVE_KEY);
    return raw ? JSON.parse(raw) : null;
  } catch (e) {
    return null;
  }
}

window.addEventListener("beforeunload", () => {
  if (state.party.length > 0) save();
});

// ---------- タイトル ----------
function initTitle() {
  showScreen("title");
  if (loadSave()) $("btn-continue").hidden = false;
}

$("btn-new").addEventListener("click", () => {
  localStorage.removeItem(SAVE_KEY);
  startIntro();
});

$("btn-continue").addEventListener("click", () => {
  const data = loadSave();
  if (!data) return;
  state.party = data.party;
  state.box = data.box || [];
  state.items = data.items;
  if (data.map && MAPS[data.map]) {
    // 新形式セーブ
    state.map = data.map;
    state.pos = data.pos;
    state.visited = data.visited || [START_MAP];
    state.lastHeal = data.lastHeal || { map: START_MAP, pos: { x: 8, y: 4 } };
  } else {
    // 旧形式セーブ(単一マップ時代)はスタート地点から再開
    state.map = START_MAP;
    state.pos = { ...MAPS[START_MAP].spawn };
    state.visited = [START_MAP];
    state.lastHeal = { map: START_MAP, pos: { x: 8, y: 4 } };
  }
  enterWorld();
});

// ---------- オーキドのイントロ & 御三家 ----------
async function startIntro() {
  showScreen("starter");
  $("starter-cards").innerHTML = "";
  state.busy = true;
  await say("オーキド『やあ！ ポケモンの せかいへ ようこそ！");
  await say("オーキド『きみの あいぼうになる ポケモンを えらんでくれ！");
  closeMsg();
  state.busy = false;

  showLoading(true);
  const bundles = await Promise.all(STARTERS.map((id) => getBundle(id)));
  showLoading(false);

  const wrap = $("starter-cards");
  bundles.forEach(({ pokemon, species }) => {
    const card = document.createElement("button");
    card.className = "starter-card";
    const nameJa = getJaName(species.names, pokemon.name);
    const types = pokemon.types
      .map((t) => TYPE_JA[t.type.name] || t.type.name)
      .join("・");
    card.innerHTML = `
      <img src="${getFrSprites(pokemon).front}" alt="${nameJa}" />
      <div class="s-name">${nameJa}</div>
      <div class="s-type">${types}</div>
    `;
    card.addEventListener("click", () => chooseStarter(pokemon.id, nameJa));
    wrap.appendChild(card);
  });
}

let starterChosen = false;
async function chooseStarter(id, nameJa) {
  if (starterChosen) return;
  starterChosen = true;
  showLoading(true);
  const starter = await createInstance(id, 5);
  showLoading(false);
  state.party = [starter];
  state.items = { ball: 10, potion: 5 };
  state.map = START_MAP;
  state.pos = { ...MAPS[START_MAP].spawn };
  state.visited = [START_MAP];
  state.lastHeal = { map: START_MAP, pos: { x: 8, y: 4 } };
  await say(`${nameJa}を てにいれた！`);
  await say("オーキド『モンスターボールと キズぐすりも もたせておこう。");
  await say("オーキド『くさむらで ポケモンを つかまえて りっぱな トレーナーに なるんじゃぞ！");
  closeMsg();
  save();
  starterChosen = false;
  enterWorld();
}

// ---------- フィールド ----------
function buildMap() {
  const src = currentMapData().src;
  const map = $("map");
  map.innerHTML = "";
  for (let y = 0; y < MAP_H; y++) {
    for (let x = 0; x < MAP_W; x++) {
      const t = document.createElement("div");
      t.className = `tile ${TILE_CLASS[src[y][x]] || "path"}`;
      map.appendChild(t);
    }
  }
}

function renderPlayer() {
  const p = $("player");
  p.style.left = `calc(${state.pos.x} * var(--tile))`;
  p.style.top = `calc(${state.pos.y} * var(--tile))`;
}

function enterWorld() {
  if (!state.visited.includes(state.map)) state.visited.push(state.map);
  buildMap();
  renderPlayer();
  $("area-name").textContent = currentMapData().name;
  showScreen("world");
}

const DIRS = {
  up: [0, -1],
  down: [0, 1],
  left: [-1, 0],
  right: [1, 0],
};

function tryMove(dir) {
  if (state.busy || !advanceIsIdle()) return;
  if (screens.world.hidden) return;
  const m = currentMapData();
  const [dx, dy] = DIRS[dir];
  const nx = state.pos.x + dx;
  const ny = state.pos.y + dy;

  // マップ端から隣のエリアへ移動
  if (nx < 0 || ny < 0 || nx >= MAP_W || ny >= MAP_H) {
    const dest = m.exits?.[dir];
    if (!dest) return;
    const wx = (nx + MAP_W) % MAP_W;
    const wy = (ny + MAP_H) % MAP_H;
    const destTile = MAPS[dest].src[wy][wx];
    if (BLOCKED.has(destTile)) return;
    state.map = dest;
    state.pos = { x: wx, y: wy };
    enterWorld();
    save();
    onStep(destTile);
    return;
  }

  const tile = m.src[ny][nx];
  if (BLOCKED.has(tile)) return;
  state.pos = { x: nx, y: ny };
  renderPlayer();
  onStep(tile);
}

function advanceIsIdle() {
  return !typing && advanceResolve === null;
}

async function onStep(tile) {
  if (tile === "C") {
    state.busy = true;
    state.party.forEach((p) => {
      p.hp = p.stats.maxHp;
      p.moves.forEach((m) => (m.pp = m.maxPp));
    });
    state.items.ball = Math.max(state.items.ball, 10);
    state.items.potion = Math.max(state.items.potion, 5);
    state.lastHeal = { map: state.map, pos: { ...state.pos } };
    await say("ポケモンセンターへ ようこそ！");
    await say("ポケモンたちは すっかり げんきになりました！\nどうぐも ほきゅうして おきますね。");
    closeMsg();
    save();
    state.busy = false;
    return;
  }

  const zone = currentMapData().encounters?.[tile];
  if (zone && Math.random() < zone.rate) {
    state.busy = true;
    const pick = zone.table[rand(0, zone.table.length - 1)];
    showLoading(true);
    let wild;
    try {
      wild = await createInstance(pick.id, rand(pick.min, pick.max));
    } catch (e) {
      console.error(e);
      showLoading(false);
      state.busy = false;
      return;
    }
    showLoading(false);
    await battle(wild);
    state.busy = false;
  }
}

document.addEventListener("keydown", (e) => {
  if (["Enter", " ", "z", "Z"].includes(e.key)) {
    if (!$("msgbox").hidden) {
      e.preventDefault();
      pressA();
    }
    return;
  }
  const keyDir = {
    ArrowUp: "up", ArrowDown: "down", ArrowLeft: "left", ArrowRight: "right",
    w: "up", s: "down", a: "left", d: "right",
  }[e.key];
  if (keyDir) {
    e.preventDefault();
    tryMove(keyDir);
  }
});

document.querySelectorAll(".dpad-btn").forEach((btn) => {
  btn.addEventListener("click", () => tryMove(btn.dataset.dir));
});

// ---------- パーティ画面 ----------
function hpBarClass(ratio) {
  return ratio > 0.5 ? "" : ratio > 0.2 ? "mid" : "low";
}

function openParty(mode = "view") {
  // mode: 'view' | 'switch'(バトル中の交代) — 戻り値: 選択index or null
  return new Promise((resolve) => {
    const overlay = $("overlay-party");
    const list = $("party-list");

    function render() {
      list.innerHTML = "";
      state.party.forEach((p, i) => {
        const row = document.createElement("button");
        row.className = "party-row" + (p.hp <= 0 ? " fainted" : "");
        const ratio = p.hp / p.stats.maxHp;
        row.innerHTML = `
          <img src="${p.sprites.front}" alt="${p.nameJa}" />
          <div>
            <div class="p-name">${p.nameJa} Lv.${p.level}</div>
            <div class="p-moves">${p.moves.map((m) => m.nameJa).join("／")}</div>
          </div>
          <div class="p-hp">
            <div class="hp-bar"><span class="${hpBarClass(ratio)}" style="width:${Math.max(0, ratio * 100)}%"></span></div>
            ${p.hp} / ${p.stats.maxHp}
          </div>
        `;
        row.addEventListener("click", async () => {
          if (mode === "switch") {
            if (p.hp <= 0 || i === 0) return;
            close(i);
            return;
          }
          const acted = await partyContextMenu(p, i, close);
          if (acted === "rerender") render();
        });
        list.appendChild(row);
      });
    }

    function close(result) {
      overlay.hidden = true;
      $("btn-party-close").onclick = null;
      resolve(result);
    }

    render();
    $("btn-party-close").onclick = () => close(null);
    overlay.hidden = false;
  });
}

// ポケモンを選んだときのメニュー（つよさをみる・そらをとぶ・ならびかえ）
async function partyContextMenu(mon, index, closeParty) {
  const flyTowns = state.visited.filter(
    (id) => MAPS[id].town && id !== state.map
  );
  const canFly =
    mon.hp > 0 && mon.types.includes("flying") && flyTowns.length > 0;

  const action = await chooseFromMenu($("context-menu"), [
    { label: "つよさをみる", value: "stats" },
    { label: "そらをとぶ", value: "fly", disabled: !canFly },
    { label: "せんとうへ", value: "front", disabled: index === 0 },
    { label: "やめる", value: null },
  ]);

  if (action === "stats") {
    await showStats(mon);
    return null;
  }
  if (action === "front") {
    const [m] = state.party.splice(index, 1);
    state.party.unshift(m);
    save();
    return "rerender";
  }
  if (action === "fly") {
    const dest = await chooseFromMenu(
      $("context-menu"),
      flyTowns
        .map((id) => ({ label: MAPS[id].name, value: id }))
        .concat([{ label: "やめる", value: null }])
    );
    if (!dest) return null;
    closeParty(null);
    state.busy = true;
    await say(`${mon.nameJa}は そらを とんだ！`);
    closeMsg();
    state.map = dest;
    state.pos = { ...MAPS[dest].flySpot };
    enterWorld();
    save();
    state.busy = false;
    return null;
  }
  return null;
}

// つよさをみる画面
function showStats(mon) {
  return new Promise((resolve) => {
    const next = mon.level < 100 ? expForLevel(mon.level + 1) - mon.exp : 0;
    $("stats-content").innerHTML = `
      <div class="stats-head">
        <img src="${mon.sprites.front}" alt="${mon.nameJa}" />
        <div>
          <div class="p-name">${mon.nameJa} Lv.${mon.level}</div>
          <div class="stats-types">${mon.types
            .map((t) => TYPE_JA[t] || t)
            .join("・")}</div>
          <div class="stats-hp">HP ${mon.hp} / ${mon.stats.maxHp}</div>
        </div>
      </div>
      <table class="stats-table">
        <tr><td>こうげき</td><td>${mon.stats.atk}</td><td>とくこう</td><td>${mon.stats.spa}</td></tr>
        <tr><td>ぼうぎょ</td><td>${mon.stats.def}</td><td>とくぼう</td><td>${mon.stats.spd}</td></tr>
        <tr><td>すばやさ</td><td>${mon.stats.spe}</td><td>つぎのLvまで</td><td>${next}</td></tr>
      </table>
      <div class="stats-moves">
        ${mon.moves
          .map(
            (m) =>
              `<div class="stats-move"><span>${m.nameJa}</span><span>${
                TYPE_JA[m.type] || m.type
              }｜いりょく${m.power}｜PP ${m.pp}/${m.maxPp}</span></div>`
          )
          .join("")}
      </div>
    `;
    const ov = $("overlay-stats");
    ov.hidden = false;
    $("btn-stats-close").onclick = () => {
      ov.hidden = true;
      $("btn-stats-close").onclick = null;
      resolve();
    };
  });
}

$("btn-party").addEventListener("click", () => {
  if (state.busy) return;
  openParty("view");
});

// ---------- バトル ----------
const battleUI = {
  enemySprite: $("enemy-sprite"),
  allySprite: $("ally-sprite"),
  enemyName: $("enemy-name"),
  enemyLevel: $("enemy-level"),
  enemyHpFill: $("enemy-hp-fill"),
  allyName: $("ally-name"),
  allyLevel: $("ally-level"),
  allyHpFill: $("ally-hp-fill"),
  allyHpText: $("ally-hp-text"),
};

function updateBattleUI(ally, enemy) {
  battleUI.enemyName.textContent = enemy.nameJa;
  battleUI.enemyLevel.textContent = `Lv.${enemy.level}`;
  const er = Math.max(0, enemy.hp / enemy.stats.maxHp);
  battleUI.enemyHpFill.style.width = `${er * 100}%`;
  battleUI.enemyHpFill.className = hpBarClass(er);

  battleUI.allyName.textContent = ally.nameJa;
  battleUI.allyLevel.textContent = `Lv.${ally.level}`;
  const ar = Math.max(0, ally.hp / ally.stats.maxHp);
  battleUI.allyHpFill.style.width = `${ar * 100}%`;
  battleUI.allyHpFill.className = hpBarClass(ar);
  battleUI.allyHpText.textContent = `${Math.max(0, ally.hp)} / ${ally.stats.maxHp}`;
}

function setBattleSprites(ally, enemy) {
  battleUI.enemySprite.src = enemy.sprites.front;
  battleUI.allySprite.src = ally.sprites.back;
}

function hideBattleMenus() {
  $("action-menu").hidden = true;
  $("move-menu").hidden = true;
  $("bag-menu").hidden = true;
}

function chooseFromMenu(menuEl, buttons) {
  // buttons: [{label, sub, value, disabled}]
  return new Promise((resolve) => {
    menuEl.innerHTML = "";
    buttons.forEach((b) => {
      const btn = document.createElement("button");
      btn.className = "gba-btn";
      btn.disabled = !!b.disabled;
      btn.innerHTML = b.label + (b.sub ? `<span class="pp">${b.sub}</span>` : "");
      btn.addEventListener("click", () => {
        menuEl.hidden = true;
        resolve(b.value);
      });
      menuEl.appendChild(btn);
    });
    menuEl.hidden = false;
  });
}

function chooseAction() {
  return new Promise((resolve) => {
    const menu = $("action-menu");
    menu.hidden = false;
    menu.querySelectorAll("button").forEach((btn) => {
      btn.onclick = () => {
        menu.hidden = true;
        resolve(btn.dataset.action);
      };
    });
  });
}

async function chooseMove(mon) {
  const usable = mon.moves.some((m) => m.pp > 0);
  const buttons = usable
    ? mon.moves.map((m) => ({
        label: m.nameJa,
        sub: `${TYPE_JA[m.type] || m.type} PP ${m.pp}/${m.maxPp}`,
        value: m,
        disabled: m.pp <= 0,
      }))
    : [{ label: "わるあがき", sub: "PPが なくなった！", value: "struggle" }];
  buttons.push({ label: "もどる", value: null });
  return chooseFromMenu($("move-menu"), buttons);
}

const STRUGGLE = {
  id: -1, nameJa: "わるあがき", power: 50, type: "normal",
  damageClass: "physical", accuracy: 100, maxPp: 1, pp: 1, struggle: true,
};

function calcDamage(att, def, move) {
  const isPhys = move.damageClass === "physical";
  const a = isPhys ? att.stats.atk : att.stats.spa;
  const d = isPhys ? def.stats.def : def.stats.spd;
  let dmg =
    Math.floor(Math.floor((Math.floor((2 * att.level) / 5 + 2) * move.power * a) / d) / 50) + 2;
  const stab = att.types.includes(move.type) ? 1.5 : 1;
  const eff = move.struggle ? 1 : effectiveness(move.type, def.types);
  const crit = Math.random() < 1 / 16 ? 2 : 1;
  dmg = Math.floor(dmg * stab * eff * crit * (0.85 + Math.random() * 0.15));
  if (eff > 0) dmg = Math.max(1, dmg);
  else dmg = 0;
  return { dmg, eff, crit: crit > 1 };
}

async function doMove(att, def, move, attLabel, defLabel, ally, enemy) {
  await say(`${attLabel}${att.nameJa}の ${move.nameJa}！`);
  if (!move.struggle) move.pp = Math.max(0, move.pp - 1);

  if (move.accuracy !== null && Math.random() * 100 > move.accuracy) {
    await say(`しかし ${def.nameJa}には あたらなかった！`);
    return;
  }

  const { dmg, eff, crit } = calcDamage(att, def, move);
  def.hp = Math.max(0, def.hp - dmg);
  updateBattleUI(ally, enemy);
  await sleep(400);

  if (crit && eff > 0) await say("きゅうしょに あたった！");
  if (eff === 0) await say(`${defLabel}${def.nameJa}には こうかが ないみたいだ…`);
  else if (eff > 1) await say("こうかは ばつぐんだ！");
  else if (eff < 1) await say("こうかは いまひとつのようだ…");
}

function enemyPickMove(enemy) {
  const usable = enemy.moves.filter((m) => m.pp > 0 && m.power > 0);
  if (usable.length === 0) return { ...STRUGGLE };
  return usable[rand(0, usable.length - 1)];
}

async function gainExp(mon, defeated) {
  const gain = Math.max(1, Math.floor((defeated.baseExp * defeated.level) / 7));
  mon.exp += gain;
  await say(`${mon.nameJa}は ${gain}の けいけんちを もらった！`);
  while (mon.level < 100 && mon.exp >= expForLevel(mon.level + 1)) {
    mon.level++;
    const old = mon.stats;
    mon.stats = buildStats(mon.baseStats, mon.level);
    mon.hp = Math.min(mon.stats.maxHp, mon.hp + (mon.stats.maxHp - old.maxHp));
    await say(`${mon.nameJa}は レベル${mon.level}に あがった！`);
    await learnMovesAt(mon, mon.level);
  }
}

async function learnMovesAt(mon, level) {
  const due = mon.learnset.filter((m) => m.level === level);
  for (const entry of due) {
    try {
      const mv = await getMove(entry.url);
      if (mv.power <= 0) continue;
      if (mon.moves.some((m) => m.id === mv.id)) continue;
      const newMove = { ...mv, pp: mv.maxPp };
      if (mon.moves.length < 4) {
        mon.moves.push(newMove);
        await say(`${mon.nameJa}は あたらしく ${mv.nameJa}を おぼえた！`);
      } else {
        let weakest = 0;
        mon.moves.forEach((m, i) => {
          if (m.power < mon.moves[weakest].power) weakest = i;
        });
        if (mon.moves[weakest].power < mv.power) {
          const forgotten = mon.moves[weakest].nameJa;
          mon.moves[weakest] = newMove;
          await say(`${mon.nameJa}は ${forgotten}を わすれて ${mv.nameJa}を おぼえた！`);
        }
      }
    } catch (e) {
      console.error(e);
    }
  }
}

async function tryCatch(enemy) {
  state.items.ball--;
  await say("モンスターボールを なげた！");
  const a = Math.min(
    255,
    ((3 * enemy.stats.maxHp - 2 * enemy.hp) * enemy.captureRate * 1.5) /
      (3 * enemy.stats.maxHp)
  );
  const success = Math.random() * 255 < a;
  const shakes = success ? 3 : rand(0, 2);
  for (let i = 0; i < shakes; i++) {
    await sleep(450);
    $("msg-text").textContent += " ゆれた…";
  }
  await sleep(450);
  if (success) {
    await say(`やったー！ ${enemy.nameJa}を つかまえた！`);
    if (state.party.length < 6) {
      state.party.push(enemy);
      await say(`${enemy.nameJa}が なかまに くわわった！`);
    } else {
      state.box.push(enemy);
      await say(`てもちが いっぱいなので\n${enemy.nameJa}は ボックスに おくられた！`);
    }
    return true;
  }
  await say(`ああ！ ${enemy.nameJa}は ボールから でてきてしまった！`);
  return false;
}

async function battle(enemy) {
  showScreen("battle");
  hideBattleMenus();

  // 先頭の生きているポケモンを前に出す
  let activeIdx = state.party.findIndex((p) => p.hp > 0);
  if (activeIdx < 0) activeIdx = 0;
  if (activeIdx > 0) {
    const [mon] = state.party.splice(activeIdx, 1);
    state.party.unshift(mon);
  }
  let ally = state.party[0];

  setBattleSprites(ally, enemy);
  updateBattleUI(ally, enemy);

  await say(`あ！ やせいの ${enemy.nameJa}が とびだしてきた！`);
  await say(`いけっ！ ${ally.nameJa}！`);

  let result = null; // 'win' | 'caught' | 'run' | 'lose'

  while (result === null) {
    promptText(`${ally.nameJa}は どうする？`);
    let playerMove = null;
    let playerAct = null;

    // --- 行動選択 ---
    while (playerAct === null) {
      const action = await chooseAction();
      if (action === "fight") {
        const mv = await chooseMove(ally);
        if (mv === null) continue;
        playerMove = mv === "struggle" ? { ...STRUGGLE } : mv;
        playerAct = "move";
      } else if (action === "bag") {
        const item = await chooseFromMenu($("bag-menu"), [
          { label: `モンスターボール ×${state.items.ball}`, value: "ball", disabled: state.items.ball <= 0 },
          { label: `キズぐすり ×${state.items.potion}`, value: "potion", disabled: state.items.potion <= 0 },
          { label: "もどる", value: null },
        ]);
        if (item === null) continue;
        playerAct = item;
      } else if (action === "pokemon") {
        const idx = await openParty("switch");
        if (idx === null) continue;
        playerAct = "switch:" + idx;
      } else if (action === "run") {
        playerAct = "run";
      }
    }

    // --- プレイヤーの行動 ---
    let enemyGetsFreeTurn = true;

    if (playerAct === "run") {
      const escaped = ally.stats.spe >= enemy.stats.spe || Math.random() < 0.6;
      if (escaped) {
        await say("うまく にげきれた！");
        result = "run";
        break;
      }
      await say("にげられない！");
    } else if (playerAct === "ball") {
      const caught = await tryCatch(enemy);
      if (caught) {
        result = "caught";
        break;
      }
    } else if (playerAct === "potion") {
      state.items.potion--;
      ally.hp = Math.min(ally.stats.maxHp, ally.hp + 20);
      updateBattleUI(ally, enemy);
      await say(`${ally.nameJa}の HPが かいふくした！`);
    } else if (playerAct.startsWith("switch:")) {
      const idx = Number(playerAct.split(":")[1]);
      await say(`もどれ！ ${ally.nameJa}！`);
      const [mon] = state.party.splice(idx, 1);
      state.party.unshift(mon);
      ally = state.party[0];
      setBattleSprites(ally, enemy);
      updateBattleUI(ally, enemy);
      await say(`いけっ！ ${ally.nameJa}！`);
    } else if (playerAct === "move") {
      // すばやさで行動順を決定
      const playerFirst =
        ally.stats.spe > enemy.stats.spe ||
        (ally.stats.spe === enemy.stats.spe && Math.random() < 0.5);
      const enemyMove = enemyPickMove(enemy);

      const playerTurn = async () => {
        await doMove(ally, enemy, playerMove, "", "やせいの ", ally, enemy);
      };
      const enemyTurn = async () => {
        await doMove(enemy, ally, enemyMove, "やせいの ", "", ally, enemy);
      };

      const order = playerFirst ? [["p", playerTurn], ["e", enemyTurn]] : [["e", enemyTurn], ["p", playerTurn]];
      for (const [side, turn] of order) {
        if (enemy.hp <= 0 || ally.hp <= 0) break;
        await turn();
      }
      enemyGetsFreeTurn = false;
    }

    // --- 交代・道具使用などの場合は敵が攻撃 ---
    if (result === null && enemyGetsFreeTurn && enemy.hp > 0 && ally.hp > 0 && playerAct !== "run") {
      await doMove(enemy, ally, enemyPickMove(enemy), "やせいの ", "", ally, enemy);
    }
    if (result === null && playerAct === "run" && enemy.hp > 0 && ally.hp > 0) {
      await doMove(enemy, ally, enemyPickMove(enemy), "やせいの ", "", ally, enemy);
    }

    // --- 戦闘不能判定 ---
    if (result === null && enemy.hp <= 0) {
      await say(`やせいの ${enemy.nameJa}は たおれた！`);
      await gainExp(ally, enemy);
      result = "win";
      break;
    }

    if (result === null && ally.hp <= 0) {
      await say(`${ally.nameJa}は たおれた！`);
      const alive = state.party.filter((p) => p.hp > 0);
      if (alive.length === 0) {
        await say("めのまえが まっくらに なった！");
        state.party.forEach((p) => {
          p.hp = p.stats.maxHp;
          p.moves.forEach((m) => (m.pp = m.maxPp));
        });
        state.map = state.lastHeal.map;
        state.pos = { ...state.lastHeal.pos };
        result = "lose";
        break;
      }
      // 生存ポケモンへの交代を強制
      let idx = null;
      while (idx === null) {
        idx = await openParty("switch");
      }
      const [mon] = state.party.splice(idx, 1);
      state.party.unshift(mon);
      ally = state.party[0];
      setBattleSprites(ally, enemy);
      updateBattleUI(ally, enemy);
      await say(`いけっ！ ${ally.nameJa}！`);
    }
  }

  closeMsg();
  hideBattleMenus();
  save();
  enterWorld();
}

// ---------- 起動 ----------
initTitle();
