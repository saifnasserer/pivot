import 'package:pivot/features/home/services/home_service.dart';

class HomeRepository {
  HomeRepository(this._service);

  final HomeService _service;

  List<String> getCategories(String? userDepartment, {String? userLevel}) =>
      _service.getCategories(userDepartment, userLevel: userLevel);

  String? getDepartmentCode(String category, String? userDepartment) =>
      _service.getDepartmentCode(category, userDepartment);

  String? getTimeFilter(String category) => _service.getTimeFilter(category);

  String? normalizeDepartment(String? department) =>
      _service.normalizeDepartment(department);

  Future<bool> shouldShowUpdateButton() => _service.shouldShowUpdateButton();

  Future<bool> areUpdatesAvailable() => _service.areUpdatesAvailable();
}
