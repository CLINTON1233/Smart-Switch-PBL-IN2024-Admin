import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:admin_smart_switch/pages/statistic/statistic_page.dart';
import 'package:admin_smart_switch/pages/auth/login_admin_page.dart';
import 'package:admin_smart_switch/pages/home/home_page.dart';
import 'package:admin_smart_switch/pages/kelola%20panduan/kelola_panduan_page.dart';
import 'package:admin_smart_switch/pages/kelola%20saklar/kelola_saklar_page.dart';
import 'package:admin_smart_switch/pages/profile/profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_auth/firebase_auth.dart' show UserCredential;

class KelolaPenggunaPage extends StatefulWidget {
  const KelolaPenggunaPage({super.key});

  @override
  State<KelolaPenggunaPage> createState() => _KelolaPenggunaPageState();
}

class AppUser {
  final String id;
  final String username;
  final String email;
  final String? password;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String role;
  final bool isActive;

  AppUser({
    required this.id,
    required this.username,
    required this.email,
    this.password,
    required this.createdAt,
    required this.updatedAt,
    required this.role,
    required this.isActive,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    try {
      // Pastikan data tidak null dan bertipe Map<String, dynamic>
      if (doc.data() == null || !(doc.data() is Map)) {
        throw Exception('Document data is null or not a Map');
      }

      final data = doc.data() as Map<String, dynamic>;

      // Handle null fields dengan nilai default
      return AppUser(
        id: doc.id,
        username: data['username']?.toString() ?? 'No Username',
        email: data['email']?.toString() ?? 'no-email@example.com',
        password: data['password']?.toString(),
        createdAt: _parseDateTime(data['createdAt']),
        updatedAt: _parseDateTime(data['updatedAt']),
        role: data['role']?.toString() ?? 'user',
        isActive: data['isActive'] as bool? ?? true,
      );
    } catch (e) {
      print('Error parsing user ${doc.id}: $e');
      // Return default user dengan error flag
      return AppUser(
        id: doc.id,
        username: 'Error User',
        email: 'error@example.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        role: 'error',
        isActive: false,
      );
    }
  }

  // Helper method untuk parsing DateTime
  static DateTime _parseDateTime(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is Timestamp) return date.toDate();
    if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
    return DateTime.now();
  }
}

