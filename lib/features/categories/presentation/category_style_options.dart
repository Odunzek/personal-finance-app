import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Icon keys are stored in the database independent of any icon-package
/// identifier (which can change between versions) — see the schema note on
/// `icon_key` in CLAUDE.md/SPEC.md. Existing keys must never be renamed or
/// removed: transactions reference categories that reference these keys.
const Map<String, IconData> kCategoryIcons = {
  // Money & income
  'income': LucideIcons.wallet,
  'revenue': LucideIcons.trendingUp,
  'salary': LucideIcons.banknote,
  'bonus': LucideIcons.badgeDollarSign,
  'refund': LucideIcons.circleDollarSign,
  'savings': LucideIcons.piggyBank,
  'investments': LucideIcons.coins,
  'crypto': LucideIcons.bitcoin,
  'creditCard': LucideIcons.creditCard,
  'bankFees': LucideIcons.landmark,
  'taxes': LucideIcons.receipt,
  'insurance': LucideIcons.shieldCheck,
  'charity': LucideIcons.handshake,

  // Food & drink
  'groceries': LucideIcons.shoppingCart,
  'dining': LucideIcons.utensils,
  'coffee': LucideIcons.coffee,
  'pizza': LucideIcons.pizza,
  'fastFood': LucideIcons.sandwich,
  'bar': LucideIcons.beer,
  'wine': LucideIcons.wine,
  'dessert': LucideIcons.cakeSlice,
  'snacks': LucideIcons.candy,
  'produce': LucideIcons.apple,
  'salad': LucideIcons.salad,
  'cooking': LucideIcons.chefHat,

  // Transport
  'transport': LucideIcons.car,
  'fuel': LucideIcons.fuel,
  'parking': LucideIcons.parkingCircle,
  'publicTransit': LucideIcons.bus,
  'taxi': LucideIcons.carTaxiFront,
  'bike': LucideIcons.bike,
  'truck': LucideIcons.truck,
  'boat': LucideIcons.sailboat,
  'travel': LucideIcons.plane,

  // Home & utilities
  'housing': LucideIcons.house,
  'rentLease': LucideIcons.building,
  'utilities': LucideIcons.zap,
  'water': LucideIcons.droplets,
  'gas': LucideIcons.flame,
  'wifi': LucideIcons.wifi,
  'phoneInternet': LucideIcons.smartphone,
  'furniture': LucideIcons.sofa,
  'appliances': LucideIcons.refrigerator,
  'laundry': LucideIcons.washingMachine,
  'lighting': LucideIcons.lightbulb,
  'bath': LucideIcons.bath,
  'bedroom': LucideIcons.bed,
  'garden': LucideIcons.flower2,
  'homeMaintenance': LucideIcons.hammer,
  'paint': LucideIcons.paintRoller,
  'keys': LucideIcons.keyRound,

  // Shopping & personal
  'shopping': LucideIcons.shoppingBag,
  'clothing': LucideIcons.shirt,
  'jewelry': LucideIcons.gem,
  'accessories': LucideIcons.watch,
  'eyewear': LucideIcons.glasses,
  'beauty': LucideIcons.sparkles,
  'personalCare': LucideIcons.scissors,

  // Health & fitness
  'health': LucideIcons.heart,
  'fitness': LucideIcons.dumbbell,
  'pharmacy': LucideIcons.pill,
  'doctor': LucideIcons.stethoscope,
  'vaccines': LucideIcons.syringe,
  'mentalHealth': LucideIcons.brain,
  'vision': LucideIcons.eye,
  'medical': LucideIcons.cross,
  'wellness': LucideIcons.activity,

  // Entertainment & leisure
  'entertainment': LucideIcons.clapperboard,
  'subscriptions': LucideIcons.tv,
  'gaming': LucideIcons.gamepad2,
  'music': LucideIcons.music,
  'events': LucideIcons.ticket,
  'books': LucideIcons.book,
  'photography': LucideIcons.camera,
  'art': LucideIcons.palette,
  'instruments': LucideIcons.guitar,
  'karaoke': LucideIcons.mic,
  'party': LucideIcons.partyPopper,
  'games': LucideIcons.dices,
  'camping': LucideIcons.tent,
  'outdoors': LucideIcons.mountain,
  'beach': LucideIcons.waves,
  'sports': LucideIcons.trophy,

  // Family & pets
  'family': LucideIcons.baby,
  'gifts': LucideIcons.gift,
  'education': LucideIcons.graduationCap,
  'school': LucideIcons.school,
  'kids': LucideIcons.toyBrick,
  'childcare': LucideIcons.heartHandshake,
  'pets': LucideIcons.pawPrint,
  'dog': LucideIcons.dog,
  'cat': LucideIcons.cat,
  'vet': LucideIcons.bone,

  // Work & business
  'officeSupplies': LucideIcons.briefcase,
  'software': LucideIcons.laptop,
  'marketing': LucideIcons.megaphone,
  'payroll': LucideIcons.users,
  'professionalServices': LucideIcons.scale,
  'equipment': LucideIcons.wrench,
  'shipping': LucideIcons.package,
  'inventory': LucideIcons.archive,
  'store': LucideIcons.store,
  'factory': LucideIcons.factory,
  'warehouse': LucideIcons.warehouse,
  'construction': LucideIcons.hardHat,
  'printing': LucideIcons.printer,
  'website': LucideIcons.globe,
  'hosting': LucideIcons.server,
  'development': LucideIcons.code,
  'phone': LucideIcons.phone,
  'mail': LucideIcons.mail,
  'contracts': LucideIcons.fileText,
  'meetings': LucideIcons.presentation,
  'accounting': LucideIcons.calculator,

  // Other
  'other': LucideIcons.moreHorizontal,
  'calendar': LucideIcons.calendar,
  'time': LucideIcons.clock,
  'nature': LucideIcons.leaf,
  'weather': LucideIcons.sun,
  'night': LucideIcons.moon,
  'star': LucideIcons.star,
  'rain': LucideIcons.umbrella,
  'winter': LucideIcons.snowflake,
  'faith': LucideIcons.church,
};

