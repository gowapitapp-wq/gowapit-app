import 'package:flutter/material.dart';

class KeranjangPage extends StatelessWidget {
  const KeranjangPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Keranjang"), backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart, size: 64, color: Colors.grey),
            SizedBox(height: 10),
            Text("Halaman Keranjang Belanja", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Daftar belanjaan tiket/kuliner kamu ada di sini.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}