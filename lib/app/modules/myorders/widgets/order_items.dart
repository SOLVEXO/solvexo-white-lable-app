import 'package:book_store_app/app/components/common_image_view.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/modules/myorders/controllers/my_orders_controller.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_text_styles.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/core/widgets/buttons/base_buttons.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OrderItems extends StatelessWidget {
  final int index;
  const OrderItems({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MyOrdersController>();
    final order = controller.orders[index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(text: 'Your Order', color: AppColors.black, fontSize: AppFontSize.small2, fontWeight: FontWeight.w800),
        ListView.builder(
          itemCount: order.allItems.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, i) {
            final orderDetail = order.allItems[i];
            final isDigital = orderDetail.type == 'digital';

            return Padding(
              padding: EdgeInsets.only(bottom: BaseSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CommonImageView(url: orderDetail.image, height: 50, width: 50),
                      SizedBox(width: BaseSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              text: orderDetail.name,
                              color: AppColors.black,
                              fontSize: AppFontSize.extraSmall,
                              fontWeight: FontWeight.w700,
                            ),
                            CustomText(text: "Qty: ${orderDetail.quantity}", color: AppColors.gray600, fontSize: AppFontSize.extraSmall),
                          ],
                        ),
                      ),
                      CustomText(
                        text: "\$${orderDetail.price.toStringAsFixed(2)}",
                        color: AppColors.black,
                        fontSize: AppFontSize.extraSmall,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppTextStyles.monoFontFamily,
                      ),
                    ],
                  ),
                  if (isDigital && order.isPaid)
                    Padding(
                      padding: EdgeInsets.only(top: BaseSpacing.xxs + 2),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Obx(() {
                          final downloading = controller.isDownloading(orderDetail.itemId);
                          return OutlineButton(
                            label: downloading ? 'Preparing...' : 'Download',
                            compact: true,
                            isLoading: downloading,
                            onPressed: downloading
                                ? null
                                : () => controller.downloadDigitalItem(order.orderId, orderDetail),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
