import 'package:get/get.dart';
import '../modules/contact_us/bindings/contact_us_binding.dart';
import '../modules/contact_us/views/contact_us_view.dart';
import '../modules/notifications/bindings/notifications_binding.dart';
import '../modules/notifications/views/notifications_view.dart';
import '../modules/notification_preferences/bindings/notification_preferences_binding.dart';
import '../modules/notification_preferences/views/notification_preferences_view.dart';
import '../modules/trending_products/bindings/trending_products_binding.dart';
import '../modules/trending_products/views/trending_products_view.dart';
import '../modules/messaging/bindings/chat_binding.dart';
import '../modules/messaging/views/chat_view.dart';
import '../modules/onboarding/views/onboarding_view.dart';
import '../modules/onboarding/bindings/onboarding_binding.dart';
import '../modules/loyalty_rewards/bindings/loyalty_rewards_binding.dart';
import '../modules/loyalty_rewards/views/loyalty_rewards_view.dart';
import '../modules/store_services/bindings/store_services_binding.dart';
import '../modules/store_services/bindings/store_service_detail_binding.dart';
import '../modules/store_services/views/store_services_view.dart';
import '../modules/store_services/views/store_service_detail_view.dart';
import '../modules/about/bindings/about_binding.dart';
import '../modules/about/views/about_view.dart';
import '../modules/address/bindings/address_binding.dart';
import '../modules/address/views/add_address_view.dart';
import '../modules/address/views/address_view.dart';
import '../modules/auth/auth_tabs_view.dart';
import '../modules/otp_verification/bindings/otp_verification_binding.dart';
import '../modules/otp_verification/views/otp_verification_view.dart';
import '../modules/forgot_password/bindings/forgot_password_binding.dart';
import '../modules/forgot_password/views/forgot_password_view.dart';
import '../modules/reset_password/bindings/reset_password_binding.dart';
import '../modules/reset_password/views/reset_password_view.dart';
import '../modules/cart/bindings/cart_binding.dart';
import '../modules/cart/views/cart_view.dart';
import '../modules/category/bindings/category_binding.dart';
import '../modules/category/views/category_view.dart';
import '../modules/ai_assistant_chat/bindings/ai_assistant_chat_binding.dart';
import '../modules/ai_assistant_chat/views/ai_assistant_chat_view.dart';
import '../modules/checkout/bindings/checkout_binding.dart';
import '../modules/checkout/views/checkout_view.dart';
import '../modules/gateway_payment/bindings/gateway_payment_binding.dart';
import '../modules/gateway_payment/views/gateway_payment_view.dart';
import '../modules/edit_profile/bindings/edit_profile_binding.dart';
import '../modules/edit_profile/views/edit_profile_view.dart';
import '../modules/help_center/bindings/faq_binding.dart';
import '../modules/help_center/views/faq_detail_view.dart';
import '../modules/help_center/views/faq_list_view.dart';
import '../modules/help_center/views/help_center_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/main_view.dart';
import '../modules/login/binding/login_binding.dart';
import '../modules/map_picker/bindings/mappicker_binding.dart';
import '../modules/map_picker/views/mappicker_view.dart';
import '../modules/myorders/bindings/profile_myorders_binding.dart';
import '../modules/myorders/views/my_orders_view.dart';
import '../modules/myorders/views/reviews_view.dart';
import '../modules/ordertracker/bindings/order_tracker_binding.dart';
import '../modules/ordertracker/views/tracker_order_view.dart';
import '../modules/payment/views/payment_success_view.dart';
import '../modules/manual_transfer/bindings/manual_transfer_binding.dart';
import '../modules/manual_transfer/bindings/manual_transfer_status_binding.dart';
import '../modules/manual_transfer/views/manual_transfer_view.dart';
import '../modules/manual_transfer/views/manual_transfer_status_view.dart';
import '../modules/privacy_policy/bindings/privacy_policy_binding.dart';
import '../modules/privacy_policy/views/privacy_policy_view.dart';
import '../modules/product_details/binding/product_detail_binding.dart';
import '../modules/product_details/views/product_details_view.dart';
import '../modules/product_preview/binding/product_preview_binding.dart';
import '../modules/product_preview/views/product_preview_view.dart';
import '../modules/seller_storefront/bindings/seller_storefront_binding.dart';
import '../modules/seller_storefront/views/seller_storefront_view.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/refund_request/bindings/refund_request_binding.dart';
import '../modules/refund_request/views/refund_request_view.dart';
import '../modules/search/bindings/search_binding.dart';
import '../modules/search/views/search_view.dart';
import '../modules/splash_screen/bindings/splash_screen_binding.dart';
import '../modules/splash_screen/views/splash_screen_view.dart';
import '../modules/sub_category/binding/sub_category_binding.dart';
import '../modules/sub_category/views/sub_category_view.dart';
import '../modules/wishlist/bindings/wishlist_binding.dart';
import '../modules/wishlist/views/wishlist_view.dart';
part 'app_routes.dart';

class AppPages {
  static const initialRoute = Routes.splashScreen;

