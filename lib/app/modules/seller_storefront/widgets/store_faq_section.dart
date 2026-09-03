import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/data/models/store_faq/store_faq_model.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/core/theme/base_shadows.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';

/// This store's own FAQ accordion — seller-authored via `solvexo-api`'s
/// `src/store-faq`, distinct from the app-wide Help Center FAQ. Same
/// hide-when-empty contract as `StoreBannerCarousel`/`StorefrontServicesTeaser`:
/// renders nothing for a store that hasn't added any.
class StoreFaqSection extends StatefulWidget {
  final List<StoreFaqModel> faqs;
  const StoreFaqSection({super.key, required this.faqs});

  @override
  State<StoreFaqSection> createState() => _StoreFaqSectionState();
}

class _StoreFaqSectionState extends State<StoreFaqSection> {
  String? _expandedId;

  @override
  Widget build(BuildContext context) {
    final faqs = widget.faqs;
    if (faqs.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(width: BaseSpacing.xs),
              CustomText(
                text: 'Frequently Asked Questions',
                color: AppColors.black2,
                fontSize: AppFontSize.small2,
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
          SizedBox(height: BaseSpacing.sm),
          ...faqs.map((faq) => _FaqAccordionTile(
                faq: faq,
                expanded: _expandedId == faq.id,
                onTap: () => setState(() => _expandedId = _expandedId == faq.id ? null : faq.id),
              )),
        ],
      ),
    );
  }
}

class _FaqAccordionTile extends StatelessWidget {
  final StoreFaqModel faq;
  final bool expanded;
  final VoidCallback onTap;

  const _FaqAccordionTile({required this.faq, required this.expanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: BaseSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(BaseRadius.lg),
        boxShadow: BaseShadows.forLevel(BaseElevation.level1),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(BaseRadius.lg),
            child: Padding(
              padding: EdgeInsets.all(BaseSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: CustomText(
                      text: faq.question,
                      color: AppColors.black,
                      fontSize: AppFontSize.extraSmall,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: BaseSpacing.xs),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.gray600, size: 22),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: EdgeInsets.fromLTRB(BaseSpacing.md, 0, BaseSpacing.md, BaseSpacing.md),
              child: Align(
                alignment: Alignment.centerLeft,
                child: CustomText(
                  text: faq.answer,
                  color: AppColors.gray600,
                  fontSize: AppFontSize.tiny,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
