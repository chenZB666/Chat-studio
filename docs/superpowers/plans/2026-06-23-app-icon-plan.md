# App Icon Replacement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the default Flutter app icon with a rounded-square robot head (blue/white gradient, purple star eyes, open round mouth) across all platforms.

**Architecture:** Generate a master 1024×1024 PNG icon using Python Pillow, then use `flutter_launcher_icons` to auto-generate Android/iOS/web/macOS variants. Generate Windows `.ico` separately with Pillow.

**Tech Stack:** Python Pillow (icon generation), flutter_launcher_icons ^0.14.3 (platform output), Flutter

## Global Constraints

- Master icon image: 1024×1024 PNG at `assets/icon/app_icon.png`
- Colors: BG `#1565C0`→`#42A5F5` gradient (top→bottom), face `#F5F9FF`, eyes `#7B1FA2` (purple stars), mouth `#0D47A1` (filled circle)
- All platform icon files must be replaced in-place (same paths/names)
- Windows: IDI_APP_ICON references `resources\\app_icon.ico` in `Runner.rc` — must produce valid .ico
- Web: favicon.png must be 32×32

---

### Task 1: Generate Master Icon with Python Pillow

**Files:**
- Create: `assets/icon/app_icon.png` (1024×1024)
- Create: `scripts/generate_icon.py`

- [ ] **Step 1: Create the icon generation script**

```python
"""scripts/generate_icon.py — Generate app icon: rounded-square robot head with star eyes."""
from PIL import Image, ImageDraw
import math

SIZE = 1024
img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Background: rounded square with blue gradient
corner_radius = 200
bg_top = (0x15, 0x65, 0xC0)   # #1565C0
bg_bot = (0x42, 0xA5, 0xF5)   # #42A5F5

# Draw gradient by horizontal strips
for y in range(SIZE):
    t = y / SIZE
    r = int(bg_top[0] + (bg_bot[0] - bg_top[0]) * t)
    g = int(bg_top[1] + (bg_bot[1] - bg_top[1]) * t)
    b = int(bg_top[2] + (bg_bot[2] - bg_top[2]) * t)
    draw.rectangle([(0, y), (SIZE, y)], fill=(r, g, b, 255))

# Mask out rounded corners
def draw_rounded_rect_mask(draw, size, rad):
    """Overdraw corners with transparency to make a rounded square."""
    for dx, dy in [(0, 0), (0, 1), (1, 0), (1, 1)]:
        cx = dx * (size - rad)
        cy = dy * (size - rad)
        draw.pieslice([(cx - rad, cy - rad), (cx + rad, cy + rad)], 180 * dx + 90 * dy, 180 * dx + 90 * dy + 90, fill=(0,0,0,0))
        # fill corner rectangles
        rx = cx - rad if dx == 0 else cx
        ry = cy - rad if dy == 0 else cy
        w = rad if dx == 0 else size - cx
        h = rad if dy == 0 else size - cy
        draw.rectangle([(rx, ry), (rx + w, ry + h)], fill=(0, 0, 0, 0))

draw_rounded_rect_mask(draw, SIZE, corner_radius)

# Face: inset white rounded rectangle
face_pad = 120
face_rad = 160
face_l, face_t = face_pad, face_pad
face_r, face_b = SIZE - face_pad, SIZE - face_pad
draw.rounded_rectangle([(face_l, face_t), (face_r, face_b)], radius=face_rad, fill=(0xF5, 0xF9, 0xFF, 255))

# Star eye function
def star_points(cx, cy, outer_r, inner_r, num_points=5):
    pts = []
    for i in range(num_points * 2):
        angle = math.pi / 2 + math.pi * i / num_points  # start from top (pi/2)
        r = outer_r if i % 2 == 0 else inner_r
        pts.append((cx + r * math.cos(angle), cy - r * math.sin(angle)))
    return pts

# Calculate inner radius for 5-pointed star
R = 75
inner_r = R * math.sin(math.radians(18)) / math.sin(math.radians(54))

# Eyes: purple stars
eye_y = 380
star1 = star_points(340, eye_y, R, inner_r)
star2 = star_points(684, eye_y, R, inner_r)
draw.polygon(star1, fill=(0x7B, 0x1F, 0xA2, 255))
draw.polygon(star2, fill=(0x7B, 0x1F, 0xA2, 255))

# Mouth: filled dark blue circle
mouth_cx, mouth_cy = 512, 680
mouth_r = 95
draw.ellipse([(mouth_cx - mouth_r, mouth_cy - mouth_r),
              (mouth_cx + mouth_r, mouth_cy + mouth_r)],
             fill=(0x0D, 0x47, 0xA1, 255))

img.save("assets/icon/app_icon.png")
print("Icon saved to assets/icon/app_icon.png")
```

- [ ] **Step 2: Ensure assets directory exists and run the script**

```bash
mkdir -p assets/icon
python scripts/generate_icon.py
```

Expected output: `Icon saved to assets/icon/app_icon.png`

