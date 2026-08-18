part of 'app_pages.dart';
// DO NOT EDIT. This is code generated via package:get_cli/get_cli.dart

abstract class Routes {
  static const mainHome = '/home';
  static const splashScreen = '/splash_screen';
  static const authTabView = '/auth/tabs_view';
  // static const signUpView = '/auth/signup';
  // static const loginView = '/auth/login';
  static const otpView = '/auth/otp';
  static const getNotified = '/auth/otp/get_notified';
  static const categoryView = '/category';
  static const categoryScreen = '/category_screen';
  static const subCategoryView = '/category/sub_category';
  static const productDetailsView = '/category/product_details';
  static const productPreviewView = '/category/product_details/preview';
  static const sellerStorefront = '/store/storefront';
  static const storesView = '/store/stores';
  static const searchView = '/search';
  static const cartView = '/cart';
  static const checkoutView = '/checkout';
  static const paymentSuccessView = '/payment/payment_success_view';
  static const manualTransferView = '/payment/manual-bank-transfer';
  static const manualTransferStatusView = '/payment/manual-bank-transfer/status';
  static const profileView = '/profile';
  static const myOrdersView = '/profile/myorders';
  static const orderTrackingView = '/profile/myorders/order_tracking';
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
  static const forgetPasswordView = '/forget-password';
  static const newPasswordView = '/new-password';
  static const SETTINGS = '/settings';
  static const CHANGE_PASSWORD = '/change-password';
  static const PRIVACY_POLICY = '/privacy-policy';
  static const ABOUT = '/about';
  static const CHAT = '/chat';
  static const WISHLIST = '/wishlist';
  static const notifications = '/notifications';
  static const notificationPreferences = '/notifications/preferences';
  static const trendingProducts = '/trending-products';
  static const messagesView = '/messages';
  static const chatView = '/messages/chat';

  // Entry
  static const welcome = '/welcome';
  static const onboarding = '/onboarding';

  // Seller setup — kept temporarily (not seller-management): POS still needs
  // a store-picker + first-store creation flow. Slated to move into the
  // standalone POS app in Phase 3.
  static const sellerOnboarding = '/seller/onboarding';
  static const sellerStores = '/seller/stores';

  // Role-based homes
  static const sellerHome = '/seller/home';
  static const posHome = '/pos/home';

  // Buyer — loyalty & rewards for a specific store
  static const loyaltyRewards = '/loyalty-rewards';

  // Buyer — store memberships (subscriptions)
  static const myMemberships = '/my-memberships';

  // Buyer — store services & bookings
  static const storeServices = '/store/services';
  static const storeServiceDetail = '/store/services/detail';
  static const myBookings = '/my-bookings';

  // Buyer/guest — free, unauthenticated AI Worksheet Builder trial
  static const worksheetTrial = '/worksheet-trial';

  // POS sub-screens
  static const posOrders = '/pos/orders';
  static const posProducts = '/pos/products';
  static const posSettings = '/pos/settings';

  // Seller POS management — kept temporarily, slated to move into the
  // standalone POS app in Phase 3.
  static const sellerPosManagement = '/seller/pos-management';
  static const sellerPosLocations = '/seller/pos-locations';

  // POS entry flow
  static const posPinLogin = '/pos/pin-login';
  static const posOpenRegister = '/pos/open-register';

  // POS operational screens
  static const posHeldSales = '/pos/held-sales';
  static const posSaleDetail = '/pos/sale-detail';
  static const posSessionReport = '/pos/session-report';
  static const posDailyReport = '/pos/daily-report';
  static const posSessionHistory = '/pos/session-history';
  static const posAuditLog = '/pos/audit-log';
  static const posRangeReport = '/pos/range-report';
}
