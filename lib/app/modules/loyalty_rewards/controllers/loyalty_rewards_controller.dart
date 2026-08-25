import 'package:book_store_app/app/data/models/loyalty/my_loyalty_balance_model.dart';
import 'package:book_store_app/app/data/models/loyalty/reward_model.dart';
import 'package:book_store_app/app/data/repositories/loyalty_repository.dart';
import 'package:book_store_app/app/data/services/current_store_service.dart';
import 'package:get/get.dart';

class LoyaltyRewardsController extends GetxController {
  final LoyaltyRepository _repo = LoyaltyRepository();

  late final String storeId;
  late final String storeName;

  final RxBool isLoading = true.obs;
  final RxString redeemingId = ''.obs;
  final Rx<MyLoyaltyBalanceModel> balance = Rx<MyLoyaltyBalanceModel>(MyLoyaltyBalanceModel.empty);
  final RxList<RewardModel> rewards = <RewardModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Prefers whatever storeId/storeName the caller passed (e.g. the
    // storefront's plans teaser, a push-notification deep link) — falling
    // back to this app's own resolved store (`CurrentStoreService`, already
    // resolved in the background since app launch by the time a buyer has
    // navigated this deep) so this screen also works as a standalone entry
    // point without every caller having to look the store up itself first.
    // Read synchronously (not awaited) so `storeId`/`storeName` are always
    // set before this method returns — `late final` fields the view reads
    // unconditionally in its AppBar, not behind an `isLoading` guard.
    final args = Get.arguments as Map<String, dynamic>?;
    var id = args?['storeId'] as String? ?? '';
    var name = args?['storeName'] as String? ?? '';

    if (id.isEmpty) {
      final currentStore = Get.find<CurrentStoreService>();
      id = currentStore.storeId ?? '';
      name = currentStore.storeName ?? '';
    }

    storeId = id;
    storeName = name.isNotEmpty ? name : 'Store';
    _load();
  }

  Future<void> _load() async {
    if (storeId.isEmpty) {
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    // Kick off both requests before awaiting so they run concurrently.
    final balanceFuture = _repo.getMyBalance(storeId);
    final rewardsFuture = _repo.getPublicRewards(storeId);
    balance.value = await balanceFuture;
    rewards.assignAll(await rewardsFuture);
    isLoading.value = false;
  }

  @override
  Future<void> refresh() => _load();

  bool canAfford(RewardModel reward) => balance.value.pointsBalance >= reward.pointsCost;

  Future<void> redeem(RewardModel reward) async {
    if (redeemingId.value.isNotEmpty) return;
    redeemingId.value = reward.id;
    final remaining = await _repo.redeemReward(storeId, reward.id);
    redeemingId.value = '';
    if (remaining != null) {
      balance.value = MyLoyaltyBalanceModel(
        pointsBalance: remaining,
        lifetimePoints: balance.value.lifetimePoints,
        currentTier: balance.value.currentTier,
        nextTier: balance.value.nextTier,
      );
      // Reward stock counters may have changed — refresh the catalog.
      rewards.assignAll(await _repo.getPublicRewards(storeId));
    }
  }
}
