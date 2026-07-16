import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/pet_avatar.dart';
import '../../../shared/utils/iterable_extensions.dart';
import '../../clinics/data/clinic_repository.dart';
import '../../clinics/models/clinic.dart';
import '../../clinics/models/doctor.dart';
import '../../clinics/models/service.dart';
import '../../pets/data/pet_repository.dart';
import '../../pets/domain/pet.dart';
import '../data/appointment_repository.dart';
import '../data/appointment_slot_generator.dart';
import '../models/appointment.dart';
import '../models/appointment_slot.dart';
import '../models/doctor_schedule.dart';
import 'appointment_confirmation_screen.dart';

class AppointmentBookingScreen extends StatefulWidget {
  const AppointmentBookingScreen({super.key, this.clinicId, this.doctorId});

  final String? clinicId;
  final String? doctorId;

  @override
  State<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  final clinicRepository = ClinicRepository();
  final appointmentRepository = AppointmentRepository();
  final petRepository = PetRepository();
  final slotGenerator = AppointmentSlotGenerator();
  final noteController = TextEditingController();

  late Future<_BookingData> dataFuture;
  String? selectedClinicId;
  String? selectedPetId;
  String? selectedServiceId;
  String? selectedDoctorId;
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  AppointmentSlot? selectedSlot;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    selectedClinicId = widget.clinicId;
    selectedDoctorId = widget.doctorId;
    dataFuture = _load();
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  Future<_BookingData> _load() async {
    final clinics = await clinicRepository.getPublishedClinics();
    final clinicId =
        selectedClinicId ?? (clinics.isNotEmpty ? clinics.first.id : null);
    selectedClinicId = clinicId;

    final pets = await petRepository.getPets();
    if ((selectedPetId == null ||
            !pets.any((pet) => pet.id == selectedPetId)) &&
        pets.isNotEmpty) {
      selectedPetId = pets.first.id;
    } else if (pets.isEmpty) {
      selectedPetId = null;
    }

    if (clinicId == null) {
      return _BookingData(
          clinics: clinics,
          pets: pets,
          services: const [],
          doctors: const [],
          schedules: const [],
          appointments: const [],
          canAcceptOnlineBooking: false);
    }

    final canAcceptOnlineBooking =
        await clinicRepository.canClinicAcceptOnlineBooking(clinicId);
    if (!canAcceptOnlineBooking) {
      return _BookingData(
        clinics: clinics,
        pets: pets,
        services: const [],
        doctors: const [],
        schedules: const [],
        appointments: const [],
        canAcceptOnlineBooking: false,
      );
    }

    final services = await clinicRepository.getClinicServices(clinicId);
    final doctors = await clinicRepository.getClinicDoctors(clinicId);
    final schedules = await appointmentRepository.getDoctorSchedules(clinicId);
    final appointments =
        await appointmentRepository.getClinicAppointments(clinicId);

    if ((selectedServiceId == null ||
            !services.any((service) => service.id == selectedServiceId)) &&
        services.isNotEmpty) {
      selectedServiceId = services.first.id;
    } else if (services.isEmpty) {
      selectedServiceId = null;
    }
    if ((selectedDoctorId == null ||
            !doctors.any((doctor) => doctor.id == selectedDoctorId)) &&
        doctors.isNotEmpty) {
      selectedDoctorId = doctors.first.id;
    } else if (doctors.isEmpty) {
      selectedDoctorId = null;
    }

    return _BookingData(
      clinics: clinics,
      pets: pets,
      services: services,
      doctors: doctors,
      schedules: schedules,
      appointments: appointments,
      canAcceptOnlineBooking: true,
    );
  }

  void reloadForClinic(String? clinicId) {
    setState(() {
      selectedClinicId = clinicId;
      selectedServiceId = null;
      selectedDoctorId = null;
      selectedSlot = null;
      dataFuture = _load();
    });
  }

