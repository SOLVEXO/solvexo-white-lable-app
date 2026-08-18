import 'dart:async';

import 'package:book_store_app/app/data/models/common_models/notification_model.dart';
import 'package:book_store_app/app/data/repositories/notifications_repository.dart';
import 'package:book_store_app/app/modules/notifications/controllers/notifications_badge_controller.dart';
import 'package:book_store_app/app/network/notifications_socket_service.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/shared_prefrences/app_prefrences.dart';
import 'package:book_store_app/utils/toast_util.dart';
import 'package:get/get.dart';

class NotificationsController extends GetxController {
  final NotificationsRepository _repository = NotificationsRepository();
  final NotificationsSocketService _socket = NotificationsSocketService.instance;
  StreamSubscription? _newSub;
  StreamSubscription? _countSub;

  final RxList<NotificationModel> _all = <NotificationModel>[].obs;
  final RxString selectedFilter = 'all'.obs;
  final RxBool isLoading = false.obs;
  final RxInt unreadCount = 0.obs;

  List<NotificationModel> get filteredNotifications {
    if (selectedFilter.value == 'all') return List.unmodifiable(_all);
    return _all.where((n) => n.filterKey == selectedFilter.value).toList();
  }

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
    _socket.ensureConnected();
    _newSub = _socket.onNewNotification.listen((json) {
      _all.insert(0, NotificationModel.fromJson(json));
    });
    _countSub = _socket.onUnreadCount.listen((count) => unreadCount.value = count);
  }

  Future<void> fetchNotifications() async {
    // Notifications are a login-only feature — a guest tapping the bell
    // icon gets a clear reason the inbox is empty, not a raw 401.
    if (!await AppPreferences.isLoggedIn()) {
      ToastUtil.showToast('Login to view your notifications');
      return;
    }
    isLoading.value = true;
    final result = await _repository.list();
    _all.assignAll(result.items);
    unreadCount.value = result.unreadCount;
    _syncBadge();
    isLoading.value = false;
  }

  /// Keeps the app-bar bell badge (`NotificationsBadgeController`) in step —
  /// it doesn't otherwise learn about read-state changes made from this
  /// screen, since the backend only pushes `notification:unread-count` on
  /// new notifications, not on markRead/markAllRead.
  void _syncBadge() {
    if (Get.isRegistered<NotificationsBadgeController>()) {
      Get.find<NotificationsBadgeController>().unreadCount.value = unreadCount.value;
    }
  }

  @override
  Future<void> refresh() => fetchNotifications();

  void setFilter(String filter) => selectedFilter.value = filter;

  Future<void> markRead(String id) async {
    final idx = _all.indexWhere((n) => n.id == id);
    if (idx < 0 || _all[idx].isRead) return;
    _all[idx] = _all[idx].copyWith(isRead: true);
    _all.refresh();
    unreadCount.value = (unreadCount.value - 1).clamp(0, 1 << 30);
    _syncBadge();
    await _repository.markRead(id);
  }

  /// Marks the tapped notification read and — where a matching screen
  /// exists — routes to it. Unrecognized/unmapped types just mark read and
  /// leave the user on the inbox.
  Future<void> openNotification(NotificationModel notification) async {
    markRead(notification.id);
    final data = notification.data ?? const <String, dynamic>{};

    switch (notification.rawType) {
      case 'order_shipped':
      case 'order_delivered':
      case 'payment_success':
      case 'payment_failed':
        Get.toNamed(Routes.myOrdersView);
        break;
      case 'new_message':
        final conversationId = data['conversationId']?.toString();
        if (conversationId != null && conversationId.isNotEmpty) {
          Get.toNamed(Routes.chatView, arguments: {'conversationId': conversationId});
        }
        break;
      case 'loyalty_points_earned':
      case 'loyalty_tier_upgrade':
        final storeId = data['storeId']?.toString();
        if (storeId != null && storeId.isNotEmpty) {
          Get.toNamed(
            Routes.loyaltyRewards,
            arguments: {'storeId': storeId, 'storeName': 'Store'},
          );
        }
        break;
      case 'subscription_renewal_reminder':
      case 'subscription_payment_failed':
      case 'subscription_cancelled':
        Get.toNamed(Routes.myMemberships);
        break;
      default:
        break;
    }
  }

  Future<void> markAllRead() async {
    for (int i = 0; i < _all.length; i++) {
      _all[i] = _all[i].copyWith(isRead: true);
    }
    _all.refresh();
    unreadCount.value = 0;
    _syncBadge();
    await _repository.markAllRead();
  }

  @override
  void onClose() {
    _newSub?.cancel();
    _countSub?.cancel();
    super.onClose();
  }
}
