/// Chat Studio — 设计令牌 (Design Tokens)
///
/// 统一间距、圆角、阴影、动画曲线、z-index 层级。
/// 所有组件引用此文件，禁止硬编码值。
library;

import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════
// Spacing — 间距系统 (4px 网格)
// ═══════════════════════════════════════════════
class Spacing {
  Spacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  // 内边距快捷值
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );
  static const EdgeInsets dialogPadding = EdgeInsets.all(lg);
}

// ═══════════════════════════════════════════════
// Border Radius — 圆角系统
// ═══════════════════════════════════════════════
class RadiusTokens {
  RadiusTokens._();

  static const double xxs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double full = 999;
}

// ═══════════════════════════════════════════════
// Shadows — 弥散阴影
// ═══════════════════════════════════════════════
class ShadowTokens {
  ShadowTokens._();

  /// 浅层阴影（卡片、列表项）
  static List<BoxShadow> lightSmall(Color surface) {
    return [
      BoxShadow(
        color: surface.withValues(alpha: 0.06),
        blurRadius: 4,
        offset: const Offset(0, 1),
      ),
      BoxShadow(
        color: surface.withValues(alpha: 0.04),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }

  /// 中层阴影（弹出面板、模态框）
  static List<BoxShadow> lightMedium(Color surface) {
    return [
      BoxShadow(
        color: surface.withValues(alpha: 0.08),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
      BoxShadow(
        color: surface.withValues(alpha: 0.04),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];
  }

  /// 深层阴影（对话框、抽屉）
  static List<BoxShadow> lightLarge(Color surface) {
    return [
      BoxShadow(
        color: surface.withValues(alpha: 0.10),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: surface.withValues(alpha: 0.06),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ];
  }

  /// 浅色模式下（shadow with surface color）
  static List<BoxShadow> small = lightSmall(const Color(0xFF000000));
  static List<BoxShadow> medium = lightMedium(const Color(0xFF000000));
  static List<BoxShadow> large = lightLarge(const Color(0xFF000000));
}

// ═══════════════════════════════════════════════
// Animation — 动画曲线与时长
// ═══════════════════════════════════════════════
class MotionTokens {
  MotionTokens._();

  // 时长
  static const Duration instant = Duration(milliseconds: 50);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  // 曲线
  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve spring = Curves.elasticOut;

  // AnimatedWidget 常用
  static const Duration buttonPress = fast;
  static const Duration pageTransition = normal;
  static const Duration expandCollapse = normal;
}

// ═══════════════════════════════════════════════
// Z-Index — 视觉层级
// ═══════════════════════════════════════════════
class ElevationTokens {
  ElevationTokens._();

  static const double ground = 0;    // 背景层
  static const double base = 1;     // 卡片、列表项
  static const double raised = 2;   // 导航栏、按钮
  static const double overlay = 4;  // 弹出面板、下拉菜单
  static const double modal = 8;    // 模态框、抽屉
  static const double top = 16;     // Toast、SnackBar
}

// ═══════════════════════════════════════════════
// Layout — 布局常量
// ═══════════════════════════════════════════════
class LayoutTokens {
  LayoutTokens._();

  static const double sidebarWidth = 300;
  static const double sidebarCollapsedWidth = 0;
  static const double titleBarHeight = 44;
  static const double chatInputMinHeight = 56;
  static const double chatInputMaxHeight = 200;
  static const double breakpointNarrow = 800;
  static const double maxContentWidth = 900;
  static const double avatarSize = 36;
  static const double iconSize = 20;
  static const double buttonHeight = 40;
  static const double touchTarget = 44;
  static const double dividerThickness = 0.5;
}
