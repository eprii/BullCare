import '../models/user_model.dart';

class PermissionHelper {
  static void requireSupervisor(UserModel? user) {
    if (user == null || !user.isSupervisor) {
      throw StateError('Akses membutuhkan role Supervisor.');
    }
  }

  static void requireActivityManager(UserModel? user) {
    if (user == null || !user.canManageActivity) {
      throw StateError('Akses aktivitas tidak diizinkan.');
    }
  }
}
