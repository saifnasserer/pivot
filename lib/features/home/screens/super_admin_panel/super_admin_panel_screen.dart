import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/administration/providers/super_admin_provider.dart';
import 'package:pivot/responsive.dart';

class SuperAdminPanelScreen extends ConsumerStatefulWidget {
  const SuperAdminPanelScreen({super.key});
  @override
  ConsumerState<SuperAdminPanelScreen> createState() =>
      _SuperAdminPanelScreenState();
}

class _SuperAdminPanelScreenState extends ConsumerState<SuperAdminPanelScreen> {
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'لوحة الإدارة',
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.heading),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Consumer(
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
                    _buildSectionTitle(context, 'إجراءات سريعة'),
                    _buildQuickActionsCard(),
                    SizedBox(
                      height: Responsive.space(context, size: Space.large),
                    ),
                    _buildSectionTitle(context, 'إدارة'),
                    _buildManagementCard(),
                    SizedBox(
                      height: Responsive.space(context, size: Space.large),
                    ),
                    _buildAnalyticsSection(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnalyticsSection() {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.pushNamed(context, '/analytics');
      },
      icon: Icon(
        Icons.analytics,
        color: Colors.white,
        size: Responsive.text(context, size: TextSize.medium),
      ),
      label: Text(
        'عرض الاحصائيات',
        style: TextStyle(
          color: Colors.white,
          fontSize: Responsive.text(context, size: TextSize.medium),
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[600],
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.space(context, size: Space.medium),
          vertical: Responsive.space(context, size: Space.small),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: Responsive.text(context, size: TextSize.heading),
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildManagementCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildManagementTile(
            context,
            Icons.manage_accounts,
            'إدارة أدوار المستخدمين',
            'إدارة صلاحيات وأدوار المستخدمين',
            () async {
              Navigator.pushNamed(context, '/user-management');
            },
          ),
          _buildDivider(),
          _buildManagementTile(
            context,
            Icons.school,
            'إدارة السكاشن',
            'إدارة أقسام وفرق الطلاب',
            () {
              Navigator.pushNamed(context, '/section-management');
            },
          ),
          _buildDivider(),
          _buildManagementTile(
            context,
            Icons.menu_book,
            'إدارة المواد',
            'إدارة المواد الدراسية والمناهج',
            () {
              Navigator.pushNamed(context, '/global-subject-management');
            },
          ),
          _buildDivider(),
          _buildManagementTile(
            context,
            Icons.feedback,
            'إدارة الملاحظات',
            'عرض وإدارة ملاحظات المستخدمين',
            () {
              Navigator.pushNamed(context, '/feedback-management');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.large),
      ),
      color: Colors.grey[300],
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildQuickActionTile(
            context,
            Icons.person_add,
            'إضافة مستخدم',
            'إضافة مستخدم جديد',
            Colors.green,
            () async {
              final result = await Navigator.pushNamed(context, '/add-user');
              if (result == true) {
                // Refresh data if user was added successfully
                ref.read(superAdminProvider.notifier).fetchDashboardData();
              }
            },
          ),
          _buildDivider(),
          _buildQuickActionTile(
            context,
            Icons.notifications,
            'إرسال إشعار',
            'إرسال إشعار سريع',
            Colors.blue,
            () {
              Navigator.pushNamed(context, '/send-notifications');
            },
          ),
          _buildDivider(),
          _buildQuickActionTile(
            context,
            Icons.notifications_active,
            'اختبار الإشعارات',
            'اختبار نظام الإشعارات وتشخيص المشاكل',
            Colors.purple,
            () {
              Navigator.pushNamed(context, '/notifications-test');
            },
          ),
          _buildDivider(),
          _buildQuickActionTile(
            context,
            Icons.system_update,
            'إدارة التحديثات',
            'إدارة تحديثات التطبيق ووضع الصيانة',
            Colors.orange,
            () {
              Navigator.pushNamed(context, '/update-management');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildManagementTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: Responsive.padding(context, size: Space.large),
          child: Row(
            children: [
              Container(
                padding: Responsive.padding(context, size: Space.small),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: Responsive.text(context, size: TextSize.heading),
                  color: Colors.black87,
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
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.small,
                        ),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: Responsive.text(context, size: TextSize.small),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: Responsive.padding(context, size: Space.large),
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
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.small,
                        ),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: Responsive.text(context, size: TextSize.small),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
