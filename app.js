const API_BASE = "https://pokeapi.co/api/v2";

// 世代ごとの全国図鑑番号範囲
const GEN_RANGES = {
  1: [1, 151],
  2: [152, 251],
  3: [252, 386],
  4: [387, 493],
  5: [494, 649],
  6: [650, 721],
  7: [722, 809],
  8: [810, 905],
  9: [906, 1025],
};

const TYPE_JA = {
  normal: "ノーマル",
  fire: "ほのお",
  water: "みず",
  grass: "くさ",
  electric: "でんき",
  ice: "こおり",
  fighting: "かくとう",
  poison: "どく",
  ground: "じめん",
  flying: "ひこう",
  psychic: "エスパー",
  bug: "むし",
  rock: "いわ",
  ghost: "ゴースト",
  dragon: "ドラゴン",
  dark: "あく",
  steel: "はがね",
  fairy: "フェアリー",
};

const STAT_JA = {
  hp: "HP",
  attack: "こうげき",
  defense: "ぼうぎょ",
  "special-attack": "とくこう",
  "special-defense": "とくぼう",
  speed: "すばやさ",
};

const grid = document.getElementById("pokemon-grid");
const statusEl = document.getElementById("status");
const searchInput = document.getElementById("search-input");
const genSelect = document.getElementById("gen-select");
const modal = document.getElementById("modal");
const modalContent = document.getElementById("modal-content");

// id => { id, name, nameJa, types, sprite }
const pokemonCache = new Map();
const speciesCache = new Map();
const detailCache = new Map();
const abilityNameCache = new Map();

let currentList = [];
let loadToken = 0; // 世代切替時に古いロードを破棄するためのトークン

function showStatus(text) {
  statusEl.textContent = text;
  statusEl.hidden = !text;
}

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

async function loadSummary(id) {
  if (pokemonCache.has(id)) return pokemonCache.get(id);
  const [pokemon, species] = await Promise.all([
    fetchJson(`${API_BASE}/pokemon/${id}`),
    speciesCache.get(id) || fetchJson(`${API_BASE}/pokemon-species/${id}`),
  ]);
  speciesCache.set(id, species);
  const summary = {
    id,
    name: pokemon.name,
    nameJa: getJaName(species.names, pokemon.name),
    types: pokemon.types.map((t) => t.type.name),
    sprite:
      pokemon.sprites.front_default ||
      pokemon.sprites.other["official-artwork"].front_default,
    raw: pokemon,
  };
  pokemonCache.set(id, summary);
  return summary;
}

// 同時リクエスト数を制限しながら順次ロードして描画
async function loadGeneration(gen) {
  const token = ++loadToken;
  const [start, end] = GEN_RANGES[gen];
  const ids = [];
  for (let i = start; i <= end; i++) ids.push(i);

  currentList = [];
  grid.innerHTML = "";
  showStatus("読み込み中…");

  const CONCURRENCY = 20;
  let index = 0;
  let loaded = 0;

  async function worker() {
    while (index < ids.length) {
      const id = ids[index++];
      try {
        const summary = await loadSummary(id);
        if (token !== loadToken) return;
        currentList.push(summary);
        loaded++;
        if (loaded % CONCURRENCY === 0 || loaded === ids.length) {
          showStatus(`読み込み中… ${loaded} / ${ids.length}`);
          renderGrid();
        }
      } catch (e) {
        console.error(e);
        loaded++;
      }
    }
  }

  await Promise.all(Array.from({ length: CONCURRENCY }, worker));
  if (token !== loadToken) return;
  showStatus("");
  renderGrid();
}

function renderGrid() {
  const query = searchInput.value.trim().toLowerCase();
  const list = [...currentList].sort((a, b) => a.id - b.id);
  const filtered = query
    ? list.filter(
        (p) =>
          p.nameJa.toLowerCase().includes(query) ||
          p.name.includes(query) ||
          String(p.id) === query
      )
    : list;

  grid.innerHTML = "";
  if (filtered.length === 0 && !statusEl.textContent) {
    showStatus("見つかりませんでした");
    return;
  }
  if (filtered.length > 0 && statusEl.textContent === "見つかりませんでした") {
    showStatus("");
  }

  const fragment = document.createDocumentFragment();
  for (const p of filtered) {
    const card = document.createElement("button");
    card.className = "card";
    card.type = "button";
    card.innerHTML = `
      <p class="no">No.${String(p.id).padStart(4, "0")}</p>
      <img src="${p.sprite}" alt="${p.nameJa}" loading="lazy" />
      <p class="name">${p.nameJa}</p>
      <div class="types">
        ${p.types
          .map(
            (t) => `<span class="type-badge type-${t}">${TYPE_JA[t] || t}</span>`
          )
          .join("")}
      </div>
    `;
    card.addEventListener("click", () => openDetail(p.id));
    fragment.appendChild(card);
  }
  grid.appendChild(fragment);
}

