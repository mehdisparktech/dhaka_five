import 'dart:async';

import 'package:get/get.dart';

import '../../../voter/presentation/page/voter_page.dart';

class SplashPresenter extends GetxController {
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    // Wait for 2 seconds to show splash screen
    await Future.delayed(const Duration(seconds: 2));

    // Navigate to VoterPage
    isLoading.value = false;
    Get.offAll(() => VoterPage());
  }
}
