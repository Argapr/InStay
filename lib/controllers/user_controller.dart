import 'package:bcrypt/bcrypt.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class UserActivityLogger {
  static String createUser(String email, String role) {
    return 'Membuat user baru: $email dengan role $role';
  }

  static String updateUser(
    String email, {
    String? username,
    String? nama,
    String? role,
  }) {
    final List<String> updates = [];
    if (username != null) updates.add('username');
    if (nama != null) updates.add('nama');
    if (role != null) updates.add('role');

    final updatedFields = updates.join(', ');
    return 'Memperbarui data ($updatedFields) untuk user: $email';
  }

  static String deleteUser(String email) {
    return 'Menghapus user: $email';
  }
}

class UserController {
  final SupabaseClient supabase;

  UserController(this.supabase);

  bool isValidEmail(String email) {
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );
    return emailRegExp.hasMatch(email);
  }

  Future<void> toggleUserStatus(String userId, bool isActive) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) throw Exception('Tidak ada user yang login');

    final currentUserData = await supabase
        .from('users')
        .select('role')
        .eq('id', currentUser.id)
        .single();

    if (currentUserData['role'] != 'admin') {
      throw Exception('Hanya admin yang dapat mengubah status user');
    }
    try {
      final userData = await supabase
          .from('users')
          .select('email')
          .eq('id', userId)
          .single();
      final email = userData['email'] as String;

      await supabase
          .from('users')
          .update({'is_active': isActive}).eq('id', userId);

      await _logActivity(
          'Mengubah status user $email menjadi ${isActive ? "Aktif" : "Non-Aktif"}');
    } catch (e) {
      print('Error toggling user status: $e');
      rethrow;
    }
  }

  Future<void> _logActivity(String activity) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        print('Error logging: No user logged in');
        return;
      }

      await supabase.from('log').insert({
        'id_user': user.id,
        'activity': activity,
      });
    } catch (e) {
      print('Gagal mencatat log: $e');
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await supabase
          .from('users')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((user) => UserModel.fromJson(user))
          .toList();
    } catch (e) {
      print('Error getting users: $e');
      rethrow;
    }
  }

  Future<UserModel> createUser({
    required String email,
    required String password,
    required String username,
    required String nama,
    required String role,
  }) async {
    try {
      if (!isValidEmail(email)) {
        throw Exception('Format email tidak valid');
      }

      if (password.isEmpty) {
        throw Exception('Password tidak boleh kosong');
      }

      // Enkripsi password menggunakan bcrypt
      final String hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

      final AuthResponse authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Gagal membuat pengguna di Auth');
      }

      final response = await supabase
          .from('users')
          .insert({
            'id': authResponse.user!.id,
            'username': username,
            'nama': nama,
            'email': email,
            'password': hashedPassword, // Simpan password terenkripsi
            'role': role,
            'is_active': true,
          })
          .select()
          .single();

      await _logActivity(UserActivityLogger.createUser(email, role));

      return UserModel.fromJson(response);
    } catch (e) {
      print('Error saat membuat pengguna: $e');
      throw Exception('Terjadi kesalahan saat membuat pengguna: $e');
    }
  }

  Future<UserModel> updateUser({
    required String userId,
    String? username,
    String? nama,
    String? role,
  }) async {
    try {
      final userData = await supabase
          .from('users')
          .select('email')
          .eq('id', userId)
          .single();
      final email = userData['email'] as String;

      final response = await supabase
          .from('users')
          .update({
            if (username != null) 'username': username,
            if (nama != null) 'nama': nama,
            if (role != null) 'role': role,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId)
          .select()
          .single();

      await _logActivity(UserActivityLogger.updateUser(
        email,
        username: username,
        nama: nama,
        role: role,
      ));

      return UserModel.fromJson(response);
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      // Periksa apakah user yang sedang login memiliki role yang sesuai
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Tidak ada user yang login');
      }

      final currentUserData = await supabase
          .from('users')
          .select('role')
          .eq('id', currentUser.id)
          .single();

      final currentUserRole = currentUserData['role'] as String;
      if (currentUserRole != 'admin' && currentUserRole != 'owner') {
        throw Exception('Anda tidak memiliki izin untuk menghapus user');
      }

      // 2. Ambil data user yang akan dihapus untuk logging
      final userData = await supabase
          .from('users')
          .select('email')
          .eq('id', userId)
          .single();
      final email = userData['email'] as String;

      // 3. Hapus data user dari tabel users terlebih dahulu
      await supabase.from('users').delete().eq('id', userId);

      // 4. Hapus user dari auth
      try {
        await supabase.auth.admin.deleteUser(userId);
      } catch (e) {
        print('Warning: Gagal menghapus user dari auth: $e');
        // Lanjutkan eksekusi karena data users sudah terhapus
      }

      // 5. Log aktivitas
      await _logActivity(UserActivityLogger.deleteUser(email));
    } catch (e) {
      print('Error deleting user: $e');
      throw Exception('Gagal menghapus user: ${e.toString()}');
    }
  }
}
