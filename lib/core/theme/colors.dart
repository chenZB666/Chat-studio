/// Chat Studio — 莫兰迪色彩系统 (Morandi Color System)
///
/// 低饱和、高级感的莫兰迪色板，适用于深色/浅色双模式。
/// 基于 Material 3 ColorScheme 结构，直接替换 FlexColorScheme。
library;

import 'package:flutter/material.dart';

/// 莫兰迪色板 — 所有颜色常量集中定义
class MorandiColors {
  MorandiColors._();

  // ── Light Mode ──
  static const lightBackground = Color(0xFFFAF8F5); // 暖白象牙
  static const lightSurface = Color(0xFFF5F2ED); // 暖白浅灰
  static const lightSurfaceVariant = Color(0xFFEDE8E1); // 浅灰米色
  static const lightPrimary = Color(0xFF8B9D83); // 鼠尾草绿 (sage)
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightPrimaryContainer = Color(0xFFD4DFCB); // 浅鼠尾草
  static const lightOnPrimaryContainer = Color(0xFF1C2E1A);
  static const lightSecondary = Color(0xFF9A8B8D); // 玫瑰灰 (rose taupe)
  static const lightOnSecondary = Color(0xFFFFFFFF);
  static const lightSecondaryContainer = Color(0xFFE3D5D6);
  static const lightOnSecondaryContainer = Color(0xFF2E2324);
  static const lightTertiary = Color(0xFF7D9BA8); // 钢蓝灰
  static const lightOnTertiary = Color(0xFFFFFFFF);
  static const lightTertiaryContainer = Color(0xFFD0E3EC);
  static const lightOnTertiaryContainer = Color(0xFF1A2E36);
  static const lightError = Color(0xFFBA4A4A); // 哑光红
  static const lightOnError = Color(0xFFFFFFFF);
  static const lightErrorContainer = Color(0xFFFFDAD6);
  static const lightOnErrorContainer = Color(0xFF410002);
  static const lightOutline = Color(0xFFC8C1B8);
  static const lightOutlineVariant = Color(0xFFE0D9D2);
  static const lightOnBackground = Color(0xFF2C2824);
  static const lightOnSurface = Color(0xFF3D3833);
  static const lightOnSurfaceVariant = Color(0xFF5C554E);
  static const lightInversePrimary = Color(0xFFB9CBAF);
  static const lightInverseSurface = Color(0xFF312D28);
  static const lightInverseOnSurface = Color(0xFFF5F0EA);
  static const lightScrim = Color(0xFF000000);

  // ── Dark Mode ──
  static const darkBackground = Color(0xFF1A1816);
  static const darkSurface = Color(0xFF242220);
  static const darkSurfaceVariant = Color(0xFF2E2B28);
  static const darkPrimary = Color(0xFFB9CBAF); // 浅鼠尾草 (light sage)
  static const darkOnPrimary = Color(0xFF1C2E1A);
  static const darkPrimaryContainer = Color(0xFF4C5B45);
  static const darkOnPrimaryContainer = Color(0xFFD0E3CB);
  static const darkSecondary = Color(0xFFCDBBBD);
  static const darkOnSecondary = Color(0xFF2E2324);
  static const darkSecondaryContainer = Color(0xFF4A3B3D);
  static const darkOnSecondaryContainer = Color(0xFFE3D5D6);
  static const darkTertiary = Color(0xFF8DB4C4);
  static const darkOnTertiary = Color(0xFF1A2E36);
  static const darkTertiaryContainer = Color(0xFF3B5E6B);
  static const darkOnTertiaryContainer = Color(0xFFD0E3EC);
  static const darkError = Color(0xFFFFB4AB);
  static const darkOnError = Color(0xFF690005);
  static const darkErrorContainer = Color(0xFF93000A);
  static const darkOnErrorContainer = Color(0xFFFFDAD6);
  static const darkOutline = Color(0xFF4E4B45);
  static const darkOutlineVariant = Color(0xFF35322E);
  static const darkOnBackground = Color(0xFFE8E2DA);
  static const darkOnSurface = Color(0xFFD4CFC8);
  static const darkOnSurfaceVariant = Color(0xFFB0A89E);
  static const darkInversePrimary = Color(0xFF8B9D83);
  static const darkInverseSurface = Color(0xFFF0EBE5);
  static const darkInverseOnSurface = Color(0xFF312D28);

  /// 从色名（10 色系）生成对应的 Material 3 ColorScheme
  static ColorScheme lightScheme(String seed) {
    return ColorScheme(
      brightness: Brightness.light,
      primary: _lightPrimary(seed),
      onPrimary: lightOnPrimary,
      primaryContainer: _lightPrimaryContainer(seed),
      onPrimaryContainer: lightOnPrimaryContainer,
      secondary: lightSecondary,
      onSecondary: lightOnSecondary,
      secondaryContainer: lightSecondaryContainer,
      onSecondaryContainer: lightOnSecondaryContainer,
      tertiary: lightTertiary,
      onTertiary: lightOnTertiary,
      tertiaryContainer: lightTertiaryContainer,
      onTertiaryContainer: lightOnTertiaryContainer,
      error: lightError,
      onError: lightOnError,
      errorContainer: lightErrorContainer,
      onErrorContainer: lightOnErrorContainer,
      outline: lightOutline,
      outlineVariant: lightOutlineVariant,
      surface: lightSurface,
      onSurface: lightOnSurface,
      surfaceContainerHighest: lightSurfaceVariant,
      onSurfaceVariant: lightOnSurfaceVariant,
      inverseSurface: lightInverseSurface,
      inversePrimary: lightInversePrimary,
      onInverseSurface: lightInverseOnSurface,
      scrim: lightScrim,
    );
  }

