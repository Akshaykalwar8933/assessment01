import 'package:get/get.dart';

import '../../core/error/app_exception.dart';
import '../../core/error/error_reporting.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/repository_contracts.dart';

class SessionController extends GetxController {
  SessionController({required AuthRepository auth}) : _auth = auth;

  final AuthRepository _auth;

  final currentUser = Rxn<AppUser>();

  bool get isAdmin => currentUser.value?.canCreateTasks ?? false;

  @override
  void onInit() {
    super.onInit();
    loadCurrentUser();
  }

  Future<void> loadCurrentUser() async {
    try {
      currentUser.value = await _auth.getCurrentUser();
    } catch (error, stackTrace) {
      showErrorSnackbar(
        userFacingMessageFor(error, stackTrace),
        title: 'Account',
      );
    }
  }

  void ensureCurrentUserIsAdmin() {
    if (!isAdmin) {
      throw const PermissionDeniedException(
        'Only admins can create and assign tasks.',
      );
    }
  }

  Future<void> switchToUser(AppUser user) async {
    if (user.id == currentUser.value?.id) return;
    try {
      currentUser.value = await _auth.switchCurrentUser(user.id);
    } catch (error, stackTrace) {
      showErrorSnackbar(
        userFacingMessageFor(error, stackTrace),
        title: 'Account',
      );
    }
  }
}
