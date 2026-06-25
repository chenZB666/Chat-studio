# LlamaChat App Icon Design

## Overview
Replace the default Flutter app icon with a custom square robot head icon across all platforms (Android, iOS, macOS, Windows, Web).

## Design Spec

### Visual Elements

| Element | Description |
|---------|-------------|
| **Shape** | Rounded square (corner radius ~200px on 1024×1024 base) |
| **Background** | Blue gradient top-to-bottom: `#1565C0` → `#42A5F5` |
| **Face** | White `#F5F9FF` inset rounded rectangle, ~120px padding from edge |
| **Eyes** | Two purple `#7B1FA2` ★ (5-pointed stars), outer diameter ~75px |
| **Mouth** | Solid dark blue `#0D47A1` filled circle (open round mouth), radius ~95px |

### Layout (1024×1024 canvas, center at 512,512)

```
┌──────────────────────────────────┐
│  ██  Blue gradient background  ██ │  ← rounded square
│  ┌────────────────────────────┐  │
│  │                            │  │
│  │         White face         │  │
│  │                            │  │
│  │     ★              ★       │  │  ← purple stars at (340,380) (684,380)
│  │                            │  │
│  │            ◯               │  │  ← mouth at (512, 680), r=95
│  │                            │  │
│  └────────────────────────────┘  │
│  ████████████████████████████████ │
└──────────────────────────────────┘
```

### Color Palette

| Usage | Hex | Description |
|-------|-----|-------------|
| BG top | `#1565C0` | Blue 800 |
| BG bottom | `#42A5F5` | Blue 400 |
| Face | `#F5F9FF` | Near-white with blue tint |
| Eye stars | `#7B1FA2` | Purple 700 |
| Mouth | `#0D47A1` | Blue 900 (dark) |

### Star Geometry
5-pointed star calculated from outer radius `R=75`:
- Inner radius `r = R × sin(18°) / sin(54°) ≈ 28.8`
- Points at 0°, 72°, 144°, 216°, 288° from center

## Implementation Approach

**Method:** Generate master 1024×1024 PNG via Python Pillow, then use `flutter_launcher_icons` package to auto-generate all platform-specific sizes.

### Platform Coverage

| Platform | Files | Output Method |
|----------|-------|---------------|
| Android | `mipmap-*/ic_launcher.png` (5 sizes) | flutter_launcher_icons |
| iOS | `Icon-App-*.png` (15 sizes) | flutter_launcher_icons |
| macOS | `app_icon_*.png` (7 sizes) | flutter_launcher_icons |
| Windows | `app_icon.ico` (multi-resolution) | Python script + icoutils |
| Web | `favicon.png` (32×32) | flutter_launcher_icons |