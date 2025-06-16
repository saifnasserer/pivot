import 'package:flutter/material.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/services/auth_service.dart';
import 'package:pivot/responsive.dart';

class UserManagementPage extends StatefulWidget {
  static const String id = 'user_management_page';
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final AuthService _authService = AuthService();
  late Future<List<UserProfile>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = _authService.getAllUsers();
  }

  void _refreshUsers() {
    setState(() {
      _usersFuture = _authService.getAllUsers();
    });
  }

  Future<void> _showEditRoleDialog(UserProfile user) async {
    String selectedRole = user.role;
    final roles = ['Super Admin', 'Admin', 'Professor', 'miniProfessor', 'Student'];

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'تغيير دور ${user.name}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: Responsive.text(context, size: TextSize.heading),
            ),
          ),
          content: DropdownButton<String>(
            value: selectedRole,
            isExpanded: true,
            items: roles.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                // This requires the dialog to be a StatefulWidget to update the UI,
                // so we'll just handle it on save for simplicity.
                selectedRole = newValue;
              }
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('الغاء'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text('حفظ', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                try {
                  await _authService.updateUserRole(user.id, selectedRole);
                  Navigator.of(context).pop();
                  _refreshUsers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم تحديث دور ${user.name}')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فشل تحديث الدور: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'ادارة المستخدمين',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<List<UserProfile>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا يوجد مستخدمين'));
          }

          final users = snapshot.data!;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Column(
                children: [
                  ListTile(
                    title: Text(
                      user.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: Responsive.text(context, size: TextSize.medium),
                      ),
                    ),
                    subtitle: Text(
                      user.role,
                      style: TextStyle(
                        fontSize: Responsive.text(context, size: TextSize.small),
                      ),
                    ),
                    onTap: () => _showEditRoleDialog(user),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
