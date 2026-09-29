import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../config/globals.dart';
import '../models/pengaduan_model.dart';
import '../services/secure_storage_service.dart';
import '../widgets/snackbarcustom.dart';

class RiwayatPengaduanScreen extends StatefulWidget {
  const RiwayatPengaduanScreen({super.key});

  @override
  State<RiwayatPengaduanScreen> createState() => _RiwayatPengaduanScreenState();
}

class _RiwayatPengaduanScreenState extends State<RiwayatPengaduanScreen> {
  static const _primary   = Color(0xFF2E7D32);
  static const _accent    = Color(0xFF16A34A);
  static const _bgGreen   = Color(0xFFE8F5E9);
  static const _bgPage    = Color(0xFFF5F7FA);

  List<PengaduanModel> _list = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPengaduan();
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await SecureStorageService.instance.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  Future<void> _fetchPengaduan() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final headers  = await _authHeaders();
      final response = await http.get(Uri.parse('$baseURL/pengaduan'), headers: headers);
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final data = body['data'] as List? ?? [];
        setState(() {
          _list = data.map((j) => PengaduanModel.fromJson(j)).toList();
          _isLoading = false;
        });
      } else {
        setState(() { _error = 'Gagal memuat data (${response.statusCode})'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Terjadi kesalahan: $e'; _isLoading = false; });
    }
  }

  Future<void> _deletePengaduan(PengaduanModel item) async {
    final confirm = await _showConfirmDialog(
      title: 'Hapus Pengaduan',
      content: 'Pengaduan ini akan dihapus permanen. Lanjutkan?',
      confirmLabel: 'Hapus',
      confirmColor: Colors.red,
    );
    if (!confirm || !mounted) return;

    try {
      final headers  = await _authHeaders();
      final response = await http.delete(
        Uri.parse('$baseURL/pengaduan/${item.id}'),
        headers: headers,
      );
      final body = json.decode(response.body);
      if (response.statusCode == 200) {
        showCustomSnackbar(context: context, message: 'Pengaduan berhasil dihapus.', backgroundColor: Colors.green, icon: Icons.check_circle);
        _fetchPengaduan();
      } else {
        showCustomSnackbar(context: context, message: body['message'] ?? 'Gagal menghapus', backgroundColor: Colors.red, icon: Icons.error);
      }
    } catch (e) {
      showCustomSnackbar(context: context, message: 'Kesalahan: $e', backgroundColor: Colors.red, icon: Icons.error);
    }
  }

  void _openEditSheet(PengaduanModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditPengaduanSheet(
        item: item,
        onUpdated: _fetchPengaduan,
      ),
    );
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String content,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(content, style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'RIWAYAT PENGADUAN',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: _primary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _primary),
            onPressed: _fetchPengaduan,
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const _FormPengaduanBaru()),
          );
          _fetchPengaduan();
        },
        icon: const Icon(Icons.add_comment_rounded),
        label: Text('Buat Pengaduan', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        color: _primary,
        onRefresh: _fetchPengaduan,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(_error!, style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchPengaduan,
                          icon: const Icon(Icons.refresh),
                          label: Text('Coba Lagi', style: GoogleFonts.poppins()),
                          style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                  )
                : _list.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        itemCount: _list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _PengaduanCard(
                          item: _list[i],
                          onEdit: () => _openEditSheet(_list[i]),
                          onDelete: () => _deletePengaduan(_list[i]),
                        ),
                      ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: _bgGreen, shape: BoxShape.circle),
            child: const Icon(Icons.campaign_outlined, size: 56, color: _primary),
          ),
          const SizedBox(height: 20),
          Text('Belum Ada Pengaduan', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: _primary)),
          const SizedBox(height: 8),
          Text(
            'Tap tombol di bawah untuk membuat pengaduan baru.',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Card item pengaduan
// ──────────────────────────────────────────────────────────────────────────────
class _PengaduanCard extends StatelessWidget {
  final PengaduanModel item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PengaduanCard({required this.item, required this.onEdit, required this.onDelete});

  static const _primary  = Color(0xFF2E7D32);
  static const _bgGreen  = Color(0xFFE8F5E9);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _bgGreen,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(_kategoriIcon(item.kategori), color: _primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.kategori,
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _primary),
                  ),
                ),
                _StatusChip(isResponded: item.isResponded),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.ulasan,
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.fotoUrl != null) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      item.fotoUrl!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 140,
                        color: Colors.grey[100],
                        child: const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 40),
                      ),
                    ),
                  ),
                ],
                if (item.feedbackAdmin != null && item.feedbackAdmin!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.verified_outlined, color: _primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Respons Desa', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: _primary)),
                              const SizedBox(height: 2),
                              Text(item.feedbackAdmin!, style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(_formatDate(item.createdAt), style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
                    const Spacer(),
                    if (!item.isResponded) ...[
                      _ActionBtn(icon: Icons.edit_note_rounded, label: 'Edit', color: Colors.blue, onTap: onEdit),
                      const SizedBox(width: 8),
                      _ActionBtn(icon: Icons.delete_outline_rounded, label: 'Hapus', color: Colors.red, onTap: onDelete),
                    ] else
                      Text('Sudah direspons', style: GoogleFonts.poppins(fontSize: 11, color: _primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _kategoriIcon(String k) {
    switch (k) {
      case 'Infrastruktur': return Icons.construction_rounded;
      case 'Pelayanan': return Icons.support_agent_rounded;
      case 'Keamanan': return Icons.security_rounded;
      case 'Lingkungan': return Icons.eco_rounded;
      default: return Icons.help_outline_rounded;
    }
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return raw;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final bool isResponded;
  const _StatusChip({required this.isResponded});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isResponded ? Colors.green.shade600 : Colors.orange.shade600,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isResponded ? Icons.check_rounded : Icons.hourglass_top_rounded, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            isResponded ? 'Direspons' : 'Menunggu',
            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Bottom sheet: Edit pengaduan
// ──────────────────────────────────────────────────────────────────────────────
class _EditPengaduanSheet extends StatefulWidget {
  final PengaduanModel item;
  final VoidCallback onUpdated;

  const _EditPengaduanSheet({required this.item, required this.onUpdated});

  @override
  State<_EditPengaduanSheet> createState() => _EditPengaduanSheetState();
}

class _EditPengaduanSheetState extends State<_EditPengaduanSheet> {
  static const _primary   = Color(0xFF2E7D32);
  static const _fillGreen = Color(0xFFF1F8F1);
  static const _bgGreen   = Color(0xFFE8F5E9);

  late TextEditingController _ulasanCtrl;
  late String? _selectedKategori;
  bool _isLoading = false;

  XFile?     _pickedFile;
  Uint8List? _imageBytes;

  final List<String> _kategoriList = ['Infrastruktur', 'Pelayanan', 'Keamanan', 'Lingkungan', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    _ulasanCtrl      = TextEditingController(text: widget.item.ulasan);
    _selectedKategori = widget.item.kategori;
  }

  @override
  void dispose() {
    _ulasanCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() { _pickedFile = picked; _imageBytes = bytes; });
  }

  Future<void> _submit() async {
    if (_ulasanCtrl.text.trim().isEmpty) {
      showCustomSnackbar(context: context, message: 'Uraian tidak boleh kosong', backgroundColor: Colors.orange, icon: Icons.warning_amber_rounded);
      return;
    }
    setState(() => _isLoading = true);

    try {
      final token = await SecureStorageService.instance.getToken();
      final uri     = Uri.parse('$baseURL/pengaduan/${widget.item.id}');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Accept']        = 'application/json'
        ..headers['Authorization'] = 'Bearer ${token ?? ''}';

      request.fields['ulasan']   = _ulasanCtrl.text.trim();
      request.fields['kategori'] = _selectedKategori ?? widget.item.kategori;

      if (_pickedFile != null && _imageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'foto1',
            _imageBytes!,
            filename: _pickedFile!.name,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      final res = await http.Response.fromStream(await request.send());
      if (!mounted) return;

      if (res.statusCode == 200) {
        showCustomSnackbar(context: context, message: 'Pengaduan berhasil diperbarui!', backgroundColor: Colors.green, icon: Icons.check_circle);
        Navigator.pop(context);
        widget.onUpdated();
      } else {
        final body = json.decode(res.body);
        showCustomSnackbar(context: context, message: body['message'] ?? 'Gagal memperbarui', backgroundColor: Colors.red, icon: Icons.error);
      }
    } catch (e) {
      showCustomSnackbar(context: context, message: 'Kesalahan: $e', backgroundColor: Colors.red, icon: Icons.error);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 16),
            Text('Edit Pengaduan', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: _primary)),
            const SizedBox(height: 16),

            // Kategori dropdown
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Kategori',
                labelStyle: GoogleFonts.poppins(color: _primary, fontWeight: FontWeight.w600, fontSize: 12),
                filled: true,
                fillColor: _fillGreen,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _primary.withOpacity(0.4))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _primary, width: 2)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedKategori,
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  items: _kategoriList.map((k) => DropdownMenuItem(value: k, child: Text(k, style: GoogleFonts.poppins(fontSize: 13)))).toList(),
                  onChanged: (v) => setState(() => _selectedKategori = v),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Ulasan
            TextFormField(
              controller: _ulasanCtrl,
              maxLines: 4,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Uraian Pengaduan',
                alignLabelWithHint: true,
                labelStyle: GoogleFonts.poppins(color: _primary, fontWeight: FontWeight.w600, fontSize: 12),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _primary, width: 1.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _primary, width: 2)),
              ),
            ),
            const SizedBox(height: 12),

            // Ganti foto
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: _imageBytes != null ? 130 : 72,
                decoration: BoxDecoration(
                  color: _bgGreen,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _primary.withOpacity(0.4)),
                ),
                child: _imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.memory(_imageBytes!, fit: BoxFit.cover, width: double.infinity),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.photo_camera_outlined, color: _primary, size: 20),
                          const SizedBox(width: 8),
                          Text('Ganti Foto (opsional)', style: GoogleFonts.poppins(color: _primary, fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(_isLoading ? 'Menyimpan...' : 'Simpan Perubahan', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Form Pengaduan Baru (inline — dipanggil dari FAB di RiwayatPengaduanScreen)
// ──────────────────────────────────────────────────────────────────────────────
class _FormPengaduanBaru extends StatefulWidget {
  const _FormPengaduanBaru();

  @override
  State<_FormPengaduanBaru> createState() => _FormPengaduanBaruState();
}

class _FormPengaduanBaruState extends State<_FormPengaduanBaru> {
  static const _primary   = Color(0xFF2E7D32);
  static const _accent    = Color(0xFF16A34A);
  static const _bgGreen   = Color(0xFFE8F5E9);
  static const _fillGreen = Color(0xFFF1F8F1);
  static const _bgPage    = Color(0xFFF5F7FA);

  final _ulasanCtrl = TextEditingController();
  String? _selectedKategori;
  bool _isLoading = false;

  XFile?     _pickedFile;
  Uint8List? _imageBytes;

  final List<String> _kategoriList = ['Infrastruktur', 'Pelayanan', 'Keamanan', 'Lingkungan', 'Lainnya'];

  @override
  void dispose() {
    _ulasanCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _pickedFile  = picked;
      _imageBytes  = bytes;
    });
  }

  Future<void> _submit() async {
    if (_selectedKategori == null) {
      showCustomSnackbar(context: context, message: 'Pilih kategori terlebih dahulu', backgroundColor: Colors.orange, icon: Icons.warning_amber_rounded);
      return;
    }
    if (_ulasanCtrl.text.trim().isEmpty) {
      showCustomSnackbar(context: context, message: 'Uraian tidak boleh kosong', backgroundColor: Colors.orange, icon: Icons.warning_amber_rounded);
      return;
    }

    setState(() => _isLoading = true);
    final token = await SecureStorageService.instance.getToken();
    if (token == null || token.isEmpty) {
      showCustomSnackbar(context: context, message: 'Sesi habis. Silakan login ulang.', backgroundColor: Colors.red, icon: Icons.error);
      setState(() => _isLoading = false);
      return;
    }

    try {
      final uri     = Uri.parse('$baseURL/pengaduan');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Accept']        = 'application/json'
        ..headers['Authorization'] = 'Bearer $token';

      request.fields['ulasan']   = _ulasanCtrl.text.trim();
      request.fields['kategori'] = _selectedKategori!;

      if (_pickedFile != null && _imageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes('foto1', _imageBytes!, filename: _pickedFile!.name, contentType: MediaType('image', 'jpeg')),
        );
      }

      final res = await http.Response.fromStream(await request.send());
      if (!mounted) return;

      if (res.statusCode == 201) {
        showCustomSnackbar(context: context, message: 'Pengaduan berhasil dikirim!', backgroundColor: Colors.green, icon: Icons.check_circle);
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) Navigator.pop(context);
      } else {
        final body = json.decode(res.body);
        showCustomSnackbar(context: context, message: body['message'] ?? 'Gagal mengirim (${res.statusCode})', backgroundColor: Colors.red, icon: Icons.error);
      }
    } catch (e) {
      showCustomSnackbar(context: context, message: 'Terjadi kesalahan: $e', backgroundColor: Colors.red, icon: Icons.error);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text('BUAT PENGADUAN', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: _primary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _bgGreen,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.campaign_rounded, color: _primary, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sampaikan pengaduan terkait infrastruktur, pelayanan, keamanan, lingkungan, atau masalah desa lainnya.',
                      style: GoogleFonts.poppins(color: _primary, fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Kategori + Ulasan card
            _card(
              title: 'Isi Pengaduan',
              icon: Icons.edit_document,
              children: [
                // Dropdown
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Kategori Pengaduan',
                    labelStyle: GoogleFonts.poppins(color: _primary, fontWeight: FontWeight.w600, fontSize: 12),
                    filled: true,
                    fillColor: _fillGreen,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _primary.withOpacity(0.4), width: 1.5)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _primary, width: 2)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedKategori,
                      isExpanded: true,
                      hint: Text('Pilih kategori', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500])),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _primary),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      items: _kategoriList.map((k) {
                        IconData icon;
                        switch (k) {
                          case 'Infrastruktur': icon = Icons.construction_rounded; break;
                          case 'Pelayanan': icon = Icons.support_agent_rounded; break;
                          case 'Keamanan': icon = Icons.security_rounded; break;
                          case 'Lingkungan': icon = Icons.eco_rounded; break;
                          default: icon = Icons.help_outline_rounded;
                        }
                        return DropdownMenuItem(
                          value: k,
                          child: Row(children: [
                            Icon(icon, color: _primary, size: 18),
                            const SizedBox(width: 10),
                            Text(k, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
                          ]),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedKategori = v),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ulasanCtrl,
                  maxLines: 5,
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Uraian Pengaduan',
                    alignLabelWithHint: true,
                    labelStyle: GoogleFonts.poppins(color: _primary, fontWeight: FontWeight.w600, fontSize: 12),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _primary, width: 1.5)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _accent, width: 2)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Upload foto
            _card(
              title: 'Foto Pendukung (Opsional)',
              icon: Icons.photo_library_outlined,
              children: [
                InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _imageBytes != null ? _primary : _primary.withOpacity(0.4), width: 1.5),
                    ),
                    child: _imageBytes != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(_imageBytes!, width: double.infinity, height: double.infinity, fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => setState(() { _pickedFile = null; _imageBytes = null; }),
                                  child: Container(
                                    decoration: BoxDecoration(color: Colors.red.shade600, shape: BoxShape.circle),
                                    padding: const EdgeInsets.all(5),
                                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: const BoxDecoration(color: _bgGreen, shape: BoxShape.circle),
                                child: const Icon(Icons.add_photo_alternate_outlined, size: 30, color: _primary),
                              ),
                              const SizedBox(height: 10),
                              Text('Tap untuk memilih foto', style: GoogleFonts.poppins(color: _primary, fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text('Format JPG / PNG (opsional)', style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 11)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  _isLoading ? 'Mengirim...' : 'Kirim Pengaduan',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.3),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _card({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.07),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              Icon(icon, color: _primary, size: 20),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _primary)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
          ),
        ],
      ),
    );
  }
}
