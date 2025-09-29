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

  /// Get categories based on user department
  /// Returns ordered list: Other Departments - User's Department - General - Today's News
  /// For RTL display (rightmost is Today's News)
  static List<String> getCategories(String? userDepartment) {
    // Create ordered list: Other Departments - User's Department - General - Today's News
    final orderedCategories = <String>[];

    // 1. Other departments (excluding Today's News and General)
    for (final category in baseCategories) {
      if (category != 'اخبار النهاردة' && category != 'اخبار عامة') {
        orderedCategories.add(category);
      }
    }

    // 2. User's Department (if it exists in the list and not already added)
    if (userDepartment != null &&
        baseCategories.contains(userDepartment) &&
        !orderedCategories.contains(userDepartment)) {
      orderedCategories.add(userDepartment);
    }

    // 3. General (always second to last)
    orderedCategories.add('اخبار عامة');

    // 4. Today's News (always last/rightmost)
    orderedCategories.add('اخبار النهاردة');

    return orderedCategories; // No need to reverse - already in correct RTL order
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
