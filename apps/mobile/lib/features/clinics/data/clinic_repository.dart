import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../shared/data/mock_data.dart';
import '../../../shared/utils/iterable_extensions.dart';
import '../models/clinic.dart';
import '../models/doctor.dart';
import '../models/service.dart';

class ClinicRepository {
  bool get _useMockData => SupabaseConfig.useMockData;
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Clinic>> getPublishedClinics({String? query}) async {
    if (_useMockData) {
      final normalized = query?.trim().toLowerCase() ?? '';
      return MockData.clinics.where((clinic) {
        final matchesQuery = normalized.isEmpty ||
            clinic.name.toLowerCase().contains(normalized) ||
            clinic.city.toLowerCase().contains(normalized) ||
            clinic.address.toLowerCase().contains(normalized);

        return clinic.isPublished && matchesQuery;
      }).toList();
    }

    final rows = await _client.from('clinics').select('*').eq('status', 'published').eq('published', true).order('name', ascending: true);
    final clinics = (rows as List<dynamic>).whereType<Map<String, dynamic>>().map(Clinic.fromJson).toList();
    final normalized = query?.trim().toLowerCase() ?? '';

    if (normalized.isEmpty) {
      return clinics;
    }

    return clinics.where((clinic) {
      return clinic.name.toLowerCase().contains(normalized) ||
          clinic.city.toLowerCase().contains(normalized) ||
          clinic.address.toLowerCase().contains(normalized);
    }).toList();
  }

  Future<Clinic?> getClinic(String id) async {
    if (_useMockData) {
      return MockData.clinics.where((clinic) => clinic.id == id).firstOrNull;
    }

    final row = await _client.from('clinics').select('*').eq('id', id).maybeSingle();
    return row == null ? null : Clinic.fromJson(row);
  }

  Future<bool> canClinicAcceptOnlineBooking(String clinicId) async {
    if (_useMockData) {
      return MockData.clinics.where((clinic) => clinic.id == clinicId).firstOrNull?.canAcceptOnlineBooking ?? false;
    }

    try {
      final result = await _client.rpc('can_clinic_create_appointment', params: {'target_clinic_id': clinicId});
      return result == true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Doctor>> getClinicDoctors(String clinicId) async {
    if (_useMockData) {
      return MockData.doctors.where((doctor) => doctor.clinicId == clinicId && doctor.isBookable).toList();
    }

    final rows = await _client
        .from('doctors')
        .select('*, clinics(name)')
        .eq('clinic_id', clinicId)
        .eq('status', 'active')
        .eq('is_public', true)
        .order('full_name', ascending: true);

    return (rows as List<dynamic>).whereType<Map<String, dynamic>>().map(Doctor.fromJson).toList();
  }

  Future<Doctor?> getDoctor(String id) async {
    if (_useMockData) {
      return MockData.doctors.where((doctor) => doctor.id == id && doctor.isBookable).firstOrNull;
    }

    final row = await _client.from('doctors').select('*, clinics(name)').eq('id', id).eq('status', 'active').eq('is_public', true).maybeSingle();
    return row == null ? null : Doctor.fromJson(row);
  }

  Future<List<ClinicService>> getClinicServices(String clinicId) async {
    if (_useMockData) {
      return MockData.services.where((service) => service.clinicId == clinicId && service.isBookable).toList();
    }

    final rows = await _client
        .from('services')
        .select('*')
        .eq('clinic_id', clinicId)
        .eq('status', 'active')
        .eq('is_public', true)
        .order('name', ascending: true);

    return (rows as List<dynamic>).whereType<Map<String, dynamic>>().map(ClinicService.fromJson).toList();
  }
}
