import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final Function(String?) onChanged;
  final VoidCallback? onClear;

  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = items.contains(value);

    return DropdownButtonFormField<String>(
      initialValue: isSelected ? value : null,
      hint: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      // Ensure the dropdown menu has a decent height relative to screen or items
      menuMaxHeight: 400,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        // Show clear button if onClear is provided and an item is selected
        suffixIcon: (onClear != null && isSelected)
            ? IconButton(
                icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                onPressed: onClear,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            : null,
      ),
    );
  }
}
