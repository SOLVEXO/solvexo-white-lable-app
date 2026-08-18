import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';

/// "Accepted" pill shown in place of the "Use This" button once a generation
/// has been accepted — shared by every tool's result section.
class AiAcceptedBadge extends StatelessWidget {
  const AiAcceptedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.secondryColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: AppColors.secondryColor, size: 18),
          SizedBox(width: BaseSpacing.xxs),
          CustomText(text: 'Accepted', color: AppColors.secondryColor, fontWeight: FontWeight.w600, fontSize: AppFontSize.verySmall),
        ],
      ),
    );
  }
}

/// A field label above any form control — consistent spacing/typography
/// across every AI Studio tool form.
class AiFieldLabel extends StatelessWidget {
  final String text;
  const AiFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: BaseSpacing.xs),
      child: CustomText(text: text, color: AppColors.black2, fontSize: AppFontSize.verySmall, fontWeight: FontWeight.w600),
    );
  }
}

/// Single-select chip row for small enums (tone, campaign goal, enhancement
/// type) — friendlier on mobile than a dropdown for ≤6 options.
class ChoiceChipGroup<T> extends StatelessWidget {
  final List<T> options;
  final T? selected;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onSelected;

  const ChoiceChipGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.labelBuilder,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: BaseSpacing.xs,
      runSpacing: BaseSpacing.xs,
      children: options.map((option) {
        final isSelected = option == selected;
        return GestureDetector(
          onTap: () => onSelected(option),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: BaseSpacing.sm, vertical: BaseSpacing.xs),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryColor : AppColors.white,
              borderRadius: BorderRadius.circular(BaseSpacing.lg),
              border: Border.all(color: isSelected ? AppColors.primaryColor : AppColors.lightGrey2),
            ),
            child: CustomText(
              text: labelBuilder(option),
              color: isSelected ? AppColors.white : AppColors.black2,
              fontSize: AppFontSize.verySmall,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Tappable "picker" field that looks like a text field but opens a bottom
/// sheet ([SimplePickerSheet]) — used for the optional product/category
/// pickers on the AI Studio tool forms.
class AiPickerTile extends StatelessWidget {
  final String placeholder;
  final String? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const AiPickerTile({super.key, required this.placeholder, this.value, required this.onTap, this.onClear});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(BaseSpacing.lg),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: BaseSpacing.md, vertical: BaseSpacing.sm + 2),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(BaseSpacing.lg),
          border: Border.all(color: AppColors.primaryColor.withOpacity(0.55)),
        ),
        child: Row(
          children: [
            Expanded(
              child: CustomText(
                text: value ?? placeholder,
                color: value != null ? AppColors.black2 : AppColors.grey,
                fontSize: AppFontSize.verySmall,
              ),
            ),
            if (value != null && onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded, size: 18, color: AppColors.grey),
              )
            else
              const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.grey),
          ],
        ),
      ),
    );
  }
}
