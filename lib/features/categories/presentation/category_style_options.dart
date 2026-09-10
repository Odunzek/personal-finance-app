import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A small curated set of icon keys, kept stable in the database independent
/// of any icon-package identifier (which can change between versions) — see
/// the schema note on `icon_key` in CLAUDE.md/SPEC.md.
const Map<String, IconData> kCategoryIcons = {
  'groceries': LucideIcons.shoppingCart,
  'housing': LucideIcons.house,
  'transport': LucideIcons.car,
  'dining': LucideIcons.utensils,
  'entertainment': LucideIcons.clapperboard,
  'utilities': LucideIcons.zap,
  'health': LucideIcons.heart,
  'income': LucideIcons.wallet,
  'other': LucideIcons.moreHorizontal,
};

IconData iconForKey(String key) => kCategoryIcons[key] ?? LucideIcons.moreHorizontal;

const List<Color> kCategoryColors = [
  Color(0xFF5CA2AC),
  Color(0xFF2F8F6B),
  Color(0xFFC98A16),
  Color(0xFFA93B1F),
  Color(0xFF6B5CA0),
  Color(0xFF3B6EA9),
  Color(0xFFA05C8A),
  Color(0xFF8A8A5C),
];
