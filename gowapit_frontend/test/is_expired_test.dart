import 'package:flutter_test/flutter_test.dart';
import 'package:gowapit_frontend/screens/berita_screen.dart';

void main() {
  group('isExpired Function Unit Tests', () {
    final referenceNow = DateTime(2026, 9, 20, 10, 30, 0); // 20 Sep 2026

    test('1. Nilai null atau string kosong harus mengembalikan false (tidak pernah kedaluwarsa)', () {
      expect(isExpired(null, now: referenceNow), isFalse);
      expect(isExpired('', now: referenceNow), isFalse);
      expect(isExpired('   ', now: referenceNow), isFalse);
    });

    test('2. Tanggal hari ini (2026-09-20) harus mengembalikan false (masih berlaku)', () {
      expect(isExpired('2026-09-20', now: referenceNow), isFalse);
      expect(isExpired('2026-09-20T23:59:59', now: referenceNow), isFalse);
    });

    test('3. Tanggal besok atau masa depan (2026-09-21 dst) harus mengembalikan false (masih berlaku)', () {
      expect(isExpired('2026-09-21', now: referenceNow), isFalse);
      expect(isExpired('2026-12-31', now: referenceNow), isFalse);
      expect(isExpired('2027-01-01', now: referenceNow), isFalse);
    });

    test('4. Tanggal kemarin atau masa lalu (2026-09-19 kebawah) harus mengembalikan true (sudah kedaluwarsa)', () {
      expect(isExpired('2026-09-19', now: referenceNow), isTrue);
      expect(isExpired('2026-09-01', now: referenceNow), isTrue);
      expect(isExpired('2025-12-31', now: referenceNow), isTrue);
    });

    test('5. String ISO tidak valid harus fallback ke false secara aman tanpa error', () {
      expect(isExpired('invalid-date-format', now: referenceNow), isFalse);
      expect(isExpired('abc-xyz', now: referenceNow), isFalse);
    });
  });
}
