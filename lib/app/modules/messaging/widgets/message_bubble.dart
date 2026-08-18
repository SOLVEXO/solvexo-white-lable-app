import 'package:book_store_app/app/components/common_image_view.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/components/svg_icon.dart';
import 'package:book_store_app/app/data/models/messaging/message_model.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_icons.dart';
import 'package:book_store_app/core/theme/base_shadows.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;

  const MessageBubble({super.key, required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: BaseSpacing.xxs),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
        child: Column(
          crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            _buildContent(context),
            SizedBox(height: BaseSpacing.xxs - 1),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  text: message.createdAt != null ? DateFormat('h:mm a').format(message.createdAt!.toLocal()) : '',
                  color: AppColors.gray600,
                  fontSize: AppFontSize.tiny,
                  fontWeight: FontWeight.w400,
                ),
                if (isMine) ...[
                  SizedBox(width: BaseSpacing.xxs),
                  Icon(_statusIcon, size: 13, color: _statusColor),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData get _statusIcon => message.status == 'sent' ? Icons.check_rounded : Icons.done_all_rounded;
  Color get _statusColor => message.status == 'seen' ? AppColors.primaryColor : AppColors.gray600;

  Widget _buildContent(BuildContext context) {
    if (message.isDeleted) {
      return _bubbleWrapper(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block_rounded, size: 14, color: isMine ? AppColors.white.withOpacity(0.7) : AppColors.gray600),
            SizedBox(width: BaseSpacing.xxs + 2),
            CustomText(
              text: 'This message was deleted',
              color: isMine ? AppColors.white.withOpacity(0.7) : AppColors.gray600,
              fontSize: AppFontSize.tiny,
              fontStyle: FontStyle.italic,
            ),
          ],
        ),
      );
    }

    switch (message.type) {
      case 'image':
        return _imageBubble(context);
      case 'product_share':
        return _productShareBubble();
      default:
        return _bubbleWrapper(
          CustomText(text: message.text ?? '', color: isMine ? AppColors.white : AppColors.black2, fontSize: AppFontSize.tiny),
        );
    }
  }

  Widget _bubbleWrapper(Widget child) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: BaseSpacing.sm + 2, vertical: BaseSpacing.xs + 2),
      decoration: BoxDecoration(
        gradient: isMine ? LinearGradient(colors: [AppColors.primaryColor, AppColors.accentColor]) : null,
        color: isMine ? null : AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(BaseRadius.lg),
          topRight: Radius.circular(BaseRadius.lg),
          bottomLeft: Radius.circular(isMine ? BaseRadius.lg : BaseRadius.xs),
          bottomRight: Radius.circular(isMine ? BaseRadius.xs : BaseRadius.lg),
        ),
        boxShadow: isMine ? null : BaseShadows.forLevel(BaseElevation.level1),
      ),
      child: child,
    );
  }

  Widget _imageBubble(BuildContext context) {
    final url = message.attachments.isNotEmpty ? message.attachments.first.url : null;
    return Semantics(
      button: url != null,
      label: 'Photo message, tap to view full size',
      child: GestureDetector(
        onTap: url == null ? null : () => _openFullImage(context, url),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(BaseRadius.lg),
            topRight: Radius.circular(BaseRadius.lg),
            bottomLeft: Radius.circular(isMine ? BaseRadius.lg : BaseRadius.xs),
            bottomRight: Radius.circular(isMine ? BaseRadius.xs : BaseRadius.lg),
          ),
          child: url != null
              ? CommonImageView(url: url, width: 200, height: 220, fit: BoxFit.cover)
              : _bubbleWrapper(CustomText(text: 'Photo', color: AppColors.black2, fontSize: AppFontSize.tiny)),
        ),
      ),
    );
  }

  void _openFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierColor: AppColors.black.withOpacity(0.9),
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              child: CommonImageView(url: url, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + BaseSpacing.sm,
            right: BaseSpacing.md,
            child: Semantics(
              button: true,
              label: 'Close image',
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: AppColors.black.withOpacity(0.4), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const SvgIcon(assetName: AppIcons.cross, color: AppColors.white, size: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productShareBubble() {
    final p = message.productShare;
    if (p == null) return _bubbleWrapper(CustomText(text: 'Shared a product', color: AppColors.black2, fontSize: AppFontSize.tiny));

    return Semantics(
      button: true,
      label: 'Shared product: ${p.title}, \$${p.price.toStringAsFixed(2)}',
      child: GestureDetector(
        onTap: () => Get.toNamed(Routes.productDetailsView, arguments: p.productId),
        child: Container(
          width: 210,
          padding: EdgeInsets.all(BaseSpacing.xs + 2),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(BaseRadius.lg),
            boxShadow: BaseShadows.forLevel(BaseElevation.level1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(BaseRadius.md),
                child: CommonImageView(url: p.image ?? '', height: 110, width: double.infinity, fit: BoxFit.cover),
              ),
              SizedBox(height: BaseSpacing.xs),
              CustomText(
                text: p.title,
                color: AppColors.black2,
                fontSize: AppFontSize.tiny,
                fontWeight: FontWeight.w600,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: BaseSpacing.xxs / 2),
              CustomText(
                text: '\$${p.price.toStringAsFixed(2)}',
                color: AppColors.primaryColor,
                fontSize: AppFontSize.extraSmall,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
