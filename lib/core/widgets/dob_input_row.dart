import 'package:flutter/material.dart';

import 'app_text_field.dart';

class DobInputRow extends StatelessWidget {
  final TextEditingController day;
  final TextEditingController month;
  final TextEditingController year;

  const DobInputRow({
    super.key,
    required this.day,
    required this.month,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppTextField(
            hint: 'দিন',
            controller: day,
            keyboardType: TextInputType.number,
            maxLength: 2,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AppTextField(
            hint: 'মাস',
            controller: month,
            keyboardType: TextInputType.number,
            maxLength: 2,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AppTextField(
            hint: 'বছর',
            controller: year,
            keyboardType: TextInputType.number,
            maxLength: 4,
          ),
        ),
      ],
    );
  }
}
