import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_text_styles.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:book_store_app/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Renders a generation's `output` map — switches on `toolType` since each
/// tool has a different, known shape. Shared by the tool generate screens
/// (fresh result) and the generation-detail screen (historical result).
class GenerationOutputView extends StatelessWidget {
  final String toolType;
  final Map<String, dynamic> output;

  const GenerationOutputView({super.key, required this.toolType, required this.output});

  @override
  Widget build(BuildContext context) {
    switch (toolType) {
      case 'listing_writer':
        return _ListingWriterOutput(output: output);
      case 'seo_booster':
        return _SeoBoosterOutput(output: output);
      case 'email_campaigns':
        return _EmailCampaignOutput(output: output);
      case 'worksheet_builder':
        return _WorksheetOutput(output: output);
      case 'price_optimizer':
        return _PriceOptimizerOutput(output: output);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── shared building blocks ───────────────────────────────────────────────────

void _copy(String label, String text) {
  Clipboard.setData(ClipboardData(text: text));
  ToastUtil.showToast('$label copied');
}

class _FieldCard extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;

  const _FieldCard({required this.label, required this.value, this.copyable = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: BaseSpacing.sm),
      padding: EdgeInsets.all(BaseSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white2,
        borderRadius: BorderRadius.circular(BaseSpacing.xs + 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomText(
                  text: label,
                  color: AppColors.gray600,
                  fontSize: AppFontSize.tiny,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (copyable)
                GestureDetector(
                  onTap: () => _copy(label, value),
                  child: const Icon(Icons.copy_rounded, size: 16, color: AppColors.grey),
                ),
            ],
          ),
          SizedBox(height: BaseSpacing.xxs),
          CustomText(text: value, color: AppColors.black2, fontSize: AppFontSize.small2, height: 1.4),
        ],
      ),
    );
  }
}

class _LowConfidenceBanner extends StatelessWidget {
  final String text;
  const _LowConfidenceBanner({this.text = 'Low confidence — limited data was available for this result.'});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: BaseSpacing.sm),
      padding: EdgeInsets.symmetric(horizontal: BaseSpacing.sm, vertical: BaseSpacing.xs),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(BaseSpacing.xs + 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF8A6D3B)),
          SizedBox(width: BaseSpacing.xs),
          Expanded(
            child: CustomText(text: text, color: const Color(0xFF8A6D3B), fontSize: AppFontSize.tiny),
          ),
        ],
      ),
    );
  }
}

// ── Listing Writer ───────────────────────────────────────────────────────────

class _ListingWriterOutput extends StatelessWidget {
  final Map<String, dynamic> output;
  const _ListingWriterOutput({required this.output});

  @override
  Widget build(BuildContext context) {
    final tags = (output['suggestedTags'] as List? ?? []).map((e) => e.toString()).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldCard(label: 'Title', value: (output['title'] ?? '').toString()),
        _FieldCard(label: 'Description', value: (output['description'] ?? '').toString()),
        if (tags.isNotEmpty) _TagWrap(tags: tags),
      ],
    );
  }
}

// ── SEO Booster ───────────────────────────────────────────────────────────────

class _SeoBoosterOutput extends StatelessWidget {
  final Map<String, dynamic> output;
  const _SeoBoosterOutput({required this.output});

  @override
  Widget build(BuildContext context) {
    final tags = (output['optimizedTags'] as List? ?? []).cast<Map>();
    final lowConfidence = output['lowConfidence'] == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lowConfidence) const _LowConfidenceBanner(text: 'No keyword research data was available — tags are general best-practice suggestions.'),
        _FieldCard(label: 'Optimized Title', value: (output['optimizedTitle'] ?? '').toString()),
        if (tags.isNotEmpty) ...[
          CustomText(
            text: 'Optimized Tags',
            color: AppColors.gray600,
            fontSize: AppFontSize.tiny,
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: BaseSpacing.xs),
          Wrap(
            spacing: BaseSpacing.xs,
            runSpacing: BaseSpacing.xs,
            children: tags.map((t) {
              final tag = (t['tag'] ?? '').toString();
              final verified = t['isVerifiedData'] == true;
              return Container(
                padding: EdgeInsets.symmetric(horizontal: BaseSpacing.xs, vertical: 5),
                decoration: BoxDecoration(
                  color: verified ? AppColors.primaryColor.withOpacity(0.12) : AppColors.white2,
                  borderRadius: BorderRadius.circular(BaseSpacing.sm),
                  border: Border.all(
                    color: verified ? AppColors.primaryColor.withOpacity(0.4) : AppColors.lightGrey2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(text: tag, color: AppColors.black2, fontSize: AppFontSize.tiny),
                    if (!verified) ...[
                      SizedBox(width: 4),
                      const Icon(Icons.psychology_alt_outlined, size: 11, color: AppColors.grey),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
          SizedBox(height: BaseSpacing.xs),
          CustomText(
            text: '🧠 = LLM estimate, not verified search-volume data',
            color: AppColors.gray600,
            fontSize: AppFontSize.tiny,
          ),
          SizedBox(height: BaseSpacing.sm),
        ],
        if ((output['rankingNotes'] as String?)?.isNotEmpty == true)
          _FieldCard(label: 'Ranking Notes', value: output['rankingNotes'].toString(), copyable: false),
      ],
    );
  }
}

// ── Email Campaigns ──────────────────────────────────────────────────────────

class _EmailCampaignOutput extends StatelessWidget {
  final Map<String, dynamic> output;
  const _EmailCampaignOutput({required this.output});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldCard(label: 'Subject', value: (output['subject'] ?? '').toString()),
        _FieldCard(label: 'Preview Text', value: (output['previewText'] ?? '').toString()),
        _FieldCard(label: 'Body', value: (output['body'] ?? '').toString()),
      ],
    );
  }
}

// ── Worksheet Builder ────────────────────────────────────────────────────────

class _WorksheetOutput extends StatelessWidget {
  final Map<String, dynamic> output;
  const _WorksheetOutput({required this.output});

