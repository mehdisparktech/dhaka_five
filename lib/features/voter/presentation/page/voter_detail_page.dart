import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_colors.dart';
import '../presenter/voter_detail_presenter.dart';

class VoterDetailPage extends StatelessWidget {
  final Map voter;

  const VoterDetailPage({super.key, required this.voter});

  @override
  Widget build(BuildContext context) {
    final presenter = Get.put(VoterDetailPresenter(voter: voter));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('ভোটারের তথ্য'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: RepaintBoundary(
            key: presenter.previewKey,
            child: Container(
              padding: const EdgeInsets.all(8),
              width: 430,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF09575b), width: 4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'কেন্দ্রের তথ্য',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          presenter.centerName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (presenter.centerInfo.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            presenter.centerInfo,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _InfoRow(label: 'নাম', value: presenter.name),
                        _InfoRow(label: 'সিরিয়াল নং', value: presenter.serial),
                        _InfoRow(label: 'পিতা', value: presenter.fatherName),
                        _InfoRow(label: 'মাতা', value: presenter.motherName),
                        // _InfoRow(
                        //   label: 'স্বামী/স্ত্রী',
                        //   value: presenter.husbandName,
                        // ),
                        _InfoRow(label: 'ভোটার নং', value: presenter.voterId),
                        _InfoRow(label: 'জন্ম তারিখ', value: presenter.dob),
                        _InfoRow(label: 'লিঙ্গ', value: presenter.gender),
                        _InfoRow(label: 'এলাকাঃ', value: presenter.area),
                        _InfoRow(label: 'ঠিকানা', value: presenter.address),
                      ],
                    ),
                  ),
                  // Container(
                  //   padding: const EdgeInsets.symmetric(
                  //     horizontal: 16,
                  //     vertical: 12,
                  //   ),
                  //   decoration: const BoxDecoration(
                  //     color: AppColors.background,
                  //     borderRadius: BorderRadius.only(
                  //       bottomLeft: Radius.circular(16),
                  //       bottomRight: Radius.circular(16),
                  //     ),
                  //   ),
                  //   child: Text(
                  //     '''মোহাম্মদ কামাল হোসেন এর সালাম নিন, দাঁড়িপাল্লা মার্কায় ভোট দিন।তারুন্যের প্রথম ভোট, দাঁড়িপাল্লা মার্কার পক্ষে হোক।''',
                  //     style: TextStyle(
                  //       fontSize: 14,
                  //       fontWeight: FontWeight.w600,
                  //       color: AppColors.primary,
                  //     ),
                  //     maxLines: 3,
                  //     overflow: TextOverflow.ellipsis,
                  //     textAlign: TextAlign.center,
                  //     softWrap: true,
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: Obx(
                  () => ElevatedButton.icon(
                    onPressed: presenter.isDownloading.value
                        ? null
                        : presenter.downloadPdf,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      disabledBackgroundColor: AppColors.primary.withOpacity(
                        0.6,
                      ),
                    ),
                    icon: presenter.isDownloading.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.download_rounded),
                    label: presenter.isDownloading.value
                        ? const Text('ডাউনলোড হচ্ছে...')
                        : const Text('PDF ডাউনলোড'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => OutlinedButton.icon(
                    onPressed: presenter.isPrinting.value
                        ? null
                        : presenter.printPdf,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      disabledForegroundColor: AppColors.primary.withOpacity(
                        0.6,
                      ),
                    ),
                    icon: presenter.isPrinting.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          )
                        : const Icon(Icons.print_rounded),
                    label: presenter.isPrinting.value
                        ? const Text('প্রিন্ট হচ্ছে...')
                        : const Text('প্রিন্ট'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }
}
