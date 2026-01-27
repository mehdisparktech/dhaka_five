import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_texts.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/dob_input_row.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_bottom_sheet.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/primary_button.dart';
import '../presenter/voter_presenter.dart';
import '../widgets/voter_result_card.dart';

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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 20),

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
                          const Text(
                            AppTexts.searchType,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          AppDropdown(
                            value: AppTexts.name,
                            items: const [AppTexts.name],
                            onChanged: (_) {},
                          ),

                          const SizedBox(height: 16),
                          const Text(
                            'নাম (ইংরেজিতে)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          AppTextField(
                            hint: 'নাম লিখুন...',
                            controller: presenter.nameController,
                          ),

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
                                    onTap: () {
                                      FocusScope.of(context).unfocus();
                                      presenter.search();
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'ফলাফল',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // Results List
            Obx(() {
              final state = presenter.state;

              if (state.error != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ErrorBottomSheet.show(state.error!);
                });
              }

              if (state.loading) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: LoadingView(),
                );
              }

              if (state.voters.isEmpty) {
                return const SliverToBoxAdapter(
                  child: EmptyState(message: 'কোন ফলাফল পাওয়া যায়নি'),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index == state.voters.length) {
                      if (state.loadingMore) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return const SizedBox.shrink();
                    }
                    return VoterResultCard(voter: state.voters[index]);
                  }, childCount: state.voters.length + (state.hasMore ? 1 : 0)),
                ),
              );
            }),

            // Bottom spacing
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}
