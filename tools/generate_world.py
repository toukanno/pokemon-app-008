#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Elementa Monsters - ワールド(マップ)ジェネレータ

街・どうろ・どうくつのタイルマップを矩形を保証しつつ生成し、
ワープ・NPC・エンカウント表とともに assets/data/world.json へ出力する。

タイル凡例:
  T = き(進入不可)        B = たてもの(進入不可)
  . = みち(歩行可)         : = くさ(歩行可・装飾)
  ~ = しげみ(エンカウント) W = みず(進入不可)
  H = かいふくセンター入口   P = ショップ入口
  D = ドア/ワープ           F = さく(進入不可)
  R = いわ(進入不可・どうくつ)
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "data")
os.makedirs(OUT, exist_ok=True)


def grid(w, h, fill="."):
    return [[fill for _ in range(w)] for _ in range(h)]


def border(g, ch="T"):
    h = len(g); w = len(g[0])
    for x in range(w):
        g[0][x] = ch
        g[h - 1][x] = ch
    for y in range(h):
        g[y][0] = ch
        g[y][w - 1] = ch


def rect(g, x0, y0, x1, y1, ch):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            g[y][x] = ch


def to_rows(g):
    return ["".join(r) for r in g]


maps = {}

# ---------------------------------------------------------------------------
# 1) コモレビタウン (はじまりの まち)
# ---------------------------------------------------------------------------
W, H = 18, 14
g = grid(W, H, ".")
border(g, "T")
# 装飾の草
rect(g, 2, 2, 4, 3, ":")
rect(g, 13, 9, 15, 11, ":")
# プレイヤーの家 (左)
rect(g, 3, 4, 5, 5, "B")
g[5][4] = "D"            # 家のドア(装飾ワープ無しでもOK)
# はかせの けんきゅうじょ (右)
rect(g, 11, 3, 14, 5, "B")
g[5][12] = "D"
# かいふくセンター
rect(g, 3, 9, 5, 10, "B")
g[10][4] = "H"
# ショップ
rect(g, 8, 9, 10, 10, "B")
g[10][9] = "P"
# 池
rect(g, 14, 11, 16, 12, "W")
maps["town_komorebi"] = {
    "id": "town_komorebi",
    "name": "コモレビタウン",
    "kind": "town",
    "rows": to_rows(g),
    "spawn": [8, 7],
    "music": "town",
    "warps": [
        {"x": 16, "y": 7, "to": "route_1", "tx": 1, "ty": 7},
    ],
    "edgeWarps": [
        {"edge": "right", "to": "route_1", "tx": 1, "ty": 7},
    ],
    "npcs": [
        {"x": 7, "y": 6, "name": "はかせ", "sprite": 0,
         "lines": ["ようこそ エレメンシア地方へ！",
                   "モンスターは きみの たいせつな パートナーじゃ。",
                   "ずかんを かんせいさせる たびに でかけよう！"]},
        {"x": 12, "y": 11, "name": "おんなのこ", "sprite": 1,
         "lines": ["しげみ に はいると やせいの モンスターが でるんだって。"]},
        {"x": 4, "y": 8, "name": "おとこのこ", "sprite": 2,
         "lines": ["かいふくセンターに のると てもちが ぜんかいふく するよ！"]},
    ],
    "signs": [
        {"x": 9, "y": 8, "text": "コモレビタウン  〜 かぜ そよぐ はじまりの ち 〜"},
    ],
    "encounters": [],
    "healTiles": [[4, 10]],
    "shopTiles": [[9, 10]],
}

# ---------------------------------------------------------------------------
# 2) 1ばんどうろ (Route 1)
# ---------------------------------------------------------------------------
W, H = 22, 12
g = grid(W, H, ".")
border(g, "T")
# しげみパッチ
rect(g, 3, 2, 7, 4, "~")
rect(g, 11, 6, 16, 9, "~")
rect(g, 9, 2, 10, 3, ":")
# 木のかたまり
rect(g, 14, 2, 15, 3, "T")
rect(g, 5, 8, 6, 9, "T")
maps["route_1"] = {
    "id": "route_1",
    "name": "1ばんどうろ",
    "kind": "route",
    "rows": to_rows(g),
    "spawn": [1, 7],
    "music": "route",
    "warps": [],
    "edgeWarps": [
        {"edge": "left", "to": "town_komorebi", "tx": 15, "ty": 7},
        {"edge": "right", "to": "town_minato", "tx": 1, "ty": 6},
    ],
    "npcs": [
        {"x": 8, "y": 6, "name": "たんけんか", "sprite": 2,
         "lines": ["この さきの みなとまち には りっぱな ショップが あるよ。",
                   "そのまえに しげみで レベルあげ だ！"]},
    ],
    "signs": [
        {"x": 2, "y": 6, "text": "1ばんどうろ  →  みなとまち"},
    ],
    "encounters": [
        {"species": 10, "min": 2, "max": 5, "weight": 30},
        {"species": 13, "min": 2, "max": 5, "weight": 30},
        {"species": 16, "min": 3, "max": 6, "weight": 20},
        {"species": 19, "min": 3, "max": 6, "weight": 15},
        {"species": 22, "min": 4, "max": 6, "weight": 5},
    ],
    "healTiles": [],
    "shopTiles": [],
}

