# Background Mode Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable the app to run in the background across all platforms, preserving ongoing LLM connections and app state.

**Architecture:** Desktop (Windows/macOS/Linux) uses `system_tray` + `window_manager` for minimize-to-tray behavior. Mobile uses built-in `AppLifecycleListener` for lifecycle-aware state preservation with no additional dependencies.

**Tech Stack:** `system_tray: ^0.1.1` (desktop tray), `window_manager: ^0.5.1` (existing, window controls), Flutter `AppLifecycleListener` (mobile lifecycle)

## Global Constraints

- Desktop close button hides to tray instead of quitting; only tray menu "Quit" terminates the process
- Mobile: no foreground service, no persistent notification
- Tray icon uses existing asset `assets/icon/app_icon.png` (already registered in pubspec.yaml assets section)
- `flutter_background_service` dependency is NOT needed — must be removed if present

---

### Task 1: Remove Unused Dependency & Register Icon Asset

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Remove flutter_background_service from pubspec.yaml**

If `flutter_background_service` is in the dependencies list, remove it. Also add `assets/icon/` to the flutter assets section:

```yaml
  # share_plus removed due to Kotlin compilation issues
  collection: ^1.18.0
  markdown: ^7.3.1
  window_manager: ^0.5.1
  system_tray: ^0.1.1

# ... (dev_dependencies unchanged)

flutter:
  uses-material-design: true
  assets:
    - assets/icon/
```

- [ ] **Step 2: Run pub get to remove the dependency**

```bash
cd E:/gemma && flutter pub get
```

Expected: `flutter_background_service` is removed from the resolved dependency graph.

- [ ] **Step 3: Commit**

```bash
cd E:/gemma && git add pubspec.yaml pubspec.lock && git commit -m "chore: add system_tray, register icon asset, remove unused background_service"
```

---

### Task 2: Create DesktopTrayService

**Files:**
- Create: `lib/services/desktop_tray_service.dart`

**Interfaces:**
- Produces: `DesktopTrayService` class with static `init()` and `destroy()` methods

- [ ] **Step 1: Implement DesktopTrayService**

```dart
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

    await _tray.initSystemTray(
      title: 'Chat Studio',
      iconPath: 'assets/icon/app_icon.png',
      toolTip: 'Chat Studio',
    );

    // Build context menu
    final menu = List<MenuItemBase>.from([
      MenuItem(
        label: 'Show / Hide',
        onClicked: _toggleVisibility,
      ),
      const MenuSeparator(),
      MenuItem(
        label: 'Quit',
        onClicked: _quit,
      ),
    ]);
    await _tray.setContextMenu(menu);

    // Handle tray icon click/double-click
    _tray.registerSystemTrayEventHandler((eventName) {
      if (eventName == 'leftMouseUp') {
        _toggleVisibility();
      }
    });

    _initialized = true;
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
    // system_tray doesn't have a remove method, so we just mark it
    _initialized = false;
  }
}
```

- [ ] **Step 2: Create test/verify file compiles**

```bash
cd E:/gemma && flutter analyze lib/services/desktop_tray_service.dart 2>&1 | tail -5
```

Expected: No errors (may show warnings about unused imports in the main analysis).

- [ ] **Step 3: Commit**

```bash
cd E:/gemma && git add lib/services/desktop_tray_service.dart && git commit -m "feat: create DesktopTrayService for system tray management"
```

---

### Task 3: Update TitleBar Close to Hide to Tray

**Files:**
- Modify: `lib/widgets/title_bar.dart:109-113`

- [ ] **Step 1: Change close button from `windowManager.close()` to `windowManager.hide()`**

Replace the close button's `onTap`:

```dart
_WindowButton(
  icon: Icons.close_rounded,
  isClose: true,
  onTap: () => windowManager.hide(),
),
```

- [ ] **Step 2: Commit**

```bash
cd E:/gemma && git add lib/widgets/title_bar.dart && git commit -m "fix: close button hides to tray instead of quitting"
```

---

### Task 4: Initialize Tray in main.dart

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Initialize DesktopTrayService after window setup**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'services/desktop_tray_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(1280, 800),
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Initialize system tray for desktop platforms
  await DesktopTrayService.init();

  runApp(const ProviderScope(child: LlamaChatApp()));
}
```

- [ ] **Step 2: Verify compilation**

```bash
cd E:/gemma && flutter analyze lib/main.dart 2>&1 | tail -10
```

Expected: No analysis errors.

- [ ] **Step 3: Commit**

```bash
cd E:/gemma && git add lib/main.dart && git commit -m "feat: initialize system tray on app startup"
```

---

### Task 5: Add Mobile Lifecycle Listener

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Add AppLifecycleListener to the app entry**

Replace the current `runApp(...)` with lifecycle-aware version:

```dart
import 'dart:async';

// ... (existing imports)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(1280, 800),
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Initialize system tray for desktop platforms
  await DesktopTrayService.init();

  runApp(const ProviderScope(child: LlamaChatApp()));
}
```

(No actual change to `main.dart` code in this step — the lifecycle listener is better placed in `app.dart` where it has access to Riverpod providers)

- [ ] **Step 2: Add AppLifecycleListener to LlamaChatApp in app.dart**

Modify `lib/app.dart` to listen for lifecycle changes:

```dart
import 'dart:async';
// ... (existing imports)

class _LlamaChatAppState extends ConsumerState<LlamaChatApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(storageServiceProvider).seedBuiltInTemplates();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Mobile: app went to background — no special action needed.
    // Dio connections stay alive, SQLite is available.
    // The UI will re-render from the current ChatState when returning.
    if (state == AppLifecycleState.resumed) {
      // Optionally trigger a refresh when returning to foreground
      debugPrint('App resumed to foreground');
    }
  }

  // ... (existing build method)
}
```

- [ ] **Step 3: Verify compilation**

```bash
cd E:/gemma && flutter analyze lib/app.dart 2>&1 | tail -10
```

Expected: No analysis errors.

- [ ] **Step 4: Commit**

```bash
cd E:/gemma && git add lib/app.dart && git commit -m "feat: add mobile lifecycle listener for background state preservation"
```

---

### Task 6: Run Tests & Final Verification

**Files:** (read-only verification)

- [ ] **Step 1: Run existing tests**

```bash
cd E:/gemma && flutter test 2>&1 | tail -10
```

Expected: All tests pass.

- [ ] **Step 2: Run full static analysis**

```bash
cd E:/gemma && flutter analyze 2>&1 | tail -10
```

Expected: No errors, warnings only from pre-existing code.

- [ ] **Step 3: Final commit if any changes needed**

```bash
cd E:/gemma && git status
```

Expected: Working tree clean (all changes committed).