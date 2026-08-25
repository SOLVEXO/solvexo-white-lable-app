import 'package:book_store_app/app/components/custom_app_bar_two.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/components/custom_text_field.dart';
import 'package:book_store_app/app/data/models/bookings/bookable_service_model.dart';
import 'package:book_store_app/app/data/models/bookings/service_availability_model.dart';
import 'package:book_store_app/app/data/models/bookings/service_package_model.dart';
import 'package:book_store_app/app/modules/store_services/controllers/store_service_detail_controller.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/core/theme/base_shadows.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/core/widgets/buttons/base_buttons.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:book_store_app/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

String _locationTypeLabel(String type) => switch (type) {
      'in_person' => 'In Person',
      'virtual' => 'Virtual',
      'customer_address' => "Your Address",
      _ => type,
    };

class StoreServiceDetailView extends StatelessWidget {
  StoreServiceDetailView({super.key});

  final StoreServiceDetailController controller = Get.put(StoreServiceDetailController());

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate.value ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) controller.selectDate(picked);
  }

  Future<void> _submitBooking(BuildContext context) async {
    final svc = controller.service.value;
    if (svc == null) return;
    if (svc.locationTypes.contains('customer_address') &&
        controller.selectedLocationType.value == 'customer_address' &&
        controller.buyerAddressLine1.trim().isEmpty) {
      ToastUtil.showToast('Please enter your address');
      return;
    }
    Map<String, dynamic>? serviceAddress;
    if (controller.selectedLocationType.value == 'customer_address') {
      serviceAddress = {
        'addressLine1': controller.buyerAddressLine1.trim(),
        if (controller.buyerCity.trim().isNotEmpty) 'city': controller.buyerCity.trim(),
        if (controller.buyerPhone.trim().isNotEmpty) 'phone': controller.buyerPhone.trim(),
      };
    }
    await controller.confirmBooking(
      serviceAddress: serviceAddress,
      buyerNote: controller.buyerNote.trim().isEmpty ? null : controller.buyerNote.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBarTwo(title: controller.storeName),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryColor),
            ),
          );
        }

        final service = controller.service.value;
        if (service == null) {
          return Center(
            child: CustomText(text: 'Service not found', color: AppColors.gray600, fontSize: AppFontSize.small),
          );
        }

        return ListView(
          padding: EdgeInsets.all(BaseSpacing.md),
          children: [
            _ServiceHeaderCard(service: service),
            SizedBox(height: BaseSpacing.md),
            if (service.locationTypes.length > 1) ...[
              _SectionTitle(text: 'Location'),
              SizedBox(height: BaseSpacing.xs),
              Obx(
                () => Wrap(
                  spacing: BaseSpacing.xs,
                  runSpacing: BaseSpacing.xs,
                  children: service.locationTypes
                      .map(
                        (t) => _SelectableChip(
                          label: _locationTypeLabel(t),
                          selected: controller.selectedLocationType.value == t,
                          onTap: () => controller.selectLocationType(t),
                        ),
                      )
                      .toList(),
                ),
              ),
              SizedBox(height: BaseSpacing.md),
            ],
            Obx(() {
              if (controller.selectedLocationType.value != 'customer_address') return const SizedBox.shrink();
              return Padding(
                padding: EdgeInsets.only(bottom: BaseSpacing.md),
                child: _AddressForm(controller: controller),
              );
            }),
            _SectionTitle(text: 'Select a date'),
            SizedBox(height: BaseSpacing.xs),
            Obx(
              () => GestureDetector(
                onTap: () => _pickDate(context),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: BaseSpacing.sm + 2, vertical: BaseSpacing.sm + 2),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(color: AppColors.lightGrey2),
                    borderRadius: BorderRadius.circular(BaseRadius.md),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event_outlined, size: 18, color: AppColors.gray600),
                      SizedBox(width: BaseSpacing.xs),
                      CustomText(
                        text: controller.selectedDate.value != null
                            ? DateFormat('EEEE, MMM d, yyyy').format(controller.selectedDate.value!)
                            : 'Choose a date',
                        color: AppColors.black2,
                        fontSize: AppFontSize.tiny,
                        fontWeight: FontWeight.w600,
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.gray600),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: BaseSpacing.md),
            _SectionTitle(text: 'Available times'),
            SizedBox(height: BaseSpacing.xs),
            Obx(() {
              if (controller.isLoadingSlots.value) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryColor)),
                );
              }
              if (controller.slots.isEmpty) {
                return CustomText(
                  text: 'No time slots available on this date.',
                  color: AppColors.gray600,
                  fontSize: AppFontSize.tiny,
                  fontWeight: FontWeight.w600,
                );
              }
              return Wrap(
                spacing: BaseSpacing.xs,
                runSpacing: BaseSpacing.xs,
                children: controller.slots.map((slot) {
                  final selected = controller.selectedSlot.value == slot;
                  return _SlotChip(
                    slot: slot,
                    selected: selected,
                    onTap: () => controller.selectSlot(slot),
                  );
                }).toList(),
              );
            }),
            Obx(() {
              if (controller.isLoadingMyPackages.value || controller.usablePackages.isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: EdgeInsets.only(top: BaseSpacing.md),
                child: _OwnedPackagesSection(controller: controller),
              );
            }),
            Obx(() {
              if (controller.isLoadingPackages.value || controller.packages.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: EdgeInsets.only(top: BaseSpacing.md),
                child: _PackagesToBuySection(controller: controller),
              );
            }),
            SizedBox(height: BaseSpacing.md),
            _NoteForm(controller: controller),
            SizedBox(height: BaseSpacing.lg),
            Obx(
              () => PrimaryButton(
                label: controller.selectedPackagePurchaseId.value.isNotEmpty ? 'Book with Package' : 'Book Appointment',
                isLoading: controller.isBooking.value,
                onPressed: controller.canSubmitBooking ? () => _submitBooking(context) : null,
              ),
            ),
            SizedBox(height: BaseSpacing.xxl),
          ],
        );
      }),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return CustomText(text: text, color: AppColors.black2, fontSize: AppFontSize.extraSmall, fontWeight: FontWeight.w700);
  }
}

