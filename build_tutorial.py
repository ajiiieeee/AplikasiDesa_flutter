import os
import subprocess
import glob
import re
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import imageio_ffmpeg

FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()

WIDTH, HEIGHT = 1080, 1920
FPS = 30

# Theme Colors
C_PRIMARY = (0, 74, 173)         # #004AAD
C_SECONDARY = (30, 136, 229)     # #1E88E5
C_BG = (245, 247, 250)           # #F5F7FA
C_CARD = (255, 255, 255)
C_BORDER = (226, 232, 240)
C_TEXT_DARK = (31, 41, 55)       # #1F2937
C_TEXT_MUTED = (107, 114, 128)   # #6B7280
C_GREEN = (34, 197, 94)          # #22C55E
C_GREEN_BG = (220, 252, 231)
C_YELLOW_BG = (255, 243, 205)
C_YELLOW_TEXT = (146, 64, 14)
C_YELLOW_BORDER = (255, 193, 7)
C_BLUE_LIGHT = (227, 242, 253)
C_RED = (239, 68, 68)

# Fonts
FONT_BOLD_XL = ImageFont.truetype("assets/fonts/Poppins-Bold.ttf", 46)
FONT_BOLD_L  = ImageFont.truetype("assets/fonts/Poppins-Bold.ttf", 34)
FONT_BOLD_M  = ImageFont.truetype("assets/fonts/Poppins-Bold.ttf", 26)
FONT_BOLD_S  = ImageFont.truetype("assets/fonts/Poppins-Bold.ttf", 20)

FONT_SB_XL   = ImageFont.truetype("assets/fonts/Poppins-SemiBold.ttf", 40)
FONT_SB_L    = ImageFont.truetype("assets/fonts/Poppins-SemiBold.ttf", 30)
FONT_SB_M    = ImageFont.truetype("assets/fonts/Poppins-SemiBold.ttf", 24)
FONT_SB_S    = ImageFont.truetype("assets/fonts/Poppins-SemiBold.ttf", 20)

FONT_REG_L   = ImageFont.truetype("assets/fonts/Poppins-Regular.ttf", 28)
FONT_REG_M   = ImageFont.truetype("assets/fonts/Poppins-Regular.ttf", 24)
FONT_REG_S   = ImageFont.truetype("assets/fonts/Poppins-Regular.ttf", 20)
FONT_REG_XS  = ImageFont.truetype("assets/fonts/Poppins-Regular.ttf", 17)

FONT_SUBTITLE = ImageFont.truetype("assets/fonts/Poppins-Medium.ttf", 25)

LOGO_DESA = Image.open("assets/logo/logo.png").convert("RGBA")
LOGO_APP  = Image.open("assets/icons/logoaplikasi.png").convert("RGBA")

# Helper functions
def draw_status_bar(draw, dark=True):
    col = C_TEXT_DARK if dark else (255, 255, 255)
    draw.text((60, 36), "09:41", font=FONT_SB_M, fill=col)
    
    # Battery icon
    bx, by = 960, 40
    draw.rounded_rectangle([bx, by, bx + 55, by + 26], radius=6, outline=col, width=3)
    draw.rectangle([bx + 4, by + 4, bx + 38, by + 22], fill=col)
    draw.rectangle([bx + 56, by + 9, bx + 60, by + 17], fill=col)
    
    # Cellular bars
    cx = 880
    for i in range(4):
        h = 8 + i * 5
        draw.rectangle([cx + i * 8, by + 26 - h, cx + i * 8 + 5, by + 26], fill=col)
    
    # Wifi arc
    draw.arc([920, by, 946, by + 26], 200, 340, fill=col, width=3)

def draw_top_banner(draw, category_text, title_text):
    draw.rounded_rectangle([40, 90, 1040, 175], radius=20, fill=C_PRIMARY)
    draw.rounded_rectangle([60, 108, 230, 156], radius=10, fill=C_SECONDARY)
    draw.text((78, 118), "TUTORIAL", font=FONT_BOLD_S, fill=(255, 255, 255))
    draw.text((250, 114), f"{category_text} • {title_text}", font=FONT_SB_L, fill=(255, 255, 255))

def draw_subtitle_box(draw, text):
    if not text:
        return
    box_y1 = 1705
    box_y2 = 1845
    draw.rounded_rectangle([40, box_y1, 1040, box_y2], radius=24, fill=(15, 23, 42))
    draw.rounded_rectangle([40, box_y1, 1040, box_y2], radius=24, outline=(71, 85, 105), width=2)
    
    words = text.split()
    lines = []
    cur = ""
    for w in words:
        test = cur + (" " if cur else "") + w
        bbox = FONT_SUBTITLE.getbbox(test)
        if (bbox[2] - bbox[0]) < 940:
            cur = test
        else:
            lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    
    if len(lines) == 1:
        bbox = FONT_SUBTITLE.getbbox(lines[0])
        tx = (1080 - (bbox[2] - bbox[0])) // 2
        draw.text((tx, box_y1 + 52), lines[0], font=FONT_SUBTITLE, fill=(255, 255, 255))
    else:
        for idx, line in enumerate(lines[:2]):
            bbox = FONT_SUBTITLE.getbbox(line)
            tx = (1080 - (bbox[2] - bbox[0])) // 2
            draw.text((tx, box_y1 + 30 + idx * 44), line, font=FONT_SUBTITLE, fill=(255, 255, 255))

def draw_bottom_nav(draw, active_index=0):
    nav_y = 1575
    draw.rectangle([0, nav_y, 1080, nav_y + 115], fill=(255, 255, 255))
    draw.line([0, nav_y, 1080, nav_y], fill=C_BORDER, width=2)
    
    items = ["Beranda", "Surat", "Status", "Profil"]
    sec_w = 1080 // 4
    for idx, label in enumerate(items):
        cx = idx * sec_w + sec_w // 2
        is_act = (idx == active_index)
        col = C_PRIMARY if is_act else C_TEXT_MUTED
        font = FONT_BOLD_S if is_act else FONT_REG_S
        
        # Icon
        if is_act:
            draw.ellipse([cx - 20, nav_y + 18, cx + 20, nav_y + 58], fill=C_PRIMARY)
            draw.ellipse([cx - 8, nav_y + 30, cx + 8, nav_y + 46], fill=(255, 255, 255))
        else:
            draw.ellipse([cx - 16, nav_y + 22, cx + 16, nav_y + 54], outline=col, width=3)
            
        bbox = font.getbbox(label)
        draw.text((cx - (bbox[2] - bbox[0]) // 2, nav_y + 68), label, font=font, fill=col)

def add_touch(img, x, y, radius=40):
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    d.ellipse([x - radius, y - radius, x + radius, y + radius], fill=(0, 74, 173, 90), outline=(0, 74, 173, 230), width=4)
    d.ellipse([x - 14, y - 14, x + 14, y + 14], fill=(255, 255, 255, 250))
    return Image.alpha_composite(img.convert("RGBA"), overlay)

def draw_snackbar(draw, text, is_success=True, top_pos=False):
    bg_col = C_GREEN if is_success else C_RED
    y = 200 if top_pos else 1470
    draw.rounded_rectangle([70, y, 1010, y + 75], radius=16, fill=bg_col)
    # Checkmark circle
    draw.ellipse([95, y + 18, 135, y + 58], fill=(255, 255, 255))
    draw.text((106, y + 22), "✓", font=FONT_BOLD_M, fill=bg_col)
    draw.text((155, y + 20), text, font=FONT_SB_M, fill=(255, 255, 255))

print("Helper setup complete.")
