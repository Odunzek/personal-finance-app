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
  'revenue': LucideIcons.trendingUp,
  'officeSupplies': LucideIcons.briefcase,
  'software': LucideIcons.laptop,
  'marketing': LucideIcons.megaphone,
  'payroll': LucideIcons.users,
  'equipment': LucideIcons.wrench,
  'travel': LucideIcons.plane,
  'professionalServices': LucideIcons.scale,
  'taxes': LucideIcons.receipt,
  // Added for broader personal + small-business coverage.
  'shopping': LucideIcons.shoppingBag,
  'pets': LucideIcons.pawPrint,
  'family': LucideIcons.baby,
  'gifts': LucideIcons.gift,
  'education': LucideIcons.graduationCap,
  'fitness': LucideIcons.dumbbell,
  'subscriptions': LucideIcons.tv,
  'phoneInternet': LucideIcons.smartphone,
  'fuel': LucideIcons.fuel,
  'parking': LucideIcons.parkingCircle,
  'publicTransit': LucideIcons.bus,
  'coffee': LucideIcons.coffee,
  'insurance': LucideIcons.shieldCheck,
  'personalCare': LucideIcons.scissors,
  'homeMaintenance': LucideIcons.hammer,
  'charity': LucideIcons.handshake,
  'savings': LucideIcons.piggyBank,
  'bankFees': LucideIcons.landmark,
  'rentLease': LucideIcons.building,
  'shipping': LucideIcons.package,
  'inventory': LucideIcons.archive,
  'refund': LucideIcons.circleDollarSign,
  'bonus': LucideIcons.badgeDollarSign,
};

IconData iconForKey(String key) =>
    kCategoryIcons[key] ?? LucideIcons.moreHorizontal;

const List<Color> kCategoryColors = [
  Color(0xFF5CA2AC), // brand teal
  Color(0xFF34A874), // green
  Color(0xFFD9932A), // amber
  Color(0xFFE0654A), // coral
  Color(0xFF8B7BC7), // violet
  Color(0xFF4E8FD6), // sky blue
  Color(0xFFC56FA0), // rose
  Color(0xFFB8A24A), // gold
];
