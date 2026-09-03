part of 'app_pages.dart';
// DO NOT EDIT. This is code generated via package:get_cli/get_cli.dart

abstract class Routes {
  static const mainHome = '/home';
  static const splashScreen = '/splash_screen';
  static const authTabView = '/auth/tabs_view';
  static const otpVerification = '/auth/otp_verification';
  static const forgotPassword = '/auth/forgot_password';
  static const resetPassword = '/auth/reset_password';
  static const categoryView = '/category';
  static const subCategoryView = '/category/sub_category';
  static const productDetailsView = '/category/product_details';
  static const productPreviewView = '/category/product_details/preview';
  static const sellerStorefront = '/store/storefront';
  static const searchView = '/search';
  static const cartView = '/cart';
  static const checkoutView = '/checkout';
  static const paymentSuccessView = '/payment/payment_success_view';
  static const manualTransferView = '/payment/manual-bank-transfer';
  static const manualTransferStatusView = '/payment/manual-bank-transfer/status';
  static const gatewayPaymentView = '/payment/gateway';
  static const profileView = '/profile';
  static const myOrdersView = '/profile/myorders';
  static const addressView = '/profile/address';
  static const addAddressView = '/profile/add_address';
  static const trackerView = '/profile/ordertracker';
  static const refundRequestView = '/profile/refund-request';
  static const reviewsView = '/profile/reviews-view';
  static const helpCenterView = '/profile/help-center';
  static const faqListView = '/profile/faq_view';
  static const faqDetailView = '/profile/faq_details';
  static const contactUsView = '/profile/contact-us';
  static const mapPickerView = '/map_picker';
  static const editProfileView = '/edit-profile';
  static const PRIVACY_POLICY = '/privacy-policy';
  static const ABOUT = '/about';
  static const CHAT = '/chat';
  static const WISHLIST = '/wishlist';
  static const notifications = '/notifications';
  static const notificationPreferences = '/notifications/preferences';
  static const trendingProducts = '/trending-products';
  static const chatView = '/messages/chat';

  // Entry
  static const onboarding = '/onboarding';

  // Buyer — loyalty & rewards for a specific store
  static const loyaltyRewards = '/loyalty-rewards';

  // Buyer — store services & bookings
  static const storeServices = '/store/services';
  static const storeServiceDetail = '/store/services/detail';

  // Seller-management (Phase 2) and POS (Phase 3) routes have all been
  // extracted into the standalone POS app — this buyer app no longer
  // registers any /seller/* or /pos/* routes.
}