class _KelolaPenggunaPageState extends State<KelolaPenggunaPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedIndex = 0;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<AppUser> _users = [];
  List<AppUser> _filteredUsers = [];
  bool _isEditing = false;
  String? _editingUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _testFirestoreConnection(); // Test koneksi dulu
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  // Tambahkan method ini di dalam class _KelolaPenggunaPageState
  Future<void> _testFirestoreConnection() async {
    try {
      await _firestore.collection('users').limit(1).get();
      print('Koneksi Firestore berhasil');
    } catch (e) {
      print('Gagal terhubung ke Firestore: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal terhubung ke database'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot querySnapshot = await _firestore.collection('users').get();

      print('Jumlah dokumen ditemukan: ${querySnapshot.docs.length}');

      List<AppUser> loadedUsers = [];
      for (var doc in querySnapshot.docs) {
        try {
          loadedUsers.add(AppUser.fromFirestore(doc));
        } catch (e) {
          print('Error parsing document ${doc.id}: $e');
        }
      }

      setState(() {
        _users = loadedUsers;
        _filteredUsers = List.from(_users);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data pengguna: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterUsers() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredUsers = List.from(_users);
      } else {
        _filteredUsers =
            _users
                .where(
                  (user) =>
                      user.username.toLowerCase().contains(
                        _searchController.text.toLowerCase(),
                      ) ||
                      user.email.toLowerCase().contains(
                        _searchController.text.toLowerCase(),
                      ),
                )
                .toList();
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const StatisticPage()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
    }
  }

  void _showAddEditUserDialog({AppUser? user}) {
    _isEditing = user != null;
    _editingUserId = user?.id;

    if (_isEditing) {
      _usernameController.text = user!.username;
      _emailController.text = user.email;
      _passwordController.text = '';
    } else {
      _usernameController.clear();
      _emailController.clear();
      _passwordController.clear();
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            _isEditing
                                ? Colors.orange.withOpacity(0.1)
                                : const Color(0xFF6BB5A6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _isEditing ? Icons.edit : Icons.add_circle,
                        color:
                            _isEditing
                                ? Colors.orange
                                : const Color(0xFF6BB5A6),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isEditing ? 'Edit Pengguna' : 'Tambah Pengguna Baru',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color:
                            _isEditing
                                ? Colors.orange
                                : const Color(0xFF6BB5A6),
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.person,
                      color:
                          _isEditing ? Colors.orange : const Color(0xFF6BB5A6),
                    ),
                  ),
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color:
                            _isEditing
                                ? Colors.orange
                                : const Color(0xFF6BB5A6),
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.email,
                      color:
                          _isEditing ? Colors.orange : const Color(0xFF6BB5A6),
                    ),
                  ),
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText:
                        _isEditing
                            ? 'Password Baru (kosongkan jika tidak diubah)'
                            : 'Password',
                    labelStyle: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color:
                            _isEditing
                                ? Colors.orange
                                : const Color(0xFF6BB5A6),
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.lock,
                      color:
                          _isEditing ? Colors.orange : const Color(0xFF6BB5A6),
                    ),
                  ),
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Text(
                          'Batal',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isEditing
                                  ? Colors.orange
                                  : const Color(0xFF6BB5A6),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _isEditing ? 'Simpan' : 'Tambah',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveUser() async {
    // Validasi input
    if (_usernameController.text.isEmpty || _emailController.text.isEmpty) {
      _showErrorSnackbar('Username dan email harus diisi');
      return;
    }

    if (!_isEditing && _passwordController.text.isEmpty) {
      _showErrorSnackbar('Password harus diisi untuk user baru');
      return;
    }

    if (!RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(_emailController.text)) {
      _showErrorSnackbar('Format email tidak valid');
      return;
    }

    try {
      if (_isEditing) {
        await _updateExistingUser();
      } else {
        await _registerNewUser();
      }

      await _loadUsers();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      print('Error saving user: $e');
      _showErrorSnackbar('Gagal menyimpan: ${e.toString()}');
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updateExistingUser() async {
    final updateData = {
      'username': _usernameController.text,
      'email': _emailController.text,
      'updatedAt': Timestamp.now(),
    };

    await _firestore.collection('users').doc(_editingUserId).update(updateData);

    if (_passwordController.text.isNotEmpty) {
      try {
        User? user = _auth.currentUser;
        if (user != null && user.email == _emailController.text) {
          await user.updatePassword(_passwordController.text);
        }
      } catch (e) {
        print('Error updating password: $e');
      }
    }
  }

  Future<void> _registerNewUser() async {
    try {
      // 1. Buat user di Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // 2. Simpan data tambahan ke Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(), // Gunakan server timestamp
        'updatedAt': FieldValue.serverTimestamp(),
        'role': 'user',
        'isActive': true,
      });

      // 3. Update UI
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User berhasil didaftarkan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Pendaftaran gagal';
      if (e.code == 'weak-password') {
        errorMessage = 'Password terlalu lemah';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Email sudah terdaftar';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print('Error during registration: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan sistem'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmationDialog(AppUser user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Hapus Pengguna?',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Apakah Anda yakin ingin menghapus "${user.username}"? Tindakan ini tidak dapat dibatalkan.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _deleteUser(user.id);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Hapus',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteUser(String userId) async {
    try {
      // Delete from Firestore
      await _firestore.collection('users').doc(userId).delete();

      // Delete from Authentication (optional)
      // await _auth.currentUser?.delete(); // Hati-hati dengan ini

      // Refresh user list
      await _loadUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pengguna berhasil dihapus',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus pengguna: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Icon(Icons.warning, color: Colors.orange, size: 40),
          content: const Text(
            "Apakah Anda yakin ingin logout dari panel admin?",
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  child: const Text(
                    "Tidak, Batalkan!",
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text(
                    "Ya",
                    style: TextStyle(color: Colors.green),
                  ),
                  onPressed: () async {
                    await _auth.signOut();
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginAdminPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromARGB(255, 13, 138, 117),
                  Color.fromARGB(255, 24, 142, 122),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.admin_panel_settings,
                        size: 30,
                        color: Color(0xFF6BB5A6),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Admin',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Administrator',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HomePage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.people,
                  title: 'Kelola Pengguna',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const KelolaPenggunaPage(),
                      ),
                    );
                  },
                  isActive: true,
                ),
                _buildDrawerItem(
                  icon: Icons.devices,
                  title: 'Kelola Saklar',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const KelolaSaklarPage(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.assignment,
                  title: 'Kelola Panduan',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const KelolaPanduanPage(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutConfirmationDialog();
                  },
                  isLogout: true,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(30),
            child: Text(
              'Admin Panel v1.0.0',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isActive = false,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color:
            isActive
                ? const Color(0xFFABD3CC).withOpacity(0.1)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color:
              isLogout
                  ? Colors.red
                  : isActive
                  ? const Color(0xFF6BB5A6)
                  : Colors.grey[600],
          size: 24,
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color:
                isLogout
                    ? Colors.red
                    : isActive
                    ? const Color(0xFF6BB5A6)
                    : Colors.black87,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 13, 138, 117),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          'Kelola Pengguna',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daftar Pengguna',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kelola semua pengguna aplikasi Smart Switch',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF6BB5A6),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6BB5A6).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () => _showAddEditUserDialog(),
                          icon: const Icon(Icons.add, color: Colors.white),
                          tooltip: 'Tambah Pengguna',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => _filterUsers(),
                      decoration: InputDecoration(
                        hintText: 'Cari pengguna...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            // Loading Indicator
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF6BB5A6)),
                ),
              ),

            // Table Header
            if (!_isLoading)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 50,
                      child: Text(
                        'ID',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Username',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Email',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: Text(
                        'Tanggal Bergabung',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                        'Action',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Table Content
            if (!_isLoading)
              Expanded(
                child:
                    _filteredUsers.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.people_outline,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tidak ada pengguna ditemukan',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Silakan tambah pengguna baru atau ubah pencarian',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // ID
                                    SizedBox(
                                      width: 50,
                                      child: Text(
                                        user.id.substring(0, 4),
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    // Username
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user.username,
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Role: ${user.role}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Email
                                    Expanded(
                                      child: Text(
                                        user.email,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    // Join Date
                                    SizedBox(
                                      width: 100,
                                      child: Text(
                                        '${user.createdAt.day.toString().padLeft(2, '0')}-${user.createdAt.month.toString().padLeft(2, '0')}-${user.createdAt.year}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                    // Action Buttons
                                    SizedBox(
                                      width: 80,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          GestureDetector(
                                            onTap:
                                                () => _showAddEditUserDialog(
                                                  user: user,
                                                ),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.orange
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Icon(
                                                Icons.edit,
                                                size: 16,
                                                color: Colors.orange[700],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap:
                                                () =>
                                                    _showDeleteConfirmationDialog(
                                                      user,
                                                    ),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withOpacity(
                                                  0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Icon(
                                                Icons.delete,
                                                size: 16,
                                                color: Colors.red[700],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),

            // Summary Footer
            if (!_isLoading)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Pengguna: ${_filteredUsers.length} pengguna',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF6BB5A6),
        unselectedItemColor: Colors.grey[600],
        selectedIconTheme: const IconThemeData(size: 24),
        unselectedIconTheme: const IconThemeData(size: 22),
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF6BB5A6),
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Colors.grey[600],
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Statistic',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