# ---------------------------------------------------------------------------
# 3) みなとまち (Port Town)
# ---------------------------------------------------------------------------
W, H = 18, 13
g = grid(W, H, ".")
border(g, "T")
# 海(右側)
rect(g, 14, 1, 16, 11, "W")
# かいふくセンター・ショップ
rect(g, 3, 3, 5, 4, "B"); g[4][4] = "H"
rect(g, 8, 3, 10, 4, "B"); g[4][9] = "P"
rect(g, 3, 8, 5, 9, "B"); g[9][4] = "D"
rect(g, 6, 9, 7, 10, ":")
maps["town_minato"] = {
    "id": "town_minato",
    "name": "みなとまち",
    "kind": "town",
    "rows": to_rows(g),
    "spawn": [1, 6],
    "music": "town",
    "warps": [],
    "edgeWarps": [
        {"edge": "left", "to": "route_1", "tx": 20, "ty": 7},
        {"edge": "bottom", "to": "cave_shinobi", "tx": 3, "ty": 1},
    ],
    "npcs": [
        {"x": 11, "y": 6, "name": "ふなのり", "sprite": 0,
         "lines": ["みなみの どうくつ には つよい モンスターが すむ。",
                   "でんせつの モンスターが いる という うわさ も…！"]},
        {"x": 6, "y": 5, "name": "おばあさん", "sprite": 1,
         "lines": ["ショップで キズぐすり や モンスターボール を そろえなさい。"]},
    ],
    "signs": [
        {"x": 7, "y": 7, "text": "みなとまち  〜 しおかぜ の みなと 〜"},
        {"x": 4, "y": 11, "text": "↓ しのびの どうくつ"},
    ],
    "encounters": [],
    "healTiles": [[4, 4]],
    "shopTiles": [[9, 4]],
}

# ---------------------------------------------------------------------------
# 4) しのびのどうくつ (Cave Dungeon)
# ---------------------------------------------------------------------------
W, H = 20, 14
g = grid(W, H, ".")
border(g, "R")
# 内部の岩
rect(g, 4, 3, 6, 4, "R")
rect(g, 12, 5, 15, 6, "R")
rect(g, 7, 9, 9, 10, "R")
# しげみ(どうくつの くらやみ = エンカウント床)
rect(g, 2, 6, 4, 9, "~")
rect(g, 10, 2, 13, 3, "~")
rect(g, 14, 9, 17, 11, "~")
maps["cave_shinobi"] = {
    "id": "cave_shinobi",
    "name": "しのびのどうくつ",
    "kind": "cave",
    "rows": to_rows(g),
    "spawn": [3, 1],
    "music": "cave",
    "warps": [],
    "edgeWarps": [
        {"edge": "top", "to": "town_minato", "tx": 3, "ty": 11},
    ],
    "npcs": [
        {"x": 16, "y": 5, "name": "たんけんか", "sprite": 2,
         "lines": ["この おくに でんせつの モンスターが ねむっている…",
                   "きみの ちからを みせてみろ！"]},
    ],
    "signs": [],
    "encounters": [
        {"species": 25, "min": 8, "max": 12, "weight": 25},
        {"species": 40, "min": 9, "max": 13, "weight": 25},
        {"species": 55, "min": 10, "max": 14, "weight": 20},
        {"species": 70, "min": 11, "max": 15, "weight": 15},
        {"species": 90, "min": 12, "max": 16, "weight": 10},
        {"species": 146, "min": 18, "max": 20, "weight": 5},
    ],
    "healTiles": [],
    "shopTiles": [],
}

world = {
    "startMap": "town_komorebi",
    "maps": maps,
}

with open(os.path.join(OUT, "world.json"), "w", encoding="utf-8") as f:
    json.dump(world, f, ensure_ascii=False, indent=2)

# 検証: 全マップが矩形であること
for mid, m in maps.items():
    widths = {len(r) for r in m["rows"]}
    assert len(widths) == 1, f"{mid}: 行の幅が不揃い {widths}"
    print(f"{mid}: {len(m['rows'][0])} x {len(m['rows'])}  warps={len(m['edgeWarps'])} npcs={len(m['npcs'])}")

print("OK ->", os.path.join(OUT, "world.json"))
