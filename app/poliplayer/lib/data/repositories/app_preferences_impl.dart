import '../../domain/repositories/app_preferences.dart';
import '../database/app_database.dart';
import '../database/tables/app_flags_table.dart';

class AppPreferencesImpl implements AppPreferences {
  final AppDatabase _db;

  AppPreferencesImpl(this._db);

  @override
  Future<bool> hasSeenOnboarding() async =>
      await _db.readFlag(AppFlagKeys.onboardingSeen) == 'true';

  @override
  Future<void> markOnboardingSeen() =>
      _db.writeFlag(AppFlagKeys.onboardingSeen, 'true');
}
