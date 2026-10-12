import 'package:flutter_test/flutter_test.dart';
import 'package:digitalv/models/pengajuan_model.dart';
import 'package:digitalv/models/pengajuandiajukan_model.dart';
import 'package:digitalv/models/pengajuanselesai_model.dart';

void main() {
  group('Pengujian Keterangan Surat Flutter Model', () {
    test('Skenario 1: Belum disetujui admin (Diajukan) -> Menggunakan keperluan', () {
      final item = PengajuanModel.fromJson({
        'id_pengajuan': 1,
        'nama_surat': 'Surat Keterangan Usaha',
        'nama_pemohon': 'Ahmad',
        'nik': '3509012345670001',
        'status': 'Diajukan',
        'keperluan': 'Untuk pengajuan KUR Bank',
        'keterangan_admin': null,
      });

      expect(item.isApprovedByAdmin, false);
      expect(item.keteranganDisplay, 'Untuk pengajuan KUR Bank');
    });

    test('Skenario 1b: Belum disetujui admin (Disetujui Kepala Dusun) -> Menggunakan keperluan', () {
      final item = PengajuanModel.fromJson({
        'id_pengajuan': 2,
        'nama_surat': 'Surat Pengantar KTP',
        'nama_pemohon': 'Budi',
        'nik': '3509012345670002',
        'status': 'Disetujui Kepala Dusun',
        'keperluan': 'Perpanjangan KTP',
        'keterangan_admin': null,
      });

      expect(item.isApprovedByAdmin, false);
      expect(item.keteranganDisplay, 'Perpanjangan KTP');
    });

    test('Skenario 2: Disetujui Admin -> Menggunakan keterangan_admin', () {
      final item = PengajuanModel.fromJson({
        'id_pengajuan': 3,
        'nama_surat': 'Surat Pengantar KTP',
        'nama_pemohon': 'Siti',
        'nik': '3509012345670003',
        'status': 'Disetujui Admin',
        'keperluan': 'Perpanjangan KTP',
        'keterangan_admin': 'Berkas persyaratan KTP lengkap dan sah',
      });

      expect(item.isApprovedByAdmin, true);
      expect(item.keteranganDisplay, 'Berkas persyaratan KTP lengkap dan sah');
    });

    test('Skenario 3: Tahap Sekdes -> Tetap menggunakan keterangan_admin', () {
      final item = PengajuanModel.fromJson({
        'id_pengajuan': 4,
        'nama_surat': 'Surat Keterangan Domisili',
        'nama_pemohon': 'Dewi',
        'nik': '3509012345670004',
        'status': 'Disetujui Admin',
        'keperluan': 'Persyaratan Kerja',
        'keterangan_admin': 'Persyaratan domisili RT/RW telah divalidasi admin',
      });

      expect(item.isApprovedByAdmin, true);
      expect(item.keteranganDisplay, 'Persyaratan domisili RT/RW telah divalidasi admin');
    });

    test('Skenario 4: Tahap Kades (Disetujui Sekretaris Desa) -> Tetap menggunakan keterangan_admin', () {
      final item = PengajuanModel.fromJson({
        'id_pengajuan': 5,
        'nama_surat': 'Surat Keterangan Usaha',
        'nama_pemohon': 'Rudi',
        'nik': '3509012345670005',
        'status': 'Disetujui Sekretaris Desa',
        'keperluan': 'Keperluan Warga Awal',
        'keterangan_admin': 'Surat telah diverifikasi Sekdes & siap TTE Kades',
      });

      expect(item.isApprovedByAdmin, true);
      expect(item.keteranganDisplay, 'Surat telah diverifikasi Sekdes & siap TTE Kades');
    });

    test('Skenario 5: Tahap Selesai -> Tetap menggunakan keterangan_admin', () {
      final item = PengajuanModel.fromJson({
        'id_pengajuan': 6,
        'nama_surat': 'Surat Pengantar KK',
        'nama_pemohon': 'Bambang',
        'nik': '3509012345670006',
        'status': 'Selesai',
        'keperluan': 'Keperluan Warga Awal',
        'keterangan_admin': 'Dokumen final telah disahkan Kepala Desa',
      });

      expect(item.isApprovedByAdmin, true);
      expect(item.keteranganDisplay, 'Dokumen final telah disahkan Kepala Desa');
    });

    test('Skenario 6: Nilai keperluan berbeda dari keterangan_admin -> Tetap menggunakan keterangan_admin setelah disetujui', () {
      final item = PengajuanModel.fromJson({
        'id_pengajuan': 7,
        'nama_surat': 'Surat Keterangan Tidak Mampu',
        'nama_pemohon': 'Haryanto',
        'nik': '3509012345670007',
        'status': 'Disetujui Admin',
        'keperluan': 'Bantuan Sekolah Anak',
        'keterangan_admin': 'Kriteria DTKS Terpenuhi, diverifikasi oleh Kasi Kesra',
      });

      expect(item.keperluan, 'Bantuan Sekolah Anak');
      expect(item.keteranganAdmin, 'Kriteria DTKS Terpenuhi, diverifikasi oleh Kasi Kesra');
      expect(item.keteranganDisplay, 'Kriteria DTKS Terpenuhi, diverifikasi oleh Kasi Kesra');
    });

    test('Skenario 7a: PengajuanModel keterangan_admin null setelah disetujui admin -> AMAN (-), tidak kembali ke keperluan', () {
      final item = PengajuanModel.fromJson({
        'id_pengajuan': 8,
        'nama_surat': 'Surat Keterangan Usaha',
        'nama_pemohon': 'Yanto',
        'nik': '3509012345670008',
        'status': 'Disetujui Admin',
        'keperluan': 'Pengajuan Kredit',
        'keterangan_admin': null,
      });

      expect(item.isApprovedByAdmin, true);
      expect(item.keteranganDisplay, '-');
    });

    test('Skenario 7b: StatusDiajukanModel keterangan_admin kosong/null setelah disetujui admin -> AMAN (-)', () {
      final item = StatusDiajukanModel.fromJson({
        'id_pengajuan': 9,
        'nama_surat': 'Surat Keterangan Usaha',
        'status': 'Disetujui Sekretaris Desa',
        'keperluan': 'Pengajuan Kredit',
        'keterangan_admin': '',
      });

      expect(item.isApprovedByAdmin, true);
      expect(item.keteranganDisplay, '-');
    });

    test('Skenario 7c: StatusSelesaiModel keterangan_admin -> menghasilkan keteranganAdmin atau (-)', () {
      final itemWithAdmin = StatusSelesaiModel.fromJson({
        'id_pengajuan': 10,
        'nama_surat': 'Surat Keterangan Usaha',
        'status': 'Selesai',
        'keperluan': 'Pengajuan Kredit',
        'keterangan_admin': 'Disahkan oleh Kades Rambipuji',
      });
      expect(itemWithAdmin.keteranganDisplay, 'Disahkan oleh Kades Rambipuji');

      final itemEmptyAdmin = StatusSelesaiModel.fromJson({
        'id_pengajuan': 11,
        'nama_surat': 'Surat Keterangan Usaha',
        'status': 'Selesai',
        'keperluan': 'Pengajuan Kredit',
        'keterangan_admin': null,
      });
      expect(itemEmptyAdmin.keteranganDisplay, '-');
    });
  });
}
