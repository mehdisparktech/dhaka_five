import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_colors.dart';
import '../widgets/voter_result_card.dart';
import 'voter_detail_page.dart';

class VoterResultPage extends StatelessWidget {
  final List voters;

  const VoterResultPage({super.key, required this.voters});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('ফলাফল'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ফলাফল',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  '${voters.length} টি ফলাফল',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: voters.length,
              itemBuilder: (context, index) {
                final voter = voters[index] as Map;
                return GestureDetector(
                  onTap: () {
                    Get.to(() => VoterDetailPage(voter: voter));
                  },
                  child: VoterResultCard(voter: voter),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
