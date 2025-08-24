import 'package:flutter/material.dart';
import 'package:pivot/providers/super_admin_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';

import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/widgets/no_internet_message.dart';

class SuperAdminPanelScreen extends StatefulWidget {
  const SuperAdminPanelScreen({super.key});

  @override
  State<SuperAdminPanelScreen> createState() => _SuperAdminPanelScreenState();
}

class _SuperAdminPanelScreenState extends State<SuperAdminPanelScreen> {
  bool _showAnalytics = true;

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
      child: NoInternetMessage(
        child: Scaffold(
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
                      // Analytics Section (Collapsible)
                      _buildAnalyticsSection(provider),
                      SizedBox(
                        height: Responsive.space(context, size: Space.large),
                      ),
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
                      _buildSectionTitle(context, 'إعدادات التطبيق'),
                      _buildSettingsCard(provider),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsSection(SuperAdminProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(context, 'إحصائيات'),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/analytics');
                  },
                  icon: Icon(
                    Icons.analytics,
                    color: Colors.blue,
                    size: Responsive.text(context, size: TextSize.heading),
                  ),
                  tooltip: 'عرض التحليلات التفصيلية',
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showAnalytics = !_showAnalytics;
                    });
                  },
                  icon: Icon(
                    _showAnalytics ? Icons.expand_less : Icons.expand_more,
                    color: Colors.blue,
                    size: Responsive.text(context, size: TextSize.heading),
                  ),
                ),
              ],
            ),
          ],
        ),
        if (_showAnalytics) ...[
          SizedBox(height: Responsive.space(context, size: Space.medium)),
          _buildCompactAnalyticsCard(provider),
        ],
      ],
    );
  }

  Widget _buildCompactAnalyticsCard(SuperAdminProvider provider) {
    return Container(
      width: double.infinity,
      padding: Responsive.padding(context, size: Space.large),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCompactInfoTile(
              context,
              Icons.people,
              'إجمالي',
              provider.totalUsers.toString(),
              Colors.blue,
            ),
          ),
          SizedBox(width: Responsive.space(context, size: Space.medium)),
          Expanded(
            child: _buildCompactInfoTile(
              context,
              Icons.shield,
              'الطلاب',
              '${provider.userRolesCount['Student'] ?? 0}',
              Colors.green,
            ),
          ),
          SizedBox(width: Responsive.space(context, size: Space.medium)),
          Expanded(
            child: _buildCompactInfoTile(
              context,
              Icons.admin_panel_settings,
              'المدراء',
              '${provider.userRolesCount['admin'] ?? 0}',
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfoTile(
    BuildContext context,
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding: Responsive.padding(context, size: Space.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Container(
            padding: Responsive.padding(context, size: Space.small),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: Responsive.text(context, size: TextSize.medium),
              color: color,
            ),
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: Responsive.text(context, size: TextSize.medium),
              color: Colors.black87,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: Responsive.text(context, size: TextSize.small),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
          _buildDivider(),
          _buildManagementTile(
            context,
            Icons.schedule,
            'الإشعارات المجدولة',
            'إدارة الإشعارات المجدولة والقادمة',
            () {
              Navigator.pushNamed(context, '/upcoming-notifications');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(SuperAdminProvider provider) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            context,
            Icons.logout,
            'تسجيل الخروج',
            'تسجيل الخروج من الحساب',
            () => _showLogoutConfirmationDialog(),
            Colors.red,
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
                Provider.of<SuperAdminProvider>(
                  context,
                  listen: false,
                ).fetchDashboardData();
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

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return UnifiedDialog(
          title: 'تسجيل الخروج؟',
          subtitle: 'هل أنت متأكد من رغبتك في تسجيل الخروج؟',
          content: Container(
            padding: Responsive.padding(context, size: Space.medium),
            child: Row(
              children: [
                Icon(
                  Icons.logout,
                  color: Colors.orange,
                  size: Responsive.text(context, size: TextSize.heading),
                ),
                SizedBox(width: Responsive.space(context, size: Space.medium)),
                Expanded(
                  child: Text(
                    'سيتم تسجيل خروجك من التطبيق وستحتاج إلى تسجيل الدخول مرة أخرى للوصول إلى لوحة الإدارة.',
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.medium),
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          confirmText: 'تأكيد الخروج',
          confirmIcon: Icons.logout,
          onConfirm: () async {
            await FirebaseAuth.instance.signOut();
            if (!mounted) return;
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/auth-wrapper',
              (Route<dynamic> route) => false,
            );
          },
          onCancel: () => Navigator.pop(context),
        );
      },
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

  Widget _buildSettingsTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
    Color color,
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
