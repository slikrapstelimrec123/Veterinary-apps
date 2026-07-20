import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../domain/owner_plan.dart';

class BillingRepository {
  BillingRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;
  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  Future<OwnerPlan> getCurrentPlan() async {
    if (SupabaseConfig.useMockData) return OwnerPlan.free;
    final data = await _supabase.rpc('get_my_owner_plan');
    return OwnerPlan.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<PublicationAccess> getPublicationAccess(String type) async {
    if (SupabaseConfig.useMockData) {
      return const PublicationAccess(
        allowed: true,
        free: true,
        requiresPurchase: false,
        planCode: 'free',
        remaining: 1,
      );
    }
    final data = await _supabase.rpc(
      'get_my_publication_access',
      params: {'target_type': type},
    );
    return PublicationAccess.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
  }

  Future<String?> getAvailableListingCredit({String? tier}) async {
    if (SupabaseConfig.useMockData) return 'mock-listing-credit';
    var query = _supabase
        .from('owner_listing_credits')
        .select('id, tier')
        .eq('status', 'available');
    if (tier != null) query = query.eq('tier', tier);
    final row = await query
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row?['id'] as String?;
  }

  Future<Map<String, List<String>>> getAvailableListingCreditsByTier() async {
    if (SupabaseConfig.useMockData) {
      return {
        'standard': ['mock-standard-credit'],
        'top_7': ['mock-top-7-credit'],
        'top_15': ['mock-top-15-credit'],
      };
    }

    final rows = await _supabase
        .from('owner_listing_credits')
        .select('id, tier')
        .eq('status', 'available')
        .order('created_at');
    final credits = <String, List<String>>{
      'standard': <String>[],
      'top_7': <String>[],
      'top_15': <String>[],
    };

    for (final item in rows) {
      final row = Map<String, dynamic>.from(item);
      final id = row['id'] as String?;
      final tier = row['tier'] as String?;
      if (id != null && tier != null && credits.containsKey(tier)) {
        credits[tier]!.add(id);
      }
    }
    return credits;
  }

  Future<void> track(
    String name, {
    String? entityType,
    String? entityId,
    Map<String, dynamic> properties = const {},
  }) async {
    if (SupabaseConfig.useMockData) return;
    await _supabase.rpc(
      'track_platform_event',
      params: {
        'target_event_name': name,
        'target_entity_type': entityType,
        'target_entity_id': entityId,
        'target_properties': properties,
      },
    );
  }

  Future<Map<String, dynamic>> verifyPurchase({
    required String productId,
    required String verificationData,
    required String source,
    required String transactionDate,
  }) async {
    final response = await _supabase.functions.invoke(
      'verify-store-purchase',
      body: {
        'product_id': productId,
        'verification_data': verificationData,
        'source': source,
        'transaction_date': transactionDate,
      },
    );
    if (response.status < 200 || response.status >= 300) {
      throw StateError('PURCHASE_VERIFICATION_FAILED');
    }
    return Map<String, dynamic>.from(response.data as Map);
  }
}
