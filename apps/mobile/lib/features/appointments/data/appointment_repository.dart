import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../shared/data/mock_data.dart';
import '../../../shared/utils/iterable_extensions.dart';
import '../models/appointment.dart';
import '../models/doctor_schedule.dart';

class AppointmentRepository {
  bool get _useMockData => SupabaseConfig.useMockData;
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Appointment>> getOwnAppointments() async {
    if (_useMockData) {
      final rows = [...MockData.appointments];
      rows.sort((left, right) => left.startsAt.compareTo(right.startsAt));
      return rows;
    }

    final rows = await _client
        .from('appointments')
        .select('*, pets(name), clinics(name), services(name), doctors(full_name)')
        .eq('owner_id', _client.auth.currentUser!.id)
        .order('appointment_date', ascending: true)
        .order('start_time', ascending: true);

    return (rows as List<dynamic>).whereType<Map<String, dynamic>>().map(Appointment.fromJson).toList();
  }

  Future<Appointment?> getAppointment(String id) async {
    if (_useMockData) {
      return MockData.appointments.where((appointment) => appointment.id == id).firstOrNull;
    }

    final row = await _client
        .from('appointments')
        .select('*, pets(name), clinics(name), services(name), doctors(full_name)')
        .eq('id', id)
        .maybeSingle();

    return row == null ? null : Appointment.fromJson(row);
  }

  Future<List<DoctorSchedule>> getDoctorSchedules(String clinicId) async {
    if (_useMockData) {
      return MockData.doctorSchedules.where((schedule) => schedule.clinicId == clinicId && schedule.isActive).toList();
    }

    final rows = await _client.from('doctor_schedules').select('*').eq('clinic_id', clinicId).eq('is_active', true);
    return (rows as List<dynamic>).whereType<Map<String, dynamic>>().map(DoctorSchedule.fromJson).toList();
  }

  Future<List<Appointment>> getClinicAppointments(String clinicId) async {
    if (_useMockData) {
      return MockData.appointments.where((appointment) => appointment.clinicId == clinicId).toList();
    }

    final rows = await _client
        .from('appointments')
        .select('*, pets(name), clinics(name), services(name), doctors(full_name)')
        .eq('clinic_id', clinicId);

    return (rows as List<dynamic>).whereType<Map<String, dynamic>>().map(Appointment.fromJson).toList();
  }

  Future<Appointment> createAppointment(Appointment draft) async {
    if (_useMockData) {
      final created = draft.copyWith(status: 'pending');
      final appointment = Appointment(
        id: 'mock_appointment_${DateTime.now().millisecondsSinceEpoch}',
        petId: created.petId,
        petName: created.petName,
        clinicId: created.clinicId,
        clinicName: created.clinicName,
        serviceId: created.serviceId,
        serviceName: created.serviceName,
        doctorId: created.doctorId,
        doctorName: created.doctorName,
        appointmentDate: created.appointmentDate,
        startTime: created.startTime,
        endTime: created.endTime,
        status: 'pending',
        ownerNote: created.ownerNote,
      );
      MockData.appointments.add(appointment);
      return appointment;
    }

    final row = await _client
        .from('appointments')
        .insert(draft.toInsertJson(ownerId: _client.auth.currentUser!.id))
        .select('*, pets(name), clinics(name), services(name), doctors(full_name)')
        .single();

    return Appointment.fromJson(row);
  }

  Future<Appointment> cancelOwnerAppointment(Appointment appointment, {String? reason}) async {
    if (_useMockData) {
      final updated = appointment.copyWith(status: 'cancelled_by_owner', cancellationReason: reason);
      final index = MockData.appointments.indexWhere((item) => item.id == appointment.id);
      if (index >= 0) {
        MockData.appointments[index] = updated;
      }
      return updated;
    }

    final row = await _client
        .from('appointments')
        .update({
          'status': 'cancelled_by_owner',
          'cancellation_reason': reason,
          'cancelled_by': _client.auth.currentUser!.id,
          'cancelled_at': DateTime.now().toIso8601String(),
        })
        .eq('id', appointment.id)
        .select('*, pets(name), clinics(name), services(name), doctors(full_name)')
        .single();

    return Appointment.fromJson(row);
  }
}
