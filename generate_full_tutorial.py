import os
import subprocess
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import imageio_ffmpeg

FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()

WIDTH, HEIGHT = 1080, 1920
FPS = 30

# Colors
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

def draw_snackbar(draw, text, is_success=True, y=1470):
    bg_col = C_GREEN if is_success else C_RED
    draw.rounded_rectangle([60, y, 1020, y + 80], radius=16, fill=bg_col)
    draw.ellipse([85, y + 20, 125, y + 60], fill=(255, 255, 255))
    draw.text((96, y + 24), "✓", font=FONT_BOLD_M, fill=bg_col)
    draw.text((145, y + 23), text, font=FONT_SB_M, fill=(255, 255, 255))

# ==================== SCENE RENDERERS ====================

# SCENE 1: PEMBUKAAN (18.91s)
def render_frame_scene1(t, dur):
    img = Image.new("RGB", (WIDTH, HEIGHT), (10, 25, 47))
    draw = ImageDraw.Draw(img)
    
    # Background gradient styling
    for y in range(HEIGHT):
        ratio = y / HEIGHT
        r = int(10 + ratio * 0)
        g = int(25 + ratio * 45)
        b = int(47 + ratio * 120)
        draw.line([(0, y), (WIDTH, y)], fill=(r, g, b))
        
    draw_status_bar(draw, dark=False)
    
    # Title & Badge
    draw.rounded_rectangle([320, 230, 760, 290], radius=30, fill=C_SECONDARY)
    draw.text((365, 245), "PANDUAN RESMI 2026", font=FONT_BOLD_M, fill=(255, 255, 255))
    
    # App Logo centered
    logo_w = 400
    logo_h = int(LOGO_DESA.height * (logo_w / LOGO_DESA.width))
    logo_resized = LOGO_DESA.resize((logo_w, logo_h), Image.Resampling.LANCZOS)
    img.paste(logo_resized, ((WIDTH - logo_w) // 2, 330), logo_resized)
    
    # Titles
    draw.text((105, 590), "APLIKASI DESA RAMBIPUJI", font=FONT_BOLD_XL, fill=(255, 255, 255))
    draw.text((230, 660), "TUTORIAL PENGGUNAAN ROLE WARGA", font=FONT_SB_L, fill=(147, 197, 253))
    
    # Info Cards
    card_data = [
        ("🔐 Aktivasi & Keamanan Akun", "Aktivasi mandiri akun warga berbasis NIK kependudukan desa"),
        ("📄 Pelayanan Surat Digital", "Pengajuan surat administrasi praktis tanpa antre di kantor desa"),
        ("⏱️ Monitoring Real-Time", "Pantau tahapan verifikasi Kadus, Sekdes, hingga tanda tangan Kades"),
        ("📢 Layanan Aspirasi & Aduan", "Sampaikan laporan lingkungan dan pengaduan langsung ke perangkat desa")
    ]
    
    cy = 760
    for icon_title, desc in card_data:
        draw.rounded_rectangle([80, cy, 1000, cy + 175], radius=20, fill=(255, 255, 255, 240))
        draw.text((120, cy + 25), icon_title, font=FONT_BOLD_M, fill=C_PRIMARY)
        draw.text((120, cy + 75), desc, font=FONT_REG_M, fill=C_TEXT_DARK)
        cy += 205
        
    # Subtitle
    if t < 6.5:
        sub = "Halo masyarakat Desa Rambipuji! Selamat datang dalam video panduan resmi penggunaan Aplikasi Mobile Desa Rambipuji."
    else:
        sub = "Melalui aplikasi ini, warga dapat mengurus berbagai administrasi persuratan dan menyampaikan aspirasi secara cepat, transparan, dan mudah."
    draw_subtitle_box(draw, sub)
    
    return img

# SCENE 2: AKTIVASI AKUN WARGA (41.95s)
def render_frame_scene2(t, dur):
    img = Image.new("RGB", (WIDTH, HEIGHT), C_BG)
    draw = ImageDraw.Draw(img)
    draw_status_bar(draw, dark=True)
    draw_top_banner(draw, "BAGIAN 1", "AKTIVASI AKUN WARGA")
    
    # App Bar
    draw.rectangle([0, 185, 1080, 275], fill=(255, 255, 255))
    draw.line([0, 275, 1080, 275], fill=C_BORDER, width=2)
    # Back arrow
    draw.polygon([(65, 230), (85, 215), (85, 245)], fill=C_TEXT_DARK)
    draw.text((115, 212), "Aktivasi Akun Warga", font=FONT_BOLD_L, fill=C_TEXT_DARK)
    
    # Avatar Circle
    draw.ellipse([490, 310, 590, 410], fill=C_BLUE_LIGHT)
    draw.ellipse([525, 335, 555, 365], fill=C_PRIMARY)
    draw.pieslice([510, 365, 570, 415], 180, 360, fill=C_PRIMARY)
    
    draw.text((410, 425), "Aktivasi Akun Baru", font=FONT_BOLD_L, fill=C_TEXT_DARK)
    draw.text((250, 475), "Masukkan NIK terdaftar di desa untuk mengaktifkan akun", font=FONT_REG_M, fill=C_TEXT_MUTED)
    
    # Yellow warning notice
    draw.rounded_rectangle([70, 525, 1010, 605], radius=14, fill=C_YELLOW_BG, outline=C_YELLOW_BORDER, width=2)
    draw.text((100, 550), "ℹ️  Hanya warga terdaftar di data desa yang dapat mendaftar.", font=FONT_SB_S, fill=C_YELLOW_TEXT)
    
    # Form Card
    draw.rounded_rectangle([70, 625, 1010, 1375], radius=24, fill=C_CARD, outline=C_BORDER, width=2)
    
    # Inputs typing simulation
    nik_str = "3509121508900001"
    email_str = "warga.rambipuji@gmail.com"
    hp_str = "081234567890"
    
    # Progressive typing
    nik_prog = nik_str[:min(len(nik_str), int((t - 6) * 4))] if t > 6 else ""
    email_prog = email_str[:min(len(email_str), int((t - 14) * 4))] if t > 14 else ""
    hp_prog = hp_str[:min(len(hp_str), int((t - 20) * 4))] if t > 20 else ""
    pw_prog = "••••••••••••" if t > 26 else ""
    pw2_prog = "••••••••••••" if t > 28 else ""
    
    fields = [
        ("NIK Kependudukan (16 digit)", nik_prog, 660, "Contoh: 3509xxxxxxxxxxxx"),
        ("Email Aktif", email_prog, 800, "Contoh: nama@gmail.com"),
        ("No. WhatsApp / HP", hp_prog, 940, "Contoh: 0812xxxxxxxx"),
        ("Password Baru", pw_prog, 1080, "Minimal 8 karakter (huruf besar, kecil, angka)"),
        ("Konfirmasi Password", pw2_prog, 1220, "Ketik ulang password")
    ]
    
    for label, val, fy, hint in fields:
        draw.text((105, fy), label, font=FONT_SB_S, fill=C_TEXT_DARK)
        draw.rounded_rectangle([105, fy + 35, 975, fy + 105], radius=12, fill=(248, 250, 252), outline=C_PRIMARY if val else C_BORDER, width=2)
        if val:
            draw.text((125, fy + 52), val, font=FONT_REG_M, fill=C_TEXT_DARK)
        else:
            draw.text((125, fy + 52), hint, font=FONT_REG_XS, fill=C_TEXT_MUTED)
            
    # Button Aktifkan Akun
    btn_y = 1410
    draw.rounded_rectangle([70, btn_y, 1010, btn_y + 85], radius=18, fill=C_PRIMARY)
    draw.text((430, btn_y + 24), "Aktifkan Akun", font=FONT_BOLD_L, fill=(255, 255, 255))
    
    # Touch click at t ~ 33s
    if 32.5 <= t <= 34.5:
        img = add_touch(img, 540, btn_y + 42)
        draw = ImageDraw.Draw(img)
        
    # Snackbar appears after click
    if t >= 34.0:
        draw_snackbar(draw, "Akun berhasil diaktivasi! Silakan login.", is_success=True, y=1520)
        
    # Subtitles
    if t < 5.0:
        sub = "Bagi warga yang baru pertama kali menggunakan aplikasi, langkah awal adalah melakukan aktivasi akun."
    elif t < 12.0:
        sub = "Pada halaman login, pilih opsi 'Aktivasi Akun'. Pastikan NIK Anda sudah terdaftar di data kependudukan desa."
    elif t < 22.0:
        sub = "Masukkan 16 digit NIK Anda, alamat email aktif, dan nomor WhatsApp yang dapat dihubungi."
    elif t < 32.0:
        sub = "Buat kata sandi minimal delapan karakter yang memuat huruf besar, huruf kecil, dan angka."
    else:
        sub = "Tekan 'Aktifkan Akun'. Sistem memverifikasi data kependudukan secara otomatis dan akun langsung aktif!"
        
    draw_subtitle_box(draw, sub)
    return img

# SCENE 3: LOGIN & DASHBOARD WARGA (31.61s)
def render_frame_scene3(t, dur):
    img = Image.new("RGB", (WIDTH, HEIGHT), C_BG)
    draw = ImageDraw.Draw(img)
    draw_status_bar(draw, dark=True)
    draw_top_banner(draw, "BAGIAN 2", "LOGIN & DASHBOARD WARGA")
    
    if t < 8.0:
        # Tampilkan Halaman Login
        draw.rectangle([0, 185, 1080, 275], fill=(255, 255, 255))
        draw.text((430, 212), "Masuk Akun", font=FONT_BOLD_L, fill=C_TEXT_DARK)
        
        # Logo Icon
        logo_w = 200
        logo_h = int(LOGO_APP.height * (logo_w / LOGO_APP.width))
        logo_resized = LOGO_APP.resize((logo_w, logo_h), Image.Resampling.LANCZOS)
        img.paste(logo_resized, ((WIDTH - logo_w) // 2, 340), logo_resized)
        
        draw.text((360, 560), "Desa Rambipuji", font=FONT_BOLD_XL, fill=C_PRIMARY)
        draw.text((350, 620), "Silakan masuk ke akun Anda", font=FONT_REG_M, fill=C_TEXT_MUTED)
        
        # Form Login
        draw.rounded_rectangle([70, 690, 1010, 1050], radius=24, fill=C_CARD, outline=C_BORDER, width=2)
        
        draw.text((110, 725), "NIK / Email", font=FONT_SB_S, fill=C_TEXT_DARK)
        draw.rounded_rectangle([110, 760, 970, 830], radius=12, fill=(248, 250, 252), outline=C_BORDER, width=2)
        draw.text((130, 778), "3509121508900001", font=FONT_REG_M, fill=C_TEXT_DARK)
        
        draw.text((110, 860), "Password", font=FONT_SB_S, fill=C_TEXT_DARK)
        draw.rounded_rectangle([110, 895, 970, 965], radius=12, fill=(248, 250, 252), outline=C_BORDER, width=2)
        draw.text((130, 915), "••••••••••••", font=FONT_REG_M, fill=C_TEXT_DARK)
        
        # Button Masuk
        draw.rounded_rectangle([70, 1090, 1010, 1175], radius=18, fill=C_PRIMARY)
        draw.text((490, 1114), "Masuk", font=FONT_BOLD_L, fill=(255, 255, 255))
        
        if t >= 6.0:
            img = add_touch(img, 540, 1132)
            draw = ImageDraw.Draw(img)
            
        sub = "Setelah akun aktif, Anda dapat langsung masuk dengan memasukkan NIK atau email dan kata sandi Anda."
    else:
        # Dashboard Warga
        # Header Warga
        draw.rectangle([0, 185, 1080, 360], fill=(255, 255, 255))
        draw.line([0, 360, 1080, 360], fill=C_BORDER, width=2)
        
        # Avatar
        draw.ellipse([70, 220, 160, 310], fill=C_BLUE_LIGHT)
        draw.ellipse([95, 235, 135, 275], fill=C_PRIMARY)
        draw.pieslice([80, 275, 150, 330], 180, 360, fill=C_PRIMARY)
        
        draw.text((185, 230), "Selamat Datang,", font=FONT_REG_S, fill=C_TEXT_MUTED)
        draw.text((185, 260), "Budi Santoso", font=FONT_BOLD_L, fill=C_PRIMARY)
        draw.text((185, 305), "Warga Dusun Krajan • RT 02 RW 05", font=FONT_REG_XS, fill=C_TEXT_MUTED)
        
        # Notif & Profile icons
        draw.ellipse([950, 240, 1010, 300], fill=C_BG, outline=C_BORDER, width=2)
        draw.text((970, 255), "🔔", font=FONT_BOLD_S, fill=C_PRIMARY)
        
        # Stats summary card (blue gradient)
        draw.rounded_rectangle([50, 390, 1030, 620], radius=24, fill=C_PRIMARY)
        draw.text((80, 420), "Ringkasan Permohonan Surat & Pengaduan", font=FONT_SB_M, fill=(255, 255, 255))
        
        stats = [
            ("1", "Diajukan", C_BLUE_LIGHT),
            ("2", "Selesai", C_GREEN_BG),
            ("0", "Ditolak", (254, 226, 226)),
            ("1", "Pengaduan", (254, 243, 199))
        ]
        
        sw = (980 - 60) // 4
        for idx, (cnt, lbl, bg) in enumerate(stats):
            sx = 75 + idx * (sw + 10)
            draw.rounded_rectangle([sx, 470, sx + sw, 590], radius=16, fill=bg)
            draw.text((sx + 35, 485), cnt, font=FONT_BOLD_XL, fill=C_TEXT_DARK)
            draw.text((sx + 15, 545), lbl, font=FONT_SB_S, fill=C_TEXT_DARK)
            
        # Menu Layanan Utama
        draw.text((60, 655), "Menu Layanan Utama", font=FONT_BOLD_L, fill=C_TEXT_DARK)
        
        menu_items = [
            ("📄 Layanan Surat", "Pengajuan surat administrasi desa online", C_BLUE_LIGHT, C_PRIMARY),
            ("⏱️ Status Surat", "Tracking proses persetujuan real-time", C_GREEN_BG, (22, 101, 52)),
            ("📢 Pengaduan Warga", "Sampaikan aspirasi & laporan lingkungan", (254, 243, 199), (180, 83, 9)),
            ("📜 Riwayat Aduan", "Pantau tanggapan pengaduan Anda", (243, 232, 255), (107, 33, 168))
        ]
        
        my = 715
        for m_title, m_desc, m_bg, m_txt in menu_items:
            draw.rounded_rectangle([60, my, 1020, my + 175], radius=20, fill=C_CARD, outline=C_BORDER, width=2)
            # icon box
            draw.rounded_rectangle([90, my + 25, 210, my + 145], radius=16, fill=m_bg)
            draw.text((120, my + 60), m_title.split()[0], font=FONT_BOLD_L, fill=m_txt)
            
            draw.text((235, my + 40), m_title.split(' ', 1)[1], font=FONT_BOLD_M, fill=C_TEXT_DARK)
            draw.text((235, my + 85), m_desc, font=FONT_REG_M, fill=C_TEXT_MUTED)
            # Arrow
            draw.text((950, my + 65), "➔", font=FONT_BOLD_L, fill=C_BORDER)
            my += 205
            
        draw_bottom_nav(draw, active_index=0)
        
        if t < 15.0:
            sub = "Pada dashboard utama, Anda disambut dengan nama lengkap Anda sesuai data kependudukan desa."
        elif t < 23.0:
            sub = "Tersedia kartu ringkasan status surat: permohonan yang diajukan, selesai, ditolak, serta total pengaduan."
        else:
            sub = "Anda dapat langsung mengakses menu utama seperti Pengajuan Surat, Monitoring Status, dan Layanan Pengaduan."
            
    draw_subtitle_box(draw, sub)
    return img

# SCENE 4: PENGAJUAN SURAT ADMINISTRASI (36.29s)
def render_frame_scene4(t, dur):
    img = Image.new("RGB", (WIDTH, HEIGHT), C_BG)
    draw = ImageDraw.Draw(img)
    draw_status_bar(draw, dark=True)
    draw_top_banner(draw, "BAGIAN 3", "PENGAJUAN SURAT ADMINISTRASI")
    
    if t < 12.0:
        # Surat List Screen
        draw.rectangle([0, 185, 1080, 275], fill=(255, 255, 255))
        draw.text((70, 215), "JENIS LAYANAN SURAT", font=FONT_BOLD_L, fill=C_PRIMARY)
        
        surat_types = [
            ("Surat Pengantar SKCK", "Surat pengantar catatan kepolisian untuk melamar kerja / instansi", True),
            ("Surat Keterangan Usaha (SKU)", "Surat keterangan izin legalitas usaha mikro/kecil warga desa", False),
            ("Surat Keterangan Domisili", "Keterangan bukti kependudukan domisili tempat tinggal warga", False),
            ("Surat Keterangan Tidak Mampu (SKTM)", "Keterangan bantuan sosial, beasiswa pendidikan, dan kesehatan", False),
            ("Surat Keterangan Kelahiran", "Pengantar pengurusan akta kelahiran anak ke disdukcapil", False)
        ]
        
        sy = 305
        for title, desc, active in surat_types:
            draw.rounded_rectangle([60, sy, 1020, sy + 185], radius=20, fill=C_CARD, outline=C_PRIMARY if active else C_BORDER, width=2)
            draw.ellipse([95, sy + 35, 165, sy + 105], fill=C_BLUE_LIGHT if active else C_BG)
            draw.text((115, sy + 48), "📄", font=FONT_BOLD_M, fill=C_PRIMARY)
            
            draw.text((185, sy + 35), title, font=FONT_BOLD_M, fill=C_PRIMARY if active else C_TEXT_DARK)
            draw.text((185, sy + 80), desc, font=FONT_REG_S, fill=C_TEXT_MUTED)
            draw.rounded_rectangle([860, sy + 60, 980, sy + 110], radius=12, fill=C_PRIMARY if active else C_BG)
            draw.text((885, sy + 72), "Ajukan", font=FONT_BOLD_S, fill=(255, 255, 255) if active else C_TEXT_MUTED)
            sy += 210
            
        draw_bottom_nav(draw, active_index=1)
        
        # Tap on first item
        if t >= 9.0:
            img = add_touch(img, 920, 390)
            draw = ImageDraw.Draw(img)
            
        if t < 6.0:
            sub = "Untuk mengajukan surat, pilih menu 'Layanan Surat'. Di sini tersedia berbagai pilihan layanan persuratan desa."
        else:
            sub = "Pilih jenis surat yang Anda butuhkan, seperti Surat Pengantar SKCK, SKU, atau Domisili."
    else:
        # Form Pengajuan Screen
        draw.rectangle([0, 185, 1080, 275], fill=(255, 255, 255))
        draw.text((70, 215), "Form Pengajuan: Surat Pengantar SKCK", font=FONT_BOLD_M, fill=C_TEXT_DARK)
        
        # Pemohon Profile card (auto-filled)
        draw.rounded_rectangle([60, 295, 1020, 520], radius=20, fill=C_CARD, outline=C_BORDER, width=2)
        draw.text((90, 320), "IDENTITAS PEMOHON (OTOMATIS TERISI)", font=FONT_BOLD_S, fill=C_PRIMARY)
        draw.text((90, 365), "Nama Pemohon   : Budi Santoso", font=FONT_SB_M, fill=C_TEXT_DARK)
        draw.text((90, 410), "NIK                    : 3509121508900001", font=FONT_REG_M, fill=C_TEXT_DARK)
        draw.text((90, 455), "Alamat               : RT 02 RW 05 Dusun Krajan, Desa Rambipuji", font=FONT_REG_M, fill=C_TEXT_MUTED)
        
        # Keperluan input
        draw.rounded_rectangle([60, 545, 1020, 840], radius=20, fill=C_CARD, outline=C_BORDER, width=2)
        draw.text((90, 575), "KEPERLUAN PENGAJUAN SURAT *", font=FONT_BOLD_S, fill=C_PRIMARY)
        
        text_isi = "Persyaratan Melamar Pekerjaan di BUMN PT Kereta Api Indonesia"
        cur_isi = text_isi[:min(len(text_isi), int((t - 14) * 4))] if t > 14 else ""
        draw.rounded_rectangle([90, 615, 990, 740], radius=14, fill=(248, 250, 252), outline=C_PRIMARY, width=2)
        draw.text((115, 645), cur_isi, font=FONT_REG_M, fill=C_TEXT_DARK)
        draw.text((90, 765), "Jelaskan tujuan dan keperluan pembuatan surat secara jelas dan lengkap.", font=FONT_REG_XS, fill=C_TEXT_MUTED)
        
        # Lampiran Berkas Persyaratan
        draw.rounded_rectangle([60, 865, 1020, 1330], radius=20, fill=C_CARD, outline=C_BORDER, width=2)
        draw.text((90, 895), "LAMPIRAN BERKAS PERSYARATAN (FOTO)", font=FONT_BOLD_S, fill=C_PRIMARY)
        
        # 2 Upload boxes
        draw.rounded_rectangle([90, 945, 520, 1220], radius=16, fill=C_GREEN_BG, outline=C_GREEN, width=2)
        draw.text((190, 1010), "📷", font=FONT_BOLD_XL, fill=C_GREEN)
        draw.text((170, 1080), "Foto KTP Asli", font=FONT_BOLD_M, fill=C_TEXT_DARK)
        draw.text((180, 1125), "✓ Terlampir", font=FONT_BOLD_S, fill=C_GREEN)
        
        draw.rounded_rectangle([560, 945, 990, 1220], radius=16, fill=C_GREEN_BG, outline=C_GREEN, width=2)
        draw.text((660, 1010), "📷", font=FONT_BOLD_XL, fill=C_GREEN)
        draw.text((620, 1080), "Foto Kartu Keluarga", font=FONT_BOLD_M, fill=C_TEXT_DARK)
        draw.text((650, 1125), "✓ Terlampir", font=FONT_BOLD_S, fill=C_GREEN)
        
        draw.text((90, 1255), "Ukuran berkas maksimal 5MB (Format JPG/PNG). Pastikan tulisan terbaca jelas.", font=FONT_REG_XS, fill=C_TEXT_MUTED)
        
        # Kirim Button
        btn_y = 1365
        draw.rounded_rectangle([60, btn_y, 1020, btn_y + 85], radius=18, fill=C_PRIMARY)
        draw.text((410, btn_y + 24), "Kirim Pengajuan Surat", font=FONT_BOLD_L, fill=(255, 255, 255))
        
        if 28.0 <= t <= 30.5:
            img = add_touch(img, 540, btn_y + 42)
            draw = ImageDraw.Draw(img)
            
        if t >= 30.0:
            draw_snackbar(draw, "Pengajuan surat berhasil dikirim ke kantor desa!", is_success=True, y=1475)
            
        if t < 22.0:
            sub = "Data diri pemohon terisi otomatis. Tuliskan keperluan pengajuan surat Anda secara jelas."
        elif t < 30.0:
            sub = "Unggah dokumen persyaratan yang diminta, seperti foto Kartu Tanda Penduduk atau Kartu Keluarga."
        else:
            sub = "Periksa kelengkapan formulir dan tekan 'Kirim Pengajuan'. Surat Anda langsung tercatat di sistem desa!"
            
    draw_subtitle_box(draw, sub)
    return img

# SCENE 5: MONITORING STATUS SURAT (37.49s)
def render_frame_scene5(t, dur):
    img = Image.new("RGB", (WIDTH, HEIGHT), C_BG)
    draw = ImageDraw.Draw(img)
    draw_status_bar(draw, dark=True)
    draw_top_banner(draw, "BAGIAN 4", "MONITORING TAHAPAN SURAT")
    
    # App Bar
    draw.rectangle([0, 185, 1080, 275], fill=(255, 255, 255))
    draw.text((70, 215), "STATUS PENGAJUAN SURAT", font=FONT_BOLD_L, fill=C_PRIMARY)
    
    # Tabs
    is_selesai_tab = (t >= 25.0)
    draw.rectangle([0, 275, 1080, 365], fill=(255, 255, 255))
    draw.line([0, 365, 1080, 365], fill=C_BORDER, width=2)
    
    # Tab 1: Diajukan
    col1 = C_TEXT_MUTED if is_selesai_tab else C_PRIMARY
    draw.text((110, 305), "Diajukan (1)", font=FONT_BOLD_M, fill=col1)
    if not is_selesai_tab:
        draw.rectangle([70, 357, 330, 365], fill=C_PRIMARY)
        
    # Tab 2: Selesai
    col2 = C_PRIMARY if is_selesai_tab else C_TEXT_MUTED
    draw.text((450, 305), "Selesai (2)", font=FONT_BOLD_M, fill=col2)
    if is_selesai_tab:
        draw.rectangle([410, 357, 670, 365], fill=C_PRIMARY)
        
    # Tab 3: Ditolak
    draw.text((790, 305), "Ditolak (0)", font=FONT_BOLD_M, fill=C_TEXT_MUTED)
    
    if not is_selesai_tab:
        # Card Permohonan Diajukan
        draw.rounded_rectangle([60, 395, 1020, 1500], radius=24, fill=C_CARD, outline=C_BORDER, width=2)
        
        # Header inside card
        draw.text((95, 430), "Surat Pengantar SKCK", font=FONT_BOLD_L, fill=C_PRIMARY)
        draw.text((95, 480), "No. Registrasi: REG-2026-SKCK-042", font=FONT_SB_S, fill=C_TEXT_MUTED)
        draw.text((95, 515), "Diajukan: 16 November 2026 • 09:30 WIB", font=FONT_REG_S, fill=C_TEXT_MUTED)
        draw.line([95, 560, 985, 560], fill=C_BORDER, width=2)
        
        # Timeline Steps
        draw.text((95, 585), "Tahapan Verifikasi Berjenjang:", font=FONT_BOLD_M, fill=C_TEXT_DARK)
        
        steps = [
            ("1. Pengajuan Masuk (Warga)", "Berkas persyaratan berhasil dikirimkan", True, False),
            ("2. Persetujuan Kepala Dusun (Kadus)", "Disetujui oleh Kepala Dusun Krajan", True, False),
            ("3. Paraf Sekretaris Desa (Sekdes)", "Sedang dalam verifikasi data oleh Sekdes", False, True),
            ("4. Persetujuan & Tanda Tangan Kades", "Menunggu tanda tangan digital Kepala Desa", False, False)
        ]
        
        ty = 650
        for idx, (s_title, s_desc, done, active) in enumerate(steps):
            # circle indicator
            cx, cy = 135, ty + 25
            if done:
                draw.ellipse([cx - 20, cy - 20, cx + 20, cy + 20], fill=C_GREEN)
                draw.text((cx - 8, cy - 14), "✓", font=FONT_BOLD_S, fill=(255, 255, 255))
            elif active:
                draw.ellipse([cx - 20, cy - 20, cx + 20, cy + 20], fill=C_PRIMARY)
                draw.ellipse([cx - 8, cy - 8, cx + 8, cy + 8], fill=(255, 255, 255))
            else:
                draw.ellipse([cx - 18, cy - 18, cx + 18, cy + 18], fill=C_BG, outline=C_BORDER, width=3)
                
            # Connecting line
            if idx < 3:
                draw.line([(cx, cy + 22), (cx, cy + 85)], fill=C_GREEN if done else C_BORDER, width=4)
                
            draw.text((185, ty + 10), s_title, font=FONT_BOLD_M, fill=C_PRIMARY if active else (C_TEXT_DARK if done else C_TEXT_MUTED))
            draw.text((185, ty + 50), s_desc, font=FONT_REG_S, fill=C_GREEN if done else (C_PRIMARY if active else C_TEXT_MUTED))
            
            ty += 115
            
        # Status Box at bottom of card
        draw.rounded_rectangle([95, 1140, 985, 1260], radius=16, fill=C_BLUE_LIGHT)
        draw.text((125, 1165), "Status Terkini: Sedang Diproses Sekretaris Desa", font=FONT_BOLD_M, fill=C_PRIMARY)
        draw.text((125, 1210), "Estimasi selesai: 1 x 24 Jam kerja.", font=FONT_REG_M, fill=C_TEXT_MUTED)
        
        # Tab switch touch at t = 23.5s
        if 23.0 <= t <= 25.0:
            img = add_touch(img, 540, 330)
            draw = ImageDraw.Draw(img)
    else:
        # Selesai Tab View
        draw.rounded_rectangle([60, 395, 1020, 780], radius=24, fill=C_CARD, outline=C_BORDER, width=2)
        draw.text((95, 430), "Surat Keterangan Domisili", font=FONT_BOLD_L, fill=C_TEXT_DARK)
        draw.text((95, 480), "No: 470/118/414.312/2026 • Selesai: 14 Nov 2026", font=FONT_REG_S, fill=C_TEXT_MUTED)
        
        draw.rounded_rectangle([95, 530, 240, 580], radius=12, fill=C_GREEN_BG)
        draw.text((125, 543), "✓ SELESAI", font=FONT_BOLD_S, fill=C_GREEN)
        
        draw.rounded_rectangle([95, 610, 985, 710], radius=16, fill=C_PRIMARY)
        draw.text((330, 642), "📥 Unduh Surat Digital (PDF)", font=FONT_BOLD_M, fill=(255, 255, 255))
        
        draw.rounded_rectangle([60, 815, 1020, 1200], radius=24, fill=C_CARD, outline=C_BORDER, width=2)
        draw.text((95, 850), "Surat Keterangan Usaha (SKU)", font=FONT_BOLD_L, fill=C_TEXT_DARK)
        draw.text((95, 900), "No: 503/084/414.312/2026 • Selesai: 10 Nov 2026", font=FONT_REG_S, fill=C_TEXT_MUTED)
        draw.rounded_rectangle([95, 950, 240, 1000], radius=12, fill=C_GREEN_BG)
        draw.text((125, 963), "✓ SELESAI", font=FONT_BOLD_S, fill=C_GREEN)
        draw.rounded_rectangle([95, 1030, 985, 1130], radius=16, fill=C_PRIMARY)
        draw.text((330, 1062), "📥 Unduh Surat Digital (PDF)", font=FONT_BOLD_M, fill=(255, 255, 255))
        
    draw_bottom_nav(draw, active_index=2)
    
    if t < 8.0:
        sub = "Buka menu 'Status' untuk memantau kemajuan surat Anda secara realtime tanpa perlu bolak-balik ke kantor desa."
    elif t < 18.0:
        sub = "Terdapat garis waktu verifikasi transparan: mulai dari Kepala Dusun, paraf Sekdes, hingga persetujuan Kepala Desa."
    elif t < 26.0:
        sub = "Setiap perubahan status dan catatan perangkat desa dapat langsung Anda lihat secara detail di layar."
    else:
        sub = "Jika surat telah selesai, Anda akan menerima pemberitahuan dan surat dapat langsung diunduh dalam format PDF!"
        
    draw_subtitle_box(draw, sub)
    return img

# SCENE 6: LAYANAN PENGADUAN WARGA (29.18s)
def render_frame_scene6(t, dur):
    img = Image.new("RGB", (WIDTH, HEIGHT), C_BG)
    draw = ImageDraw.Draw(img)
    draw_status_bar(draw, dark=True)
    draw_top_banner(draw, "BAGIAN 5", "LAYANAN PENGADUAN & ASPIRASI")
    
    draw.rectangle([0, 185, 1080, 275], fill=(255, 255, 255))
    draw.text((70, 215), "LAYANAN PENGADUAN WARGA", font=FONT_BOLD_L, fill=C_PRIMARY)
    
    # Form Card
    draw.rounded_rectangle([60, 295, 1020, 1420], radius=24, fill=C_CARD, outline=C_BORDER, width=2)
    
    # Dropdown Kategori
    draw.text((95, 330), "KATEGORI PENGADUAN *", font=FONT_BOLD_S, fill=C_PRIMARY)
    draw.rounded_rectangle([95, 370, 985, 450], radius=14, fill=(248, 250, 252), outline=C_PRIMARY, width=2)
    draw.text((125, 395), "Infrastruktur & Lingkungan", font=FONT_BOLD_M, fill=C_TEXT_DARK)
    draw.text((940, 395), "▼", font=FONT_BOLD_S, fill=C_PRIMARY)
    
    # Judul Pengaduan
    draw.text((95, 480), "JUDUL PENGADUAN *", font=FONT_BOLD_S, fill=C_PRIMARY)
    draw.rounded_rectangle([95, 520, 985, 600], radius=14, fill=(248, 250, 252), outline=C_BORDER, width=2)
    draw.text((125, 545), "Perbaikan Lampu Penerangan Jalan RT 02 RW 05", font=FONT_SB_M, fill=C_TEXT_DARK)
    
    # Deskripsi / Ulasan
    draw.text((95, 630), "URAIAN / DESKRIPSI PENGADUAN *", font=FONT_BOLD_S, fill=C_PRIMARY)
    draw.rounded_rectangle([95, 670, 985, 940], radius=14, fill=(248, 250, 252), outline=C_BORDER, width=2)
    
    desc_text = "Lampu penerangan jalan utama di RT 02 padam sejak 3 hari lalu. Mohon bantuan perbaikan dari perangkat desa demi keamanan warga di malam hari."
    draw.text((125, 695), desc_text[:min(len(desc_text), int((t - 5) * 5))] if t > 5 else "", font=FONT_REG_M, fill=C_TEXT_DARK)
    
    # Lampiran Foto Bukti
    draw.text((95, 970), "FOTO BUKTI / DOKUMENTASI LOKASI", font=FONT_BOLD_S, fill=C_PRIMARY)
    draw.rounded_rectangle([95, 1010, 520, 1260], radius=16, fill=C_GREEN_BG, outline=C_GREEN, width=2)
    draw.text((270, 1070), "📷", font=FONT_BOLD_XL, fill=C_GREEN)
    draw.text((170, 1145), "foto_lampu_padam.jpg", font=FONT_SB_S, fill=C_TEXT_DARK)
    draw.text((230, 1185), "✓ Terlampir (2.1 MB)", font=FONT_REG_XS, fill=C_GREEN)
    
    # Kirim button
    btn_y = 1300
    draw.rounded_rectangle([95, btn_y, 985, btn_y + 85], radius=18, fill=C_PRIMARY)
    draw.text((410, btn_y + 24), "Kirim Laporan Pengaduan", font=FONT_BOLD_M, fill=(255, 255, 255))
    
    if 21.0 <= t <= 23.5:
        img = add_touch(img, 540, btn_y + 42)
        draw = ImageDraw.Draw(img)
        
    if t >= 23.0:
        draw_snackbar(draw, "Laporan pengaduan berhasil dikirim ke perangkat desa!", is_success=True, y=1440)
        
    draw_bottom_nav(draw, active_index=0)
    
    if t < 7.0:
        sub = "Aplikasi ini juga menyediakan saluran aspirasi warga melalui menu 'Pengaduan'."
    elif t < 16.0:
        sub = "Jika ada kendala fasilitas umum, pilih kategori pengaduan dan tuliskan laporan secara rinci."
    elif t < 24.0:
        sub = "Lampirkan foto dokumentasi sebagai bukti pendukung, lalu tekan tombol 'Kirim Laporan Pengaduan'."
    else:
        sub = "Laporan yang Anda kirimkan langsung diteruskan ke perangkat desa untuk ditindaklanjuti secara tanggap!"
        
    draw_subtitle_box(draw, sub)
    return img

# SCENE 7: PENUTUP (17.66s)
def render_frame_scene7(t, dur):
    img = Image.new("RGB", (WIDTH, HEIGHT), (10, 25, 47))
    draw = ImageDraw.Draw(img)
    
    for y in range(HEIGHT):
        ratio = y / HEIGHT
        r = int(10 + ratio * 0)
        g = int(25 + ratio * 45)
        b = int(47 + ratio * 120)
        draw.line([(0, y), (WIDTH, y)], fill=(r, g, b))
        
    draw_status_bar(draw, dark=False)
    
    logo_w = 340
    logo_h = int(LOGO_DESA.height * (logo_w / LOGO_DESA.width))
    logo_resized = LOGO_DESA.resize((logo_w, logo_h), Image.Resampling.LANCZOS)
    img.paste(logo_resized, ((WIDTH - logo_w) // 2, 240), logo_resized)
    
    draw.text((360, 480), "TERIMA KASIH", font=FONT_BOLD_XL, fill=(255, 255, 255))
    draw.text((220, 555), "Pelayanan Digital Prima untuk Warga Rambipuji", font=FONT_SB_L, fill=(147, 197, 253))
    
    # Summary Box
    draw.rounded_rectangle([80, 650, 1000, 1160], radius=24, fill=(255, 255, 255, 240))
    draw.text((120, 690), "Keunggulan Layanan Digital Desa:", font=FONT_BOLD_L, fill=C_PRIMARY)
    
    points = [
        "✓  Pelayanan mandiri 24 jam tanpa antre di kantor desa",
        "✓  Verifikasi surat berjenjang transparan & akuntabel",
        "✓  Kemudahan menyampaikan pengaduan & aspirasi warga",
        "✓  Keamanan akun terjamin berbasis NIK kependudukan"
    ]
    py = 760
    for pt in points:
        draw.text((120, py), pt, font=FONT_SB_M, fill=C_TEXT_DARK)
        py += 80
        
    # Kontak Desa
    draw.rounded_rectangle([80, 1200, 1000, 1480], radius=24, fill=C_PRIMARY)
    draw.text((120, 1235), "KANTOR PEMERINTAH DESA RAMBIPUJI", font=FONT_BOLD_M, fill=(255, 255, 255))
    draw.text((120, 1285), "📍 Jl. Gajah Mada No. 1, Rambipuji, Kabupaten Jember", font=FONT_REG_M, fill=(255, 255, 255))
    draw.text((120, 1335), "🌐 Website Resmi : desarambipuji-jember.com", font=FONT_REG_M, fill=(147, 197, 253))
    draw.text((120, 1385), "📞 Layanan Warga : (0331) 712-xxx / WhatsApp Desa", font=FONT_REG_M, fill=(147, 197, 253))
    
    if t < 8.0:
        sub = "Demikian panduan lengkap penggunaan Aplikasi Mobile Desa Rambipuji untuk role warga."
    else:
        sub = "Jaga kerahasiaan kata sandi akun Anda. Terima kasih, dan selamat menggunakan Aplikasi Desa Rambipuji!"
        
    draw_subtitle_box(draw, sub)
    return img

print("All frame renderers defined successfully.")

def make_segment(scene_func, audio_file, out_file, dur):
    total_frames = int(dur * FPS)
    print(f"Rendering {out_file}: {total_frames} frames ({dur:.2f}s)...")
    
    cmd = [
        FFMPEG, "-y",
        "-f", "rawvideo",
        "-vcodec", "rawvideo",
        "-s", f"{WIDTH}x{HEIGHT}",
        "-pix_fmt", "rgb24",
        "-r", str(FPS),
        "-i", "-",
        "-i", audio_file,
        "-c:v", "libx264",
        "-preset", "ultrafast",
        "-pix_fmt", "yuv420p",
        "-c:a", "aac",
        "-b:a", "192k",
        "-shortest",
        out_file
    ]
    
    proc = subprocess.Popen(cmd, stdin=subprocess.PIPE, stderr=subprocess.DEVNULL)
    
    for f in range(total_frames):
        t = f / FPS
        frame = scene_func(t, dur)
        proc.stdin.write(frame.tobytes())
        if f % 150 == 0:
            print(f"  Frame {f}/{total_frames} ({f*100//total_frames}%)")
            
    proc.stdin.close()
    proc.wait()
    print(f"Completed: {out_file} ({os.path.getsize(out_file)} bytes)")

def main():
    segments = [
        (render_frame_scene1, "tutorial-video/audio_01_pembukaan.mp3", "tutorial-video/raw_01_pembukaan.mp4", 18.91),
        (render_frame_scene2, "tutorial-video/audio_02_aktivasi.mp3", "tutorial-video/raw_02_aktivasi.mp4", 41.95),
        (render_frame_scene3, "tutorial-video/audio_03_login.mp3", "tutorial-video/raw_03_login.mp4", 31.61),
        (render_frame_scene4, "tutorial-video/audio_04_pengajuan.mp3", "tutorial-video/raw_04_pengajuan.mp4", 36.29),
        (render_frame_scene5, "tutorial-video/audio_05_monitoring.mp3", "tutorial-video/raw_05_monitoring.mp4", 37.49),
        (render_frame_scene6, "tutorial-video/audio_06_pengaduan.mp3", "tutorial-video/raw_06_pengaduan.mp4", 29.18),
        (render_frame_scene7, "tutorial-video/audio_07_penutup.mp3", "tutorial-video/raw_07_penutup.mp4", 17.66),
    ]
    
    raw_files = []
    for func, audio, out, dur in segments:
        make_segment(func, audio, out, dur)
        raw_files.append(out)
        
    # Concatenate all into final tutorial video
    list_path = "tutorial-video/concat_list.txt"
    with open(list_path, "w", encoding="utf-8") as f:
        for rf in raw_files:
            base = os.path.basename(rf)
            f.write(f"file '{base}'\n")
            
    final_output = "tutorial-video/tutorial-aplikasi-desa-rambipuji.mp4"
    print(f"Concatenating all segments into {final_output}...")
    
    concat_cmd = [
        FFMPEG, "-y",
        "-f", "concat",
        "-safe", "0",
        "-i", list_path,
        "-c", "copy",
        final_output
    ]
    
    subprocess.run(concat_cmd, check=True)
    print(f"SUCCESS! Final Video Tutorial Created: {final_output} ({os.path.getsize(final_output)} bytes)")

if __name__ == "__main__":
    main()

