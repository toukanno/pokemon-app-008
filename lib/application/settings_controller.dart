import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/game_constants.dart';
import '../data/datasources/hive_save_source.dart';

/// 設定(ダークモード・メッセージ速度)。
class GameSettings {
  final ThemeMode themeMode;

  /// メッセージ送り速度(1=おそい,2=ふつう,3=はやい)
  final int textSpeed;
  final bool battleAnimations;

  const GameSettings({
    this.themeMode = ThemeMode.system,
    this.textSpeed = 2,
    this.battleAnimations = true,
  });

  GameSettings copyWith({ThemeMode? themeMode, int? textSpeed, bool? battleAnimations}) =>
      GameSettings(
        themeMode: themeMode ?? this.themeMode,
        textSpeed: textSpeed ?? this.textSpeed,
        battleAnimations: battleAnimations ?? this.battleAnimations,
      );

  /// メッセージ1文字あたりの表示間隔(ミリ秒)
  int get charDelayMs => textSpeed >= 3 ? 8 : (textSpeed == 2 ? 22 : 40);

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'textSpeed': textSpeed,
        'battleAnimations': battleAnimations,
      };

  factory GameSettings.fromJson(Map<String, dynamic> json) => GameSettings(
        themeMode: ThemeMode.values.firstWhere(
          (m) => m.name == json['themeMode'],
          orElse: () => ThemeMode.system,
        ),
        textSpeed: (json['textSpeed'] ?? 2) as int,
        battleAnimations: (json['battleAnimations'] ?? true) as bool,
      );
}

class SettingsController extends StateNotifier<GameSettings> {
  final HiveSaveSource _source;

  SettingsController(this._source) : super(const GameSettings()) {
    _load();
  }

  void _load() {
    final raw = _source.read(GameConstants.settingsKey);
    if (raw != null) {
      try {
        state = GameSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
  }

  void _persist() {
    _source.write(GameConstants.settingsKey, jsonEncode(state.toJson()));
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _persist();
  }

  void toggleDark() {
    final next = state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setThemeMode(next);
  }

  void setTextSpeed(int speed) {
    state = state.copyWith(textSpeed: speed.clamp(1, 3));
    _persist();
  }

  void setBattleAnimations(bool on) {
    state = state.copyWith(battleAnimations: on);
    _persist();
  }
}
