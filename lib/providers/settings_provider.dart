import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class AppSettings {
  final ThemeMode themeMode;
  final String colorSeed;
  final double fontSize;
  final String defaultSystemPrompt;
  final double defaultTemperature;
  final double defaultTopP;
  final int defaultTopK;
  final int defaultMaxTokens;
  final double defaultRepeatPenalty;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.colorSeed = 'blue',
    this.fontSize = 14.0,
    this.defaultSystemPrompt = 'You are a helpful assistant.',
    this.defaultTemperature = AppConstants.defaultTemperature,
    this.defaultTopP = AppConstants.defaultTopP,
    this.defaultTopK = AppConstants.defaultTopK,
    this.defaultMaxTokens = AppConstants.defaultMaxTokens,
    this.defaultRepeatPenalty = AppConstants.defaultRepeatPenalty,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? colorSeed,
    double? fontSize,
    String? defaultSystemPrompt,
    double? defaultTemperature,
    double? defaultTopP,
    int? defaultTopK,
    int? defaultMaxTokens,
    double? defaultRepeatPenalty,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      colorSeed: colorSeed ?? this.colorSeed,
      fontSize: fontSize ?? this.fontSize,
      defaultSystemPrompt: defaultSystemPrompt ?? this.defaultSystemPrompt,
      defaultTemperature: defaultTemperature ?? this.defaultTemperature,
      defaultTopP: defaultTopP ?? this.defaultTopP,
      defaultTopK: defaultTopK ?? this.defaultTopK,
      defaultMaxTokens: defaultMaxTokens ?? this.defaultMaxTokens,
      defaultRepeatPenalty: defaultRepeatPenalty ?? this.defaultRepeatPenalty,
    );
  }

  // ── Persistence ──

  static const _kThemeMode = 'themeMode';
  static const _kColorSeed = 'colorSeed';
  static const _kFontSize = 'fontSize';
  static const _kSystemPrompt = 'defaultSystemPrompt';
  static const _kTemperature = 'defaultTemperature';
  static const _kTopP = 'defaultTopP';
  static const _kTopK = 'defaultTopK';
  static const _kMaxTokens = 'defaultMaxTokens';
  static const _kRepeatPenalty = 'defaultRepeatPenalty';

  Map<String, dynamic> toJson() => {
        _kThemeMode: themeMode.index,
        _kColorSeed: colorSeed,
        _kFontSize: fontSize,
        _kSystemPrompt: defaultSystemPrompt,
        _kTemperature: defaultTemperature,
        _kTopP: defaultTopP,
        _kTopK: defaultTopK,
        _kMaxTokens: defaultMaxTokens,
        _kRepeatPenalty: defaultRepeatPenalty,
      };

  factory AppSettings.fromPrefs(SharedPreferences prefs) {
    return AppSettings(
      themeMode: ThemeMode.values[prefs.getInt(_kThemeMode) ?? ThemeMode.system.index],
      colorSeed: prefs.getString(_kColorSeed) ?? 'blue',
      fontSize: prefs.getDouble(_kFontSize) ?? 14.0,
      defaultSystemPrompt: prefs.getString(_kSystemPrompt) ?? 'You are a helpful assistant.',
      defaultTemperature: prefs.getDouble(_kTemperature) ?? AppConstants.defaultTemperature,
      defaultTopP: prefs.getDouble(_kTopP) ?? AppConstants.defaultTopP,
      defaultTopK: prefs.getInt(_kTopK) ?? AppConstants.defaultTopK,
      defaultMaxTokens: prefs.getInt(_kMaxTokens) ?? AppConstants.defaultMaxTokens,
      defaultRepeatPenalty: prefs.getDouble(_kRepeatPenalty) ?? AppConstants.defaultRepeatPenalty,
    );
  }

  Future<void> saveToPrefs(SharedPreferences prefs) async {
    await prefs.setInt(_kThemeMode, themeMode.index);
    await prefs.setString(_kColorSeed, colorSeed);
    await prefs.setDouble(_kFontSize, fontSize);
    await prefs.setString(_kSystemPrompt, defaultSystemPrompt);
    await prefs.setDouble(_kTemperature, defaultTemperature);
    await prefs.setDouble(_kTopP, defaultTopP);
    await prefs.setInt(_kTopK, defaultTopK);
    await prefs.setInt(_kMaxTokens, defaultMaxTokens);
    await prefs.setDouble(_kRepeatPenalty, defaultRepeatPenalty);
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings());

  /// Load settings from SharedPreferences. Call once at app startup.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings.fromPrefs(prefs);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await state.saveToPrefs(prefs);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _save();
  }

  Future<void> setColorSeed(String seed) async {
    state = state.copyWith(colorSeed: seed);
    await _save();
  }

  Future<void> setFontSize(double size) async {
    state = state.copyWith(fontSize: size);
    await _save();
  }

  Future<void> setDefaultSystemPrompt(String prompt) async {
    state = state.copyWith(defaultSystemPrompt: prompt);
    await _save();
  }

  Future<void> setDefaultTemperature(double t) async {
    state = state.copyWith(defaultTemperature: t);
    await _save();
  }

  Future<void> setDefaultTopP(double p) async {
    state = state.copyWith(defaultTopP: p);
    await _save();
  }

  Future<void> setDefaultTopK(int k) async {
    state = state.copyWith(defaultTopK: k);
    await _save();
  }

  Future<void> setDefaultMaxTokens(int t) async {
    state = state.copyWith(defaultMaxTokens: t);
    await _save();
  }

  Future<void> setDefaultRepeatPenalty(double p) async {
    state = state.copyWith(defaultRepeatPenalty: p);
    await _save();
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
