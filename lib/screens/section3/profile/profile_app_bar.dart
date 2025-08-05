import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';
import 'profile_provider.dart';

class ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController tabController;
  final VoidCallback onLogoutPressed;

  const ProfileAppBar({
    super.key,
    required this.tabController,
    required this.onLogoutPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'المطبخ',
        style: TextStyle(
          fontSize: Responsive.text(context, size: TextSize.heading),
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.red),
          onPressed: () => _showLogoutConfirmationDialog(context),
          tooltip: 'تسجيل الخروج',
        ),
      ],
      bottom: TabBar(
        controller: tabController,
        isScrollable: true,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.large),
          ),
          color: Colors.black,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.black,
        labelStyle: TextStyle(
          fontSize: Responsive.text(context, size: TextSize.medium),
          fontWeight: FontWeight.w600,
          fontFamily: 'NotoSansArabic',
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: Responsive.text(context, size: TextSize.medium),
          fontWeight: FontWeight.w500,
          fontFamily: 'NotoSansArabic',
        ),
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.space(context, size: Space.medium),
        ),
        tabs: const [
          Tab(text: 'الملف الشخصي'),
          Tab(text: 'المحفوظات'),
          Tab(text: 'السكاشن'),
          Tab(text: 'مواد الترم'),
          Tab(text: 'الجدول'),
          Tab(text: 'تاسكات الاسبوع'),
        ],
      ),
    );
  }

  Future<void> _showLogoutConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
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
                    'سيتم تسجيل خروجك من التطبيق وستحتاج إلى تسجيل الدخول مرة أخرى للوصول إلى ملفك الشخصي.',
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
            final provider = context.read<ProfileProvider>();
            await provider.logout();
            if (!context.mounted) return;
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/auth-wrapper',
              (Route<dynamic> route) => false,
            );
          },
          onCancel: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 48);
}
