import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_texts.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/dob_input_row.dart';
import '../../../../core/widgets/primary_button.dart';
import '../presenter/voter_presenter.dart';
import 'voter_history_page.dart';
import 'voter_result_page.dart';

class VoterPage extends StatelessWidget {
  VoterPage({super.key});

  final presenter = Get.put(VoterPresenter());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(AppTexts.voterSearch),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Get.to(() => const VoterHistoryPage());
            },
            tooltip: 'ইতিহাস',
          ),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
              !presenter.state.loadingMore &&
              presenter.state.hasMore) {
            presenter.search(loadMore: true);
          }
          return false;
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 240,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/cover.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppTexts.subtitle,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 10),
                    // Search Form
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Obx(() {
                            final currentType = presenter.searchType.value;
                            final isVoterId =
                                currentType == AppTexts.voterIdNumber;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  AppTexts.searchType,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                AppDropdown(
                                  value: presenter.searchType.value,
                                  items: const [
                                    AppTexts.name,
                                    AppTexts.voterIdNumber,
                                    AppTexts.fathersName,
                                    AppTexts.mothersName,
                                  ],
                                  onChanged: (value) {
                                    if (value == null) return;
                                    presenter.searchType.value = value;
                                    presenter.nameController.clear();
                                  },
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  () {
                                    if (isVoterId) {
                                      return 'ভোটার আইডি নম্বর';
                                    } else if (currentType ==
                                        AppTexts.fathersName) {
                                      return 'পিতার নাম (বাংলায় লিখুন)';
                                    } else if (currentType ==
                                        AppTexts.mothersName) {
                                      return 'মাতার নাম (বাংলায় লিখুন)';
                                    }
                                    return 'নাম (বাংলায় লিখুন)';
                                  }(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AppTextField(
                                  hint: () {
                                    if (isVoterId) {
                                      return 'ভোটার আইডি নম্বর লিখুন';
                                    } else if (currentType ==
                                        AppTexts.fathersName) {
                                      return 'পিতার নাম লিখুন...';
                                    } else if (currentType ==
                                        AppTexts.mothersName) {
                                      return 'মাতার নাম লিখুন...';
                                    }
                                    return 'নাম লিখুন...';
                                  }(),
                                  controller: presenter.nameController,
                                  keyboardType: isVoterId
                                      ? TextInputType.number
                                      : TextInputType.text,
                                ),
                              ],
                            );
                          }),

                          const SizedBox(height: 16),
                          const Text(
                            AppTexts.dob,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          DobInputRow(
                            day: presenter.dayController,
                            month: presenter.monthController,
                            year: presenter.yearController,
                          ),

                          const SizedBox(height: 24),
                          Obx(
                            () => presenter.state.loading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : PrimaryButton(
                                    text: AppTexts.search,
                                    onTap: () async {
                                      FocusScope.of(context).unfocus();
                                      await presenter.search();
                                      final voters = presenter.state.voters;
                                      if (voters.isNotEmpty) {
                                        Get.to(
                                          () => VoterResultPage(
                                            voters: List.from(voters),
                                          ),
                                        );
                                      } else {
                                        Get.dialog(
                                          AlertDialog(
                                            title: const Text('দুঃখিত'),
                                            content: const Text(
                                              'কোন ফলাফল পাওয়া যায়নি',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Get.back(),
                                                child: const Text('ঠিক আছে'),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom spacing
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}
