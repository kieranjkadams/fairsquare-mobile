import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/property.dart';
import '../models/investor.dart';
import '../models/mortgage.dart';
import '../models/valuation.dart';
import '../services/property_service.dart';
import 'auth_provider.dart';

final propertyServiceProvider = Provider<PropertyService>((ref) => PropertyService());

final propertiesProvider = FutureProvider<List<Property>>((ref) async {
  // Re-fetch when auth state changes
  ref.watch(authStateProvider);
  return ref.watch(propertyServiceProvider).getProperties();
});

final investorsProvider =
    FutureProvider.family<List<Investor>, String>((ref, propertyId) async {
  return ref.watch(propertyServiceProvider).getInvestors(propertyId);
});

final mortgageProvider =
    FutureProvider.family<Mortgage?, String>((ref, propertyId) async {
  return ref.watch(propertyServiceProvider).getMortgage(propertyId);
});

final valuationProvider =
    FutureProvider.family<Valuation?, String>((ref, propertyId) async {
  return ref.watch(propertyServiceProvider).getLatestValuation(propertyId);
});
