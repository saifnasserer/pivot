class CategoryService {
  static const List<String> baseCategories = [
    'اخبار النهاردة',
    'اخبار عامة',
    'SC',
    'AI',
    'CS',
    'IS',
    'General',
  ];

  /// Get categories based on user department and level
  /// Returns ordered list for RTL display: Other Departments - User's Department - General - Today's News
  /// Priority order (rightmost first): Today's News → General News → Department(s)
  ///
  /// Level-based filtering (same as signup):
  /// - Years 1-2 (الفرقة الأولى, الفرقة الثانية): Only General department
  /// - Years 3-4 (الفرقة الثالثة, الفرقة الرابعة): All departments EXCEPT General
  static List<String> getCategories(
    String? userDepartment, {
    String? userLevel,
  }) {
    final orderedCategories = <String>[];

    // Determine which departments to show based on user level
    final isFirstOrSecondYear =
        userLevel == 'الفرقة الأولى' || userLevel == 'الفرقة الثانية';

    print(
      '📱 [CategoryService] User level: $userLevel, isFirstOrSecondYear: $isFirstOrSecondYear',
    );

    if (isFirstOrSecondYear) {
      // Years 1-2: Only show General department category
      orderedCategories.add('General');
    } else {
      // Years 3-4 (or null): Show all departments except General
      // 1. Other departments (excluding Today's News, General News, General, and user's department)
      for (final category in baseCategories) {
        if (category != 'اخبار النهاردة' &&
            category != 'اخبار عامة' &&
            category != 'General' &&
            category != userDepartment) {
          orderedCategories.add(category);
        }
      }

      // 2. User's Department (if exists and is a valid specialized department)
      if (userDepartment != null &&
          baseCategories.contains(userDepartment) &&
          userDepartment != 'General') {
        orderedCategories.add(userDepartment);
      }
    }

    // 3. General News (always second to last - second from right)
    orderedCategories.add('اخبار عامة');

    // 4. Today's News (always last/rightmost - highest priority)
    orderedCategories.add('اخبار النهاردة');

    print(
      '📱 [CategoryService] Ordered categories for user (dept: $userDepartment, level: $userLevel): $orderedCategories',
    );
    return orderedCategories;
  }

  /// Normalize department name by removing 'اخبار قسم ' prefix
  static String? normalizeDepartment(String? department) {
    if (department == null) return null;

    if (department.startsWith('اخبار قسم ')) {
      return department.replaceFirst('اخبار قسم ', '');
    }

    return department;
  }

  /// Get department code for API calls
  static String? getDepartmentCode(String category, String? userDepartment) {
    String? departmentCode;

    if (category == 'SC' ||
        category == 'AI' ||
        category == 'CS' ||
        category == 'IS' ||
        category == 'General') {
      departmentCode = 'اخبار قسم $category';
    } else if (category == 'اخبار النهاردة') {
      // Handle today's news with mixed department content
      String? normalizedDepartment = normalizeDepartment(userDepartment);

      if (normalizedDepartment != null) {
        departmentCode = 'today_mixed:اخبار قسم $normalizedDepartment';
      } else {
        departmentCode = 'اخبار عامة';
      }
    } else if (category == 'اخبار عامة') {
      departmentCode = 'اخبار عامة';
    }

    return departmentCode;
  }

  /// Get time filter for API calls
  static String? getTimeFilter(String category) {
    if (category == 'اخبار النهاردة') {
      return 'today';
    }
    return null;
  }
}