  static ColorScheme darkScheme(String seed) {
    return ColorScheme(
      brightness: Brightness.dark,
      primary: _darkPrimary(seed),
      onPrimary: darkOnPrimary,
      primaryContainer: _darkPrimaryContainer(seed),
      onPrimaryContainer: darkOnPrimaryContainer,
      secondary: darkSecondary,
      onSecondary: darkOnSecondary,
      secondaryContainer: darkSecondaryContainer,
      onSecondaryContainer: darkOnSecondaryContainer,
      tertiary: darkTertiary,
      onTertiary: darkOnTertiary,
      tertiaryContainer: darkTertiaryContainer,
      onTertiaryContainer: darkOnTertiaryContainer,
      error: darkError,
      onError: darkOnError,
      errorContainer: darkErrorContainer,
      onErrorContainer: darkOnErrorContainer,
      outline: darkOutline,
      outlineVariant: darkOutlineVariant,
      surface: darkSurface,
      onSurface: darkOnSurface,
      surfaceContainerHighest: darkSurfaceVariant,
      onSurfaceVariant: darkOnSurfaceVariant,
      inverseSurface: darkInverseSurface,
      inversePrimary: darkInversePrimary,
      onInverseSurface: darkInverseOnSurface,
      scrim: lightScrim,
    );
  }

  // ── 10 色系 primary 映射（在莫兰迪基调上微调主色） ──
  static Color _lightPrimary(String seed) {
    switch (seed) {
      case 'blue':    return const Color(0xFF7D9BA8);
      case 'green':   return const Color(0xFF8B9D83);
      case 'purple':  return const Color(0xFF9890A8);
      case 'orange':  return const Color(0xFFC49A7C);
      case 'red':     return const Color(0xFFC48C8C);
      case 'teal':    return const Color(0xFF7FA8A0);
      case 'pink':    return const Color(0xFFC48CA0);
      case 'grey':    return const Color(0xFF94908C);
      case 'brown':   return const Color(0xFFB09C8C);
      case 'indigo':  return const Color(0xFF8C8CB0);
      default:        return const Color(0xFF8B9D83); // default sage
    }
  }

  static Color _lightPrimaryContainer(String seed) {
    switch (seed) {
      case 'blue':    return const Color(0xFFD0E3EC);
      case 'green':   return const Color(0xFFD4DFCB);
      case 'purple':  return const Color(0xFFE0D8EA);
      case 'orange':  return const Color(0xFFEDE0D4);
      case 'red':     return const Color(0xFFEDD4D4);
      case 'teal':    return const Color(0xFFD0E3DF);
      case 'pink':    return const Color(0xFFEDD4DF);
      case 'grey':    return const Color(0xFFE0DCD8);
      case 'brown':   return const Color(0xFFE8DDD4);
      case 'indigo':  return const Color(0xFFD4D4E8);
      default:        return const Color(0xFFD4DFCB);
    }
  }

  static Color _darkPrimary(String seed) {
    switch (seed) {
      case 'blue':    return const Color(0xFF8DB4C4);
      case 'green':   return const Color(0xFFB9CBAF);
      case 'purple':  return const Color(0xFFB8ADC8);
      case 'orange':  return const Color(0xFFD4B8A0);
      case 'red':     return const Color(0xFFD4ADAD);
      case 'teal':    return const Color(0xFFA8C8C0);
      case 'pink':    return const Color(0xFFD4ADC0);
      case 'grey':    return const Color(0xFFB8B4B0);
      case 'brown':   return const Color(0xFFC8B8A8);
      case 'indigo':  return const Color(0xFFADADC8);
      default:        return const Color(0xFFB9CBAF);
    }
  }

  static Color _darkPrimaryContainer(String seed) {
    switch (seed) {
      case 'blue':    return const Color(0xFF3B5E6B);
      case 'green':   return const Color(0xFF4C5B45);
      case 'purple':  return const Color(0xFF54506B);
      case 'orange':  return const Color(0xFF6B5540);
      case 'red':     return const Color(0xFF6B4040);
      case 'teal':    return const Color(0xFF3B5E55);
      case 'pink':    return const Color(0xFF6B4055);
      case 'grey':    return const Color(0xFF55504C);
      case 'brown':   return const Color(0xFF5C4E40);
      case 'indigo':  return const Color(0xFF40406B);
      default:        return const Color(0xFF4C5B45);
    }
  }
}
