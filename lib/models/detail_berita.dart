import 'package:flutter/material.dart';

class Berita {
  final String idberita;
  final String judul;
  final String createdAt;
  final String deskripsi;
  final String? gambar;
  final String nik;
  final String? nama;

  Berita({
    required this.idberita,
    required this.judul,
    required this.createdAt,
    required this.deskripsi,
    this.gambar,
    required this.nik,
    this.nama,
  });

  factory Berita.fromJson(Map<String, dynamic> json) {
    return Berita(
      idberita: json['idberita'] ?? '',
      judul: json['judul'] ?? '',
      createdAt: json['created_at'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      gambar: json['gambar'],
      nik: json['nik'] ?? '',
      nama: json['nama'],
    );
  }
}
