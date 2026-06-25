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

# --- Generate Windows .ico (multi-res) ---
import io, struct
ico_sizes = [16, 32, 48, 64, 128, 256]
png_data = []
for s in ico_sizes:
    resized = img.resize((s, s), Image.LANCZOS)
    buf = io.BytesIO()
    resized.save(buf, format="PNG")
    png_data.append(buf.getvalue())
num_images = len(ico_sizes)
header = struct.pack("<HHH", 0, 1, num_images)
offset = 6 + num_images * 16
entries = b""
all_data = b""
for i, s in enumerate(ico_sizes):
    w = 0 if s == 256 else s
    h = 0 if s == 256 else s
    entry = struct.pack("<BBBBHHII", w, h, 0, 0, 1, 32, len(png_data[i]), offset)
    entries += entry
    all_data += png_data[i]
    offset += len(png_data[i])
with open("windows/runner/resources/app_icon.ico", "wb") as f:
    f.write(header + entries + all_data)
print("ICO saved to windows/runner/resources/app_icon.ico")

# Also save to assets/icon for system_tray on desktop
with open("assets/icon/app_icon.ico", "wb") as f:
    f.write(header + entries + all_data)
print("ICO saved to assets/icon/app_icon.ico")
