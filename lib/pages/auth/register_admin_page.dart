import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin_smart_switch/pages/auth/login_admin_page.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterAdminPage extends StatefulWidget {
  const RegisterAdminPage({super.key});

  @override
  State<RegisterAdminPage> createState() => _RegisterAdminPageState();
}

class _RegisterAdminPageState extends State<RegisterAdminPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // Show SnackBar dengan pesan
  void _showSnackBar(String message, {bool isSuccess = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: isSuccess ? Colors.green[600] : Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Validasi form input
  bool _validateForm() {
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showSnackBar("Semua field wajib diisi");
      return false;
    }

    if (username.length < 3) {
      _showSnackBar("Username minimal 3 karakter");
      return false;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showSnackBar("Format email tidak valid");
      return false;
    }

    if (password.length < 6) {
      _showSnackBar("Password minimal 6 karakter");
      return false;
    }

    if (password != confirmPassword) {
      _showSnackBar("Password tidak cocok");
      return false;
    }

    return true;
  }

  // Simpan data admin ke Firestore
  Future<void> _saveAdminData({
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

  // Fungsi registrasi admin dengan Firebase - SIMPLIFIED VERSION
  Future<void> _registerUser() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      // Langsung buat akun Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        // Simpan data admin ke Firestore
        await _saveAdminData(
          userId: userCredential.user!.uid,
          username: username,
          email: email,
        );

        // Update display name
        await userCredential.user!.updateDisplayName(username);

        // Tampilkan pesan sukses
        _showSnackBar("Registrasi admin berhasil!", isSuccess: true);

        // Navigasi ke halaman login admin
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginAdminPage()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = "Terjadi kesalahan";

      switch (e.code) {
        case 'email-already-in-use':
          message = "Email sudah digunakan";
          break;
        case 'invalid-email':
          message = "Email tidak valid";
          break;
        case 'weak-password':
          message = "Password terlalu lemah";
          break;
        case 'operation-not-allowed':
          message = "Operasi tidak diizinkan";
          break;
        default:
          message = "Terjadi kesalahan: ${e.message}";
      }

      _showSnackBar(message);
    } catch (e) {
      _showSnackBar("Terjadi kesalahan: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToLogin() {
    if (_isLoading) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginAdminPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Background decorations
            Positioned(
              top: 0,
              left: 0,
              child: Stack(
                alignment: Alignment.topLeft,
                children: [
                  Image.asset(
                    'assets/desain_kiri_atas_transparan.jpg',
                    width: 140,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 140,
                        height: 100,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 20.0),
                    child: Text(
                      'Create\nAccount',
                      style: GoogleFonts.oleoScriptSwashCaps(
                        fontSize: 25,
                        color: const Color(0xFF2C5C52),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              right: 0,
              child: Image.asset(
                'assets/splashscreen2.png',
                width: 100,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported),
                  );
                },
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 220,
                child: Image.asset(
                  'assets/hiasan_bawah.jpg',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 220,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported),
                    );
                  },
                ),
              ),
            ),

            // Main content
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(40, 125, 40, 300),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 30, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Regist Admin Account',
                    style: GoogleFonts.oleoScriptSwashCaps(
                      fontSize: 20,
                      color: const Color(0xFF2C5C52),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    usernameController,
                    Icons.person,
                    'Username (min 3 karakter)',
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(emailController, Icons.email, 'Email'),
                  const SizedBox(height: 10),
                  _buildTextField(
                    passwordController,
                    Icons.lock,
                    'Password (min 6 karakter)',
                    isPassword: true,
                    obscureText: _obscurePassword,
                    onToggle:
                        () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    confirmPasswordController,
                    Icons.lock,
                    'Confirm Password',
                    isPassword: true,
                    obscureText: _obscureConfirmPassword,
                    onToggle:
                        () => setState(
                          () =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                        ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isLoading ? Colors.grey : Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Text(
                                'Regist Now',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?"),
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: _navigateToLogin,
                        child: Text(
                          'Login',
                          style: TextStyle(
                            color: _isLoading ? Colors.grey : Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    IconData icon,
    String hintText, {
    bool isPassword = false,
    bool? obscureText,
    VoidCallback? onToggle,
  }) {
    return SizedBox(
      height: 45,
      child: TextField(
        controller: controller,
        enabled: !_isLoading,
        obscureText: obscureText ?? false,
        keyboardType:
            hintText.toLowerCase().contains('email')
                ? TextInputType.emailAddress
                : TextInputType.text,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 20),
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 5,
          ),
          filled: true,
          fillColor: _isLoading ? Colors.grey[200] : Colors.teal.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          suffixIcon:
              isPassword
                  ? IconButton(
                    icon: Icon(
                      obscureText == true
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: _isLoading ? null : onToggle,
                  )
                  : null,
        ),
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
