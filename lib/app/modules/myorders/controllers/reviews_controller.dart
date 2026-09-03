import 'package:book_store_app/app/data/repositories/rating_repository.dart';
import 'package:book_store_app/app/data/services/current_store_service.dart';
import 'package:book_store_app/app/modules/myorders/models/order_item_model.dart';
import 'package:book_store_app/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Writes a review for one order line item —
/// `POST /api/rating/add-review` (`rating.service.ts#addReview`).
/// Expects `Get.arguments` as `{'orderId': String, 'item': OrderItem}`,
/// set by whichever "Write Review" button navigated here.
class ReviewsController extends GetxController {
  ReviewsController({RatingRepository? repository})
    : _repo = repository ?? RatingRepository();

  final RatingRepository _repo;

  String orderId = '';
  OrderItem? item;

  final RxDouble rating = 0.0.obs;
  final TextEditingController commentController = TextEditingController();
  final RxBool isSubmitting = false.obs;

  bool get canSubmit => item != null && rating.value > 0 && !isSubmitting.value;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      orderId = args['orderId'] as String? ?? '';
      item = args['item'] as OrderItem?;
    }
  }

  @override
  void onClose() {
    commentController.dispose();
    super.onClose();
  }

  Future<void> submit() async {
    final product = item;
    if (product == null || rating.value == 0 || isSubmitting.value) return;

    isSubmitting.value = true;
    final comment = commentController.text.trim();
    final success = await _repo.addReview(
      productId: product.productId,
      orderId: orderId.isNotEmpty ? orderId : null,
      rating: rating.value,
      comment: comment.isEmpty ? null : comment,
      storeId: Get.find<CurrentStoreService>().storeId,
    );
    isSubmitting.value = false;

    if (success) {
      ToastUtil.showToast('Thanks for your review!');
      Get.back();
    } else {
      ToastUtil.showToast('Could not submit your review. Please try again.');
    }
  }
}