// ---------- 詳細モーダル ----------
async function getAbilityNameJa(url) {
  if (abilityNameCache.has(url)) return abilityNameCache.get(url);
  const data = await fetchJson(url);
  const name = getJaName(data.names, data.name);
  abilityNameCache.set(url, name);
  return name;
}

async function loadDetail(id) {
  if (detailCache.has(id)) return detailCache.get(id);
  const summary = await loadSummary(id);
  const species = speciesCache.get(id);
  const pokemon = summary.raw;

  const flavorEntry =
    species.flavor_text_entries.find((e) => e.language.name === "ja") ||
    species.flavor_text_entries.find((e) => e.language.name === "ja-Hrkt") ||
    species.flavor_text_entries.find((e) => e.language.name === "en");
  const genusEntry =
    species.genera.find((g) => g.language.name === "ja") ||
    species.genera.find((g) => g.language.name === "ja-Hrkt");

  const abilities = await Promise.all(
    pokemon.abilities.map(async (a) => ({
      name: await getAbilityNameJa(a.ability.url),
      hidden: a.is_hidden,
    }))
  );

  const detail = {
    ...summary,
    artwork:
      pokemon.sprites.other["official-artwork"].front_default || summary.sprite,
    flavor: flavorEntry ? flavorEntry.flavor_text.replace(/\s+/g, "") : "",
    genus: genusEntry ? genusEntry.genus : "",
    height: pokemon.height / 10, // m
    weight: pokemon.weight / 10, // kg
    abilities,
    stats: pokemon.stats.map((s) => ({
      name: STAT_JA[s.stat.name] || s.stat.name,
      value: s.base_stat,
    })),
  };
  detailCache.set(id, detail);
  return detail;
}

async function openDetail(id) {
  modal.hidden = false;
  modalContent.innerHTML = `<div class="status">読み込み中…</div>`;
  try {
    const d = await loadDetail(id);
    modalContent.innerHTML = `
      <div class="detail-header">
        <img src="${d.artwork}" alt="${d.nameJa}" />
        <p class="no">No.${String(d.id).padStart(4, "0")}</p>
        <h2>${d.nameJa}</h2>
        <p class="genus">${d.genus}</p>
        <div class="types">
          ${d.types
            .map(
              (t) =>
                `<span class="type-badge type-${t}">${TYPE_JA[t] || t}</span>`
            )
            .join("")}
        </div>
      </div>
      ${d.flavor ? `<p class="flavor">${d.flavor}</p>` : ""}
      <div class="meta">
        <div>たかさ<strong>${d.height.toFixed(1)} m</strong></div>
        <div>おもさ<strong>${d.weight.toFixed(1)} kg</strong></div>
        <div>とくせい<strong>${d.abilities
          .map((a) => (a.hidden ? `${a.name}（隠）` : a.name))
          .join(" / ")}</strong></div>
      </div>
      <div class="stats">
        <h3>種族値</h3>
        ${d.stats
          .map(
            (s) => `
          <div class="stat-row">
            <span>${s.name}</span>
            <span class="val">${s.value}</span>
            <div class="stat-bar"><span style="width:${Math.min(
              (s.value / 200) * 100,
              100
            )}%"></span></div>
          </div>`
          )
          .join("")}
      </div>
    `;
  } catch (e) {
    console.error(e);
    modalContent.innerHTML = `<div class="status">読み込みに失敗しました</div>`;
  }
}

function closeModal() {
  modal.hidden = true;
  modalContent.innerHTML = "";
}

modal.addEventListener("click", (e) => {
  if (e.target.dataset.close !== undefined) closeModal();
});

document.addEventListener("keydown", (e) => {
  if (e.key === "Escape" && !modal.hidden) closeModal();
});

// ---------- イベント ----------
let searchTimer;
searchInput.addEventListener("input", () => {
  clearTimeout(searchTimer);
  searchTimer = setTimeout(renderGrid, 150);
});

genSelect.addEventListener("change", () => {
  searchInput.value = "";
  loadGeneration(Number(genSelect.value));
});

// 初期表示: 第1世代
loadGeneration(1);
