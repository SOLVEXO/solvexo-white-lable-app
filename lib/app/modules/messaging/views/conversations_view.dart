import 'package:book_store_app/app/components/app_search_field.dart';
import 'package:book_store_app/app/components/custom_app_bar_two.dart';
import 'package:book_store_app/app/components/custom_refresh_wrapper.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/components/svg_icon.dart';
import 'package:book_store_app/app/modules/messaging/controllers/conversations_controller.dart';
import 'package:book_store_app/app/modules/messaging/widgets/conversation_tile.dart';
import 'package:book_store_app/app/modules/messaging/widgets/conversations_shimmer.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_icons.dart';
import 'package:book_store_app/core/theme/base_animations.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConversationsView extends StatelessWidget {
  ConversationsView({super.key});

  final ConversationsController c = Get.put(ConversationsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBarTwo(title: "Messages"),
      body: Column(
        children: [
          _SearchBar(c: c),
          _FilterPills(c: c),
          Expanded(
            child: Obx(() {
              if (c.isLoading.value) return const ConversationsShimmer();

              if (c.conversations.isEmpty) return const _EmptyInbox();

              final convs = c.filteredConversations;
              if (convs.isEmpty) return const _EmptyFilterResult();

              return CustomRefreshWrapper(
                onRefresh: c.loadConversations,
                child: ListView.separated(
                  padding: EdgeInsets.only(bottom: BaseSpacing.md),
                  itemCount: convs.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.lightGrey3),
                  itemBuilder: (_, i) {
                    final conv = convs[i];
                    return ConversationTile(
                      conversation: conv,
                      onTap: () => c.openChat(conv),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.c});
  final ConversationsController c;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(
        BaseSpacing.md,
        BaseSpacing.xs,
        BaseSpacing.md,
        BaseSpacing.sm,
      ),
      child: Obx(
        () => AppSearchField(
          controller: c.searchController,
          onChanged: c.onSearch,
          staticHint: 'Search messages',
          suffixIcon: c.searchQuery.value.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    c.searchController.clear();
                    c.onSearch('');
                  },
                  child: SvgIcon(
                    assetName: AppIcons.cross,
                    color: AppColors.textPrimary,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _FilterPills extends StatelessWidget {
  const _FilterPills({required this.c});
  final ConversationsController c;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(
        BaseSpacing.md,
        0,
        BaseSpacing.md,
        BaseSpacing.sm,
      ),
      child: Obx(
        () => Row(
          children: [
            _Pill(
              label: 'All',
              selected: !c.unreadOnly.value,
              onTap: () => c.setUnreadOnly(false),
            ),
            SizedBox(width: BaseSpacing.xs),
            _Pill(
              label: 'Unread',
              selected: c.unreadOnly.value,
              onTap: () => c.setUnreadOnly(true),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: BaseMotion.normal,
        padding: EdgeInsets.symmetric(
          horizontal: BaseSpacing.md,
          vertical: BaseSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryColor : AppColors.lightGrey10,
          borderRadius: BorderRadius.circular(BaseRadius.pill),
        ),
        child: CustomText(
          text: label,
          color: selected ? AppColors.white : AppColors.gray600,
          fontSize: AppFontSize.tiny,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor.withOpacity(0.12),
                  AppColors.accentColor.withOpacity(0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(BaseRadius.xxl),
            ),
            alignment: Alignment.center,
            child: SvgIcon(
              assetName: AppIcons.messageIcon,
              size: 34,
              color: AppColors.primaryColor,
            ),
          ),
          SizedBox(height: BaseSpacing.md),
          CustomText(
            text: 'No messages yet',
            color: AppColors.black2,
            fontSize: AppFontSize.small2,
            fontWeight: FontWeight.bold,
          ),
          SizedBox(height: BaseSpacing.xxs + 2),
          CustomText(
            text: 'Messages with sellers you contact\nwill show up here.',
            color: AppColors.gray600,
            fontSize: AppFontSize.tiny,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EmptyFilterResult extends StatelessWidget {
  const _EmptyFilterResult();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomText(
        text: 'No conversations match',
        color: AppColors.gray600,
        fontSize: AppFontSize.extraSmall,
      ),
    );
  }
}
