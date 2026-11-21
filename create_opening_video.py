import os, sys, math, subprocess
from PIL import Image, ImageDraw, ImageFont
import imageio_ffmpeg

WIDTH = 1080
HEIGHT = 1920
FPS = 30
DUR = 18.91
TOTAL_FRAMES = int(math.ceil(FPS * DUR))

ffmpeg_bin = imageio_ffmpeg.get_ffmpeg_exe()
base_img_path = "tutorial-video/screen_01_opening.png"
base_img = Image.open(base_img_path).convert("RGB")

FONT_PATH = "assets/fonts/Poppins-SemiBold.ttf"
FONT_BOLD = "assets/fonts/Poppins-Bold.ttf"
font_sub = ImageFont.truetype(FONT_PATH, 32)
font_sub_bold = ImageFont.truetype(FONT_BOLD, 34)

# Subtitle segments for Scene 1 (Pembukaan)
subtitles = [
    (0.8, 6.5, "Halo masyarakat Desa Rambipuji! Selamat datang dalam video panduan resmi penggunaan Aplikasi Mobile Desa Rambipuji."),
    (6.6, 14.8, "Melalui aplikasi ini, warga dapat mengurus berbagai administrasi persuratan dan menyampaikan aspirasi secara mandiri, transparan, dan mudah."),
    (14.9, 18.8, "Mari kita simak panduan lengkap setiap fiturnya dari awal hingga akhir.")
]

def get_current_subtitle(t):
    for start, end, text in subtitles:
        if start <= t <= end:
            return text
    return None

def draw_subtitle_box(draw, text, width, y_pos):
    # Split text into lines if too long
    words = text.split()
    lines = []
    curr = []
    for w in words:
        curr.append(w)
        test_line = " ".join(curr)
        bbox = draw.textbbox((0, 0), test_line, font=font_sub)
        if (bbox[2] - bbox[0]) > (width - 160):
            curr.pop()
            lines.append(" ".join(curr))
            curr = [w]
    if curr:
        lines.append(" ".join(curr))

    line_height = 42
    total_h = len(lines) * line_height + 28
    box_top = y_pos - total_h // 2
    box_bottom = box_top + total_h

    # Semi-transparent dark blue pill
    overlay = Image.new("RGBA", (width, HEIGHT), (0, 0, 0, 0))
    ov_draw = ImageDraw.Draw(overlay)
    
    # Calculate max width of lines
    max_w = max(draw.textbbox((0, 0), l, font=font_sub)[2] - draw.textbbox((0, 0), l, font=font_sub)[0] for l in lines)
    box_left = (width - max_w) // 2 - 30
    box_right = (width + max_w) // 2 + 30

    ov_draw.rounded_rectangle([box_left, box_top, box_right, box_bottom], radius=24, fill=(10, 25, 47, 215), outline=(255, 255, 255, 120), width=2)

    for i, line in enumerate(lines):
        line_bbox = draw.textbbox((0, 0), line, font=font_sub)
        lw = line_bbox[2] - line_bbox[0]
        lx = (width - lw) // 2
        ly = box_top + 14 + i * line_height
        ov_draw.text((lx, ly), line, font=font_sub, fill=(255, 255, 255, 255))
        
    return overlay

def render_frame(frame_idx):
    t = frame_idx / FPS
    
    # Subtle cinematic Ken Burns effect (smooth zoom 1.00 -> 1.025)
    progress = t / DUR
    scale = 1.0 + 0.025 * math.sin(progress * math.pi * 0.5)
    
    new_w = int(WIDTH * scale)
    new_h = int(HEIGHT * scale)
    scaled_img = base_img.resize((new_w, new_h), Image.Resampling.BILINEAR)
    
    # Center crop back to 1080x1920
    crop_x = (new_w - WIDTH) // 2
    crop_y = int((new_h - HEIGHT) * 0.35) # focus slightly upper
    frame = scaled_img.crop((crop_x, crop_y, crop_x + WIDTH, crop_y + HEIGHT))

    # Fade in at start (first 0.6 seconds)
    if t < 0.6:
        fade = t / 0.6
        black = Image.new("RGB", (WIDTH, HEIGHT), (0, 0, 0))
        frame = Image.blend(black, frame, fade)

    # Subtitles
    sub_text = get_current_subtitle(t)
    if sub_text:
        draw_temp = ImageDraw.Draw(frame)
        sub_overlay = draw_subtitle_box(draw_temp, sub_text, WIDTH, 1750)
        frame_rgba = frame.convert("RGBA")
        frame = Image.alpha_composite(frame_rgba, sub_overlay).convert("RGB")

    return frame

def generate_video():
    out_file = "tutorial-video/raw_01_pembukaan.mp4"
    audio_file = "tutorial-video/audio_01_pembukaan.mp3"
    
    print(f"Generating opening video: {out_file} ({TOTAL_FRAMES} frames)...")
    
    cmd = [
        ffmpeg_bin, "-y",
        "-f", "rawvideo",
        "-vcodec", "rawvideo",
        "-s", f"{WIDTH}x{HEIGHT}",
        "-pix_fmt", "rgb24",
        "-r", str(FPS),
        "-i", "-",
        "-i", audio_file,
        "-c:v", "libx264",
        "-preset", "medium",
        "-crf", "18",
        "-pix_fmt", "yuv420p",
        "-c:a", "aac",
        "-b:a", "192k",
        "-shortest",
        out_file
    ]
    
    proc = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    
    for i in range(TOTAL_FRAMES):
        frame = render_frame(i)
        proc.stdin.write(frame.tobytes())
        if i % 60 == 0:
            print(f"Rendered {i}/{TOTAL_FRAMES} frames ({(i/TOTAL_FRAMES)*100:.1f}%)")
            
    proc.stdin.close()
    proc.wait()
    print(f"Done! Created: {out_file}, Size: {os.path.getsize(out_file)} bytes")

if __name__ == "__main__":
    generate_video()

