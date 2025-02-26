import 'package:flutter/material.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  // Style constants
  static const _inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(30)),
    borderSide: BorderSide(color: Colors.grey),
  );

  static const _headerStyle = TextStyle(
    fontSize: 32,
    color: Color(0xFF6B6B6B),
    fontWeight: FontWeight.w500,
  );

  static const _inputLabelStyle = TextStyle(
    color: Color(0xFF6B6B6B),
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> saveUserData(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
  }

  Future<void> _logActivity(String userId, String activity) async {
    try {
      await _supabase.from('log').insert({
        'id_user': userId,
        'activity': activity,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Login activity log failed: $e');
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userData = await _supabase
          .from('users')
          .select()
          .eq('email', _emailController.text.trim())
          .single();

      if (userData == null) {
        throw Exception('Akun tidak ditemukan');
      }

      final bool isPasswordCorrect =
          BCrypt.checkpw(_passwordController.text.trim(), userData['password']);

      if (!isPasswordCorrect) {
        throw Exception('Password Anda salah');
      }

      if (!(userData['is_active'] as bool)) {
        throw Exception('Akun Anda tidak aktif');
      }

      // Simpan user data ke shared_preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userData['id']);
      await prefs.setString('user_username', userData['username']);
      await prefs.setString('user_name', userData['nama']);
      await prefs.setString('user_email', userData['email']);
      await prefs.setString('user_role', userData['role']);

      await _logActivity(userData['id'], 'Successful login');

      if (!mounted) return;
      _redirectBasedOnRole(userData['role']);
    } catch (e) {
      _showErrorSnackBar(e.toString());
      await _logActivity('', 'Failed login attempt: ${_emailController.text}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', role);
  }

  void _redirectBasedOnRole(String role) {
    final routes = {
      'admin': '/admin',
      'kasir': '/kasir',
      'owner': '/owner',
    };

    if (routes.containsKey(role)) {
      Navigator.pushReplacementNamed(context, routes[role]!);
    } else {
      throw Exception('Invalid user role');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          // Tambahkan ini
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  Center(
                    child: Image.asset(
                      'assets/instay_logo.png',
                      height: 100,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text('Hello,', style: _headerStyle),
                  const Text('Welcome back', style: _headerStyle),
                  const SizedBox(height: 40),

                  // Email Input
                  const Text('Email', style: _inputLabelStyle),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    decoration: _inputDecoration(hint: 'arga@instay.id'),
                    validator: _validateRequiredField,
                  ),
                  const SizedBox(height: 24),

                  // Password Input
                  const Text('Password', style: _inputLabelStyle),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: _inputDecoration(
                      hint: '*********',
                      suffix: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                    validator: _validateRequiredField,
                  ),
                  const SizedBox(height: 40),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9E9E9E),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(30)),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                          : const Text(
                              'Log In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(
                      height: 20), // Tambahkan padding ekstra di bawah
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFB3B3B3)),
      border: _inputBorder,
      enabledBorder: _inputBorder,
      focusedBorder: _inputBorder,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      suffixIcon: suffix,
    );
  }

  String? _validateRequiredField(String? value) {
    if (value == null || value.isEmpty) {
      return 'Field ini wajib diisi';
    }
    return null;
  }
}
