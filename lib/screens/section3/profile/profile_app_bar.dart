import 'package:flutter/material.dart';

import 'package:pivot/responsive.dart';

class ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController tabController;

  const ProfileAppBar({super.key, required this.tabController});

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
      title: TabBar(
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
          fontSize: Responsive.text(context, size: TextSize.small),
          fontWeight: FontWeight.w600,
          fontFamily: 'NotoSansArabic',
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: Responsive.text(context, size: TextSize.small),
          fontWeight: FontWeight.w500,
          fontFamily: 'NotoSansArabic',
        ),
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.space(context, size: Space.small),
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
      centerTitle: false,
      titleSpacing: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
