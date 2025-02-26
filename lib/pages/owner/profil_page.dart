import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ProfilPage({Key? key, this.userData}) : super(key: key);

  @override
  _ProfilPageState createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  Map<String, dynamic>? userData;
  bool _isLoading = true;

  final Color primaryColor = const Color(0xFF9A9A9A);
  final Color lightGrey = const Color(0xFFF5F5F5);
  final Color darkGrey = const Color(0xFF707070);
  final Color accentGrey = const Color(0xFFB8B8B8);

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString('user_id');

      if (userId == null) {
        throw 'User not logged in';
      }

      setState(() {
        userData = {
          'id': userId,
          'username':
              prefs.getString('user_username') ?? 'Username Tidak Tersedia',
          'nama': prefs.getString('user_name') ?? 'Nama Tidak Tersedia',
          'email': prefs.getString('user_email') ?? 'Email Tidak Tersedia',
          'role': prefs.getString('user_role') ?? 'Role Tidak Tersedia',
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat profil: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Hapus semua data user yang tersimpan di lokal

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout gagal: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Konfirmation Logout',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: darkGrey,
            ),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: GoogleFonts.poppins(
              color: accentGrey,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(
                  color: accentGrey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                'Logout',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9A9A9A)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: lightGrey,
      body: RefreshIndicator(
        onRefresh: _fetchUserData,
        color: primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Profile Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: primaryColor,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      userData?['nama'] ?? 'Nama Tidak Tersedia',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: darkGrey,
                      ),
                    ),
                    Text(
                      userData?['role'] ?? 'Role Tidak Tersedia',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: accentGrey,
                      ),
                    ),
                  ],
                ),
              ),
              // Info Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildInfoCard(
                      'Username',
                      userData?['username'] ?? '-',
                      Icons.person_outline,
                    ),
                    const SizedBox(height: 15),
                    _buildInfoCard(
                      'Email',
                      userData?['email'] ?? 'Email Tidak Tersedia',
                      Icons.email_outlined,
                    ),
                    const SizedBox(height: 15),
                    _buildInfoCard(
                      'Role',
                      userData?['role'] ?? 'Role Tidak Tersedia',
                      Icons.badge_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Logout Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed: _showLogoutConfirmation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Logout',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: lightGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: accentGrey,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: darkGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
