import 'package:pivot/features/settings/services/settings_service.dart';

class SettingsRepository {
  SettingsRepository(this._service);

  final SettingsService _service;

  Future<Map<String, int>> fetchSectionCounts() =>
      _service.fetchSectionCounts();

  Future<bool> fetchTeamFormationButtonVisibility() =>
      _service.fetchTeamFormationButtonVisibility();

  Future<void> updateSectionCount(String section, int count) =>
      _service.updateSectionCount(section, count);

  Future<void> updateTeamFormationButtonVisibility(bool show) =>
      _service.updateTeamFormationButtonVisibility(show);
}
