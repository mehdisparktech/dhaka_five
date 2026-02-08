import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/digit_converter.dart';

class VoterResultCard extends StatelessWidget {
  final Map voter;

  const VoterResultCard({super.key, required this.voter});

  @override
  Widget build(BuildContext context) {
    final String name = (voter['name'] ?? '').toString();
    final String fathersName = (voter['fathers_name'] ?? '').toString();
    // API theke asha `serial` key use korbo, na paile `voter_id`
    final String serialRaw = (voter['serial'] ?? voter['voter_id'] ?? '')
        .toString()
        .trim();
    final String serial = DigitConverter.enToBn(serialRaw);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // বামে নাম + পিতার নাম
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'নাম পাওয়া যায়নি' : name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'পিতা: ${fathersName.isEmpty ? 'তথ্য নেই' : fathersName}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // ডানে Serial + arrow (image er moto)
          Text(
            serial.isEmpty ? '-' : '#$serial',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.textLight,
          ),
        ],
      ),
    );
  }
}
