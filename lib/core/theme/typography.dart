/// Chat Studio — 排版系统 (Typography)
///
/// 现代无衬线字体层级，宽松行高，清晰字号梯度。
/// 使用系统默认字体（Windows Segoe UI / macOS SF / Linux Roboto）。
library;

import 'package:flutter/material.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── 字号梯度 ──
  static const double _displaySize = 32;
  static const double _headline1Size = 24;
  static const double _headline2Size = 20;
  static const double _title1Size = 18;
  static const double _title2Size = 16;
  static const double _bodySize = 14;
  static const double _bodySmallSize = 13;
  static const double _captionSize = 12;
  static const double _labelSize = 11;
  static const double _codeSize = 13;

  // ── 行高 ──
  static const double _tightHeight = 1.2;
  static const double _normalHeight = 1.4;
  static const double _relaxedHeight = 1.6;
  static const FontWeight _regular = FontWeight.w400;
  static const FontWeight _medium = FontWeight.w500;
  static const FontWeight _semiBold = FontWeight.w600;
  static const FontWeight _bold = FontWeight.w700;

  /// 构建完整 TextTheme
  static TextTheme textTheme(Color onSurface, Color onSurfaceVariant) {
    return TextTheme(
      // Display — 大标题（极少使用）
      displayLarge: TextStyle(
        fontSize: _displaySize,
        fontWeight: _bold,
        height: _tightHeight,
        letterSpacing: -0.5,
        color: onSurface,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: _semiBold,
        height: _tightHeight,
        letterSpacing: -0.3,
        color: onSurface,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: _semiBold,
        height: _tightHeight,
        letterSpacing: -0.2,
        color: onSurface,
      ),

      // Headline — 页面标题
      headlineLarge: TextStyle(
        fontSize: _headline1Size,
        fontWeight: _semiBold,
        height: _normalHeight,
        letterSpacing: -0.2,
        color: onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: _headline2Size,
        fontWeight: _semiBold,
        height: _normalHeight,
        color: onSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: _title1Size,
        fontWeight: _semiBold,
        height: _normalHeight,
        color: onSurface,
      ),

      // Title — 区块标题
      titleLarge: TextStyle(
        fontSize: _title1Size,
        fontWeight: _semiBold,
        height: _normalHeight,
        color: onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: _title2Size,
        fontWeight: _medium,
        height: _normalHeight,
        letterSpacing: 0.15,
        color: onSurface,
      ),
      titleSmall: TextStyle(
        fontSize: _bodySize,
        fontWeight: _medium,
        height: _normalHeight,
        letterSpacing: 0.1,
        color: onSurface,
      ),

      // Body — 正文
      bodyLarge: TextStyle(
        fontSize: _bodySize,
        fontWeight: _regular,
        height: _relaxedHeight,
        letterSpacing: 0.15,
        color: onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: _bodySmallSize,
        fontWeight: _regular,
        height: _relaxedHeight,
        letterSpacing: 0.25,
        color: onSurface,
      ),
      bodySmall: TextStyle(
        fontSize: _captionSize,
        fontWeight: _regular,
        height: _relaxedHeight,
        letterSpacing: 0.4,
        color: onSurfaceVariant,
      ),

      // Label — 按钮、标签、小控件
      labelLarge: TextStyle(
        fontSize: _bodySize,
        fontWeight: _medium,
        height: _normalHeight,
        letterSpacing: 0.5,
        color: onSurface,
      ),
      labelMedium: TextStyle(
        fontSize: _captionSize,
        fontWeight: _medium,
        height: _normalHeight,
        letterSpacing: 0.5,
        color: onSurfaceVariant,
      ),
      labelSmall: TextStyle(
        fontSize: _labelSize,
        fontWeight: _medium,
        height: _normalHeight,
        letterSpacing: 0.5,
        color: onSurfaceVariant,
      ),
    );
  }

  /// 代码样式（用于 Markdown 代码块）
  static TextStyle codeStyle(Color surface) {
    return TextStyle(
      fontFamily: 'monospace',
      fontSize: _codeSize,
      fontWeight: _regular,
      height: _normalHeight,
      color: surface,
    );
  }
}