class _ServiceHeaderCard extends StatelessWidget {
  final BookableServiceModel service;
  const _ServiceHeaderCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(BaseSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(BaseRadius.lg),
        boxShadow: BaseShadows.forLevel(BaseElevation.level1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(text: service.name, color: AppColors.black2, fontSize: AppFontSize.small, fontWeight: FontWeight.bold),
          SizedBox(height: BaseSpacing.xxs),
          Row(
            children: [
              CustomText(
                text: '\$${service.price.toStringAsFixed(2)} ${service.currency}',
                color: AppColors.primaryColor,
                fontSize: AppFontSize.extraSmall,
                fontWeight: FontWeight.w700,
              ),
              SizedBox(width: BaseSpacing.sm),
              Icon(Icons.schedule_rounded, size: 14, color: AppColors.gray600),
              SizedBox(width: BaseSpacing.xxs / 2),
              CustomText(
                text: '${service.durationMinutes} min',
                color: AppColors.gray600,
                fontSize: AppFontSize.tiny,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
          if (service.description != null && service.description!.isNotEmpty) ...[
            SizedBox(height: BaseSpacing.sm),
            CustomText(text: service.description!, color: AppColors.gray600, fontSize: AppFontSize.tiny, fontWeight: FontWeight.w500),
          ],
        ],
      ),
    );
  }
}

class _SelectableChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SelectableChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: BaseSpacing.sm, vertical: BaseSpacing.xs),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryColor : AppColors.lightGrey10,
          borderRadius: BorderRadius.circular(BaseRadius.pill),
        ),
        child: CustomText(
          text: label,
          color: selected ? AppColors.white : AppColors.gray600,
          fontSize: AppFontSize.tiny,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  final ServiceSlotModel slot;
  final bool selected;
  final VoidCallback onTap;
  const _SlotChip({required this.slot, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = !slot.isAvailable;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: BaseSpacing.sm, vertical: BaseSpacing.xs),
        decoration: BoxDecoration(
          color: disabled
              ? AppColors.lightGrey10
              : (selected ? AppColors.primaryColor : AppColors.white),
          border: Border.all(color: disabled ? AppColors.lightGrey2 : (selected ? AppColors.primaryColor : AppColors.lightGrey2)),
          borderRadius: BorderRadius.circular(BaseRadius.pill),
        ),
        child: CustomText(
          text: slot.startTime,
          color: disabled ? AppColors.lightGrey : (selected ? AppColors.white : AppColors.black2),
          fontSize: AppFontSize.tiny,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Optional note to the seller — a Stateful leaf so its TextEditingController
/// survives rebuilds of the (Stateless) page around it.
class _NoteForm extends StatefulWidget {
  final StoreServiceDetailController controller;
  const _NoteForm({required this.controller});

  @override
  State<_NoteForm> createState() => _NoteFormState();
}

class _NoteFormState extends State<_NoteForm> {
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController(text: widget.controller.buyerNote)
      ..addListener(() => widget.controller.buyerNote = _noteCtrl.text);
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomTextField(label: 'Note for the store (optional)', controller: _noteCtrl, isborder: true, maxLines: 2);
  }
}

/// Owns the buyer's address/phone/note text fields — the only Stateful
/// widget on this page, per house convention for text-input forms.
class _AddressForm extends StatefulWidget {
  final StoreServiceDetailController controller;
  const _AddressForm({required this.controller});

  @override
  State<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<_AddressForm> {
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    _addressCtrl = TextEditingController(text: widget.controller.buyerAddressLine1)
      ..addListener(() => widget.controller.buyerAddressLine1 = _addressCtrl.text);
    _cityCtrl = TextEditingController(text: widget.controller.buyerCity)
      ..addListener(() => widget.controller.buyerCity = _cityCtrl.text);
    _phoneCtrl = TextEditingController(text: widget.controller.buyerPhone)
      ..addListener(() => widget.controller.buyerPhone = _phoneCtrl.text);
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(BaseSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(BaseRadius.lg),
        boxShadow: BaseShadows.forLevel(BaseElevation.level1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(text: 'Your address', color: AppColors.black2, fontSize: AppFontSize.tiny, fontWeight: FontWeight.w700),
          SizedBox(height: BaseSpacing.sm),
          CustomTextField(label: 'Address Line', controller: _addressCtrl, isborder: true),
          SizedBox(height: BaseSpacing.sm),
          CustomTextField(label: 'City (optional)', controller: _cityCtrl, isborder: true),
          SizedBox(height: BaseSpacing.sm),
          CustomTextField(label: 'Phone (optional)', controller: _phoneCtrl, isborder: true, keyboardType: TextInputType.phone),
        ],
      ),
    );
  }
}

class _OwnedPackagesSection extends StatelessWidget {
  final StoreServiceDetailController controller;
  const _OwnedPackagesSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(BaseSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.greenSuccess.withOpacity(0.06),
        borderRadius: BorderRadius.circular(BaseRadius.lg),
        border: Border.all(color: AppColors.greenSuccess.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.card_giftcard_rounded, color: AppColors.greenSuccess, size: 16),
              SizedBox(width: BaseSpacing.xs),
              CustomText(text: 'You own a package', color: AppColors.black2, fontSize: AppFontSize.tiny, fontWeight: FontWeight.w700),
            ],
          ),
          SizedBox(height: BaseSpacing.sm),
          ...controller.usablePackages.map((pkg) {
            return Obx(() {
              final selected = controller.selectedPackagePurchaseId.value == pkg.id;
              return Padding(
                padding: EdgeInsets.only(bottom: BaseSpacing.xs),
                child: GestureDetector(
                  onTap: () => controller.useOwnedPackage(selected ? null : pkg),
                  child: Row(
                    children: [
                      Icon(
                        selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                        size: 18,
                        color: selected ? AppColors.greenSuccess : AppColors.gray600,
                      ),
                      SizedBox(width: BaseSpacing.xs),
                      Expanded(
                        child: CustomText(
                          text: 'Book with package (${pkg.sessionsRemaining} session${pkg.sessionsRemaining == 1 ? '' : 's'} left)',
                          color: AppColors.black2,
                          fontSize: AppFontSize.tiny,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            });
          }),
        ],
      ),
    );
  }
}

class _PackagesToBuySection extends StatelessWidget {
  final StoreServiceDetailController controller;
  const _PackagesToBuySection({required this.controller});

  Future<void> _confirmBuy(BuildContext context, ServicePackageModel package) async {
    await controller.buyPackage(package);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(text: 'Buy a package'),
        SizedBox(height: BaseSpacing.xs),
        ...controller.packages.map((pkg) => Padding(
              padding: EdgeInsets.only(bottom: BaseSpacing.sm),
              child: _PackageBuyRow(
                package: pkg,
                onBuy: () => _confirmBuy(context, pkg),
                isBuying: controller.purchasingPackageId.value == pkg.id,
              ),
            )),
      ],
    );
  }
}

class _PackageBuyRow extends StatelessWidget {
  final ServicePackageModel package;
  final VoidCallback onBuy;
  final bool isBuying;
  const _PackageBuyRow({required this.package, required this.onBuy, required this.isBuying});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(BaseSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(BaseRadius.lg),
        boxShadow: BaseShadows.forLevel(BaseElevation.level1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(text: package.name, color: AppColors.black2, fontSize: AppFontSize.tiny, fontWeight: FontWeight.w700),
                SizedBox(height: BaseSpacing.xxs / 2),
                CustomText(
                  text: '${package.sessionsCount} sessions · valid ${package.validityDays}d',
                  color: AppColors.gray600,
                  fontSize: AppFontSize.tiny,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),
          SizedBox(width: BaseSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomText(
                text: '\$${package.price.toStringAsFixed(2)}',
                color: AppColors.primaryColor,
                fontSize: AppFontSize.tiny,
                fontWeight: FontWeight.w700,
              ),
              SizedBox(height: BaseSpacing.xxs),
              OutlineButton(label: 'Buy Package', isLoading: isBuying, expand: false, compact: true, onPressed: isBuying ? null : onBuy),
            ],
          ),
        ],
      ),
    );
  }
}
