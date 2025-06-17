class FormOptions {
  static const List<String> genders = ['ذكر', 'انثى'];

  static const List<String> academicYears = [
    'الفرقة الأولى',
    'الفرقة الثانية',
    'الفرقة الثالثة',
    'الفرقة الرابعة',
  ];

  static const List<String> allDepartments = ['CS', 'IS', 'AI', 'SC', 'General'];

  static List<String> getDepartmentsForYear(String? year) {
    if (year == 'الفرقة الأولى') {
      return ['General'];
    }
    return allDepartments.where((d) => d != 'General').toList();
  }

  static List<String> getSectionsForYear(String? year, String? department) {
    if (year == 'الفرقة الأولى') {
      return List.generate(8, (index) => (index + 1).toString());
    }
    if (year != null && department != null && department != 'General') {
      return List.generate(2, (index) => (index + 1).toString());
    }
    return [];
  }
}