- [ ] **Step 3: Verify the icon visually**

```bash
python -c "from PIL import Image; i=Image.open('assets/icon/app_icon.png'); print(i.size, i.mode)"
```

Expected: `(1024, 1024) RGBA`

- [ ] **Step 4: Commit**

```bash
git add assets/icon/app_icon.png scripts/generate_icon.py
git commit -m "feat: add app icon generation script and master icon asset"
```

---

### Task 2: Add flutter_launcher_icons Dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add flutter_launcher_icons to dev_dependencies in pubspec.yaml**

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  flutter_launcher_icons: ^0.14.3
  # ... rest stays unchanged
```

- [ ] **Step 2: Install the dependency**

```bash
flutter pub get
```

Expected: `flutter_launcher_icons` is resolved and added.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add flutter_launcher_icons dependency"
```

---

### Task 3: Configure flutter_launcher_icons

**Files:**
- Create: `flutter_launcher_icons.yaml`

- [ ] **Step 1: Create the flutter_launcher_icons config**

```yaml
# flutter_launcher_icons.yaml
flutter_launcher_icons:
  android: true
  ios: true
  web:
    generate: true
    image_path: "assets/icon/app_icon.png"
  macos:
    generate: true
    image_path: "assets/icon/app_icon.png"
  image_path: "assets/icon/app_icon.png"
  min_sdk_android: 21
  remove_alpha_ios: true
```

- [ ] **Step 2: Run flutter_launcher_icons**

```bash
dart run flutter_launcher_icons -f flutter_launcher_icons.yaml
```

Expected output: All Android mipmap PNGs, iOS Icon-App PNGs, macOS app_icon PNGs, and web favicon.png are generated.

- [ ] **Step 3: Commit**

```bash
git add flutter_launcher_icons.yaml
git add android/app/src/main/res/mipmap-mdpi/ic_launcher.png
git add android/app/src/main/res/mipmap-hdpi/ic_launcher.png
git add android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
git add android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
git add android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
git add ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-*.png
git add macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_*.png
git add web/favicon.png
git commit -m "feat: generate all platform icons via flutter_launcher_icons"
```

---

### Task 4: Generate Windows .ico

**Files:**
- Modify: `scripts/generate_icon.py` (add .ico generation)
- Overwrite: `windows/runner/resources/app_icon.ico`

- [ ] **Step 1: Append .ico generation to the script and re-run**

Append to `scripts/generate_icon.py` before the final `img.save(...)`:

```python
# --- Generate Windows .ico (multi-res) ---
ico_sizes = [16, 32, 48, 64, 128, 256]
ico_images = []
for s in ico_sizes:
    resized = img.resize((s, s), Image.LANCZOS)
    ico_images.append(resized)
ico_images[0].save(
    "windows/runner/resources/app_icon.ico",
    format="ICO",
    sizes=[(s, s) for s in ico_sizes],
    append_images=ico_images[1:]
)
print("ICO saved to windows/runner/resources/app_icon.ico")
```

Then run:

```bash
python scripts/generate_icon.py
```

Expected output: `ICO saved to windows/runner/resources/app_icon.ico`

- [ ] **Step 2: Verify the .ico file**

```bash
python -c "
from PIL import Image
ico = Image.open('windows/runner/resources/app_icon.ico')
print('Frames:', ico.n_frames if hasattr(ico, 'n_frames') else 1)
for i in range(getattr(ico, 'n_frames', 1)):
    ico.seek(i)
    print(f'  Frame {i}: {ico.size}')
"
```

Expected: 6 frames at sizes 16×16, 32×32, 48×48, 64×64, 128×128, 256×256

- [ ] **Step 3: Commit**

```bash
git add scripts/generate_icon.py windows/runner/resources/app_icon.ico
git commit -m "feat: generate Windows .ico with multi-resolution icon"
```

---

### Task 5: Verify All Platforms

**Files:** (read-only verification)

- [ ] **Step 1: Verify Android icons exist at all densities**

```bash
ls -la android/app/src/main/res/mipmap-*/ic_launcher.png
```

Expected: 5 files (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)

- [ ] **Step 2: Verify iOS icons exist (sample check)**

```bash
ls ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-*.png | wc -l
```

Expected: 15 files

- [ ] **Step 3: Verify macOS icons exist**

```bash
ls macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_*.png | wc -l
```

Expected: 7 files (16, 32, 64, 128, 256, 512, 1024)

- [ ] **Step 4: Verify web icon**

```bash
python -c "from PIL import Image; i=Image.open('web/favicon.png'); print(i.size)"
```

Expected: `(32, 32)`

- [ ] **Step 5: Verify Windows .ico**

```bash
python -c "
from PIL import Image
ico = Image.open('windows/runner/resources/app_icon.ico')
print('Valid ICO with', ico.n_frames, 'frames')
"
```

- [ ] **Step 6: Final commit (if verification uncovered anything)**

```bash
git status
```

Expected: Working tree clean (no uncommitted changes)