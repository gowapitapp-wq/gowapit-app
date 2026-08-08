import 'package:flutter/material.dart';

class BeritaKegiatanPage extends StatelessWidget {
  const BeritaKegiatanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Berita Kegiatan"), backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.newspaper, size: 64, color: Colors.grey),
            SizedBox(height: 10),
            Text("Halaman Berita Kegiatan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Konten berita akan muncul di sini.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}