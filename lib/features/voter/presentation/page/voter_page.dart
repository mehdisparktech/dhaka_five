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
                      ),
                      child: Center(
                        child: Text(
                          'আপনার ভোটার তথ্য খুঁজুন',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
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
                          // Camera Button for NID Card OCR
                          Obx(
                            () => Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 16),
                              child: ElevatedButton.icon(
                                onPressed: presenter.isProcessingOcr.value
                                    ? null
                                    : () => presenter.pickImageAndExtractData(),
                                icon: presenter.isProcessingOcr.value
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Icon(Icons.camera_alt),
                                label: Text(
                                  presenter.isProcessingOcr.value
                                      ? 'প্রক্রিয়াকরণ...'
                                      : 'NID কার্ডের ছবি তুলুন',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.textDark,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Obx(() {
                            if (presenter.selectedImage.value != null) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        presenter.selectedImage.value!,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'ছবি নির্বাচিত হয়েছে',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'তথ্য স্বয়ংক্রিয়ভাবে পূরণ করা হয়েছে',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textDark
                                                  .withOpacity(0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        presenter.selectedImage.value = null;
                                      },
                                      tooltip: 'ছবি সরান',
                                    ),
                                  ],
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }),
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
                                    AppTexts.nameWithDob,
                                    AppTexts.voterIdNumber,
                                    AppTexts.fathersName,
                                    AppTexts.mothersName,
                                    AppTexts.address,
                                    AppTexts.area,
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
                                    } else if (currentType ==
                                        AppTexts.address) {
                                      return 'ঠিকানা (বাংলায় লিখুন)';
                                    } else if (currentType == AppTexts.area) {
                                      return 'স্থানীয় প্রশাসন (ঐচ্ছিক)';
                                    } else if (currentType ==
                                        AppTexts.nameWithDob) {
                                      return 'নাম (বাংলায় লিখুন)';
                                    }
                                    return 'নাম (বাংলায় লিখুন)';
                                  }(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                // Name/Input Field - Visible for all types
                                const SizedBox(height: 8),
                                Obx(() {
                                  // Hide text field for area search only
                                  if (presenter.isSearchByArea) {
                                    return const SizedBox.shrink();
                                  }
                                  return AppTextField(
                                    hint: () {
                                      if (isVoterId) {
                                        return 'ভোটার আইডি নম্বর লিখুন';
                                      } else if (currentType ==
                                          AppTexts.fathersName) {
                                        return 'পিতার নাম লিখুন...';
                                      } else if (currentType ==
                                          AppTexts.mothersName) {
                                        return 'মাতার নাম লিখুন...';
                                      } else if (currentType ==
                                          AppTexts.address) {
                                        return 'ঠিকানা লিখুন...';
                                      } else if (currentType ==
                                          AppTexts.nameWithDob) {
                                        return 'নাম লিখুন...';
                                      }
                                      return 'নাম লিখুন...';
                                    }(),
                                    controller: presenter.nameController,
                                    keyboardType: isVoterId
                                        ? TextInputType.number
                                        : TextInputType.text,
                                  );
                                }),

                                // Optional Dropdowns for Area Search only
                                if (presenter.isSearchByArea)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),

                                      // Local Administration Dropdown
                                      Obx(
                                        () => AppDropdown(
                                          value:
                                              presenter.selectedWard.value ??
                                              'স্থানীয় প্রশাসন নির্বাচন করুন',
                                          items: presenter.wards
                                              .map(
                                                (e) =>
                                                    e['local_administrative_area']
                                                        as String,
                                              )
                                              .toList(),
                                          onChanged: (value) {
                                            presenter.onWardSelected(value);
                                          },
                                          onClear: () {
                                            presenter.onWardSelected(null);
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      // Area Dropdown
                                      const Text(
                                        'এলাকা (ঐচ্ছিক)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Obx(
                                        () => AppDropdown(
                                          value:
                                              presenter.selectedArea.value ??
                                              (presenter.selectedWard.value ==
                                                      null
                                                  ? 'আগে স্থানীয় প্রশাসন নির্বাচন করুন'
                                                  : 'এলাকা নির্বাচন করুন'),
                                          items: presenter.availableAreas,
                                          onChanged: (value) {
                                            presenter.selectedArea.value =
                                                value;
                                          },
                                          onClear: () {
                                            presenter.selectedArea.value = null;
                                          },
                                        ),
                                      ),
                                      if (presenter.selectedWard.value == null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            '* আগে স্থানীয় প্রশাসন নির্বাচন করুন',
                                            style: TextStyle(
                                              color: AppColors.textDark
                                                  .withOpacity(0.6),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 16),
                                      // Gender Dropdown
                                      const Text(
                                        'লিঙ্গ (ঐচ্ছিক)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Obx(
                                        () => AppDropdown(
                                          value:
                                              presenter.selectedGender.value ??
                                              'সব লিঙ্গ',
                                          items: const [
                                            'সব লিঙ্গ',
                                            'পুরুষ',
                                            'মহিলা',
                                          ],
                                          onChanged: (value) {
                                            presenter.selectedGender.value =
                                                value == 'সব লিঙ্গ'
                                                ? null
                                                : value;
                                          },
                                          onClear: () {
                                            presenter.selectedGender.value =
                                                null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            );
                          }),

                          Obx(() {
                            // Show DOB only for nameWithDob, father's name, and mother's name
                            if (presenter.isSearchByAddress ||
                                presenter.isSearchByArea ||
                                presenter.isSearchByName ||
                                presenter.isSearchByVoterId) {
                              return const SizedBox.shrink();
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                              ],
                            );
                          }),

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
                                      final totalCount =
                                          presenter.state.totalCount;
                                      if (voters.isNotEmpty) {
                                        Get.to(
                                          () => VoterResultPage(
                                            voters: List.from(voters),
                                            totalCount: totalCount,
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
