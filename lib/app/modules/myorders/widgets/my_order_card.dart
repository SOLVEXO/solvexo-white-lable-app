import 'package:book_store_app/app/components/common_image_view.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/modules/myorders/models/my_order_model.dart';
import 'package:book_store_app/app/modules/myorders/models/order_item_model.dart';
import 'package:book_store_app/app/modules/myorders/widgets/order_actions.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_text_styles.dart';
import 'package:book_store_app/core/theme/base_shadows.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:book_store_app/utils/currency_formatter.dart';
import 'package:flutter/material.dart';

class MyOrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;
  const MyOrderCard({super.key, required this.order, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: BaseSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(BaseRadius.lg),
        boxShadow: BaseShadows.forLevel(BaseElevation.level2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Status accent strip ────────────────────────────────
              Container(height: 4, color: order.statusColor),

              // ── Header ──────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                  BaseSpacing.md,
                  BaseSpacing.sm + 2,
                  BaseSpacing.md,
                  BaseSpacing.sm,
                ),
                child: _OrderHeaderRow(order: order),
              ),
              Divider(height: 1, thickness: 1, color: AppColors.background),

              // ── Stores + items ────────────────────────────────────
              for (int i = 0; i < order.stores.length; i++) ...[
                if (i > 0)
                  Divider(height: 1, thickness: 1, color: AppColors.background),
                _StoreSection(store: order.stores[i], currency: order.currency),
              ],

              Divider(height: 1, thickness: 1, color: AppColors.background),

              // ── Total + payment ───────────────────────────────────
              Container(
                width: double.infinity,
                color: AppColors.background,
                padding: EdgeInsets.symmetric(
                  horizontal: BaseSpacing.md,
                  vertical: BaseSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _PaymentStatusChip(order: order),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        CustomText(
                          text: 'Total  ',
                          color: AppColors.gray600,
                          fontSize: AppFontSize.tiny,
                          fontWeight: FontWeight.w500,
                        ),
                        CustomText(
                          text: order.formattedTotal,
                          color: AppColors.primaryColor,
                          fontSize: AppFontSize.small,
                          fontWeight: FontWeight.w800,
                          fontFamily: AppTextStyles.monoFontFamily,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Actions ───────────────────────────────────────────
              if (order.isCompleted || order.canCancel)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    BaseSpacing.md,
                    BaseSpacing.sm,
                    BaseSpacing.md,
                    BaseSpacing.sm + 2,
                  ),
                  child: OrderActions(order: order),
                )
              else
                SizedBox(height: BaseSpacing.xxs),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header: order #, date, item count + status pill with icon ─────────────────

class _OrderHeaderRow extends StatelessWidget {
  final OrderModel order;
  const _OrderHeaderRow({required this.order});

  IconData get _statusIcon {
    switch (order.orderStatus) {
      case 'completed':
        return Icons.check_circle_rounded;
      case 'shipped':
      case 'partially_shipped':
        return Icons.local_shipping_rounded;
      case 'processing':
        return Icons.autorenew_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: order.orderNumber,
                color: AppColors.black,
                fontSize: AppFontSize.extraSmall,
                fontWeight: FontWeight.bold,
                fontFamily: AppTextStyles.monoFontFamily,
              ),
              SizedBox(height: BaseSpacing.xxs / 2),
              Row(
                children: [
                  CustomText(
                    text: order.formattedDate,
                    color: AppColors.gray600,
                    fontSize: AppFontSize.tiny,
                    fontWeight: FontWeight.w400,
                  ),
                  CustomText(
                    text: '  ·  ',
                    color: AppColors.gray600,
                    fontSize: AppFontSize.tiny,
                  ),
                  CustomText(
                    text: '${order.totalItemCount} item${order.totalItemCount == 1 ? '' : 's'}',
                    color: AppColors.gray600,
                    fontSize: AppFontSize.tiny,
                    fontWeight: FontWeight.w400,
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(width: BaseSpacing.xs),
        Container(
          padding: EdgeInsets.symmetric(horizontal: BaseSpacing.xs + 2, vertical: BaseSpacing.xxs),
          decoration: BoxDecoration(
            color: order.statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(BaseRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_statusIcon, size: 12, color: order.statusColor),
              SizedBox(width: BaseSpacing.xxs / 2),
              CustomText(
                text: order.statusDisplay,
                color: order.statusColor,
                fontSize: AppFontSize.tiny,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Payment status chip ─────────────────────────────────────────────────────

class _PaymentStatusChip extends StatelessWidget {
  final OrderModel order;
  const _PaymentStatusChip({required this.order});

  IconData get _icon {
    switch (order.paymentStatus) {
      case 'paid':
        return Icons.check_circle_rounded;
      case 'pending_verification':
        return Icons.hourglass_top_rounded;
      case 'failed':
        return Icons.error_rounded;
      case 'refunded':
        return Icons.replay_rounded;
      default:
        return Icons.payments_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_icon, size: 13, color: order.paymentStatusColor),
        SizedBox(width: BaseSpacing.xxs / 2),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              text: order.paymentStatusDisplay,
              color: order.paymentStatusColor,
              fontSize: AppFontSize.tiny,
              fontWeight: FontWeight.w600,
            ),
            CustomText(
              text: order.paymentType.replaceAll('_', ' ').toUpperCase(),
              color: AppColors.gray600,
              fontSize: 10,
              fontWeight: FontWeight.w400,
            ),
          ],
        ),
      ],
    );
  }
}

// ── Single store section ──────────────────────────────────────────────────────

class _StoreSection extends StatelessWidget {
  final OrderStore store;
  final String currency;
  const _StoreSection({required this.store, required this.currency});

  Color get _storeStatusColor {
    switch (store.status) {
      case 'shipped':    return AppColors.statusShipped;
      case 'delivered':
      case 'completed':  return AppColors.statusCompleted;
      case 'processing': return AppColors.statusProcessing;
      case 'cancelled':  return AppColors.statusCancelled;
      default:           return AppColors.statusDefault;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Store status row
        Padding(
          padding: EdgeInsets.fromLTRB(BaseSpacing.md, BaseSpacing.sm, BaseSpacing.md, BaseSpacing.xxs),
          child: Row(
            children: [
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: BaseSpacing.xxs + 2, vertical: 2),
                decoration: BoxDecoration(
                  color: _storeStatusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(BaseRadius.pill),
                ),
                child: CustomText(
                  text: store.status[0].toUpperCase() + store.status.substring(1),
                  color: _storeStatusColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (store.tracking != null)
          Padding(
            padding: EdgeInsets.fromLTRB(BaseSpacing.md, BaseSpacing.xxs, BaseSpacing.md, 0),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: BaseSpacing.xs + 2, vertical: BaseSpacing.xxs),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(BaseRadius.sm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping_outlined, size: 13, color: AppColors.gray600),
                  SizedBox(width: BaseSpacing.xxs),
                  Expanded(
                    child: CustomText(
                      text: '${store.tracking!.carrier} · ${store.tracking!.trackingNumber}',
                      color: AppColors.gray600,
                      fontSize: AppFontSize.tiny,
                      fontWeight: FontWeight.w500,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Items
        Padding(
          padding: EdgeInsets.symmetric(vertical: BaseSpacing.xxs),
          child: Column(
            children: store.items
                .map((item) => _OrderItemRow(item: item, currency: currency))
                .toList(),
          ),
        ),
      ],
    );
  }
}

// ── Single item row ───────────────────────────────────────────────────────────

class _OrderItemRow extends StatelessWidget {
  final OrderItem item;
  final String currency;
  const _OrderItemRow({required this.item, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(BaseSpacing.md, BaseSpacing.xxs, BaseSpacing.md, BaseSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CommonImageView(
                url: item.image,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                radius: BorderRadius.circular(BaseRadius.sm),
                border: Border.all(color: AppColors.background, width: 1),
              ),
              if (item.quantity > 1)
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.black.withOpacity(0.72),
                      borderRadius: BorderRadius.circular(BaseRadius.pill),
                      border: Border.all(color: AppColors.white, width: 1),
                    ),
                    child: CustomText(
                      text: '×${item.quantity}',
                      color: AppColors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: BaseSpacing.sm),
          Expanded(
            child: CustomText(
              text: item.name,
              color: AppColors.black2,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: BaseSpacing.xs),
          CustomText(
            text: CurrencyFormatter.amount(item.totalPrice, currency),
            color: AppColors.black,
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            fontFamily: AppTextStyles.monoFontFamily,
          ),
        ],
      ),
    );
  }
}
