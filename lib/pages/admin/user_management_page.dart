import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../controllers/user_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';

class UserManagementPage extends StatefulWidget {
  @override
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final UserController _userController =
      UserController(Supabase.instance.client);
  late Future<List<UserModel>> _usersFuture;

  final Color primaryColor = Color(0xFF9A9A9A);
  final Color backgroundColor = Color(0xFFF5F5F5);
  final Color cardColor = Colors.white;
  final Color textColor = Color(0xFF2D2D2D);

  @override
  void initState() {
    super.initState();
    _usersFuture = _userController.getAllUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: FutureBuilder<List<UserModel>>(
                  future: _usersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(primaryColor),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 48, color: Colors.red[300]),
                            SizedBox(height: 16),
                            Text(
                              'Error: ${snapshot.error}',
                              style: TextStyle(color: Colors.red[300]),
                            ),
                          ],
                        ),
                      );
                    }

                    final users = snapshot.data!;
                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {},
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        user.nama[0].toUpperCase(),
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.nama,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: textColor,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          user.email,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: primaryColor
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                user.role,
                                                style: TextStyle(
                                                  color: primaryColor,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: user.isActive
                                                    ? Colors.green
                                                        .withOpacity(0.1)
                                                    : Colors.red
                                                        .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                user.isActive
                                                    ? 'Aktif'
                                                    : 'Non-Aktif',
                                                style: TextStyle(
                                                  color: user.isActive
                                                      ? Colors.green
                                                      : Colors.red,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton(
                                    icon: Icon(Icons.more_vert,
                                        color: primaryColor),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined,
                                                color: primaryColor),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline,
                                                color: Colors.red[300]),
                                            SizedBox(width: 8),
                                            Text(
                                              'Hapus',
                                              style: TextStyle(
                                                  color: Colors.red[300]),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'toggle',
                                        child: Row(
                                          children: [
                                            Icon(
                                              user.isActive
                                                  ? Icons.toggle_off
                                                  : Icons.toggle_on,
                                              color: user.isActive
                                                  ? Colors.red
                                                  : Colors.green,
                                            ),
                                            SizedBox(width: 8),
                                            Text(user.isActive
                                                ? 'Non-Aktifkan'
                                                : 'Aktifkan'),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showEditUserDialog(context, user);
                                      } else if (value == 'delete') {
                                        _showDeleteConfirmation(context, user);
                                      } else if (value == 'toggle') {
                                        _showToggleConfirmation(context, user);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddUserDialog(context),
      ),
    );
  }

  Future<void> _showToggleConfirmation(
      BuildContext context, UserModel user) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text('Konfirmasi Status'),
        content: Text(
            'Apakah Anda yakin ingin ${user.isActive ? 'menonaktifkan' : 'mengaktifkan'} ${user.nama}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: primaryColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              try {
                await _userController.toggleUserStatus(user.id, !user.isActive);
                Navigator.pop(context);
                setState(() {
                  _usersFuture = _userController.getAllUsers();
                });
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            child: Text('Ya'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddUserDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    String email = '';
    String password = '';
    String username = '';
    String nama = '';
    String role = 'kasir';
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Add Users',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(
                    label: 'Email',
                    hint: 'Masukkan email valid',
                    onSaved: (value) => email = value?.trim() ?? '',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email tidak boleh kosong';
                      }
                      if (!_userController.isValidEmail(value)) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    label: 'Password',
                    hint: 'Minimal 6 karakter',
                    onSaved: (value) => password = value ?? '',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password tidak boleh kosong';
                      }
                      if (value.length < 6) {
                        return 'Password minimal 6 karakter';
                      }
                      return null;
                    },
                    obscureText: true,
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    label: 'Username',
                    hint: 'Masukkan username',
                    onSaved: (value) => username = value?.trim() ?? '',
                    validator: (value) => value?.isEmpty == true
                        ? 'Username tidak boleh kosong'
                        : null,
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    label: 'Nama',
                    hint: 'Masukkan nama lengkap',
                    onSaved: (value) => nama = value?.trim() ?? '',
                    validator: (value) => value?.isEmpty == true
                        ? 'Nama tidak boleh kosong'
                        : null,
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: primaryColor.withOpacity(0.3)),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: ['admin', 'kasir', 'owner']
                        .map((role) => DropdownMenuItem(
                              value: role,
                              child: Text(role),
                            ))
                        .toList(),
                    onChanged: (value) => role = value ?? 'kasir',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: TextStyle(color: primaryColor),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState?.validate() ?? false) {
                        setState(() => isLoading = true);
                        formKey.currentState?.save();

                        try {
                          await _userController.createUser(
                            email: email,
                            password: password,
                            username: username,
                            nama: nama,
                            role: role,
                          );
                          Navigator.pop(context);
                          setState(() {
                            _usersFuture = _userController.getAllUsers();
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Pengguna berhasil ditambahkan'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        } catch (e) {
                          setState(() => isLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      }
                    },
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required Function(String?) onSaved,
    required String? Function(String?) validator,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      onSaved: onSaved,
      validator: validator,
    );
  }

  Future<void> _showEditUserDialog(BuildContext context, UserModel user) async {
    final formKey = GlobalKey<FormState>();
    String username = user.username;
    String nama = user.nama;
    String role = user.role;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Edit Users',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                label: 'Username',
                hint: 'Masukkan username',
                onSaved: (value) => username = value!,
                validator: (value) => value?.isEmpty == true
                    ? 'Username tidak boleh kosong'
                    : null,
              ),
              SizedBox(height: 16),
              _buildTextField(
                label: 'Nama',
                hint: 'Masukkan nama lengkap',
                onSaved: (value) => nama = value!,
                validator: (value) =>
                    value?.isEmpty == true ? 'Nama tidak boleh kosong' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: role,
                decoration: InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: primaryColor.withOpacity(0.3)),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: ['admin', 'kasir', 'owner']
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(role),
                        ))
                    .toList(),
                onChanged: (value) => role = value!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: primaryColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                try {
                  await _userController.updateUser(
                    userId: user.id,
                    username: username,
                    nama: nama,
                    role: role,
                  );
                  Navigator.pop(context);
                  setState(() {
                    _usersFuture = _userController.getAllUsers();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Pengguna berhasil diperbarui'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              }
            },
            child: Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, UserModel user) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text('Hapus Pengguna'),
        content:
            Text('Apakah Anda yakin ingin menghapus pengguna ${user.nama}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: primaryColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              try {
                await _userController.deleteUser(user.id);
                Navigator.pop(context);
                setState(() {
                  _usersFuture = _userController.getAllUsers();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Pengguna berhasil dihapus'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            child: Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
