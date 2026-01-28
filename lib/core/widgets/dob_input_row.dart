import 'package:flutter/material.dart';

import 'app_text_field.dart';

class DobInputRow extends StatefulWidget {
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
  State<DobInputRow> createState() => _DobInputRowState();
}

class _DobInputRowState extends State<DobInputRow> {
  late FocusNode _dayFocusNode;
  late FocusNode _monthFocusNode;
  late FocusNode _yearFocusNode;

  @override
  void initState() {
    super.initState();
    _dayFocusNode = FocusNode();
    _monthFocusNode = FocusNode();
    _yearFocusNode = FocusNode();

    // Add listeners to controllers for auto-focus
    widget.day.addListener(_onDayChanged);
    widget.month.addListener(_onMonthChanged);
  }

  @override
  void dispose() {
    widget.day.removeListener(_onDayChanged);
    widget.month.removeListener(_onMonthChanged);
    _dayFocusNode.dispose();
    _monthFocusNode.dispose();
    _yearFocusNode.dispose();
    super.dispose();
  }

  void _onDayChanged() {
    final text = widget.day.text;
    if (text.isNotEmpty) {
      // Validate day - prevent numbers > 31
      final dayValue = int.tryParse(text);
      if (dayValue != null && dayValue > 31) {
        // Reset to 31 if exceeds
        widget.day.text = '31';
        widget.day.selection = TextSelection.collapsed(offset: 2);
        // Move to month field after correction
        _monthFocusNode.requestFocus();
        return;
      }
    }
    // Auto-focus to next field when 2 digits are entered
    if (text.length == 2) {
      _monthFocusNode.requestFocus();
    }
  }

  void _onMonthChanged() {
    final text = widget.month.text;
    if (text.isNotEmpty) {
      // Validate month - prevent numbers > 12
      final monthValue = int.tryParse(text);
      if (monthValue != null && monthValue > 12) {
        // Reset to 12 if exceeds
        widget.month.text = '12';
        widget.month.selection = TextSelection.collapsed(offset: 2);
        // Move to year field after correction
        _yearFocusNode.requestFocus();
        return;
      }
    }
    // Auto-focus to next field when 2 digits are entered
    if (text.length == 2) {
      _yearFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppTextField(
            hint: 'দিন',
            controller: widget.day,
            keyboardType: TextInputType.number,
            maxLength: 2,
            focusNode: _dayFocusNode,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AppTextField(
            hint: 'মাস',
            controller: widget.month,
            keyboardType: TextInputType.number,
            maxLength: 2,
            focusNode: _monthFocusNode,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AppTextField(
            hint: 'বছর',
            controller: widget.year,
            keyboardType: TextInputType.number,
            maxLength: 4,
            focusNode: _yearFocusNode,
          ),
        ),
      ],
    );
  }
}