  Future<void> submit(_BookingData data) async {
    final clinic =
        data.clinics.where((item) => item.id == selectedClinicId).firstOrNull;
    final pet = data.pets.where((item) => item.id == selectedPetId).firstOrNull;
    final service =
        data.services.where((item) => item.id == selectedServiceId).firstOrNull;
    final doctor =
        data.doctors.where((item) => item.id == selectedDoctorId).firstOrNull;
    final slot = selectedSlot;

    if (!data.canAcceptOnlineBooking) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ця клініка тимчасово недоступна для онлайн-запису.')));
      return;
    }

    if (clinic == null ||
        pet == null ||
        service == null ||
        doctor == null ||
        slot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Оберіть тварину, клініку, послугу, лікаря, дату й час.')));
      return;
    }

    setState(() => isSubmitting = true);
    try {
      final created = await appointmentRepository.createAppointment(
        Appointment(
          id: 'draft',
          petId: pet.id,
          petName: pet.name,
          clinicId: clinic.id,
          clinicName: clinic.name,
          serviceId: service.id,
          serviceName: service.name,
          doctorId: doctor.id,
          doctorName: doctor.fullName,
          appointmentDate: selectedDate,
          startTime: slot.startTime,
          endTime: slot.endTime,
          status: 'pending',
          ownerNote: noteController.text.trim().isEmpty
              ? null
              : noteController.text.trim(),
        ),
      );

      if (!mounted) {
        return;
      }

      await Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => AppointmentConfirmationScreen(appointment: created)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Не вдалося створити запис. Спробуйте ще раз.')));
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BookingData>(
      future: dataFuture,
      builder: (context, snapshot) {
        final data = snapshot.data;

        return AppScaffold(
          title: 'Записатися на прийом',
          subtitle: 'Оберіть тварину, клініку, лікаря та вільний час.',
          children: [
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              ErrorState(
                  message: 'Не вдалося завантажити варіанти запису.',
                  onRetry: () => setState(() => dataFuture = _load()))
            else if (data == null || data.clinics.isEmpty)
              const EmptyState(
                  title: 'Немає доступних клінік',
                  message: 'Опубліковані клініки з’являться тут.',
                  icon: Icons.local_hospital_outlined)
            else
              _BookingForm(
                data: data,
                selectedClinicId: selectedClinicId,
                selectedPetId: selectedPetId,
                selectedServiceId: selectedServiceId,
                selectedDoctorId: selectedDoctorId,
                selectedDate: selectedDate,
                selectedSlot: selectedSlot,
                noteController: noteController,
                isSubmitting: isSubmitting,
                onClinicChanged: reloadForClinic,
                onPetChanged: (value) => setState(() => selectedPetId = value),
                onServiceChanged: (value) => setState(() {
                  selectedServiceId = value;
                  selectedSlot = null;
                }),
                onDoctorChanged: (value) => setState(() {
                  selectedDoctorId = value;
                  selectedSlot = null;
                }),
                onDateChanged: (value) => setState(() {
                  selectedDate = value;
                  selectedSlot = null;
                }),
                onSlotChanged: (value) => setState(() => selectedSlot = value),
                onSubmit: () => submit(data),
              ),
          ],
        );
      },
    );
  }
}

class _BookingForm extends StatelessWidget {
  const _BookingForm({
    required this.data,
    required this.selectedClinicId,
    required this.selectedPetId,
    required this.selectedServiceId,
    required this.selectedDoctorId,
    required this.selectedDate,
    required this.selectedSlot,
    required this.noteController,
    required this.isSubmitting,
    required this.onClinicChanged,
    required this.onPetChanged,
    required this.onServiceChanged,
    required this.onDoctorChanged,
    required this.onDateChanged,
    required this.onSlotChanged,
    required this.onSubmit,
  });

