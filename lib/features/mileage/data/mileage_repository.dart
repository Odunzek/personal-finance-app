import '../../../core/models/mileage_trip.dart';
import '../../../core/supabase/supabase_client.dart';

String _dateOnly(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

abstract class MileageRepository {
  Future<List<MileageTrip>> listTrips(int profileId);

  Future<MileageTrip> createTrip({
    required int profileId,
    required DateTime occurredAt,
    required String destination,
    String? purpose,
    required double kilometers,
  });

  Future<void> deleteTrip(int id);
}

class SupabaseMileageRepository implements MileageRepository {
  @override
  Future<List<MileageTrip>> listTrips(int profileId) async {
    final rows = await supabase
        .from('mileage_trips')
        .select()
        .eq('profile_id', profileId)
        .order('occurred_at', ascending: false);
    return (rows as List)
        .map((r) => MileageTrip.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<MileageTrip> createTrip({
    required int profileId,
    required DateTime occurredAt,
    required String destination,
    String? purpose,
    required double kilometers,
  }) async {
    final row = await supabase
        .from('mileage_trips')
        .insert({
          'profile_id': profileId,
          'occurred_at': _dateOnly(occurredAt),
          'destination': destination,
          'purpose': purpose,
          'kilometers': kilometers,
        })
        .select()
        .single();
    return MileageTrip.fromRow(row);
  }

  @override
  Future<void> deleteTrip(int id) async {
    await supabase.from('mileage_trips').delete().eq('id', id);
  }
}
