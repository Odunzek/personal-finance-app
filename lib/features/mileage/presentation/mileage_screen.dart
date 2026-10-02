import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/mileage_trip.dart';
import '../../../core/models/money.dart';
import '../../../core/models/profile.dart';
import '../../../core/widgets/mural_background.dart';
import '../data/mileage_repository.dart';
import 'mileage_trip_form_sheet.dart';

class MileageScreen extends StatefulWidget {
  final Profile profile;
  final MileageRepository mileageRepository;

  MileageScreen({
    super.key,
    required this.profile,
    MileageRepository? mileageRepository,
  }) : mileageRepository = mileageRepository ?? SupabaseMileageRepository();

  @override
  State<MileageScreen> createState() => _MileageScreenState();
}

class _MileageScreenState extends State<MileageScreen> {
  late Future<List<MileageTrip>> _tripsFuture;
  int _year = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _tripsFuture = widget.mileageRepository.listTrips(widget.profile.id);
    });
  }

  Future<void> _addTrip() async {
    final result = await showMileageTripFormSheet(context);
    if (result == null) return;
    await widget.mileageRepository.createTrip(
      profileId: widget.profile.id,
      occurredAt: result.occurredAt,
      destination: result.destination,
      purpose: result.purpose,
      kilometers: result.kilometers,
    );
    _reload();
  }

  Future<void> _confirmDelete(MileageTrip trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this trip?'),
        content: Text(
          'The trip to "${trip.destination}" on '
          '${DateFormat.yMMMd().format(trip.occurredAt)} will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.mileageRepository.deleteTrip(trip.id);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mileage log')),
      body: MuralBackground.ambient(
        child: FutureBuilder<List<MileageTrip>>(
          future: _tripsFuture,
          builder: (context, snapshot) {
            final all = snapshot.data;
            if (all == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final trips = all.where((t) => t.occurredAt.year == _year).toList()
              ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

            // Deduction is tiered on the year's running total, so walk trips
            // oldest-first to get each one's correct blended rate, then show
            // newest-first.
            final oldestFirst = trips.reversed.toList();
            var cumulativeKm = 0.0;
            var cumulativeCents = 0;
            final deductionById = <int, int>{};
            for (final t in oldestFirst) {
              final cents = craMileageDeductionCents(
                kmAlreadyThisYear: cumulativeKm,
                kmThisTrip: t.kilometers,
              );
              deductionById[t.id] = cents;
              cumulativeKm += t.kilometers;
              cumulativeCents += cents;
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => setState(() => _year--),
                      icon: const Icon(LucideIcons.chevronLeft),
                    ),
                    Text(
                      '$_year',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      onPressed: _year >= DateTime.now().year
                          ? null
                          : () => setState(() => _year++),
                      icon: const Icon(LucideIcons.chevronRight),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total distance',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                '${cumulativeKm.toStringAsFixed(1)} km',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estimated deduction',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                formatMoney(cumulativeCents),
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: Text(
                    'Based on CRA\'s per-km rate: ${(kCraMileageRateFirst5000Cents / 100).toStringAsFixed(2)}'
                    ' for the first 5,000 km this year, '
                    '${(kCraMileageRateAfter5000Cents / 100).toStringAsFixed(2)} after. '
                    'Check canada.ca each year — this rate changes annually.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (trips.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No trips logged for $_year yet.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  )
                else
                  for (final trip in trips)
                    Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            margin: EdgeInsets.zero,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              title: Text(trip.destination),
                              subtitle: Text(
                                [
                                  DateFormat.yMMMd().format(trip.occurredAt),
                                  if (trip.purpose != null) trip.purpose!,
                                ].join(' · '),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${trip.kilometers.toStringAsFixed(1)} km',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    formatMoney(deductionById[trip.id] ?? 0),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                              onLongPress: () => _confirmDelete(trip),
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 200.ms)
                        .slideX(begin: 0.03, end: 0),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTrip,
        child: const Icon(LucideIcons.plus),
      ),
    );
  }
}
