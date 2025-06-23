// lib/services/firestore_admin_services.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreAdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Menyimpan data admin setelah registrasi
  Future<void> saveAdminData({
    required String adminId,
    required String username,
    required String email,
  }) async {
    try {
      await _firestore.collection('admins').doc(adminId).set({
        'username': username,
        'email': email,
        'role': 'admin',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal menyimpan data admin: $e');
    }
  }

  // Mengambil data admin berdasarkan adminId
  Future<Map<String, dynamic>?> getAdminData(String adminId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('admins').doc(adminId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil data admin: $e');
    }
  }

  // Update data admin
  Future<void> updateAdminData({
    required String adminId,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (data != null) {
        data['updatedAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('admins').doc(adminId).update(data);
      }
    } catch (e) {
      throw Exception('Gagal update data admin: $e');
    }
  }

  // Cek apakah username admin sudah digunakan
  Future<bool> isUsernameExists(String username) async {
    try {
      QuerySnapshot query =
          await _firestore
              .collection('admins')
              .where('username', isEqualTo: username)
              .limit(1)
              .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Gagal cek username admin: $e');
    }
  }

  // Cek apakah email admin sudah digunakan di Firestore
  Future<bool> isEmailExists(String email) async {
    try {
      QuerySnapshot query =
          await _firestore
              .collection('admins')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Gagal cek email admin: $e');
    }
  }

  // Verifikasi bahwa user adalah admin (digunakan saat login)
  Future<bool> verifyAdmin(String adminId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('admins').doc(adminId).get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['role'] == 'admin' && data['isActive'] == true;
      }
      return false;
    } catch (e) {
      throw Exception('Gagal verifikasi admin: $e');
    }
  }

  // Nonaktifkan admin
  Future<void> deactivateAdmin(String adminId) async {
    try {
      await _firestore.collection('admins').doc(adminId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal nonaktifkan admin: $e');
    }
  }

  // Aktifkan admin
  Future<void> activateAdmin(String adminId) async {
    try {
      await _firestore.collection('admins').doc(adminId).update({
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal aktifkan admin: $e');
    }
  }

  // Hapus data admin
  Future<void> deleteAdminData(String adminId) async {
    try {
      await _firestore.collection('admins').doc(adminId).delete();
    } catch (e) {
      throw Exception('Gagal menghapus data admin: $e');
    }
  }

  // Mendapatkan semua data admin (untuk management)
  Future<List<Map<String, dynamic>>> getAllAdmins() async {
    try {
      QuerySnapshot query =
          await _firestore
              .collection('admins')
              .orderBy('createdAt', descending: true)
              .get();

      return query.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Gagal mengambil data semua admin: $e');
    }
  }

  // Mendapatkan jumlah admin aktif
  Future<int> getActiveAdminCount() async {
    try {
      QuerySnapshot query =
          await _firestore
              .collection('admins')
              .where('isActive', isEqualTo: true)
              .get();

      return query.docs.length;
    } catch (e) {
      throw Exception('Gagal menghitung admin aktif: $e');
    }
  }

  // Update password admin (jika diperlukan)
  Future<void> updateAdminPassword({
    required String adminId,
    required String newPassword,
  }) async {
    try {
      // Hanya update timestamp di Firestore, password diupdate di Firebase Auth
      await _firestore.collection('admins').doc(adminId).update({
        'passwordUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal update password admin: $e');
    }
  }

  // Cek apakah admin adalah super admin
  Future<bool> isSuperAdmin(String adminId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('admins').doc(adminId).get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['role'] == 'super_admin';
      }
      return false;
    } catch (e) {
      throw Exception('Gagal cek super admin: $e');
    }
  }

  // Set admin sebagai super admin
  Future<void> setSuperAdmin(String adminId) async {
    try {
      await _firestore.collection('admins').doc(adminId).update({
        'role': 'super_admin',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal set super admin: $e');
    }
  }
}
