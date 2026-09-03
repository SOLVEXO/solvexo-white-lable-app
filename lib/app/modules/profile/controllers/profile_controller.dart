import 'dart:io';
import 'package:book_store_app/app/components/custom_bottom_sheet.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/data/models/common_models/user_model.dart';
import 'package:book_store_app/app/data/repositories/auth_repository.dart';
import 'package:book_store_app/app/data/repositories/upload_repository.dart';
import 'package:book_store_app/app/modules/auth/controller/auth_controller.dart';
import 'package:book_store_app/app/modules/settings/models/settings_section_model.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_icons.dart';
import 'package:book_store_app/shared_prefrences/app_prefrences.dart';
import 'package:book_store_app/utils/custom_alert_dialog_util.dart';
import 'package:book_store_app/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ProfileController extends GetxController {
  /// Guests get a stripped-down section list — anything that reads/writes
  /// account data is hidden rather than shown broken (no fake data).
  bool get isLoggedIn => user.value != null;

  // ── Sections for merged profile/settings UI ──────────────────────────────
  List<SettingsSection> get sections => [
    if (isLoggedIn)
      SettingsSection(
        header: 'ACCOUNT',
        tiles: [
          SettingsTile(
            icon: AppIcons.billsIcon,
            title: 'My Orders',
            onTap: () => Get.toNamed(Routes.myOrdersView),
          ),
          SettingsTile(
            icon: AppIcons.editIcon,
            title: 'Edit Profile',
            onTap: () => Get.toNamed(Routes.editProfileView),
          ),
          SettingsTile(
            icon: AppIcons.locationIcon,
            title: 'My Addresses',
            onTap: () => Get.toNamed(Routes.addressView),
          ),
          SettingsTile(
            icon: AppIcons.notificationIcon,
            title: 'Notification Preferences',
            onTap: () => Get.toNamed(Routes.notificationPreferences),
          ),
        ],
      ),
    SettingsSection(
      header: 'SUPPORT',
      tiles: [
        // SettingsTile(
        //   icon: AppIcons.shoppingBag,
        //   title: 'About ${Get.find<BrandingService>().config.value.storeDisplayName}',
        //   onTap: () => Get.toNamed(Routes.sellerStorefront),
        // ),
        SettingsTile(
          icon: AppIcons.phoneIcon,
          title: 'Help Center',
          onTap: () => Get.toNamed(Routes.helpCenterView),
        ),
        SettingsTile(
          icon: AppIcons.emailIcon,
          title: 'Contact Us',
          onTap: () => Get.toNamed(Routes.contactUsView),
        ),
        SettingsTile(
          icon: AppIcons.privacy,
          title: 'Privacy Policy',
          onTap: () => Get.toNamed(Routes.PRIVACY_POLICY),
        ),
        SettingsTile(
          icon: AppIcons.aboutIcon,
          title: 'About App',
          onTap: () => Get.toNamed(Routes.ABOUT),
        ),
      ],
    ),
    if (isLoggedIn)
      SettingsSection(
        header: 'DANGER ZONE',
        tiles: [
          SettingsTile(
            icon: AppIcons.logoutIcon,
            title: 'Logout',
            isDanger: true,
            onTap: logout,
          ),
          // SettingsTile(
          //   icon: AppIcons.deleteIcon,
          //   title: 'Delete Account',
          //   isDanger: true,
          //   onTap: deleteAccount,
          // ),
        ],
      ),
  ];

  /// Guest CTA — explicitly tags the intent as buyer, matching the only
  /// role this single-store app ever signs anyone in as.
  Future<void> goToLogin() async {
    await AppPreferences.saveIntentRole('user');
    Get.toNamed(Routes.authTabView);
  }

  String get initials {
    final n = user.value?.name ?? '';
    final parts = n.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  final AuthRepository _authRepository = AuthRepository();
  final AuthController _authController = Get.put(AuthController());
  final UploadRepository _uploadRepository = UploadRepository();

  // Loading states
  RxBool isLoading = false.obs;
  RxBool isUpdating = false.obs;
  RxBool isUploadingImage = false.obs;

  // User data
  Rx<UserModel?> user = Rx<UserModel?>(null);
  Rx<File?> selectedImageFile = Rx<File?>(null);

  // Edit mode
  RxBool isEditMode = true.obs;

  // Text controllers for editing
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final RxString currencyPreference = ''.obs; // 'PKR' | 'USD'

  // Form keys
  final GlobalKey<FormState> profileFormKey = GlobalKey<FormState>();
  @override
  void onInit() {
    super.onInit();
    // Load profile after a small delay to ensure widget tree is ready
    Future.delayed(Duration(milliseconds: 100), () {
      loadUserProfile();
    });
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.onClose();
  }

  Future<void> refreshProfile() => loadUserProfile();

  /// Load user profile from backend
  Future<void> loadUserProfile() async {
    try {
      isLoading.value = true;

      final token = await AppPreferences.getAccessTokenAsync();

      if (token == null || token.isEmpty) {
        debugPrint('No token found, user not logged in');
        user.value = null;
        isLoading.value = false;
        return;
      }

      debugPrint('Loading profile with token: ${token.substring(0, 20)}...');

      final userData = await _authRepository.getUserProfile(token: token);

      if (userData != null) {
        user.value = userData;
        _updateControllers();
        debugPrint('Profile loaded successfully: ${userData.name}');
      } else {
        debugPrint('Failed to load profile - userData is null');
        ToastUtil.showToast('Failed to load profile');
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      ToastUtil.showToast('Error loading profile');
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh profile data
  // Future<void> refreshProfile() async {
  //   await loadUserProfile();
  // }

  /// Update text controllers with user data
  void _updateControllers() {
    if (user.value != null) {
      nameController.text = user.value!.name;
      emailController.text = user.value!.email;
      phoneController.text = user.value!.phone ?? '';
      addressController.text = user.value!.address ?? '';
      currencyPreference.value = user.value!.currencyPreference ?? '';
    }
  }

  void pickCurrencyPreference(String currency) {
    currencyPreference.value = currency;
  }

  /// Toggle edit mode
  void toggleEditMode() {
    if (isEditMode.value) {
      // Cancel editing - restore original values
      _updateControllers();
      selectedImageFile.value = null;
    }
    isEditMode.value = !isEditMode.value;
  }

  /// Pick image from gallery
  Future<void> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        selectedImageFile.value = File(image.path);
        debugPrint('Image selected: ${image.path}');
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      ToastUtil.showToast('Failed to pick image');
    }
  }

  /// Take photo with camera
  Future<void> takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        selectedImageFile.value = File(image.path);
        debugPrint('Photo taken: ${image.path}');
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
      ToastUtil.showToast('Failed to take photo');
    }
  }

  /// Show image picker options
  void showImagePickerOptions() {
    Get.bottomSheet(
      CustomBottomSheet(
        title: 'Choose Profile Picture',
        widget: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library),
              title: CustomText(text: 'Choose from Gallery'),
              onTap: () {
                Get.back();
                pickImage();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: CustomText(text: 'Take Photo'),
              onTap: () {
                Get.back();
                takePhoto();
              },
            ),
            if (user.value?.profileImage != null ||
                selectedImageFile.value != null)
              ListTile(
                leading: Icon(Icons.delete, color: AppColors.red),
                title: CustomText(text: 'Remove Photo', color: AppColors.red),
                onTap: () {
                  Get.back();
                  removeProfileImage();
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Remove profile image
  void removeProfileImage() {
    selectedImageFile.value = null;
    ToastUtil.showToast('Profile picture removed');
  }

  /// Upload profile image
  Future<String?> uploadProfileImage() async {
    if (selectedImageFile.value == null) return null;

    try {
      isUploadingImage.value = true;

      final url = await _uploadRepository.uploadImage(selectedImageFile.value!);

      if (url == null) {
        ToastUtil.showToast('Image upload failed');
        return null;
      }

      debugPrint("✅ Profile image uploaded: $url");
      return url;
    } catch (e) {
      debugPrint("❌ Upload error: $e");
      ToastUtil.showToast("Failed to upload image");
      return null;
    } finally {
      isUploadingImage.value = false;
    }
  }

  /// Update user profile
  Future<void> updateProfile() async {
    if (!profileFormKey.currentState!.validate()) return;

    isUpdating.value = true;

    try {
      // ✅ MUST await
      final token = await AppPreferences.getAccessTokenAsync();

      if (token == null || token.isEmpty) {
        ToastUtil.showToast('Session expired. Please login again');
        return;
      }

      String? imageUrl;
      if (selectedImageFile.value != null) {
        imageUrl = await uploadProfileImage();
      }

      final updatedUser = await _authRepository.updateProfile(
        token: token,
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim().isEmpty
            ? null
            : phoneController.text.trim(),
        address: addressController.text.trim().isEmpty
            ? null
            : addressController.text.trim(),
        profileImage: imageUrl ?? user.value?.profileImage,
        currencyPreference: currencyPreference.value.isEmpty
            ? null
            : currencyPreference.value,
      );

      if (updatedUser != null) {
        user.value = updatedUser;
        _authController.currentUser.value = updatedUser;
        isEditMode.value = false;
        selectedImageFile.value = null;
        ToastUtil.showToast('Profile updated successfully');
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      ToastUtil.showToast('Failed to update profile');
    } finally {
      isUpdating.value = false;
    }
  }

  /// Logout
  Future<void> logout() async {
    showCustomDialog(
      title: "Logout",
      content: 'Are you sure you want to logout?',
      leftButtonName: "Cancel",
      rightButtonName: "Logout",
      onLeftButtonTap: () => Get.back(),
      onRightButtonTap: () async {
        await _authController.logout();
      },
    );
  }

  /// Delete account
  Future<void> deleteAccount() async {
    Get.dialog(
      AlertDialog(
        title: CustomText(text: 'Delete Account'),
        content: CustomText(
          text:
              'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: CustomText(text: 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _performDeleteAccount();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: CustomText(text: 'Delete'),
          ),
        ],
      ),
    );
  }

  /// Perform account deletion
  Future<void> _performDeleteAccount() async {
    try {
      final token = await AppPreferences.getAccessTokenAsync();

      if (token == null || token.isEmpty) {
        ToastUtil.showToast('Session expired');
        return;
      }

      final success = await _authRepository.deleteAccount(token: token);

      if (success) {
        ToastUtil.showToast('Account deleted successfully');
        await _authController.logout();
      } else {
        ToastUtil.showToast('Failed to delete account');
      }
    } catch (e) {
      debugPrint('Error deleting account: $e');
      ToastUtil.showToast('Failed to delete account');
    }
  }

  // Validation methods
  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value != null && value.isNotEmpty) {
      if (value.length < 10) {
        return 'Please enter a valid phone number';
      }
    }
    return null;
  }
}
