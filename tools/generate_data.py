#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Elementa Monsters - データジェネレータ

完全オリジナルのモンスター(150体以上)・技・タイプ相性表を生成し、
assets/data/ 配下に JSON として書き出す。

Nintendo / Game Freak / Creatures の著作物・商標は一切使用しない。
モンスター名・タイプ名・技名はすべて本作オリジナルの造語。
"""
import json
import os
import random

random.seed(20260614)  # 再現性のため固定シード

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "data")
os.makedirs(OUT, exist_ok=True)

# ---------------------------------------------------------------------------
# タイプ(オリジナル12属性) — 一般名詞のため著作権非該当
# ---------------------------------------------------------------------------
TYPES = [
    "ノーマル",  # normal
    "ほのお",    # flame
    "みず",      # aqua
    "くさ",      # leaf
    "でんき",    # volt
    "いわ",      # stone
    "かぜ",      # gale
    "どく",      # venom
    "こおり",    # frost
    "ひかり",    # light
    "やみ",      # shadow
    "はがね",    # steel
]

TYPE_COLOR = {
    "ノーマル": "#A8A878", "ほのお": "#F0803C", "みず": "#6890F0",
    "くさ": "#78C850", "でんき": "#F8D030", "いわ": "#B8A038",
    "かぜ": "#A0E0E0", "どく": "#A040A0", "こおり": "#98D8D8",
    "ひかり": "#F8F0A0", "やみ": "#705848", "はがね": "#B8B8D0",
}

# 相性表: attacker -> {defender: multiplier} (等倍は省略)
# オリジナルのバランス。じゃんけん基軸 + 補助関係。
TYPE_CHART = {
    "ノーマル": {"いわ": 0.5, "はがね": 0.5},
    "ほのお":   {"くさ": 2, "こおり": 2, "はがね": 2, "みず": 0.5, "いわ": 0.5, "ほのお": 0.5},
    "みず":     {"ほのお": 2, "いわ": 2, "くさ": 0.5, "みず": 0.5, "でんき": 0.5},
    "くさ":     {"みず": 2, "いわ": 2, "ほのお": 0.5, "くさ": 0.5, "どく": 0.5, "かぜ": 0.5, "はがね": 0.5},
    "でんき":   {"みず": 2, "かぜ": 2, "くさ": 0.5, "でんき": 0.5, "いわ": 0.5},
    "いわ":     {"ほのお": 2, "かぜ": 2, "こおり": 2, "くさ": 0.5, "はがね": 0.5},
    "かぜ":     {"くさ": 2, "どく": 2, "いわ": 0.5, "でんき": 0.5, "はがね": 0.5},
    "どく":     {"くさ": 2, "ひかり": 2, "どく": 0.5, "いわ": 0.5, "はがね": 0},
    "こおり":   {"くさ": 2, "かぜ": 2, "みず": 0.5, "こおり": 0.5, "はがね": 0.5, "ほのお": 0.5},
    "ひかり":   {"やみ": 2, "どく": 2, "ひかり": 0.5, "はがね": 0.5},
    "やみ":     {"ひかり": 2, "やみ": 0.5, "はがね": 0.5},
    "はがね":   {"いわ": 2, "こおり": 2, "ほのお": 0.5, "みず": 0.5, "でんき": 0.5, "はがね": 0.5},
}

# ---------------------------------------------------------------------------
# 技(オリジナル)
# ---------------------------------------------------------------------------
# 各タイプの代表技(弱・中・強) + ノーマル汎用 + 状態異常技
MOVES = []
_move_id = 0


def add_move(name, type_, power, accuracy, pp, category, effect=None, effect_chance=0, desc=""):
    global _move_id
    _move_id += 1
    MOVES.append({
        "id": _move_id,
        "name": name,
        "type": type_,
        "power": power,
        "accuracy": accuracy,
        "pp": pp,
        "category": category,          # physical / special / status
        "effect": effect,              # poison/paralyze/sleep/burn/freeze/heal/none
        "effectChance": effect_chance,
        "desc": desc,
    })


# ノーマル汎用
add_move("たいあたり", "ノーマル", 40, 100, 35, "physical", desc="からだ ごと ぶつかって こうげき する。")
add_move("ひっかき", "ノーマル", 45, 100, 30, "physical", desc="するどい ツメで ひっかいて こうげき する。")
add_move("れんだ", "ノーマル", 60, 95, 20, "physical", desc="すばやく なんども こうげき する。")
add_move("こうそくとっしん", "ノーマル", 90, 95, 10, "physical", desc="もうスピードで からだ ごと ぶつかる。")
add_move("ねむる", "ノーマル", 0, 100, 5, "status", effect="heal", effect_chance=100, desc="ねむって たいりょくを かいふく する。")
add_move("にらみつける", "ノーマル", 0, 100, 30, "status", effect="none", desc="あいてを にらんで ひるませようと する。")

# 各属性技を生成
_atk_names = {
    "ほのお": ["ひのこ", "かえんだん", "ごくえんは"],
    "みず":   ["みずでっぽう", "アクアジェット", "だくりゅうは"],
    "くさ":   ["はっぱカッター", "リーフスピア", "もりのいかり"],
    "でんき": ["でんげき", "サンダーボルト", "らいめいざん"],
    "いわ":   ["いわおとし", "ロックブラスト", "がんせきほう"],
    "かぜ":   ["かまいたち", "エアスラッシュ", "あらしのつばさ"],
    "どく":   ["どくばり", "ヘドロこうげき", "もうどくのきり"],
    "こおり": ["こなゆき", "こおりのつぶて", "ぜったいれいど風"],
    "ひかり": ["ひかりのや", "せんこうだん", "オーロラビーム光"],
    "やみ":   ["かげうち", "ナイトスラッシュ", "あんこくは"],
    "はがね": ["メタルクロー", "はがねのつばさ", "ラスターカノン風"],
}
_status_for_type = {
    "ほのお": "burn", "みず": None, "くさ": None, "でんき": "paralyze",
    "いわ": None, "かぜ": None, "どく": "poison", "こおり": "freeze",
    "ひかり": None, "やみ": None, "はがね": None,
}
for t in TYPES:
    if t == "ノーマル":
        continue
    names = _atk_names[t]
    cat = "special" if t in ("ほのお", "みず", "でんき", "こおり", "ひかり", "くさ") else "physical"
    add_move(names[0], t, 40, 100, 25, cat, effect=_status_for_type[t], effect_chance=10,
             desc=f"{t}の ちからで こうげき する。")
    add_move(names[1], t, 65, 100, 15, cat, effect=_status_for_type[t], effect_chance=20,
             desc=f"つよい {t}の ちからで こうげき する。")
    add_move(names[2], t, 95, 90, 5, cat, effect=_status_for_type[t], effect_chance=30,
             desc=f"さいだいきゅうの {t}の ちからを はなつ。")

# 状態異常 専用 補助技
add_move("どくのこな", "どく", 0, 90, 25, "status", effect="poison", effect_chance=100, desc="どくの こなで あいてを どく状態に する。")
add_move("しびれごな", "でんき", 0, 90, 25, "status", effect="paralyze", effect_chance=100, desc="しびれる こなで あいてを まひ状態に する。")
add_move("さいみんじゅつ", "やみ", 0, 70, 20, "status", effect="sleep", effect_chance=100, desc="あいてを ねむり状態に する。")
add_move("こおりのいき", "こおり", 0, 80, 20, "status", effect="freeze", effect_chance=100, desc="つめたい いきで こおり状態に する。")

MOVE_BY_NAME = {m["name"]: m["id"] for m in MOVES}
MOVES_BY_TYPE = {}
for m in MOVES:
    MOVES_BY_TYPE.setdefault(m["type"], []).append(m)


# ---------------------------------------------------------------------------
# モンスター名ジェネレータ(オリジナル造語)
# ---------------------------------------------------------------------------
_HEAD = ["リ", "ガ", "モ", "フ", "ヴ", "ピ", "ボ", "ザ", "テ", "ク", "ネ", "ド",
         "ベ", "ジ", "メ", "ラ", "ソ", "ヒ", "ヌ", "グ", "シャ", "チ", "ファ", "ウ"]
_MID = ["ル", "ガ", "モ", "ニ", "ポ", "リ", "バ", "ズ", "デ", "コ", "ミ", "ラ",
        "ベ", "ノ", "サ", "テ", "メ", "ド", "キ", "ジ", "ゴ", "パ"]
_TAIL1 = ["ン", "ム", "ス", "ル", "ニョ", "ッパ", "ック", "ーノ", "ミ", "ピ"]
_TAIL_EVO = ["ドン", "ガス", "ザード", "ラング", "ギオス", "バーン", "クロス",
             "テリオン", "ドラ", "ガルド", "レオン", "フィウス", "ニクス", "ローグ"]

_used_names = set()


def make_name(stage, total_stages):
    for _ in range(200):
        n = random.choice(_HEAD)
        n += random.choice(_MID)
        if stage == total_stages and total_stages >= 2:
            n += random.choice(_TAIL_EVO)
        elif stage == 2:
            n += random.choice(_MID) + random.choice(_TAIL1)
        else:
            n += random.choice(_TAIL1)
        if n not in _used_names and 3 <= len(n) <= 7:
            _used_names.add(n)
            return n
    # フォールバック
    n = f"モンス{len(_used_names)}"
    _used_names.add(n)
    return n


_CATEGORY = ["わかば", "とかげ", "みずべ", "ほのお", "いわやま", "そうげん",
             "よぞら", "もり", "どうくつ", "うみ", "でんこう", "つばさ",
             "きば", "ふしぎ", "おに", "せいれい", "こだい", "けんじゃ"]


def make_category():
    return random.choice(_CATEGORY) + "モンスター"


# ---------------------------------------------------------------------------
# モンスター生成
# ---------------------------------------------------------------------------
MONSTERS = []
_id = 0


def base_total_for_stage(stage, total):
    """進化段階に応じた合計種族値の目安。"""
    if total == 1:
        return random.randint(440, 540)            # 単独種(伝説含む)
    if total == 2:
        return [300, 460][stage - 1] + random.randint(-15, 15)
    return [300, 410, 520][stage - 1] + random.randint(-15, 15)


def split_stats(total):
    parts = [random.random() for _ in range(5)]
    s = sum(parts)
    raw = [max(1, int(total * p / s)) for p in parts]
    # 30〜130 にクランプ
    raw = [min(130, max(20, v)) for v in raw]
    keys = ["hp", "attack", "defense", "speed", "special"]
    return dict(zip(keys, raw))


def pick_learnset(types):
    """タイプに沿った技をレベル習得順に。"""
    learn = [{"level": 1, "move": MOVE_BY_NAME["たいあたり"]}]
    # 低レベルでタイプ弱技
    type_moves = []
    for t in types:
        type_moves += MOVES_BY_TYPE.get(t, [])
    type_moves = [m for m in type_moves if m["category"] != "status" or m["power"] == 0]
    # 出現順を power でソート
    atk_moves = sorted([m for m in type_moves if m["power"] > 0], key=lambda m: m["power"])
    status_moves = [m for m in type_moves if m["power"] == 0]
    lvl = 5
    for m in atk_moves[:1]:
        learn.append({"level": lvl, "move": m["id"]}); lvl += 6
    learn.append({"level": lvl, "move": MOVE_BY_NAME["ひっかき"]}); lvl += 5
    for m in atk_moves[1:2]:
        learn.append({"level": lvl, "move": m["id"]}); lvl += 7
    if status_moves:
        learn.append({"level": lvl, "move": random.choice(status_moves)["id"]}); lvl += 6
    learn.append({"level": lvl, "move": MOVE_BY_NAME["こうそくとっしん"]}); lvl += 6
    for m in atk_moves[2:3]:
        learn.append({"level": lvl, "move": m["id"]}); lvl += 8
    return learn


DEX_TEMPLATES = [
    "{cat}。{t}の エネルギーを たくわえ、なかまを まもる ために たたかう。",
    "とても {trait}な せいかくで しられる {t}タイプの モンスター。",
    "{t}の ちからを あやつり、{place}に すんでいる。よる に なると かつどう する。",
    "こだいから いきづく {t}の せいれい。その {part}には ふしぎな ちからが やどる。",
    "{trait}で ぐんを なす。きけんを かんじると {t}の ちからで みを まもる。",
]
_TRAITS = ["おくびょう", "ゆうかん", "おだやか", "やんちゃ", "れいせい", "わんぱく", "がんこ"]
_PLACES = ["やまおく", "みずべ", "もりのおく", "どうくつ", "そうげん", "いせき", "かざんちかく"]
_PARTS = ["ひたい", "しっぽ", "つばさ", "ツノ", "むね", "りょうて"]


def make_dex(types):
    t = types[0]
    tpl = random.choice(DEX_TEMPLATES)
    return tpl.format(cat=make_category(), t=t, trait=random.choice(_TRAITS),
                      place=random.choice(_PLACES), part=random.choice(_PARTS))


def add_family(total_stages, types_per_stage, catch_base, is_legendary=False, growth="medium"):
    """1つの進化系統を追加。types_per_stage は各段階のタイプリスト。"""
    global _id
    start_id = _id + 1
    ids = []
    for stage in range(1, total_stages + 1):
        _id += 1
        types = types_per_stage[min(stage - 1, len(types_per_stage) - 1)]
        bt = base_total_for_stage(stage, total_stages)
        if is_legendary:
            bt = random.randint(560, 640)
        stats = split_stats(bt)
        evolve_to = None
        evolve_level = None
        if stage < total_stages:
            evolve_to = _id + 1
            evolve_level = 16 if total_stages == 2 else (16 if stage == 1 else 34)
        catch = 3 if is_legendary else max(3, catch_base - (stage - 1) * 30)
        mon = {
            "id": _id,
            "name": make_name(stage, total_stages),
            "category": make_category(),
            "types": types,
            "baseStats": stats,
            "catchRate": catch,
            "baseExp": int(sum(stats.values()) / 5) + 20,
            "growthRate": growth,
            "evolveTo": evolve_to,
            "evolveLevel": evolve_level,
            "learnset": pick_learnset(types),
            "dexEntry": make_dex(types),
            "height": round(random.uniform(0.3, 2.5) * stage, 1),
            "weight": round(random.uniform(3, 60) * stage, 1),
            "isLegendary": is_legendary,
            "spriteColor": TYPE_COLOR[types[0]],
            "spriteColor2": TYPE_COLOR[types[-1]],
            "spriteShape": (_id * 7) % 12,
        }
        MONSTERS.append(mon)
        ids.append(_id)
    return ids


def rand_types(allow_dual=True):
    t1 = random.choice(TYPES)
    if allow_dual and random.random() < 0.35:
        t2 = random.choice([t for t in TYPES if t != t1])
        return [t1, t2]
    return [t1]


# --- 御三家(3段階)。プレイヤーの最初の相棒 ---
# くさ / ほのお / みず の伝統的トリオをオリジナル種で
add_family(3, [["くさ"], ["くさ"], ["くさ", "どく"]], catch_base=45)       # 1-3
add_family(3, [["ほのお"], ["ほのお"], ["ほのお", "かぜ"]], catch_base=45)  # 4-6
add_family(3, [["みず"], ["みず"], ["みず", "はがね"]], catch_base=45)      # 7-9

# --- 序盤の鳥・小動物(3段階) ---
add_family(3, [["ノーマル", "かぜ"], ["ノーマル", "かぜ"], ["ノーマル", "かぜ"]], catch_base=255)  # 10-12
add_family(3, [["ノーマル"], ["ノーマル"], ["ノーマル"]], catch_base=255)  # 13-15

# --- 2段階ファミリーを多数 ---
while _id < 120:
    t = rand_types()
    add_family(2, [t, t], catch_base=random.choice([120, 150, 190, 220]))

# --- 単独種を追加して150に近づける ---
while _id < 145:
    t = rand_types()
    add_family(1, [t], catch_base=random.choice([90, 120, 150]))

# --- 伝説モンスター(単独・低捕獲率) ---
for _ in range(6):
    t = rand_types(allow_dual=True)
    add_family(1, [t], catch_base=3, is_legendary=True, growth="slow")

assert len(MONSTERS) >= 150, f"モンスター数が不足: {len(MONSTERS)}"

# ---------------------------------------------------------------------------
# 書き出し
# ---------------------------------------------------------------------------
type_chart_full = {}
for atk in TYPES:
    type_chart_full[atk] = {}
    for dfn in TYPES:
        type_chart_full[atk][dfn] = TYPE_CHART.get(atk, {}).get(dfn, 1)

with open(os.path.join(OUT, "types.json"), "w", encoding="utf-8") as f:
    json.dump({"types": TYPES, "colors": TYPE_COLOR, "chart": type_chart_full},
              f, ensure_ascii=False, indent=2)

with open(os.path.join(OUT, "moves.json"), "w", encoding="utf-8") as f:
    json.dump(MOVES, f, ensure_ascii=False, indent=2)

with open(os.path.join(OUT, "monsters.json"), "w", encoding="utf-8") as f:
    json.dump(MONSTERS, f, ensure_ascii=False, indent=2)

print(f"types: {len(TYPES)}")
print(f"moves: {len(MOVES)}")
print(f"monsters: {len(MONSTERS)}")
print(f"legendary: {sum(1 for m in MONSTERS if m['isLegendary'])}")
print("OK ->", OUT)