  static final routes = [
    GetPage(
      name: Routes.mainHome,
      page: () => MainView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: Routes.splashScreen,
      page: () => SplashView(),
      binding: SplashScreenBinding(),
    ),
    GetPage(
      name: Routes.onboarding,
      page: () => const OnboardingView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: Routes.authTabView,
      page: () => AuthTabsView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: Routes.otpVerification,
      page: () => const OtpVerificationView(),
      binding: OtpVerificationBinding(),
    ),
    GetPage(
      name: Routes.forgotPassword,
      page: () => const ForgotPasswordView(),
      binding: ForgotPasswordBinding(),
    ),
    GetPage(
      name: Routes.resetPassword,
      page: () => const ResetPasswordView(),
      binding: ResetPasswordBinding(),
    ),
    GetPage(
      name: Routes.categoryView,
      page: () => CategoryView(),
      binding: CategoryBinding(),
    ),
    GetPage(
      name: Routes.subCategoryView,
      page: () => const SubCategoryView(),
      binding: SubCategoryBinding(),
    ),
    GetPage(
      name: Routes.productDetailsView,
      page: () => ProductDetailsView(),
      binding: ProductDetailBinding(),
    ),
    GetPage(
      name: Routes.productPreviewView,
      page: () => ProductPreviewView(),
      binding: ProductPreviewBinding(),
    ),
    GetPage(
      name: Routes.sellerStorefront,
      page: () => SellerStorefrontView(),
      binding: SellerStorefrontBinding(),
    ),
    GetPage(
      name: Routes.searchView,
      page: () => SearchView(),
      binding: SearchBinding(),
    ),
    GetPage(
      name: Routes.cartView,
      page: () => CartView(),
      binding: CartBinding(),
    ),
    GetPage(
      name: Routes.checkoutView,
      page: () => CheckoutView(),
      binding: CheckoutBinding(),
    ),
    GetPage(name: Routes.paymentSuccessView, page: () => PaymentSuccessView()),
    GetPage(
      name: Routes.manualTransferView,
      page: () => ManualTransferView(),
      binding: ManualTransferBinding(),
    ),
    GetPage(
      name: Routes.manualTransferStatusView,
      page: () => ManualTransferStatusView(),
      binding: ManualTransferStatusBinding(),
    ),
    GetPage(
      name: Routes.gatewayPaymentView,
      page: () => GatewayPaymentView(),
      binding: GatewayPaymentBinding(),
    ),
    GetPage(
      name: Routes.profileView,
      page: () => ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: Routes.notificationPreferences,
      page: () => NotificationPreferencesView(),
      binding: NotificationPreferencesBinding(),
    ),
    GetPage(
      name: Routes.trendingProducts,
      page: () => TrendingProductsView(),
      binding: TrendingProductsBinding(),
    ),
    GetPage(
      name: Routes.myOrdersView,
      page: () => MyOrdersView(),
      binding: ProfileMyordersBinding(),
    ),
    GetPage(
      name: Routes.reviewsView,
      page: () => ReviewsView(),
    ),
    GetPage(
      name: Routes.addressView,
      page: () => AddressView(),
      binding: AddressBinding(),
    ),
    GetPage(
      name: Routes.addAddressView,
      page: () => AddAddressView(),
      binding: AddressBinding(),
    ),
    GetPage(
      name: Routes.trackerView,
      page: () => TrackOrderView(),
      binding: OrderTrackerBinding(),
    ),
    GetPage(
      name: Routes.refundRequestView,
      page: () => RefundRequestView(),
      binding: RefundRequestBinding(),
    ),
    GetPage(
      name: Routes.helpCenterView,
      page: () => HelpCenterView(),
      binding: FaqBinding(),
    ),
    GetPage(
      name: Routes.faqListView,
      page: () => FAQListView(),
      binding: FaqBinding(),
    ),
    GetPage(
      name: Routes.faqDetailView,
      page: () => FAQDetailView(),
      binding: FaqBinding(),
    ),
    GetPage(
      name: Routes.contactUsView,
      page: () => ContactUsView(),
      binding: ContactUsBinding(),
    ),
    GetPage(
      name: Routes.mapPickerView,
      page: () => MapPickerScreen(),
      binding: MappickerBinding(),
    ),
    GetPage(
      name: Routes.editProfileView,
      page: () => const EditProfileView(),
      binding: EditProfileBinding(),
    ),
    GetPage(
      name: Routes.PRIVACY_POLICY,
      page: () => const PrivacyPolicyView(),
      binding: PrivacyPolicyBinding(),
    ),
    GetPage(
      name: Routes.ABOUT,
      page: () => const AboutView(),
      binding: AboutBinding(),
    ),
    GetPage(
      name: Routes.CHAT,
      page: () => const AiAssistantChatView(),
      binding: AiAssistantChatBinding(),
    ),
    GetPage(
      name: Routes.WISHLIST,
      page: () => const WishlistView(),
      binding: WishlistBinding(),
    ),
    // Seller-management dashboard (Phase 2) and POS (Phase 3) have both
    // been extracted out of this buyer app — sellers/POS terminals now use
    // the standalone POS app, which depends on this app as a path
    // dependency for its shared network/data/UI layers.
    GetPage(
      name: Routes.chatView,
      page: () => ChatView(),
      binding: ChatBinding(),
    ),
    GetPage(
      name: Routes.loyaltyRewards,
      page: () => LoyaltyRewardsView(),
      binding: LoyaltyRewardsBinding(),
    ),
    GetPage(
      name: Routes.storeServices,
      page: () => StoreServicesView(),
      binding: StoreServicesBinding(),
    ),
    GetPage(
      name: Routes.storeServiceDetail,
      page: () => StoreServiceDetailView(),
      binding: StoreServiceDetailBinding(),
    ),
    GetPage(
      name: Routes.notifications,
      page: () => NotificationsView(),
      binding: NotificationsBinding(),
    ),
  ];
}
