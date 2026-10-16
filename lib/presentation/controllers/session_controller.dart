import 'package:get/get.dart';

import '../../core/error/app_exception.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/usecases/team_usecases.dart';

class SessionController extends GetxController {
  SessionController({
    required GetCurrentUser getCurrentUser,
    required GetAvailableUsers getAvailableUsers,
    required SwitchCurrentUser switchCurrentUser,
  }) : _getCurrentUser = getCurrentUser,
       _getAvailableUsers = getAvailableUsers,
       _switchCurrentUser = switchCurrentUser;

  final GetCurrentUser _getCurrentUser;
  final GetAvailableUsers _getAvailableUsers;
  final SwitchCurrentUser _switchCurrentUser;

  final currentUser = Rxn<AppUser>();
  final availableUsers = <AppUser>[].obs;

  bool get isAdmin => currentUser.value?.canCreateTasks ?? false;

  @override
  void onInit() {
    super.onInit();
    loadCurrentUser();
  }

  Future<void> loadCurrentUser() async {
    try {
      currentUser.value = await _getCurrentUser();
      availableUsers.assignAll(await _getAvailableUsers());
    } on AppException catch (e) {
      Get.snackbar('Account', e.message);
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
      currentUser.value = await _switchCurrentUser(user.id);
    } on AppException catch (e) {
      Get.snackbar('Account', e.message);
    }
  }
}
