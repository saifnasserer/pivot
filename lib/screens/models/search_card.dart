import 'package:flutter/material.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/services/auth_service.dart';
import 'package:pivot/services/cache_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserSearchCard extends StatelessWidget {
  final UserProfile user;
  final VoidCallback? onTap;
  const UserSearchCard({super.key, required this.user, this.onTap});

  String getTitle() {
    if (user.role.toLowerCase() == 'professor') {
      String title = user.gender == 'ذكر' ? 'الدكتور ' : 'الدكتورة ';
      return title;
    } else if (user.role.toLowerCase() == 'miniprofessor') {
      String title = user.gender == 'ذكر' ? 'البشمهندس ' : 'البشمهندسة ';
      return title;
    }
    return '';
  }

  void _defaultTap(BuildContext context) {
    if (user.role.toLowerCase() == 'professor') {
      Navigator.pushNamed(context, '/doctor-profile', arguments: user);
    } else if (user.role.toLowerCase() == 'miniprofessor') {
      Navigator.pushNamed(context, '/assistant-profile', arguments: user);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gold = Colors.grey;
    return InkWell(
      borderRadius: BorderRadius.circular(
        Responsive.space(context, size: Space.large),
      ),
      onTap: onTap ?? () => _defaultTap(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.large),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: gold, width: 1.2),
        ),
        padding: EdgeInsets.symmetric(
          vertical: Responsive.space(context, size: Space.small) * 1.2,
          horizontal: Responsive.space(context, size: Space.medium),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  getTitle(),
                  style: TextStyle(
                    color: gold,
                    fontSize: Responsive.text(context, size: TextSize.small),
                  ),
                  textAlign: TextAlign.right,
                ),
                Text(
                  user.name,
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize:
                        Responsive.text(context, size: TextSize.medium) * 1.1,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
            SizedBox(width: Responsive.space(context, size: Space.medium)),
            CircleAvatar(
              radius: Responsive.space(context, size: Space.medium),
              backgroundColor: gold.withOpacity(0.15),
              child:
                  (user.profileImageUrl != null &&
                          user.profileImageUrl!.isNotEmpty)
                      ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: user.profileImageUrl!,
                          width:
                              Responsive.space(context, size: Space.medium) * 2,
                          height:
                              Responsive.space(context, size: Space.medium) * 2,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Icon(
                                Icons.person,
                                color: gold,
                                size: Responsive.space(
                                  context,
                                  size: Space.large,
                                ),
                              ),
                        ),
                      )
                      : Icon(
                        Icons.person,
                        color: gold,
                        size: Responsive.space(context, size: Space.large),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

void showUserSearchModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(Responsive.space(context, size: Space.large)),
      ),
    ),
    builder: (context) {
      return _UserSearchModalContent();
    },
  );
}

class _UserSearchModalContent extends StatefulWidget {
  @override
  State<_UserSearchModalContent> createState() =>
      _UserSearchModalContentState();
}

class _UserSearchModalContentState extends State<_UserSearchModalContent> {
  final TextEditingController _searchController = TextEditingController();
  List<UserProfile> _allProfessors = [];
  List<UserProfile> _filteredProfessors = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchProfessors();
    _searchController.addListener(_filterProfessors);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfessors() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    // Debugging: print current user and token
    final user = FirebaseAuth.instance.currentUser;
    print('Current user: ${user?.uid ?? 'null'}');
    if (user != null) {
      final token = await user.getIdToken();
      print('User token: $token');
    }

    try {
      // Direct server fetch first (bypass cache for testing)
      final serverUsers = await AuthService().getAllUsers();

      final filteredServerUsers =
          serverUsers
              .where(
                (u) => [
                  'Professor',
                  'miniProfessor',
                  'professor',
                  'miniprofessor',
                ].contains(u.role),
              )
              .toList();

      // Update UI immediately with server data
      if (mounted) {
        setState(() {
          _allProfessors = filteredServerUsers;
          _filteredProfessors = filteredServerUsers;
          _isLoading = false;
        });
        await CacheService.instance.cacheUsers(serverUsers);
      }

      // Load from cache for future use
      final cachedUsers = CacheService.instance.getCachedUsers();
      if (cachedUsers.isNotEmpty) {
        final filteredCachedUsers =
            cachedUsers
                .where(
                  (u) => [
                    'professor',
                    'miniprofessor',
                  ].contains(u.role.trim().toLowerCase()),
                )
                .toList();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load users: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _filterProfessors() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filteredProfessors =
          _allProfessors
              .where(
                (u) =>
                    u.name.toLowerCase().contains(q) ||
                    (u.email?.toLowerCase().contains(q) ?? false),
              )
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: Responsive.space(context, size: Space.medium),
        left: Responsive.space(context, size: Space.medium),
        right: Responsive.space(context, size: Space.medium),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Search Field - Always visible at top
          SizedBox(
            height: 60,
            child: TextField(
              controller: _searchController,
              autofocus: true,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'ابحث عن دكتور أو مهندس',
                suffixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                ),
                contentPadding: Responsive.padding(context, size: Space.small),
              ),
            ),
          ),
          SizedBox(height: Responsive.space(context, size: Space.medium)),

          // Content Area - Flexible to take remaining space
          Expanded(child: _buildContentArea()),
        ],
      ),
    );
  }

  Widget _buildContentArea() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error if there's one
    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: Responsive.space(context, size: Space.xlarge),
              color: Colors.red[400],
            ),
            SizedBox(height: Responsive.space(context, size: Space.medium)),
            Text(
              'خطأ في تحميل البيانات',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
                color: Colors.red[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: Responsive.space(context, size: Space.small)),
            Text(
              _error,
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.small),
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Responsive.space(context, size: Space.medium)),
            ElevatedButton(
              onPressed: _fetchProfessors,
              child: Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (_filteredProfessors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: Responsive.space(context, size: Space.xlarge),
              color: Colors.grey[400],
            ),
            SizedBox(height: Responsive.space(context, size: Space.medium)),
            Text(
              _searchController.text.isEmpty
                  ? 'لا يوجد مستخدمين متاحين'
                  : 'لا يوجد نتائج مطابقة',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
                color: Colors.grey[600],
              ),
            ),
            // Debug information
            if (_allProfessors.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                  top: Responsive.space(context, size: Space.small),
                ),
                child: Text(
                  'إجمالي المستخدمين: ${_allProfessors.length}',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.small),
                    color: Colors.grey[500],
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _filteredProfessors.length,
      itemBuilder: (context, index) {
        final user = _filteredProfessors[index];
        return Padding(
          padding: EdgeInsets.symmetric(
            vertical: Responsive.space(context, size: Space.tiny),
          ),
          child: UserSearchCard(user: user),
        );
      },
    );
  }
}
