import 'package:flutter/material.dart';
import 'package:pivot/providers/super_admin_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section2/admin_control.dart';

import 'package:pivot/screens/section2/adminstration/user_management_page.dart';
import 'package:pivot/screens/section2/adminstration/global_subject_management_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/screens/section1/auth_wrapper.dart';
import 'package:pivot/services/remote_config_service.dart';

class SuperAdminPanelScreen extends StatefulWidget {
  const SuperAdminPanelScreen({super.key});

  @override
  State<SuperAdminPanelScreen> createState() => _SuperAdminPanelScreenState();
}

class _SuperAdminPanelScreenState extends State<SuperAdminPanelScreen> {
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
        appBar: AppBar(title: const Text('الادارة')),
        body: Consumer<SuperAdminProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return RefreshIndicator(
              onRefresh: () => provider.fetchDashboardData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: Responsive.padding(context, size: Space.medium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(context, 'إحصائيات'),
                    _buildAnalyticsCard(provider),
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
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: Responsive.space(context, size: Space.small),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: Responsive.text(context, size: TextSize.heading),
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(SuperAdminProvider provider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: Responsive.padding(context, size: Space.medium),
        child: Column(
          children: [
            _buildInfoTile(
              context,
              Icons.people,
              'إجمالي المستخدمين',
              provider.totalUsers.toString(),
            ),
            const Divider(),
            _buildInfoTile(
              context,
              Icons.shield,
              'الأدوار',
              '${provider.userRolesCount['Student'] ?? 0} طالب, ${provider.userRolesCount['Professor'] ?? 0} أستاذ',
            ),
            const Divider(),
            _buildInfoTile(
              context,
              Icons.cloud_done,
              'حالة النظام',
              'يعمل',
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          _buildManagementTile(
            context,
            Icons.manage_accounts,
            'إدارة أدوار المستخدمين',
            () {
              Navigator.pushNamed(context, UserManagementPage.id);
            },
          ),
          const Divider(height: 1),
          _buildManagementTile(context, Icons.school, 'إدارة السكاشن', () {
            Navigator.pushNamed(context, '/section-management');
          }),
          const Divider(height: 1),
          _buildManagementTile(context, Icons.menu_book, 'إدارة المواد', () {
            Navigator.pushNamed(context, GlobalSubjectManagementScreen.id);
          }),
          // const Divider(height: 1),
          // _buildManagementTile(context, Icons.campaign, 'إدارة الإعلانات', () {
          //   Navigator.pushNamed(context, AdminControl.id);
          // }),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(SuperAdminProvider provider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(
              'وضع الصيانة',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
              ),
            ),
            secondary: const Icon(Icons.construction),
            value: provider.isMaintenanceMode,
            onChanged: (bool value) {
              provider.setMaintenanceMode(value);
            },
          ),
          const Divider(height: 1),
          // ListTile(
          //   leading: const Icon(Icons.cleaning_services),
          //   title: Text(
          //     'مسح ذاكرة التخزين المؤقت للصور',
          //     style: TextStyle(
          //       fontSize: Responsive.text(context, size: TextSize.medium),
          //     ),
          //   ),
          //   onTap: () async {
          //     await provider.clearImageCache();
          //     if (!context.mounted) return;
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       const SnackBar(
          //         content: Text('تم مسح ذاكرة التخزين المؤقت للصور بنجاح!'),
          //       ),
          //     );
          //   },
          // ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.sync),
            title: Text(
              'ارفع الابديت (Remote Config)',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
              ),
            ),
            onTap: () async {
              final remoteConfigService = Provider.of<RemoteConfigService>(
                context,
                listen: false,
              );
              final success = await remoteConfigService.forceFetch();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'تم التحديث بنجاح!' : 'فشل التحديث.'),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              'تسجيل الخروج',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
                color: Colors.red,
              ),
            ),
            onTap: () => _showLogoutConfirmationDialog(),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تسجيل الخروج', textAlign: TextAlign.center),
            actions: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text(
                      'تأكيد',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (!mounted) return;
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AuthWrapper.id,
                        (Route<dynamic> route) => false,
                      );
                    },
                  ),
                  TextButton(
                    child: const Text('لا'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, size: 30),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: Responsive.text(context, size: TextSize.medium),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: color ?? Colors.black54,
          fontSize: Responsive.text(context, size: TextSize.small),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildManagementTile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(
        title,
        style: TextStyle(
          fontSize: Responsive.text(context, size: TextSize.medium),
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }
}
