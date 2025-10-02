import 'package:pivot/services/category_service.dart';
import 'package:pivot/services/update_service.dart';

class HomeService {
  List<String> getCategories(String? userDepartment, {String? userLevel}) {
    return CategoryService.getCategories(userDepartment, userLevel: userLevel);
  }

  String? getDepartmentCode(String category, String? userDepartment) {
    return CategoryService.getDepartmentCode(category, userDepartment);
  }

  String? getTimeFilter(String category) {
    return CategoryService.getTimeFilter(category);
  }

  String? normalizeDepartment(String? department) {
    return CategoryService.normalizeDepartment(department);
  }

  Future<bool> shouldShowUpdateButton() async {
    final updateService = UpdateService();
    return await updateService.shouldShowUpdateButton();
  }

  Future<bool> areUpdatesAvailable() async {
    final updateService = UpdateService();
    return await updateService.areUpdatesAvailable();
  }
}
