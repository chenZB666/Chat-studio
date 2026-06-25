import 'dart:io';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

/// Manages the system tray icon and menu for desktop platforms.
class DesktopTrayService {
  static final SystemTray _tray = SystemTray();
  static bool _initialized = false;

  /// Initialize the system tray with icon and context menu.
  static Future<void> init() async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) return;

    try {
      final iconPath = Platform.isWindows
          ? 'assets/icon/app_icon.ico'
          : 'assets/icon/app_icon.png';
      await _tray.initSystemTray(
        title: 'Chat Studio',
        iconPath: iconPath,
        toolTip: 'Chat Studio',
      ).timeout(const Duration(seconds: 5));

      // Build context menu
      final menu = <MenuItemBase>[
        MenuItem(
          label: 'Show / Hide',
          onClicked: _toggleVisibility,
        ),
        MenuSeparator(),
        MenuItem(
          label: 'Quit',
          onClicked: _quit,
        ),
      ];
      await _tray.setContextMenu(menu).timeout(const Duration(seconds: 3));

      // Handle tray icon click/double-click
      _tray.registerSystemTrayEventHandler((eventName) {
        if (eventName == 'leftMouseUp') {
          _toggleVisibility();
        } else if (eventName == 'rightMouseUp') {
          _tray.popUpContextMenu();
        }
      });

      _initialized = true;
    } catch (e) {
      // ignore: avoid_print
      print('DesktopTrayService init error (non-fatal): $e');
    }
  }

  /// Toggle window visibility between shown and hidden.
  static void _toggleVisibility() {
    windowManager.isVisible().then((visible) {
      if (visible) {
        windowManager.hide();
      } else {
        windowManager.show();
        windowManager.focus();
      }
    });
  }

  /// Quit the application entirely.
  static void _quit() {
    windowManager.destroy();
  }

  /// Clean up the tray icon.
  static Future<void> destroy() async {
    if (!_initialized) return;
    _initialized = false;
  }
}
