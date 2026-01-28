import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_colors.dart';
import '../presenter/voter_history_presenter.dart';
import 'voter_result_page.dart';

class VoterHistoryPage extends StatelessWidget {
  const VoterHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final presenter = Get.put(VoterHistoryPresenter());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('খোঁজার ইতিহাস'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        actions: [
          Obx(() {
            if (presenter.history.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                Get.dialog(
                  AlertDialog(
                    title: const Text('সতর্কতা'),
                    content: const Text('আপনি কি সব ইতিহাস মুছে ফেলতে চান?'),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('বাতিল'),
                      ),
                      TextButton(
                        onPressed: () {
                          Get.back();
                          presenter.clearAllHistory();
                        },
                        child: const Text(
                          'মুছে ফেলুন',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
              tooltip: 'সব ইতিহাস মুছুন',
            );
          }),
        ],
      ),
      body: Obx(() {
        if (presenter.history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: AppColors.textLight),
                const SizedBox(height: 16),
                Text(
                  'কোন ইতিহাস নেই',
                  style: TextStyle(fontSize: 16, color: AppColors.textLight),
                ),
                const SizedBox(height: 8),
                Text(
                  'আপনার খোঁজার ফলাফল এখানে দেখা যাবে',
                  style: TextStyle(fontSize: 14, color: AppColors.textLight),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Action buttons
            // Container(
            //   padding: const EdgeInsets.all(16),
            //   decoration: BoxDecoration(
            //     color: AppColors.background,
            //     border: Border(bottom: BorderSide(color: AppColors.border)),
            //   ),
            //   child: Row(
            //     children: [
            //       Expanded(
            //         child: Obx(
            //           () => ElevatedButton.icon(
            //             onPressed:
            //                 presenter.isDownloading.value ||
            //                     presenter.isPrinting.value
            //                 ? null
            //                 : presenter.downloadAllHistory,
            //             style: ElevatedButton.styleFrom(
            //               backgroundColor: AppColors.primary,
            //               foregroundColor: Colors.white,
            //               padding: const EdgeInsets.symmetric(vertical: 12),
            //               disabledBackgroundColor: AppColors.primary
            //                   .withOpacity(0.6),
            //             ),
            //             icon: presenter.isDownloading.value
            //                 ? const SizedBox(
            //                     width: 20,
            //                     height: 20,
            //                     child: CircularProgressIndicator(
            //                       strokeWidth: 2,
            //                       valueColor: AlwaysStoppedAnimation<Color>(
            //                         Colors.white,
            //                       ),
            //                     ),
            //                   )
            //                 : const Icon(Icons.download_rounded),
            //             label: presenter.isDownloading.value
            //                 ? const Text('তৈরি হচ্ছে...')
            //                 : const Text('সব ডাউনলোড'),
            //           ),
            //         ),
            //       ),
            //       const SizedBox(width: 12),
            //       Expanded(
            //         child: Obx(
            //           () => OutlinedButton.icon(
            //             onPressed:
            //                 presenter.isDownloading.value ||
            //                     presenter.isPrinting.value
            //                 ? null
            //                 : presenter.printAllHistory,
            //             style: OutlinedButton.styleFrom(
            //               foregroundColor: AppColors.primary,
            //               side: const BorderSide(color: AppColors.primary),
            //               padding: const EdgeInsets.symmetric(vertical: 12),
            //               disabledForegroundColor: AppColors.primary
            //                   .withOpacity(0.6),
            //             ),
            //             icon: presenter.isPrinting.value
            //                 ? const SizedBox(
            //                     width: 20,
            //                     height: 20,
            //                     child: CircularProgressIndicator(
            //                       strokeWidth: 2,
            //                       valueColor: AlwaysStoppedAnimation<Color>(
            //                         AppColors.primary,
            //                       ),
            //                     ),
            //                   )
            //                 : const Icon(Icons.print_rounded),
            //             label: presenter.isPrinting.value
            //                 ? const Text('প্রিন্ট হচ্ছে...')
            //                 : const Text('সব প্রিন্ট'),
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),

            // History list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: presenter.history.length,
                itemBuilder: (context, index) {
                  final historyItem = presenter.history[index];
                  final voters = historyItem['voters'] as List;
                  final searchType = historyItem['searchType'] as String;
                  final searchValue = historyItem['searchValue'] as String;
                  final dobDay = historyItem['dobDay'] as String;
                  final dobMonth = historyItem['dobMonth'] as String;
                  final dobYear = historyItem['dobYear'] as String;
                  final timestamp = historyItem['timestamp'] as String;
                  final voterCount = voters.length;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: AppColors.border),
                    ),
                    child: InkWell(
                      onTap: () {
                        Get.to(
                          () => VoterResultPage(voters: List.from(voters)),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _formatDate(timestamp),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textLight,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$searchType: $searchValue',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'জন্ম তারিখ: $dobDay/$dobMonth/$dobYear',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$voterCount টি',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Get.to(
                                        () => VoterResultPage(
                                          voters: List.from(voters),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.visibility,
                                      size: 16,
                                    ),
                                    label: const Text('দেখুন'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(
                                        color: AppColors.primary,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () {
                                    Get.dialog(
                                      AlertDialog(
                                        title: const Text('সতর্কতা'),
                                        content: const Text(
                                          'আপনি কি এই ইতিহাস মুছে ফেলতে চান?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Get.back(),
                                            child: const Text('বাতিল'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Get.back();
                                              presenter.deleteHistoryItem(
                                                historyItem['id'] as String,
                                              );
                                            },
                                            child: const Text(
                                              'মুছে ফেলুন',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.delete_outline),
                                  color: Colors.red,
                                  tooltip: 'মুছে ফেলুন',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return 'তারিখ নেই';
    try {
      final date = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            return 'এখনই';
          }
          return '${difference.inMinutes} মিনিট আগে';
        }
        return '${difference.inHours} ঘন্টা আগে';
      } else if (difference.inDays == 1) {
        return 'গতকাল';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} দিন আগে';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return isoString;
    }
  }
}
