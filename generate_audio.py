import asyncio
import os
import edge_tts

VOICE = "id-ID-ArdiNeural" # Bahasa Indonesia - Suara Pria Formal & Profesional

SECTIONS = [
    (
        "audio_01_pembukaan.mp3",
        "Halo masyarakat Desa Rambipuji! Selamat datang dalam video panduan resmi penggunaan Aplikasi Mobile Desa Rambipuji. "
        "Melalui aplikasi ini, warga dapat mengurus berbagai administrasi persuratan dan menyampaikan aspirasi kapan saja dan di mana saja secara cepat, transparan, dan mudah."
    ),
    (
        "audio_02_aktivasi.mp3",
        "Bagi warga yang baru pertama kali menggunakan aplikasi, langkah awal adalah melakukan aktivasi akun. "
        "Pada halaman utama login, pilih opsi 'Aktivasi Akun'. Pastikan Nomor Induk Kependudukan atau NIK Anda sudah terdaftar di data kependudukan desa. "
        "Masukkan 16 digit NIK Anda, alamat email aktif, nomor WhatsApp, serta buat kata sandi minimal delapan karakter yang memuat huruf besar, huruf kecil, dan angka. "
        "Setelah data terisi lengkap, tekan tombol 'Aktifkan Akun'. Sistem akan memverifikasi NIK Anda secara otomatis dengan basis data desa, dan notifikasi sukses akan muncul menandakan akun Anda telah berhasil diaktifkan."
    ),
    (
        "audio_03_login.mp3",
        "Setelah akun aktif, Anda dapat langsung masuk dengan memasukkan NIK atau email dan kata sandi yang telah didaftarkan. "
        "Pada halaman utama, Anda akan disambut dengan nama lengkap Anda sesuai data kependudukan. "
        "Di bagian atas, tersedia kartu ringkasan status pengajuan surat, mulai dari permohonan yang sedang diajukan, selesai, ditolak, serta total pengaduan. "
        "Di bawahnya, Anda dapat dengan mudah mengakses menu layanan utama seperti Pengajuan Surat, Monitoring Status, dan Layanan Pengaduan."
    ),
    (
        "audio_04_pengajuan.mp3",
        "Untuk mengajukan surat administrasi, pilih menu 'Layanan Surat'. Di sini tersedia berbagai jenis layanan persuratan desa seperti Surat Keterangan Domisili, Surat Pengantar SKCK, Surat Keterangan Usaha, dan lain-lain. "
        "Pilih jenis surat yang Anda butuhkan, isi keterangan keperluan Anda secara jelas, lalu unggah dokumen persyaratan yang diminta seperti foto Kartu Tanda Penduduk atau Kartu Keluarga. "
        "Terakhir, periksa kembali kelengkapan formulir Anda dan tekan tombol 'Kirim Pengajuan'. Surat Anda akan langsung tercatat di sistem desa untuk segera diproses."
    ),
    (
        "audio_05_monitoring.mp3",
        "Anda tidak perlu lagi bolak-balik datang ke kantor desa hanya untuk mengecek proses surat permohonan Anda. "
        "Buka menu 'Status' untuk memantau kemajuan surat Anda secara realtime. Terdapat tiga tab status: Diajukan, Selesai, dan Ditolak. "
        "Pada detail pengajuan, Anda dapat melihat garis waktu verifikasi berjenjang yang transparan: mulai dari pemeriksaan awal oleh Kepala Dusun, paraf oleh Sekretaris Desa, hingga persetujuan dan tanda tangan digital oleh Kepala Desa. "
        "Jika surat telah selesai, Anda akan menerima pemberitahuan dan surat dapat langsung diunduh atau diambil di balai desa."
    ),
    (
        "audio_06_pengaduan.mp3",
        "Selain layanan persuratan, aplikasi ini juga menyediakan saluran aspirasi warga melalui menu 'Pengaduan'. "
        "Jika Anda memiliki masukan terkait fasilitas umum, kebersihan, atau pelayanan lingkungan di Desa Rambipuji, pilih kategori pengaduan, tuliskan laporan Anda secara rinci, dan lampirkan foto dokumentasi sebagai bukti pendukung. "
        "Laporan yang Anda kirimkan akan langsung diteruskan kepada perangkat desa terkait untuk segera ditindaklanjuti secara tanggap dan akuntabel."
    ),
    (
        "audio_07_penutup.mp3",
        "Demikian panduan lengkap penggunaan Aplikasi Mobile Desa Rambipuji untuk warga. "
        "Selalu jaga kerahasiaan kata sandi akun Anda dan manfaatkan kemudahan layanan digital ini untuk kemajuan bersama. "
        "Terima kasih atas perhatian Anda, dan selamat menggunakan Aplikasi Desa Rambipuji!"
    )
]

async def generate():
    os.makedirs("tutorial-video", exist_ok=True)
    for filename, text in SECTIONS:
        filepath = os.path.join("tutorial-video", filename)
        print(f"Generating {filepath}...")
        communicate = edge_tts.Communicate(text, VOICE, rate="-4%")
        await communicate.save(filepath)
        print(f"Done: {filepath} ({os.path.getsize(filepath)} bytes)")

if __name__ == "__main__":
    asyncio.run(generate())

