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
  final TextEditingController _searchController = TextEditingController();
  List<UserProfile> _allUsers = [];
  List<UserProfile> _filteredUsers = [];
  Map<String, String> _selectedRoles = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _authService.getAllUsers();
      setState(() {
        _allUsers = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في جلب المستخدمين: $e')),
      );
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final userName = user.name.toLowerCase();
        final userEmail = user.email?.toLowerCase() ?? '';
        return userName.contains(query) || userEmail.contains(query);
      }).toList();
    });
  }

  Future<void> _updateRole(UserProfile user) async {
    final newRole = _selectedRoles[user.id];
    if (newRole == null) return;

    try {
      await _authService.updateUserRole(user.id, newRole);
      setState(() {
        user.role = newRole;
        _selectedRoles.remove(user.id);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديث دور ${user.name} بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تحديث الدور: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final roles = ['Super Admin', 'Admin', 'Professor', 'miniProfessor', 'Student'];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة أدوار المستخدمين'),
          centerTitle: true,
        ),
        body: RefreshIndicator(
          onRefresh: _fetchUsers,
          child: Column(
            children: [
              Padding(
                padding: Responsive.padding(context, size: Space.medium),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'ابحث بالاسم أو البريد الإلكتروني',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredUsers.isEmpty
                        ? Center(
                            child: Text(
                              'لا يوجد مستخدمين مطابقين للبحث',
                              style: TextStyle(
                                fontSize: Responsive.text(context, size: TextSize.medium),
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8.0),
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = _filteredUsers[index];
                              final selectedRole = _selectedRoles[user.id];
                              final hasChanged = selectedRole != null && selectedRole != user.role;

                              return Card(
                                elevation: 4,
                                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Padding(
                                  padding: Responsive.padding(context, size: Space.medium),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: Responsive.text(context, size: TextSize.medium),
                                        ),
                                      ),
                                      Text(
                                        user.email ?? 'لا يوجد بريد إلكتروني',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: Responsive.text(context, size: TextSize.small),
                                        ),
                                      ),
                                      SizedBox(height: Responsive.space(context, size: Space.medium)),
                                      DropdownButtonFormField<String>(
                                        value: selectedRole ?? user.role,
                                        decoration: InputDecoration(
                                          labelText: 'الدور الحالي',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        items: roles.map((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                        onChanged: (String? newValue) {
                                          if (newValue != null) {
                                            setState(() {
                                              _selectedRoles[user.id] = newValue;
                                            });
                                          }
                                        },
                                      ),
                                      if (hasChanged)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 12.0),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: ElevatedButton.icon(
                                              onPressed: () => _updateRole(user),
                                              icon: const Icon(Icons.save),
                                              label: const Text('حفظ التغييرات'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Theme.of(context).primaryColor,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
