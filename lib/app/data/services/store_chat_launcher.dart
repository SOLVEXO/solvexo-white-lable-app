import 'package:book_store_app/app/data/repositories/messaging_repository.dart';
import 'package:book_store_app/app/data/services/auth_gate_service.dart';
import 'package:book_store_app/app/data/services/current_store_service.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:get/get.dart';

/// Single-tenant apps have exactly one conversation to open — this store's
/// owner — so every "message us" entry point (the global app bar icon, the
/// store info page's contact button) opens the same chat directly instead of
/// showing an inbox to choose from. Requires login (guests get the usual
/// login-prompt sheet via [AuthGateService]) and creates the conversation on
/// first use — the backend returns the existing one on every call after.
class StoreChatLauncher {
  const StoreChatLauncher._();

  static Future<void> open() async {
    final allowed = await AuthGateService.instance.requireAuth(
      message: 'Login to message us.',
    );
    if (!allowed) return;

    final currentStore = Get.find<CurrentStoreService>();
    await currentStore.ensureResolved();
    final store = currentStore.store.value;
    if (store == null) return;

    final conversation = await MessagingRepository().startConversation(store.storeId);
    if (conversation == null) return;

    Get.toNamed(
      Routes.chatView,
      arguments: {
        'conversationId': conversation.id,
        'peerName': store.name,
        'peerAvatar': store.logo,
      },
    );
  }
}
