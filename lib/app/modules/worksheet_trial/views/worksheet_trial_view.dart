import 'package:book_store_app/app/components/custom_app_bar_two.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/components/custom_text_field.dart';
import 'package:book_store_app/app/components/ai_form_widgets.dart';
import 'package:book_store_app/app/components/generation_output_view.dart';
import 'package:book_store_app/app/modules/login/controller/auth_tabs_controller.dart';
import 'package:book_store_app/app/modules/worksheet_trial/controllers/worksheet_trial_controller.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/core/theme/base_shadows.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/core/widgets/buttons/base_buttons.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WorksheetTrialView extends GetView<WorksheetTrialController> {
  const WorksheetTrialView({super.key});

  void _goToSignup() {
    Get.toNamed(Routes.authTabView);
    // Best-effort: land directly on the "Sign up" tab (index 1) rather than
    // the default "Log in" tab — `AuthTabsController` is lazy-bound by
    // `LoginBinding` as part of pushing `Routes.authTabView`.
    if (Get.isRegistered<AuthTabsController>()) {
      Get.find<AuthTabsController>().switchTab(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBarTwo(title: 'Free Worksheet Builder'),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          BaseSpacing.md,
          BaseSpacing.md,
          BaseSpacing.md,
          BaseSpacing.xxl * 2,
        ),
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(BaseSpacing.sm + 2),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(BaseRadius.lg),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
                SizedBox(width: BaseSpacing.xs),
                Expanded(
                  child: CustomText(
                    text: 'Free trial — no sign-up needed. Generate a sample worksheet in seconds.',
                    color: AppColors.black2,
                    fontSize: AppFontSize.tiny,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: BaseSpacing.lg),
          const AiFieldLabel('Subject'),
          CustomTextField(
            controller: controller.subjectCtrl,
            hintText: 'e.g. Fractions',
          ),
          SizedBox(height: BaseSpacing.md),
          const AiFieldLabel('Grade Level'),
          CustomTextField(
            controller: controller.gradeLevelCtrl,
            hintText: 'e.g. Grade 4',
          ),
          SizedBox(height: BaseSpacing.md),
          AiFieldLabel('Topics (comma separated, up to ${WorksheetTrialController.maxTopics})'),
          CustomTextField(
            controller: controller.topicsCtrl,
            hintText: 'e.g. adding fractions, simplifying',
            maxLines: 2,
          ),
          SizedBox(height: BaseSpacing.md),
          const AiFieldLabel('Number of questions'),
          Obx(
            () => Row(
              children: [
                _StepperButton(
                  icon: Icons.remove,
                  onTap: controller.decrementQuestions,
                ),
                SizedBox(
                  width: 60,
                  child: Center(
                    child: CustomText(
                      text: '${controller.questionCount.value}',
                      color: AppColors.black2,
                      fontSize: AppFontSize.medium,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _StepperButton(
                  icon: Icons.add,
                  onTap: controller.incrementQuestions,
                ),
              ],
            ),
          ),
          SizedBox(height: BaseSpacing.md),
          Obx(
            () => Row(
              children: [
                Switch(
                  value: controller.includeAnswerKey.value,
                  onChanged: (v) => controller.includeAnswerKey.value = v,
                  activeColor: AppColors.primaryColor,
                ),
                CustomText(
                  text: 'Include answer key',
                  color: AppColors.black2,
                  fontSize: AppFontSize.verySmall,
                ),
              ],
            ),
          ),
          SizedBox(height: BaseSpacing.lg),
          Obx(
            () => PrimaryButton(
              label: 'Generate with AI',
              isLoading: controller.isGenerating.value,
              onPressed: controller.generate,
            ),
          ),
          SizedBox(height: BaseSpacing.lg),
          Obx(() {
            final output = controller.result.value;
            if (output == null) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: 'Result',
                  color: AppColors.black2,
                  fontWeight: FontWeight.w700,
                  fontSize: AppFontSize.small2,
                ),
                SizedBox(height: BaseSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(BaseSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(BaseRadius.lg),
                    boxShadow: BaseShadows.forLevel(BaseElevation.level1),
                  ),
                  child: GenerationOutputView(
                    toolType: 'worksheet_builder',
                    output: output,
                  ),
                ),
                SizedBox(height: BaseSpacing.md),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(BaseSpacing.sm + 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColorLight.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(BaseRadius.lg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: 'Like what you see?',
                        color: AppColors.black2,
                        fontSize: AppFontSize.verySmall,
                        fontWeight: FontWeight.w700,
                      ),
                      SizedBox(height: BaseSpacing.xxs),
                      CustomText(
                        text: 'Sellers get unlimited generations, regenerate, and 5 more AI tools in AI Studio.',
                        color: AppColors.gray600,
                        fontSize: AppFontSize.tiny,
                      ),
                      SizedBox(height: BaseSpacing.sm),
                      PrimaryButton(
                        label: 'Create a free seller account to unlock AI Studio',
                        onPressed: _goToSignup,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.white2,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors.black2),
      ),
    );
  }
}
