# LlamaChat Background Mode Support Design

## Overview
Enable the app to run in the background across all platforms when minimized or switched away, preserving ongoing LLM connections and application state.

## Platform Scope

| Platform | Approach | Dependencies |
|----------|----------|--------------|
| **Windows / macOS / Linux** | Minimize to system tray on close, restore via tray menu | `system_tray` (add), `window_manager` (existing) |
| **Android / iOS** | Lifecycle-aware state persistence, no foreground service or notifications | No new dependencies |

## Design

### 1. Desktop System Tray

**Behavior:**
- Clicking the **close button** (title bar `×`) no longer terminates the process — instead the window is hidden (`windowManager.hide()`)
- A **system tray icon** (the app icon) appears in the OS tray area
- **Right-click menu** offers three actions:
  - `显示` / `Show` — calls `windowManager.show()` + `windowManager.focus()`
  - `隐藏` / `Hide` — calls `windowManager.hide()`
  - `退出` / `Quit` — calls `windowManager.destroy()`, truly terminates
- **Double-click** on the tray icon also restores the window
- The tray icon is initialized once at app startup (`main.dart`)

**Files:**
- Create: `lib/services/desktop_tray_service.dart`
- Modify: `lib/widgets/title_bar.dart` (close button → hide)
- Modify: `lib/main.dart` (init system tray on supported platforms)

**DesktopTrayService API:**
```dart
class DesktopTrayService {
  static Future<void> init() async { /* — create tray icon + menu — */ }
  static Future<void> destroy() async { /* — remove tray — */ }
}
```

### 2. Mobile Lifecycle Handling

**Behavior:**
- No foreground service, no persistent notification
- Rely on natural app lifecycle (Flutter/Dart VM stays alive when backgrounded on Android/iOS by default)
- Add `AppLifecycleListener` to detect when app enters/leaves background
- When entering background: no special action needed — the existing Dio HTTP connection and SQLite DB continue to work
- When returning to foreground: the `ChatState` is already in memory; if a streaming response was in progress, the UI re-renders with whatever content was received while in background
- The existing SQLite persistence (`StorageService`) already ensures messages are saved; `watchMessages` stream replays the latest state on reconnection

**Files:**
- Modify: `lib/main.dart` — add `AppLifecycleListener`
- Modify: `lib/providers/chat_provider.dart` — add lifecycle-aware pause/resume safeguard for streaming

### 3. Connection Keep-Alive

**Streaming behavior during background:**
- `LlamaApiClient` uses Dio with streaming (`responseType: ResponseType.stream`)
- When the app goes to background while a stream is active, the **Dio HTTP connection remains open** (native platform socket, not affected by UI lifecycle)
- The `ChatNotifier` continues to accumulate `currentStreamContent` even without UI listeners
- On return to foreground, the UI re-reads the latest state via `ref.watch(chatProvider)`

**Non-streaming behavior:**
- Normal HTTP requests complete as usual regardless of lifecycle state

### 4. Error Handling

| Scenario | Behavior |
|----------|----------|
| Desktop: tray init fails (unsupported platform) | Gracefully skip, app works normally |
| Desktop: user closes via task manager | Process terminates, tray icon removed |
| Mobile: system kills process (low memory) | Next launch loads last state from SQLite |
| Mobile: network lost while backgrounded | Dio timeout triggers `ChatStreamState.error` on return |
| Streaming interrupted by system kill | Last saved message is in DB; conversation picks up from history |

### 5. Testing

- **Desktop:** minimize window → verify tray icon appears → restore via menu → quit via tray
- **Mobile:** send a message → switch to another app → wait → switch back → verify state preserved
- **Edge case:** start streaming → background → system kills app → reopen → verify DB recovery