  final _BookingData data;
  final String? selectedClinicId;
  final String? selectedPetId;
  final String? selectedServiceId;
  final String? selectedDoctorId;
  final DateTime selectedDate;
  final AppointmentSlot? selectedSlot;
  final TextEditingController noteController;
  final bool isSubmitting;
  final ValueChanged<String?> onClinicChanged;
  final ValueChanged<String?> onPetChanged;
  final ValueChanged<String?> onServiceChanged;
  final ValueChanged<String?> onDoctorChanged;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<AppointmentSlot> onSlotChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final service =
        data.services.where((item) => item.id == selectedServiceId).firstOrNull;
    final generator = AppointmentSlotGenerator();
    final slots = selectedDoctorId == null || service == null
        ? <AppointmentSlot>[]
        : generator.generate(
            date: selectedDate,
            doctorId: selectedDoctorId!,
            serviceDurationMinutes: service.durationMinutes,
            schedules: data.schedules,
            appointments: data.appointments,
          );
    final dates = List.generate(
        14, (index) => DateTime.now().add(Duration(days: index + 1)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: selectedClinicId,
          decoration: const InputDecoration(labelText: 'Клініка'),
          items: data.clinics
              .map((clinic) =>
                  DropdownMenuItem(value: clinic.id, child: Text(clinic.name)))
              .toList(),
          onChanged: onClinicChanged,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: selectedPetId,
          decoration: const InputDecoration(labelText: 'Тварина'),
          items: data.pets
              .map((pet) => DropdownMenuItem(
                    value: pet.id,
                    child: Row(
                      children: [
                        PetAvatar(
                            name: pet.name, avatarUrl: pet.avatarUrl, size: 32),
                        const SizedBox(width: 10),
                        Text(pet.name),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: onPetChanged,
        ),
        if (!data.canAcceptOnlineBooking) ...[
          const SizedBox(height: 16),
          const EmptyState(
            title: 'Онлайн-запис недоступний',
            message: 'Ця клініка тимчасово недоступна для онлайн-запису.',
            icon: Icons.event_busy_outlined,
          ),
          const SizedBox(height: 16),
          const FilledButton(onPressed: null, child: Text('Підтвердити запис')),
        ] else ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: selectedServiceId,
            decoration: const InputDecoration(labelText: 'Послуга'),
            items: data.services
                .map((service) => DropdownMenuItem(
                    value: service.id,
                    child: Text(
                        '${service.name} - ${service.durationMinutes} хв')))
                .toList(),
            onChanged: onServiceChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: selectedDoctorId,
            decoration: const InputDecoration(labelText: 'Лікар'),
            items: data.doctors
                .map((doctor) => DropdownMenuItem(
                    value: doctor.id, child: Text(doctor.fullName)))
                .toList(),
            onChanged: onDoctorChanged,
          ),
          const SizedBox(height: 18),
          Text('Дата', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: dates.map((date) {
                final selected = _sameDay(date, selectedDate);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                      label: Text('${date.day}.${date.month}'),
                      selected: selected,
                      onSelected: (_) => onDateChanged(date)),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),
          Text('Час', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (slots.isEmpty)
            const EmptyState(
                title: 'Немає вільного часу',
                message: 'Оберіть іншу дату, лікаря або послугу.',
                icon: Icons.schedule_outlined)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: slots.map((slot) {
                final selected = selectedSlot?.doctorId == slot.doctorId &&
                    selectedSlot?.startTime == slot.startTime &&
                    _sameDay(selectedSlot!.date, slot.date);
                return ChoiceChip(
                    label: Text(slot.label),
                    selected: selected,
                    onSelected: (_) => onSlotChanged(slot));
              }).toList(),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: noteController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
                labelText: 'Нотатка для клініки',
                hintText: 'Причина візиту, симптоми або побажання щодо огляду'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: isSubmitting ? null : onSubmit,
            child: Text(isSubmitting ? 'Створення...' : 'Підтвердити запис'),
          ),
        ],
      ],
    );
  }

  bool _sameDay(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

class _BookingData {
  const _BookingData({
    required this.clinics,
    required this.pets,
    required this.services,
    required this.doctors,
    required this.schedules,
    required this.appointments,
    required this.canAcceptOnlineBooking,
  });

  final List<Clinic> clinics;
  final List<Pet> pets;
  final List<ClinicService> services;
  final List<Doctor> doctors;
  final List<DoctorSchedule> schedules;
  final List<Appointment> appointments;
  final bool canAcceptOnlineBooking;
}
