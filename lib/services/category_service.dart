class CategoryService {
  static const List<String> baseCategories = [
    'اخبار النهاردة',
    'عام',
    'SC',
    'AI',
    'CS',
    'IS',
    'General',
  ];

  /// Get categories based on user department
  /// Returns ordered list: Today's News - General - User's Department - Other Departments
  /// Reversed for RTL display (rightmost first)
  static List<String> getCategories(String? userDepartment) {
    // If no user department, return default order
    if (userDepartment == null) {
      return baseCategories.reversed.toList(); // Reverse for RTL
    }

    // Create ordered list: Today's News - General - User's Department - Other Departments
    final orderedCategories = <String>[];

    // 1. Today's News (always first)
    orderedCategories.add('اخبار النهاردة');

    // 2. General (always second)
    orderedCategories.add('عام');

    // 3. User's Department (if it exists in the list)
    if (baseCategories.contains(userDepartment)) {
      orderedCategories.add(userDepartment);
    }

    // 4. Other departments (excluding the ones already added)
    for (final category in baseCategories) {
      if (!orderedCategories.contains(category)) {
        orderedCategories.add(category);
      }
    }

    return orderedCategories.reversed.toList(); // Reverse for RTL display
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
        departmentCode = 'عام';
      }
    } else if (category == 'عام') {
      departmentCode = 'عام';
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
