import 'package:flutter/material.dart';

/// A grouped section of tappable rows on the merged profile/settings screen
/// (`ProfileController.sections`, rendered by `SettingsSectionWidget`).
class SettingsSection {
  final String header;
  final List<SettingsTile> tiles;

  SettingsSection({required this.header, required this.tiles});
}

/// A single row within a [SettingsSection] (rendered by `SettingsTileWidget`).
class SettingsTile {
  final String icon;
  final String title;
  final String? trailing;
  final bool isDanger;
  final VoidCallback onTap;

  SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.isDanger = false,
    required this.onTap,
  });
}
