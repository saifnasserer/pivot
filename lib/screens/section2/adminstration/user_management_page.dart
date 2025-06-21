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
  final Map<String, String> _selectedRoles = {};
  final Set<String> _selectedUsers = {};
  bool _isLoading = true;
  String _selectedRoleFilter = 'الكل';
  bool showSearchBar = false;

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
        SnackBar(
          content: Text('فشل في جلب المستخدمين: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers =
          _allUsers.where((user) {
            final userName = user.name.toLowerCase();
            final userEmail = user.email?.toLowerCase() ?? '';
            final matchesSearch =
                userName.contains(query) || userEmail.contains(query);

            if (_selectedRoleFilter == 'الكل') return matchesSearch;
            return matchesSearch && user.role == _selectedRoleFilter;
          }).toList();
    });
  }

  void _onRoleFilterChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedRoleFilter = newValue;
        _filterUsers();
      });
    }
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
        SnackBar(
          content: Text('تم تحديث دور ${user.name} بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل تحديث الدور: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteUser(UserProfile user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'تأكيد الحذف',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.heading),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                'هل أنت متأكد أنك تريد حذف المستخدم ${user.name}? لا يمكن التراجع عن هذا الإجراء.',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(
                          'حذف',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: Responsive.space(context, size: Space.medium),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(
                          'إلغاء',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            fontWeight: FontWeight.bold,
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

    if (confirm == true) {
      try {
        await _authService.deleteUser(user.id);
        setState(() {
          _allUsers.removeWhere((u) => u.id == user.id);
          _filteredUsers.removeWhere((u) => u.id == user.id);
          _selectedUsers.remove(user.id);
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف المستخدم بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل حذف المستخدم: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _bulkUpdateRoles() async {
    if (_selectedUsers.isEmpty) return;

    final roles = [
      'Super Admin',
      'Admin',
      'Professor',
      'miniProfessor',
      'Student',
    ];
    String? selectedRole;

    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'تحديث الأدوار',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.heading),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'اختر الدور الجديد للمستخدمين المحددين (${_selectedUsers.length})',
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.medium),
                    ),
                  ),
                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'الدور الجديد',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items:
                        roles
                            .map(
                              (role) => DropdownMenuItem(
                                value: role,
                                child: Text(role),
                              ),
                            )
                            .toList(),
                    onChanged: (value) => selectedRole = value,
                  ),
                ],
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextButton(
                        onPressed:
                            () => Navigator.of(context).pop(selectedRole),
                        child: Text(
                          'تحديث',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: Responsive.space(context, size: Space.medium),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(null),
                        child: Text(
                          'إلغاء',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            fontWeight: FontWeight.bold,
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

    if (result != null) {
      try {
        for (final userId in _selectedUsers) {
          await _authService.updateUserRole(userId, result);
        }

        setState(() {
          for (final user in _allUsers) {
            if (_selectedUsers.contains(user.id)) {
              user.role = result;
            }
          }
          _selectedUsers.clear();
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحديث ${_selectedUsers.length} مستخدم بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحديث الأدوار: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Super Admin':
        return Colors.red;
      case 'Admin':
        return Colors.orange;
      case 'Professor':
        return Colors.purple;
      case 'miniProfessor':
        return Colors.indigo;
      case 'Student':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'Super Admin':
        return Icons.admin_panel_settings;
      case 'Admin':
        return Icons.manage_accounts;
      case 'Professor':
        return Icons.school;
      case 'miniProfessor':
        return Icons.person;
      case 'Student':
        return Icons.person_outline;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    final roles = [
      'الكل',
      'Super Admin',
      'Admin',
      'Professor',
      'miniProfessor',
      'Student',
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'إدارة أدوار المستخدمين',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.heading),
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          actions: [
            if (_selectedUsers.isNotEmpty)
              Container(
                margin: EdgeInsets.only(
                  right: Responsive.space(context, size: Space.medium),
                ),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton.icon(
                  onPressed: _bulkUpdateRoles,
                  icon: Icon(Icons.edit, color: Colors.white, size: 16),
                  label: Text(
                    'تحديث ${_selectedUsers.length}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.text(context, size: TextSize.small),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _fetchUsers,
          child: Column(
            children: [
              // Search and Filter Section
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(showSearchBar ? Icons.close : Icons.search),
                    onPressed: () {
                      setState(() {
                        showSearchBar = !showSearchBar;
                        if (!showSearchBar) _searchController.clear();
                      });
                    },
                  ),
                ],
              ),
              if (showSearchBar) ...[
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'ابحث بالاسم أو البريد الإلكتروني',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
              ],

              // Users List
              Expanded(
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredUsers.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(
                                height: Responsive.space(
                                  context,
                                  size: Space.medium,
                                ),
                              ),
                              Text(
                                'لا يوجد مستخدمين مطابقين للبحث',
                                style: TextStyle(
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.medium,
                                  ),
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          padding: Responsive.padding(
                            context,
                            size: Space.medium,
                          ),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            final selectedRole = _selectedRoles[user.id];
                            final hasChanged =
                                selectedRole != null &&
                                selectedRole != user.role;
                            final isSelected = _selectedUsers.contains(user.id);

                            return _buildUserCard(
                              user,
                              selectedRole,
                              hasChanged,
                              isSelected,
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

  Widget _buildStatTile(
    BuildContext context,
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: Responsive.padding(context, size: Space.medium),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: Responsive.space(context, size: Space.small)),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: Responsive.text(context, size: TextSize.medium),
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.small),
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(
    UserProfile user,
    String? selectedRole,
    bool hasChanged,
    bool isSelected,
  ) {
    return Container(
      margin: EdgeInsets.only(
        bottom: Responsive.space(context, size: Space.medium),
      ),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedUsers.remove(user.id);
              } else {
                _selectedUsers.add(user.id);
              }
            });
          },
          child: Padding(
            padding: Responsive.padding(context, size: Space.large),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with user info and actions
                Row(
                  children: [
                    // User avatar and info
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: _getRoleColor(user.role).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Icon(
                              _getRoleIcon(user.role),
                              color: _getRoleColor(user.role),
                              size: 24,
                            ),
                          ),
                          SizedBox(
                            width: Responsive.space(
                              context,
                              size: Space.medium,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: Responsive.text(
                                      context,
                                      size: TextSize.medium,
                                    ),
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  user.email ?? 'لا يوجد بريد إلكتروني',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: Responsive.text(
                                      context,
                                      size: TextSize.small,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Role badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.space(
                          context,
                          size: Space.small,
                        ),
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getRoleColor(user.role).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getRoleColor(user.role).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        user.role,
                        style: TextStyle(
                          color: _getRoleColor(user.role),
                          fontWeight: FontWeight.bold,
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.small,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: Responsive.space(context, size: Space.medium)),

                // Role selection dropdown
                DropdownButtonFormField<String>(
                  value: selectedRole ?? user.role,
                  decoration: InputDecoration(
                    labelText: 'تغيير الدور',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  items:
                      [
                            'Super Admin',
                            'Admin',
                            'Professor',
                            'miniProfessor',
                            'Student',
                          ]
                          .map(
                            (role) => DropdownMenuItem(
                              value: role,
                              child: Row(
                                children: [
                                  Icon(
                                    _getRoleIcon(role),
                                    color: _getRoleColor(role),
                                    size: 16,
                                  ),
                                  SizedBox(
                                    width: Responsive.space(
                                      context,
                                      size: Space.small,
                                    ),
                                  ),
                                  Text(role),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedRoles[user.id] = newValue;
                      });
                    }
                  },
                ),

                // Action buttons
                if (hasChanged || isSelected)
                  Padding(
                    padding: EdgeInsets.only(
                      top: Responsive.space(context, size: Space.medium),
                    ),
                    child: Row(
                      children: [
                        if (hasChanged)
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: TextButton.icon(
                                onPressed: () => _updateRole(user),
                                icon: const Icon(
                                  Icons.save,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                label: Text(
                                  'حفظ التغييرات',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: Responsive.text(
                                      context,
                                      size: TextSize.small,
                                    ),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (hasChanged && isSelected)
                          SizedBox(
                            width: Responsive.space(
                              context,
                              size: Space.medium,
                            ),
                          ),
                        if (isSelected)
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: TextButton.icon(
                                onPressed: () => _deleteUser(user),
                                icon: const Icon(
                                  Icons.delete_forever,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                label: Text(
                                  'حذف المستخدم',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: Responsive.text(
                                      context,
                                      size: TextSize.small,
                                    ),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
