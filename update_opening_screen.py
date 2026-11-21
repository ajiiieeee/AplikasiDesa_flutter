import os, sys, math, subprocess
from PIL import Image, ImageDraw, ImageFilter
import numpy as np

def update_opening_screen():
    orig_path = "tutorial-video/opening_poster_original.jpg"
    im = Image.open(orig_path).convert("RGB")
    im = im.resize((1080, 1920), Image.Resampling.LANCZOS)
    arr = np.array(im)

    # 1. Clean old top logo area
    # Background interpolation across X: 432 to 648, Y: 60 to 248
    bg_left = arr[60:248, 430, :].astype(float)
    bg_right = arr[60:248, 650, :].astype(float)
    for y_idx, y in enumerate(range(60, 248)):
        c1 = bg_left[y_idx]
        c2 = bg_right[y_idx]
        for x in range(432, 648):
            r = (x - 432) / (648 - 432)
            arr[y, x] = (c1 * (1 - r) + c2 * r).astype(np.uint8)

    im_clean = Image.fromarray(arr)

    # 2. Place official project logo at the top
    logo = Image.open("tutorial-video/actual_project_logo.png").convert("RGBA")
    target_h = 168
    target_w = int(logo.width * (target_h / logo.height))
    logo_top = logo.resize((target_w, target_h), Image.Resampling.LANCZOS)

    # Create soft drop shadow for top logo
    shadow = Image.new("RGBA", (target_w + 30, target_h + 30), (0, 0, 0, 0))
    logo_alpha = logo_top.split()[-1]
    shadow_mask = Image.new("L", logo_top.size, 0)
    shadow_mask.paste(logo_alpha)
    shadow_colored = Image.new("RGBA", logo_top.size, (10, 30, 60, 110))
    shadow.paste(shadow_colored, (15, 17), mask=shadow_mask)
    shadow = shadow.filter(ImageFilter.GaussianBlur(5))

    top_x = 540 - target_w // 2
    top_y = 73

    im_clean.paste(shadow, (top_x - 15, top_y - 15), mask=shadow)
    im_clean.paste(logo_top, (top_x, top_y), mask=logo_top)

    # 3. Place official logo on phone appbar (matching lib/screens/home.dart)
    # Center is at (655, 1006)
    phone_cx = 655
    phone_cy = 1006
    r = 23 # radius of white circle

    # Draw white circle with subtle shadow
    draw = ImageDraw.Draw(im_clean)
    draw.ellipse([phone_cx - r - 1, phone_cy - r, phone_cx + r + 1, phone_cy + r + 2], fill=(25, 45, 80)) # subtle shadow
    draw.ellipse([phone_cx - r, phone_cy - r, phone_cx + r, phone_cy + r], fill=(255, 255, 255), outline=(220, 230, 245), width=1)

    # Inside white circle, place official logo
    target_phone_h = 34
    target_phone_w = int(logo.width * (target_phone_h / logo.height))
    logo_phone = logo.resize((target_phone_w, target_phone_h), Image.Resampling.LANCZOS)
    px = phone_cx - target_phone_w // 2
    py = phone_cy - target_phone_h // 2
    im_clean.paste(logo_phone, (px, py), mask=logo_phone)

    # Save outputs
    out_png = "tutorial-video/screen_01_opening.png"
    out_jpg = "tutorial-video/thumbnail_tutorial.jpg"
    im_clean.save(out_png, quality=98)
    im_clean.save(out_jpg, quality=95)
    print(f"Updated opening screen saved to {out_png} ({os.path.getsize(out_png)} bytes)")

if __name__ == "__main__":
    update_opening_screen()

