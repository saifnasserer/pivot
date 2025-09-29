import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/administration/providers/super_admin_provider.dart';
import 'package:pivot/responsive.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch data when the screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(superAdminProvider.notifier).fetchDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'الإحصائيات والتحليلات',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.heading),
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Consumer(
          builder: (context, ref, child) {
            final superAdminState = ref.watch(superAdminProvider);

            if (superAdminState.isLoading) {
              return Center(
                child: CircularProgressIndicator(color: Colors.black),
              );
            }

            return RefreshIndicator(
              onRefresh:
                  () =>
                      ref
                          .read(superAdminProvider.notifier)
                          .fetchDashboardData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: Responsive.padding(context, size: Space.large),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionTitle(context, 'إحصائيات المستخدمين'),
                    _buildUserStatsCard(superAdminState),
                    SizedBox(
                      height: Responsive.space(context, size: Space.large),
                    ),
                    _buildSectionTitle(context, 'توزيع الأدوار'),
                    _buildRoleDistributionCard(superAdminState),
                    SizedBox(
                      height: Responsive.space(context, size: Space.large),
                    ),
                    _buildSectionTitle(context, 'إحصائيات الأقسام'),
                    _buildDepartmentStatsCard(superAdminState),
                    SizedBox(
                      height: Responsive.space(context, size: Space.large),
                    ),
                    _buildSectionTitle(context, 'إحصائيات المستويات'),
                    _buildLevelStatsCard(superAdminState),
                    SizedBox(
                      height: Responsive.space(context, size: Space.large),
                    ),
                    _buildSectionTitle(context, 'إحصائيات الجنس'),
                    _buildGenderStatsCard(superAdminState),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: Responsive.space(context, size: Space.medium),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: Responsive.text(context, size: TextSize.heading),
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildUserStatsCard(SuperAdminState provider) {
    return Container(
      width: double.infinity,
      padding: Responsive.padding(context, size: Space.large),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildInfoTile(
            context,
            Icons.people,
            'إجمالي المستخدمين',
            (provider.dashboardData?['totalUsers'] ?? 0).toString(),
            Colors.blue,
          ),
          SizedBox(height: Responsive.space(context, size: Space.medium)),
          _buildInfoTile(
            context,
            Icons.person_add,
            'المستخدمين الجدد هذا الشهر',
            (provider.dashboardData?['newUsersThisMonth'] ?? 0).toString(),
            Colors.green,
          ),
          SizedBox(height: Responsive.space(context, size: Space.medium)),
          _buildInfoTile(
            context,
            Icons.trending_up,
            'نسبة النمو',
            '${_calculateGrowthRate(provider).round()}%',
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleDistributionCard(SuperAdminState provider) {
    final roles = [
      {
        'name': 'طلاب',
        'count': (provider.dashboardData?['userRolesCount']?['Student'] ?? 0),
        'color': Colors.green,
      },
      {
        'name': 'أساتذة',
        'count':
            (provider.dashboardData?['userRolesCount']?['Professor'] ?? 0) +
            (provider.dashboardData?['userRolesCount']?['miniProfessor'] ?? 0),
        'color': Colors.purple,
      },
      {
        'name': 'مدراء',
        'count': (provider.dashboardData?['userRolesCount']?['Admin'] ?? 0),
        'color': Colors.orange,
      },
      {
        'name': 'مدراء عامين',
        'count':
            (provider.dashboardData?['userRolesCount']?['Super Admin'] ?? 0),
        'color': Colors.red,
      },
    ];

    return Container(
      width: double.infinity,
      padding: Responsive.padding(context, size: Space.large),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children:
            roles.map((role) {
              final percentage =
                  (provider.dashboardData?['totalUsers'] ?? 0) > 0
                      ? (((role['count'] as int) /
                                  (provider.dashboardData?['totalUsers'] ??
                                      1)) *
                              100)
                          .round()
                      : 0;

              return Column(
                children: [
                  _buildRoleTile(
                    context,
                    role['name'] as String,
                    role['count'] as int,
                    percentage,
                    role['color'] as Color,
                  ),
                  if (role != roles.last)
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                ],
              );
            }).toList(),
      ),
    );
  }

  Widget _buildDepartmentStatsCard(SuperAdminState provider) {
    final departments = provider.topDepartments ?? [];

    if (departments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: Responsive.padding(context, size: Space.large),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Center(
          child: Text(
            'لا توجد بيانات للأقسام',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.medium),
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: Responsive.padding(context, size: Space.large),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children:
            departments.map((dept) {
              return Column(
                children: [
                  _buildDepartmentTile(
                    context,
                    dept['name'] as String,
                    dept['count'] as int,
                    dept['percentage'] as int,
                  ),
                  if (dept != departments.last)
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                ],
              );
            }).toList(),
      ),
    );
  }

  Widget _buildLevelStatsCard(SuperAdminState provider) {
    final levels = provider.topLevels ?? [];

    if (levels.isEmpty) {
      return Container(
        width: double.infinity,
        padding: Responsive.padding(context, size: Space.large),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Center(
          child: Text(
            'لا توجد بيانات للمستويات',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.medium),
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: Responsive.padding(context, size: Space.large),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children:
            levels.map((level) {
              return Column(
                children: [
                  _buildLevelTile(
                    context,
                    level['name'] as String,
                    level['count'] as int,
                    level['percentage'] as int,
                  ),
                  if (level != levels.last)
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                ],
              );
            }).toList(),
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: Responsive.padding(context, size: Space.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: Responsive.padding(context, size: Space.small),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: Responsive.text(context, size: TextSize.heading),
              color: color,
            ),
          ),
          SizedBox(width: Responsive.space(context, size: Space.medium)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: Responsive.text(context, size: TextSize.small),
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

  Widget _buildRoleTile(
    BuildContext context,
    String roleName,
    int count,
    int percentage,
    Color color,
  ) {
    return Container(
      padding: Responsive.padding(context, size: Space.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: Responsive.padding(context, size: Space.small),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person,
              size: Responsive.text(context, size: TextSize.heading),
              color: color,
            ),
          ),
          SizedBox(width: Responsive.space(context, size: Space.medium)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roleName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '$count مستخدم ($percentage%)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: Responsive.text(context, size: TextSize.small),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.space(context, size: Space.small),
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$percentage%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: Responsive.text(context, size: TextSize.small),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentTile(
    BuildContext context,
    String department,
    int count,
    int percentage,
  ) {
    return Container(
      padding: Responsive.padding(context, size: Space.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: Responsive.padding(context, size: Space.small),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.school,
              size: Responsive.text(context, size: TextSize.heading),
              color: Colors.blue,
            ),
          ),
          SizedBox(width: Responsive.space(context, size: Space.medium)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  department,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '$count طالب ($percentage%)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: Responsive.text(context, size: TextSize.small),
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

  Widget _buildLevelTile(
    BuildContext context,
    String level,
    int count,
    int percentage,
  ) {
    return Container(
      padding: Responsive.padding(context, size: Space.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: Responsive.padding(context, size: Space.small),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.grade,
              size: Responsive.text(context, size: TextSize.heading),
              color: Colors.green,
            ),
          ),
          SizedBox(width: Responsive.space(context, size: Space.medium)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المستوى $level',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '$count طالب ($percentage%)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: Responsive.text(context, size: TextSize.small),
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

  Widget _buildGenderStatsCard(SuperAdminState provider) {
    // Debug: Print all gender stats to see what's available

    final genders = [
      {
        'name': 'ذكور',
        'count': (provider.dashboardData?['genderStats']?['ذكر'] ?? 0),
        'color': Colors.blue,
      },
      {
        'name': 'إناث',
        'count': (provider.dashboardData?['genderStats']?['أنثى'] ?? 0),
        'color': Colors.pink,
      },
    ];

    return Container(
      width: double.infinity,
      padding: Responsive.padding(context, size: Space.large),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children:
            genders.map((gender) {
              final percentage =
                  (provider.dashboardData?['totalUsers'] ?? 0) > 0
                      ? (((gender['count'] as int) /
                                  (provider.dashboardData?['totalUsers'] ??
                                      1)) *
                              100)
                          .round()
                      : 0;

              return Column(
                children: [
                  _buildGenderTile(
                    context,
                    gender['name'] as String,
                    gender['count'] as int,
                    percentage,
                    gender['color'] as Color,
                  ),
                  if (gender != genders.last)
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                ],
              );
            }).toList(),
      ),
    );
  }

  Widget _buildGenderTile(
    BuildContext context,
    String genderName,
    int count,
    int percentage,
    Color color,
  ) {
    return Container(
      padding: Responsive.padding(context, size: Space.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: Responsive.padding(context, size: Space.small),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person,
              size: Responsive.text(context, size: TextSize.heading),
              color: color,
            ),
          ),
          SizedBox(width: Responsive.space(context, size: Space.medium)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  genderName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '$count مستخدم ($percentage%)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: Responsive.text(context, size: TextSize.small),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.space(context, size: Space.small),
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$percentage%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: Responsive.text(context, size: TextSize.small),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateGrowthRate(SuperAdminState provider) {
    final dashboardData = provider.dashboardData;
    if (dashboardData == null) return 0.0;

    final totalUsers = dashboardData['totalUsers'] as int? ?? 0;
    final newUsersThisMonth = dashboardData['newUsersThisMonth'] as int? ?? 0;

    if (totalUsers == 0) return 0.0;
    return (newUsersThisMonth / totalUsers) * 100;
  }
}
