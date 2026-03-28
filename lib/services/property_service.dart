import 'supabase_service.dart';
import '../models/property.dart';
import '../models/investor.dart';
import '../models/mortgage.dart';
import '../models/valuation.dart';

class PropertyService {
  final _client = SupabaseService.client;

  /// Fetches all properties the current user owns or is an accepted investor on.
  Future<List<Property>> getProperties() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return [];

    // Properties owned by the user
    final ownedResponse = await _client
        .from('properties')
        .select()
        .eq('user_id', userId);

    // Properties where user is an accepted investor
    final investedResponse = await _client
        .from('investors')
        .select('property_id, properties(*)')
        .eq('user_id', userId)
        .eq('invitation_status', 'accepted');

    final properties = <String, Property>{};

    for (final row in ownedResponse) {
      final p = Property.fromJson(row);
      properties[p.id] = p;
    }

    for (final row in investedResponse) {
      if (row['properties'] != null) {
        final p = Property.fromJson(row['properties'] as Map<String, dynamic>);
        properties[p.id] = p;
      }
    }

    return properties.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Gets the user's role for a property (Owner or Investor).
  String getUserRole(Property property) {
    return property.userId == SupabaseService.currentUserId
        ? 'Owner'
        : 'Investor';
  }

  /// Fetches investors for a property.
  Future<List<Investor>> getInvestors(String propertyId) async {
    final response = await _client
        .from('investors')
        .select()
        .eq('property_id', propertyId)
        .order('created_at');

    return response.map<Investor>((e) => Investor.fromJson(e)).toList();
  }

  /// Fetches the mortgage for a property.
  Future<Mortgage?> getMortgage(String propertyId) async {
    final response = await _client
        .from('mortgages')
        .select()
        .eq('property_id', propertyId)
        .maybeSingle();

    if (response == null) return null;
    return Mortgage.fromJson(response);
  }

  /// Fetches the latest valuation for a property.
  Future<Valuation?> getLatestValuation(String propertyId) async {
    final response = await _client
        .from('valuations')
        .select()
        .eq('property_id', propertyId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return Valuation.fromJson(response);
  }
}
