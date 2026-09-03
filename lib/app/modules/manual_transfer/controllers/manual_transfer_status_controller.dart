import 'dart:io';
import 'package:book_store_app/app/components/app_image_picker.dart';
import 'package:book_store_app/app/data/models/payment/manual_payment_model.dart';
import 'package:book_store_app/app/data/repositories/manual_transfer_repository.dart';
import 'package:book_store_app/app/data/services/current_store_service.dart';
import 'package:book_store_app/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ManualTransferStatusController extends GetxController {
  ManualTransferStatusController({ManualTransferRepository? repository})
      : _repository = repository ?? ManualTransferRepository();

  final ManualTransferRepository _repository;

  final Rx<ManualPaymentProof?> proof = Rx<ManualPaymentProof?>(null);
  final RxBool isRefreshing = false.obs;

  // Re-upload form state — only relevant once `proof.status == 'rejected'`.
  final Rx<File?> newProofImage = Rx<File?>(null);
  final referenceController = TextEditingController();
  final senderNameController = TextEditingController();
  final RxBool isReuploading = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is ManualPaymentProof) {
      proof.value = args;
      referenceController.text = args.transactionReference ?? '';
      senderNameController.text = args.senderName ?? '';
    } else if (args is String) {
      _loadById(args);
    }
  }

  Future<void> _loadById(String proofId) async {
    isRefreshing.value = true;
    proof.value = await _repository.getProofStatus(proofId, storeId: Get.find<CurrentStoreService>().storeId);
    isRefreshing.value = false;
  }

  @override
  Future<void> refresh() async {
    final id = proof.value?.id;
    if (id == null || id.isEmpty || isRefreshing.value) return;
    isRefreshing.value = true;
    final updated = await _repository.getProofStatus(id, storeId: Get.find<CurrentStoreService>().storeId);
    if (updated != null) proof.value = updated;
    isRefreshing.value = false;
  }

  void pickNewProofImage() {
    AppImagePicker.show(
      title: 'Upload New Proof',
      canRemove: newProofImage.value != null,
      onRemove: () => newProofImage.value = null,
      onPicked: (file) => newProofImage.value = file,
    );
  }

  Future<void> reupload() async {
    final id = proof.value?.id;
    if (id == null || id.isEmpty) return;
    if (newProofImage.value == null) {
      ToastUtil.showToast('Please upload a new screenshot or receipt');
      return;
    }
    if (isReuploading.value) return;

    isReuploading.value = true;
    try {
      final result = await _repository.reuploadPayment(
        proofId: id,
        proofImage: newProofImage.value!,
        transactionReference: referenceController.text.trim(),
        senderName: senderNameController.text.trim(),
      );
      if (result.success && result.proof != null) {
        proof.value = result.proof;
        newProofImage.value = null;
        ToastUtil.showToast(result.message ?? 'Proof re-uploaded — awaiting review.');
      } else {
        ToastUtil.showToast(result.message ?? 'Failed to re-upload payment proof');
      }
    } finally {
      isReuploading.value = false;
    }
  }

  @override
  void onClose() {
    referenceController.dispose();
    senderNameController.dispose();
    super.onClose();
  }
}