/// Picker sections, in display order. Every key must exist in
/// [kCategoryIcons]; keys not listed here are still resolvable (legacy),
/// just not offered for new picks.
const List<({String label, List<String> keys})> kCategoryIconGroups = [
  (
    label: 'Money',
    keys: [
      'income',
      'revenue',
      'salary',
      'bonus',
      'refund',
      'savings',
      'investments',
      'crypto',
      'creditCard',
      'bankFees',
      'taxes',
      'insurance',
      'charity',
    ],
  ),
  (
    label: 'Food & drink',
    keys: [
      'groceries',
      'dining',
      'coffee',
      'pizza',
      'fastFood',
      'bar',
      'wine',
      'dessert',
      'snacks',
      'produce',
      'salad',
      'cooking',
    ],
  ),
  (
    label: 'Transport',
    keys: [
      'transport',
      'fuel',
      'parking',
      'publicTransit',
      'taxi',
      'bike',
      'truck',
      'boat',
      'travel',
    ],
  ),
  (
    label: 'Home & utilities',
    keys: [
      'housing',
      'rentLease',
      'utilities',
      'water',
      'gas',
      'wifi',
      'phoneInternet',
      'furniture',
      'appliances',
      'laundry',
      'lighting',
      'bath',
      'bedroom',
      'garden',
      'homeMaintenance',
      'paint',
      'keys',
    ],
  ),
  (
    label: 'Shopping & personal',
    keys: [
      'shopping',
      'clothing',
      'jewelry',
      'accessories',
      'eyewear',
      'beauty',
      'personalCare',
    ],
  ),
  (
    label: 'Health & fitness',
    keys: [
      'health',
      'fitness',
      'pharmacy',
      'doctor',
      'vaccines',
      'mentalHealth',
      'vision',
      'medical',
      'wellness',
    ],
  ),
  (
    label: 'Fun & leisure',
    keys: [
      'entertainment',
      'subscriptions',
      'gaming',
      'music',
      'events',
      'books',
      'photography',
      'art',
      'instruments',
      'karaoke',
      'party',
      'games',
      'camping',
      'outdoors',
      'beach',
      'sports',
    ],
  ),
  (
    label: 'Family & pets',
    keys: [
      'family',
      'gifts',
      'education',
      'school',
      'kids',
      'childcare',
      'pets',
      'dog',
      'cat',
      'vet',
    ],
  ),
  (
    label: 'Work & business',
    keys: [
      'officeSupplies',
      'software',
      'marketing',
      'payroll',
      'professionalServices',
      'equipment',
      'shipping',
      'inventory',
      'store',
      'factory',
      'warehouse',
      'construction',
      'printing',
      'website',
      'hosting',
      'development',
      'phone',
      'mail',
      'contracts',
      'meetings',
      'accounting',
    ],
  ),
  (
    label: 'Other',
    keys: [
      'other',
      'calendar',
      'time',
      'nature',
      'weather',
      'night',
      'star',
      'rain',
      'winter',
      'faith',
    ],
  ),
];

IconData iconForKey(String key) =>
    kCategoryIcons[key] ?? LucideIcons.moreHorizontal;

const List<Color> kCategoryColors = [
  Color(0xFF5CA2AC), // brand teal
  Color(0xFF3FBFA0), // mint
  Color(0xFF34A874), // green
  Color(0xFF8A9A4B), // olive
  Color(0xFFB8A24A), // gold
  Color(0xFFD9932A), // amber
  Color(0xFFCC7A3B), // burnt orange
  Color(0xFFE0654A), // coral
  Color(0xFFC94F4F), // red
  Color(0xFFC56FA0), // rose
  Color(0xFFB85CC2), // magenta
  Color(0xFF8B7BC7), // violet
  Color(0xFF3A6EA8), // deep blue
  Color(0xFF4E8FD6), // sky blue
  Color(0xFF9A6B4F), // brown
  Color(0xFF7D8A99), // slate
];