  @override
  Widget build(BuildContext context) {
    final sections = (output['sections'] as List? ?? []).cast<Map>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: (output['title'] ?? '').toString(),
          color: AppColors.black2,
          fontSize: AppFontSize.medium,
          fontWeight: FontWeight.w700,
        ),
        SizedBox(height: BaseSpacing.sm),
        for (int i = 0; i < sections.length; i++) _WorksheetSection(index: i + 1, section: sections[i]),
      ],
    );
  }
}

class _WorksheetSection extends StatelessWidget {
  final int index;
  final Map section;
  const _WorksheetSection({required this.index, required this.section});

  @override
  Widget build(BuildContext context) {
    final questions = (section['questions'] as List? ?? []).cast<Map>();
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: BaseSpacing.sm),
      padding: EdgeInsets.all(BaseSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white2,
        borderRadius: BorderRadius.circular(BaseSpacing.xs + 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: 'Section $index',
            color: AppColors.primaryColor,
            fontSize: AppFontSize.tiny,
            fontWeight: FontWeight.w700,
          ),
          SizedBox(height: BaseSpacing.xxs),
          CustomText(
            text: (section['instructions'] ?? '').toString(),
            color: AppColors.gray600,
            fontSize: AppFontSize.tiny,
          ),
          SizedBox(height: BaseSpacing.xs),
          for (int q = 0; q < questions.length; q++) _WorksheetQuestion(index: q + 1, question: questions[q]),
        ],
      ),
    );
  }
}

class _WorksheetQuestion extends StatelessWidget {
  final int index;
  final Map question;
  const _WorksheetQuestion({required this.index, required this.question});

  @override
  Widget build(BuildContext context) {
    final choices = (question['choices'] as List? ?? []).map((e) => e.toString()).toList();
    final answer = question['answer']?.toString();
    return Padding(
      padding: EdgeInsets.only(bottom: BaseSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: '$index. ${(question['prompt'] ?? '').toString()}',
            color: AppColors.black2,
            fontSize: AppFontSize.verySmall,
            fontWeight: FontWeight.w600,
          ),
          if (choices.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: choices
                    .map((c) => CustomText(text: '• $c', color: AppColors.gray600, fontSize: AppFontSize.tiny))
                    .toList(),
              ),
            ),
          if (answer != null && answer.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 2),
              child: CustomText(
                text: 'Answer: $answer',
                color: AppColors.secondryColor,
                fontSize: AppFontSize.tiny,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Price Optimizer ──────────────────────────────────────────────────────────

class _PriceOptimizerOutput extends StatelessWidget {
  final Map<String, dynamic> output;
  const _PriceOptimizerOutput({required this.output});

  @override
  Widget build(BuildContext context) {
    final suggested = output['suggestedPrice'];
    final min = output['suggestedPriceMin'];
    final max = output['suggestedPriceMax'];
    final sampleSize = output['comparableListingsSampleSize'];
    final lowConfidence = output['lowConfidence'] == true;
    final externalNote = output['externalMarketNote'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lowConfidence) const _LowConfidenceBanner(),
        if (suggested != null) ...[
          Center(
            child: Column(
              children: [
                CustomText(
                  text: '\$$suggested',
                  color: AppColors.primaryColor,
                  fontSize: AppFontSize.veryLarge3,
                  fontWeight: FontWeight.w800,
                ),
                if (min != null && max != null)
                  CustomText(
                    text: 'Range: \$$min – \$$max',
                    color: AppColors.gray600,
                    fontSize: AppFontSize.tiny,
                  ),
              ],
            ),
          ),
          SizedBox(height: BaseSpacing.sm),
        ],
        CustomText(
          text: 'Based on $sampleSize comparable listing${sampleSize == 1 ? '' : 's'} on this marketplace',
          color: AppColors.gray600,
          fontSize: AppFontSize.tiny,
        ),
        SizedBox(height: BaseSpacing.sm),
        if ((output['explanation'] as String?)?.isNotEmpty == true)
          _FieldCard(label: 'Explanation', value: output['explanation'].toString(), copyable: false),
        if (externalNote != null && externalNote.isNotEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(BaseSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.lightGrey2),
              borderRadius: BorderRadius.circular(BaseSpacing.xs + 2),
            ),
            child: CustomText(
              text: externalNote,
              color: AppColors.gray600,
              fontSize: AppFontSize.tiny,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }
}

// ── shared tag wrap (Listing Writer) ─────────────────────────────────────────

class _TagWrap extends StatelessWidget {
  final List<String> tags;
  const _TagWrap({required this.tags});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: BaseSpacing.xs,
      runSpacing: BaseSpacing.xs,
      children: tags
          .map(
            (t) => Container(
              padding: EdgeInsets.symmetric(horizontal: BaseSpacing.xs, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.white2,
                borderRadius: BorderRadius.circular(BaseSpacing.sm),
              ),
              child: CustomText(
                text: t,
                color: AppColors.black2,
                fontSize: AppFontSize.tiny,
                fontFamily: AppTextStyles.monoFontFamily,
              ),
            ),
          )
          .toList(),
    );
  }
}
