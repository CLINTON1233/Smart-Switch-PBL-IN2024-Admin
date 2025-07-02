// lib/services/firestore_auth_services.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register admin dengan Firebase Auth + Firestore
  Future<User?> registerAdmin({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      // Cek apakah username sudah ada (jika berhasil)
      try {
        bool usernameExists = await isUsernameExists(username);
        if (usernameExists) {
          throw Exception('Username sudah digunakan');
        }
      } catch (e) {
        // Jika gagal cek username karena permission, lanjutkan saja
        print('Cannot check username uniqueness: $e');
      }

      // Registrasi dengan Firebase Auth (ini akan handle email duplication)
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Simpan data admin ke Firestore
        await saveAdminData(
          userId: credential.user!.uid,
          username: username,
          email: email,
        );

        // Update display name
        await credential.user!.updateDisplayName(username);
      }

      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    } catch (e) {
      throw Exception('Gagal registrasi admin: $e');
    }
  }

  // Login admin dengan verifikasi role
  Future<User?> loginAdmin({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Verifikasi apakah user adalah admin
        bool isAdmin = await verifyAdminRole(credential.user!.uid);
        if (!isAdmin) {
          await _auth.signOut();
          throw Exception('Akun bukan admin atau tidak aktif');
        }
      }

      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    } catch (e) {
      throw Exception('Gagal login admin: $e');
    }
  }

  // Verifikasi role admin
  Future<bool> verifyAdminRole(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('admins').doc(userId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['role'] == 'admin' && data['isActive'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Logout admin
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Gagal logout: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    } catch (e) {
      throw Exception('Gagal reset password: $e');
    }
  }

  // Menyimpan data admin setelah registrasi
  Future<void> saveAdminData({
    required String userId,
    required String username,
    required String email,
  }) async {
    try {
      await _firestore.collection('admins').doc(userId).set({
        'username': username,
        'email': email,
        'role': 'admin',
        'isActive': true,
        'permissions': [
          'manage_users',
          'manage_switches',
          'manage_education',
          'view_statistics',
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal menyimpan data admin: $e');
    }
  }

  // Mengambil data admin berdasarkan userId
  Future<Map<String, dynamic>?> getAdminData(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('admins').doc(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil data admin: $e');
    }
  }

  // Get current admin data
  Future<Map<String, dynamic>?> getCurrentAdminData() async {
    if (currentUser != null) {
      return await getAdminData(currentUser!.uid);
    }
    return null;
  }

  // Update data admin
  Future<void> updateAdminData({
    required String userId,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (data != null) {
        data['updatedAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('admins').doc(userId).update(data);
      }
    } catch (e) {
      throw Exception('Gagal update data admin: $e');
    }
  }

  // Cek apakah username sudah digunakan
  Future<bool> isUsernameExists(String username) async {
    try {
      QuerySnapshot userQuery =
          await _firestore
              .collection('users')
              .where('username', isEqualTo: username)
              .limit(1)
              .get();

      QuerySnapshot adminQuery =
          await _firestore
              .collection('admins')
              .where('username', isEqualTo: username)
              .limit(1)
              .get();

      return userQuery.docs.isNotEmpty || adminQuery.docs.isNotEmpty;
    } catch (e) {
      // Jika error karena permission, return false (assume username available)
      print('Error checking username: $e');
      return false;
    }
  }

  // Cek apakah email sudah digunakan di Firestore
  Future<bool> isEmailExists(String email) async {
    try {
      QuerySnapshot userQuery =
          await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      QuerySnapshot adminQuery =
          await _firestore
              .collection('admins')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      return userQuery.docs.isNotEmpty || adminQuery.docs.isNotEmpty;
    } catch (e) {
      // Jika error karena permission, return false (assume email available)
      print('Error checking email: $e');
      return false;
    }
  }

  // ===== ADMIN SPECIFIC FUNCTIONS =====

  // Get all users (untuk admin)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection('users')
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Gagal mengambil data users: $e');
    }
  }

  // Get users stream (real-time)
  Stream<QuerySnapshot> getUsersStream() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Disable/Enable user
  Future<void> toggleUserStatus(String userId, bool isActive) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal mengubah status user: $e');
    }
  }

  // Get user switches (untuk admin)
  Future<List<Map<String, dynamic>>> getUserSwitches(String userId) async {
    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection('switches')
              .where('userId', isEqualTo: userId)
              .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Gagal mengambil data switches: $e');
    }
  }

  // Handle Firebase Auth errors
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Email tidak terdaftar';
      case 'wrong-password':
        return 'Password salah';
      case 'email-already-in-use':
        return 'Email sudah terdaftar';
      case 'weak-password':
        return 'Password terlalu lemah';
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'user-disabled':
        return 'Akun telah dinonaktifkan';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan, coba lagi nanti';
      default:
        return 'Terjadi kesalahan: ${e.message}';
    }
  }
}
