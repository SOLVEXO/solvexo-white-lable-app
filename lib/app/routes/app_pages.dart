import 'package:get/get.dart';
import '../modules/contact_us/bindings/contact_us_binding.dart';
import '../modules/contact_us/views/contact_us_view.dart';
import '../modules/notifications/bindings/notifications_binding.dart';
import '../modules/notifications/views/notifications_view.dart';
import '../modules/notification_preferences/bindings/notification_preferences_binding.dart';
import '../modules/notification_preferences/views/notification_preferences_view.dart';
import '../modules/trending_products/bindings/trending_products_binding.dart';
import '../modules/trending_products/views/trending_products_view.dart';
import '../modules/messaging/bindings/conversations_binding.dart';
import '../modules/messaging/bindings/chat_binding.dart';
import '../modules/messaging/views/conversations_view.dart';
import '../modules/messaging/views/chat_view.dart';
import '../modules/seller_onboarding/bindings/seller_onboarding_binding.dart';
import '../modules/seller_onboarding/views/seller_onboarding_view.dart';
import '../modules/seller_stores/bindings/seller_stores_binding.dart';
import '../modules/seller_stores/views/seller_stores_view.dart';
import '../modules/welcome/views/welcome_view.dart';
import '../modules/welcome/bindings/welcome_binding.dart';
import '../modules/onboarding/views/onboarding_view.dart';
import '../modules/onboarding/bindings/onboarding_binding.dart';
import '../modules/pos/bindings/pos_binding.dart';
import '../modules/pos_orders/bindings/pos_orders_binding.dart';
import '../modules/pos_products/bindings/pos_products_binding.dart';
import '../modules/pos_settings/bindings/pos_settings_binding.dart';
import '../modules/pos/views/pos_main_view.dart';
import '../modules/pos_orders/views/pos_orders_view.dart';
import '../modules/pos_products/views/pos_products_view.dart';
import '../modules/pos_settings/views/pos_settings_view.dart';
import '../modules/pos_pin_login/bindings/pos_pin_login_binding.dart';
import '../modules/pos_pin_login/views/pos_pin_login_view.dart';
import '../modules/pos_open_register/bindings/pos_open_register_binding.dart';
import '../modules/pos_open_register/views/pos_open_register_view.dart';
import '../modules/pos_held_sales/bindings/pos_held_sales_binding.dart';
import '../modules/pos_held_sales/views/pos_held_sales_view.dart';
import '../modules/pos_daily_report/bindings/pos_daily_report_binding.dart';
import '../modules/pos_daily_report/views/pos_daily_report_view.dart';
import '../modules/seller_pos_management/bindings/seller_pos_management_binding.dart';
import '../modules/seller_pos_management/views/seller_pos_management_view.dart';
import '../modules/seller_pos_locations/bindings/seller_pos_locations_binding.dart';
import '../modules/seller_pos_locations/views/seller_pos_locations_view.dart';
import '../modules/loyalty_rewards/bindings/loyalty_rewards_binding.dart';
import '../modules/loyalty_rewards/views/loyalty_rewards_view.dart';
import '../modules/my_memberships/bindings/my_memberships_binding.dart';
import '../modules/my_memberships/views/my_memberships_view.dart';
import '../modules/store_services/bindings/store_services_binding.dart';
import '../modules/store_services/bindings/store_service_detail_binding.dart';
import '../modules/store_services/views/store_services_view.dart';
import '../modules/store_services/views/store_service_detail_view.dart';
import '../modules/my_bookings/bindings/my_bookings_binding.dart';
import '../modules/my_bookings/views/my_bookings_view.dart';
import '../modules/worksheet_trial/bindings/worksheet_trial_binding.dart';
import '../modules/worksheet_trial/views/worksheet_trial_view.dart';
import '../modules/about/bindings/about_binding.dart';
import '../modules/about/views/about_view.dart';
import '../modules/address/bindings/address_binding.dart';
import '../modules/address/views/add_address_view.dart';
import '../modules/address/views/address_view.dart';
import '../modules/auth/auth_tabs_view.dart';
import '../modules/cart/bindings/cart_binding.dart';
import '../modules/cart/views/cart_view.dart';
import '../modules/category/bindings/category_binding.dart';
import '../modules/category/views/category_view.dart';
import '../modules/change_password/bindings/change_password_binding.dart';
import '../modules/change_password/views/change_password_view.dart';
import '../modules/ai_assistant_chat/bindings/ai_assistant_chat_binding.dart';
import '../modules/ai_assistant_chat/views/ai_assistant_chat_view.dart';
import '../modules/checkout/bindings/checkout_binding.dart';
import '../modules/checkout/views/checkout_view.dart';
import '../modules/edit_profile/bindings/edit_profile_binding.dart';
import '../modules/edit_profile/views/edit_profile_view.dart';
import '../modules/forget_password/bindings/forget_password_binding.dart';
import '../modules/forget_password/views/forget_password_view.dart';
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
import '../modules/otp/binding/otp_binding.dart';
import '../modules/otp/views/get_notified.dart';
import '../modules/otp/views/otp_view.dart';
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
import '../modules/stores/bindings/stores_binding.dart';
import '../modules/stores/views/stores_view.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/refund_request/bindings/refund_request_binding.dart';
import '../modules/refund_request/views/refund_request_view.dart';
import '../modules/reset_password/bindings/new_password_binding.dart';
import '../modules/reset_password/views/new_password_view.dart';
import '../modules/search/bindings/search_binding.dart';
import '../modules/search/views/search_view.dart';
import '../modules/splash_screen/bindings/splash_screen_binding.dart';
import '../modules/splash_screen/views/splash_screen_view.dart';
import '../modules/sub_category/binding/sub_category_binding.dart';
import '../modules/sub_category/views/sub_category_view.dart';
import '../modules/wishlist/bindings/wishlist_binding.dart';
import '../modules/wishlist/views/wishlist_view.dart';
import '../modules/pos_sale_detail/bindings/pos_sale_detail_binding.dart';
import '../modules/pos_sale_detail/views/pos_sale_detail_view.dart';
import '../modules/pos_session_report/bindings/pos_session_report_binding.dart';
import '../modules/pos_session_report/views/pos_session_report_view.dart';
import '../modules/pos_session_history/bindings/pos_session_history_binding.dart';
import '../modules/pos_session_history/views/pos_session_history_view.dart';
import '../modules/pos_audit_log/bindings/pos_audit_log_binding.dart';
import '../modules/pos_audit_log/views/pos_audit_log_view.dart';
import '../modules/pos_range_report/bindings/pos_range_report_binding.dart';
import '../modules/pos_range_report/views/pos_range_report_view.dart';
import '../middleware/auth_middleware.dart';

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
      name: Routes.welcome,
      page: () => const WelcomeView(),
      binding: WelcomeBinding(),
    ),
    GetPage(
      name: Routes.onboarding,
      page: () => const OnboardingView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: Routes.sellerStores,
      page: () => SellerStoresView(),
      binding: SellerStoresBinding(),
    ),
    GetPage(
      name: Routes.authTabView,
      page: () => AuthTabsView(),
      binding: LoginBinding(),
    ),
    GetPage(name: Routes.otpView, page: () => OtpView(), binding: OtpBinding()),
    GetPage(
      name: Routes.getNotified,
      page: () => GetNotified(),
      binding: OtpBinding(),
    ),
    // GetPage(name: Routes.signUpView, page: () => SignUpView()),
    // GetPage(name: Routes.loginView, page: () => LoginView()),
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
      name: Routes.storesView,
      page: () => StoresView(),
      binding: StoresBinding(),
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
    // GetPage(
    //   name: Routes.orderTrackingView,
    //   page: () => OrderTrackingView(),
    //   binding: ProfileMyordersBinding(),
    // ),
    GetPage(
      name: Routes.reviewsView,
      page: () => ReviewsView(),
      binding: ProfileMyordersBinding(),
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
      name: Routes.forgetPasswordView,
      page: () => const ForgetPasswordView(),
      binding: ForgetPasswordBinding(),
    ),
    GetPage(
      name: Routes.newPasswordView,
      page: () => const NewPasswordView(),
      binding: NewPasswordBinding(),
    ),
    // GetPage(
    //   name: Routes.SETTINGS,
    //   page: () => const SettingsView(),
    //   binding: SettingsBinding(),
    // ),
    GetPage(
      name: Routes.CHANGE_PASSWORD,
      page: () => ChangePasswordView(),
      binding: ChangePasswordBinding(),
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
    GetPage(
      name: Routes.sellerOnboarding,
      page: () => SellerOnboardingView(),
      binding: SellerOnboardingBinding(),
    ),
    // Seller-management dashboard removed (Phase 2) — this app no longer
    // carries a seller dashboard shell. The only seller-side screens left
    // here are POS configuration (staff/registers/locations), pending
    // relocation into the standalone POS app in Phase 3.
    GetPage(
      name: Routes.sellerHome,
      page: () => SellerPosManagementView(),
      binding: SellerPosManagementBinding(),
    ),
    GetPage(
      name: Routes.posHome,
      page: () => PosMainView(),
      binding: PosBinding(),
      middlewares: [PosAccessMiddleware(requireActiveSession: true)],
    ),
    GetPage(
      name: Routes.messagesView,
      page: () => ConversationsView(),
      binding: ConversationsBinding(),
    ),
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
      name: Routes.myMemberships,
      page: () => MyMembershipsView(),
      binding: MyMembershipsBinding(),
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
      name: Routes.myBookings,
      page: () => MyBookingsView(),
      binding: MyBookingsBinding(),
    ),
    GetPage(
      name: Routes.worksheetTrial,
      page: () => const WorksheetTrialView(),
      binding: WorksheetTrialBinding(),
    ),
    GetPage(
      name: Routes.posOrders,
      page: () => PosOrdersView(),
      binding: PosOrdersBinding(),
      middlewares: [PosAccessMiddleware(requireActiveSession: true)],
    ),
    GetPage(
      name: Routes.posPinLogin,
      page: () => PosPinLoginView(),
      binding: PosPinLoginBinding(),
      middlewares: [PosAccessMiddleware()],
    ),
    GetPage(
      name: Routes.posOpenRegister,
      page: () => PosOpenRegisterView(),
      binding: PosOpenRegisterBinding(),
      middlewares: [PosAccessMiddleware()],
    ),
    GetPage(
      name: Routes.posHeldSales,
      page: () => PosHeldSalesView(),
      binding: PosHeldSalesBinding(),
      middlewares: [PosAccessMiddleware(requireActiveSession: true)],
    ),
    GetPage(
      name: Routes.posDailyReport,
      page: () => PosDailyReportView(),
      binding: PosDailyReportBinding(),
      middlewares: [PosAccessMiddleware(requireActiveSession: true)],
    ),
    GetPage(
      name: Routes.sellerPosManagement,
      page: () => SellerPosManagementView(),
      binding: SellerPosManagementBinding(),
    ),
    GetPage(
      name: Routes.sellerPosLocations,
      page: () => SellerPosLocationsView(),
      binding: SellerPosLocationsBinding(),
    ),
    GetPage(
      name: Routes.posProducts,
      page: () => PosProductsView(),
      binding: PosProductsBinding(),
      middlewares: [PosAccessMiddleware(requireActiveSession: true)],
    ),
    GetPage(
      name: Routes.posSettings,
      page: () => PosSettingsView(),
      binding: PosSettingsBinding(),
      middlewares: [PosAccessMiddleware(requireActiveSession: true)],
    ),
    GetPage(
      name: Routes.posSaleDetail,
      page: () => PosSaleDetailView(),
      binding: PosSaleDetailBinding(),
      middlewares: [PosAccessMiddleware(requireActiveSession: true)],
    ),
    GetPage(
      name: Routes.posSessionReport,
      page: () => PosSessionReportView(),
      binding: PosSessionReportBinding(),
      middlewares: [PosAccessMiddleware(requireActiveSession: true)],
    ),
    GetPage(
      name: Routes.posSessionHistory,
      page: () => PosSessionHistoryView(),
      binding: PosSessionHistoryBinding(),
      middlewares: [PosAccessMiddleware(requireActiveSession: true)],
    ),
    GetPage(
      name: Routes.posAuditLog,
      page: () => PosAuditLogView(),
      binding: PosAuditLogBinding(),
      middlewares: [PosAccessMiddleware()],
    ),
    GetPage(
      name: Routes.posRangeReport,
      page: () => PosRangeReportView(),
      binding: PosRangeReportBinding(),
      middlewares: [PosAccessMiddleware()],
    ),
    GetPage(
      name: Routes.notifications,
      page: () => NotificationsView(),
      binding: NotificationsBinding(),
    ),
  ];
}
