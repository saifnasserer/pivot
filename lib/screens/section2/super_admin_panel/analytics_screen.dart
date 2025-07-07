import 'package:flutter/material.dart';
import 'package:pivot/providers/super_admin_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:provider/provider.dart';

class AnalyticsScreen extends StatefulWidget {
  // = 'analytics_screen';
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch data when the screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SuperAdminProvider>(
        context,
        listen: false,
      ).fetchDashboardData();
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
        body: Consumer<SuperAdminProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return Center(
                child: CircularProgressIndicator(color: Colors.black),
              );
            }
            return RefreshIndicator(
              onRefresh: () => provider.fetchDashboardData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: Responsive.padding(context, size: Space.large),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionTitle(context, 'إحصائيات المستخدمين'),
                    _buildUserStatsCard(provider),
                    SizedBox(
                      height: Responsive.space(context, size: Space.large),
                    ),
                    _buildSectionTitle(context, 'توزيع الأدوار'),
                    _buildRoleDistributionCard(provider),
                    SizedBox(
                      height: Responsive.space(context, size: Space.large),
                    ),
                    _buildSectionTitle(context, 'إحصائيات الأقسام'),
                    _buildDepartmentStatsCard(provider),
                    SizedBox(
                      height: Responsive.space(context, size: Space.large),
                    ),
                    _buildSectionTitle(context, 'إحصائيات المستويات'),
                    _buildLevelStatsCard(provider),
                    SizedBox(
                      height: Responsive.space(context, size: Space.large),
                    ),
                    _buildSectionTitle(context, 'إحصائيات الجنس'),
                    _buildGenderStatsCard(provider),
                    SizedBox(
                      height: Responsive.space(context, size: Space.large),
                    ),
                    _buildSectionTitle(context, 'إحصائيات الأقسام الفرعية'),
                    _buildSectionStatsCard(provider),
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

  Widget _buildUserStatsCard(SuperAdminProvider provider) {
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
            provider.totalUsers.toString(),
            Colors.blue,
          ),
          SizedBox(height: Responsive.space(context, size: Space.medium)),
          _buildInfoTile(
            context,
            Icons.person_add,
            'المستخدمين الجدد هذا الشهر',
            provider.newUsersThisMonth.toString(),
            Colors.green,
          ),
          SizedBox(height: Responsive.space(context, size: Space.medium)),
          _buildInfoTile(
            context,
            Icons.trending_up,
            'نسبة النمو',
            '${provider.getGrowthRate().round()}%',
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleDistributionCard(SuperAdminProvider provider) {
    final roles = [
      {
        'name': 'طلاب',
        'count': provider.userRolesCount['Student'] ?? 0,
        'color': Colors.green,
      },
      {
        'name': 'أساتذة',
        'count':
            (provider.userRolesCount['Professor'] ?? 0) +
            (provider.userRolesCount['miniProfessor'] ?? 0),
        'color': Colors.purple,
      },
      {
        'name': 'مدراء',
        'count': provider.userRolesCount['Admin'] ?? 0,
        'color': Colors.orange,
      },
      {
        'name': 'مدراء عامين',
        'count': provider.userRolesCount['Super Admin'] ?? 0,
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
                  provider.totalUsers > 0
                      ? (((role['count'] as int) / provider.totalUsers) * 100)
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

  Widget _buildDepartmentStatsCard(SuperAdminProvider provider) {
    final departments = provider.getTopDepartments();

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

  Widget _buildLevelStatsCard(SuperAdminProvider provider) {
    final levels = provider.getTopLevels();

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

  Widget _buildGenderStatsCard(SuperAdminProvider provider) {
    final genders = [
      {
        'name': 'ذكور',
        'count': provider.genderStats['ذكر'] ?? 0,
        'color': Colors.blue,
      },
      {
        'name': 'إناث',
        'count': provider.genderStats['أنثى'] ?? 0,
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
                  provider.totalUsers > 0
                      ? (((gender['count'] as int) / provider.totalUsers) * 100)
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

  Widget _buildSectionStatsCard(SuperAdminProvider provider) {
    final sections = provider.getTopSections();

    if (sections.isEmpty) {
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
            'لا توجد بيانات للأقسام الفرعية',
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
            sections.map((section) {
              return Column(
                children: [
                  _buildSectionTile(
                    context,
                    section['name'] as String,
                    section['count'] as int,
                    section['percentage'] as int,
                  ),
                  if (section != sections.last)
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

  Widget _buildSectionTile(
    BuildContext context,
    String section,
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
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.group_work,
              size: Responsive.text(context, size: TextSize.heading),
              color: Colors.teal,
            ),
          ),
          SizedBox(width: Responsive.space(context, size: Space.medium)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section,
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
}
