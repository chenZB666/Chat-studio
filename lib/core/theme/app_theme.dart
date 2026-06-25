/// Chat Studio — 应用主题配置
///
/// 基于莫兰迪色彩系统 + 自定义设计令牌的 Material 3 主题。
/// 完全替代 FlexColorScheme，提供更精致、一致的外观。
library;

import 'package:flutter/material.dart';
import 'colors.dart';
import 'design_tokens.dart';
import 'typography.dart';

class AppTheme {
  AppTheme._();

  /// 浅色主题
  static ThemeData light(String colorSeed) {
    final colorScheme = MorandiColors.lightScheme(colorSeed);
    final textTheme = AppTextStyles.textTheme(
      colorScheme.onSurface,
      colorScheme.onSurfaceVariant,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      textTheme: textTheme,
      primaryTextTheme: textTheme,

      // ── 应用栏 ──
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        centerTitle: false,
        titleSpacing: 0,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(
          color: colorScheme.onSurfaceVariant,
          size: LayoutTokens.iconSize,
        ),
      ),

      // ── 卡片 ──
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.md),
        ),
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),

      // ── 输入框 ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        labelStyle: textTheme.bodyMedium,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),

      // ── 按钮 ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
          disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
          disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusTokens.md),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.sm,
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusTokens.md),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.sm,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusTokens.md),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.xs,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusTokens.md),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.xs,
          ),
        ),
      ),

      // ── 图标按钮 ──
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusTokens.sm),
          ),
          padding: const EdgeInsets.all(Spacing.xs),
          minimumSize: const Size(LayoutTokens.touchTarget, LayoutTokens.touchTarget),
        ),
      ),

      // ── 弹出菜单 ──
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.md),
        ),
        elevation: ElevationTokens.overlay,
        color: colorScheme.surface,
        shadowColor: Colors.black.withValues(alpha: 0.08),
      ),

      // ── 对话框 ──
      dialogTheme: DialogThemeData(
        elevation: ElevationTokens.modal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.lg),
        ),
        backgroundColor: colorScheme.surface,
      ),

      // ── 底部弹窗 ──
      bottomSheetTheme: BottomSheetThemeData(
        elevation: ElevationTokens.modal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(RadiusTokens.lg),
          ),
        ),
        backgroundColor: colorScheme.surface,
        showDragHandle: true,
        dragHandleColor: colorScheme.outlineVariant,
      ),

      // ── 抽屉 ──
      drawerTheme: DrawerThemeData(
        elevation: ElevationTokens.modal,
        shape: const RoundedRectangleBorder(),
        backgroundColor: colorScheme.surface,
      ),

      // ── 列表瓦片 ──
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
        ),
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.sm),
        ),
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.bodySmall,
        leadingAndTrailingTextStyle: textTheme.bodySmall,
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
      ),

      // ── 分隔线 ──
      dividerTheme: DividerThemeData(
        space: 0,
        thickness: LayoutTokens.dividerThickness,
        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
      ),

      // ── 复选框 / 开关 ──
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.xxs),
        ),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary;
          return Colors.transparent;
        }),
        side: BorderSide(color: colorScheme.outline),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary;
          return colorScheme.outline;
        }),
        thumbColor: WidgetStateProperty.all(colorScheme.surface),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        elevation: ElevationTokens.top,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.sm),
        ),
        behavior: SnackBarBehavior.floating,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        backgroundColor: colorScheme.inverseSurface,
      ),

      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(RadiusTokens.xxs),
        ),
        textStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.xs,
          vertical: Spacing.xxs,
        ),
      ),

      // ── FloatingActionButton ──
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: ElevationTokens.raised,
        foregroundColor: colorScheme.onPrimary,
        backgroundColor: colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.lg),
        ),
      ),

      // ── TabBar ──
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.onSurface,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge,
        indicatorColor: colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        overlayColor: WidgetStateProperty.resolveWith((_) => Colors.transparent),
      ),

      // ── Chip ──
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.full),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.xxs,
        ),
        labelStyle: textTheme.labelMedium,
        backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        selectedColor: colorScheme.primaryContainer,
        side: BorderSide.none,
      ),

      // ── Scrollbar ──
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(4),
        radius: const Radius.circular(2),
        thumbColor: WidgetStateProperty.all(
          colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
        ),
      ),

      // ── Menu ──
      menuBarTheme: MenuBarThemeData(
        style: MenuStyle(
          elevation: WidgetStateProperty.all(0),
          backgroundColor: WidgetStateProperty.all(colorScheme.surface),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(RadiusTokens.sm),
            ),
          ),
        ),
      ),
      menuButtonTheme: MenuButtonThemeData(
        style: MenuItemButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusTokens.sm),
          ),
        ),
      ),

      // ── 全局 ──
      scaffoldBackgroundColor: colorScheme.background,
      canvasColor: colorScheme.surface,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: colorScheme.onSurface.withValues(alpha: 0.04),
      focusColor: colorScheme.onSurface.withValues(alpha: 0.08),
      dividerColor: colorScheme.outlineVariant.withValues(alpha: 0.5),
      disabledColor: colorScheme.onSurface.withValues(alpha: 0.38),
    );
  }

  /// 深色主题
  static ThemeData dark(String colorSeed) {
    final colorScheme = MorandiColors.darkScheme(colorSeed);
    final textTheme = AppTextStyles.textTheme(
      colorScheme.onSurface,
      colorScheme.onSurfaceVariant,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: textTheme,
      primaryTextTheme: textTheme,

      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        centerTitle: false,
        titleSpacing: 0,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(
          color: colorScheme.onSurfaceVariant,
          size: LayoutTokens.iconSize,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.md),
        ),
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        labelStyle: textTheme.bodyMedium,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
          disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
          disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusTokens.md),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.sm,
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusTokens.md),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.sm,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusTokens.md),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.xs,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusTokens.md),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.xs,
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusTokens.sm),
          ),
          padding: const EdgeInsets.all(Spacing.xs),
          minimumSize: const Size(LayoutTokens.touchTarget, LayoutTokens.touchTarget),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.md),
        ),
        elevation: ElevationTokens.overlay,
        color: colorScheme.surface,
        shadowColor: Colors.black.withValues(alpha: 0.3),
      ),

      dialogTheme: DialogThemeData(
        elevation: ElevationTokens.modal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.lg),
        ),
        backgroundColor: colorScheme.surface,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        elevation: ElevationTokens.modal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(RadiusTokens.lg),
          ),
        ),
        backgroundColor: colorScheme.surface,
        showDragHandle: true,
        dragHandleColor: colorScheme.outlineVariant,
      ),

      drawerTheme: DrawerThemeData(
        elevation: ElevationTokens.modal,
        shape: const RoundedRectangleBorder(),
        backgroundColor: colorScheme.surface,
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
        ),
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.sm),
        ),
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.bodySmall,
        leadingAndTrailingTextStyle: textTheme.bodySmall,
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
      ),

      dividerTheme: DividerThemeData(
        space: 0,
        thickness: LayoutTokens.dividerThickness,
        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
      ),

      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.xxs),
        ),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary;
          return Colors.transparent;
        }),
        side: BorderSide(color: colorScheme.outline),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary;
          return colorScheme.outline;
        }),
        thumbColor: WidgetStateProperty.all(colorScheme.surface),
      ),

      snackBarTheme: SnackBarThemeData(
        elevation: ElevationTokens.top,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.sm),
        ),
        behavior: SnackBarBehavior.floating,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        backgroundColor: colorScheme.inverseSurface,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(RadiusTokens.xxs),
        ),
        textStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.xs,
          vertical: Spacing.xxs,
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: ElevationTokens.raised,
        foregroundColor: colorScheme.onPrimary,
        backgroundColor: colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.lg),
        ),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.onSurface,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge,
        indicatorColor: colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        overlayColor: WidgetStateProperty.resolveWith((_) => Colors.transparent),
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.full),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.xxs,
        ),
        labelStyle: textTheme.labelMedium,
        backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        selectedColor: colorScheme.primaryContainer,
        side: BorderSide.none,
      ),

      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(4),
        radius: const Radius.circular(2),
        thumbColor: WidgetStateProperty.all(
          colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
        ),
      ),

      menuBarTheme: MenuBarThemeData(
        style: MenuStyle(
          elevation: WidgetStateProperty.all(0),
          backgroundColor: WidgetStateProperty.all(colorScheme.surface),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(RadiusTokens.sm),
            ),
          ),
        ),
      ),
      menuButtonTheme: MenuButtonThemeData(
        style: MenuItemButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusTokens.sm),
          ),
        ),
      ),

      scaffoldBackgroundColor: colorScheme.background,
      canvasColor: colorScheme.surface,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: colorScheme.onSurface.withValues(alpha: 0.06),
      focusColor: colorScheme.onSurface.withValues(alpha: 0.10),
      dividerColor: colorScheme.outlineVariant.withValues(alpha: 0.5),
      disabledColor: colorScheme.onSurface.withValues(alpha: 0.38),
    );
  }

  /// 将色名映射回颜色值（兼容旧 API）
  static Color colorFromSeed(String seedName) {
    return MorandiColors.lightScheme(seedName).primary;
  }
}
