import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/city_autocomplete_field.dart';
import '../../../features/pets/domain/pet.dart';
import '../data/announcement_repository.dart';
import '../domain/breeding_announcement.dart';

class AddBreedingAnnouncementScreen extends StatefulWidget {
  const AddBreedingAnnouncementScreen({super.key, required this.pet});
  final Pet pet;

  @override
  State<AddBreedingAnnouncementScreen> createState() =>
      _AddBreedingAnnouncementScreenState();
}

class _AddBreedingAnnouncementScreenState
    extends State<AddBreedingAnnouncementScreen> {
  final _repo = AnnouncementRepository();
  final _formKey = GlobalKey<FormState>();

  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _notesController = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _ownerNameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _conditionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final age = widget.pet.birthDate != null
        ? (DateTime.now().difference(widget.pet.birthDate!).inDays / 365)
            .floor()
        : 1;

    final announcement = BreedingAnnouncement(
      id: 'user_br_${DateTime.now().millisecondsSinceEpoch}',
      ownerName: _ownerNameController.text.trim(),
      phone: _phoneController.text.trim(),
      breed: widget.pet.breed ?? widget.pet.speciesLabel,
      myDogName: widget.pet.name,
      myDogGender: widget.pet.sex ?? 'unknown',
      myDogAge: age.clamp(0, 30),
      myDogPhotoUrl: widget.pet.avatarUrl,
      conditions: _conditionsController.text.trim().isEmpty
          ? null
          : _conditionsController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      createdAt: DateTime.now(),
      ownerId: 'mock_pet_owner',
    );

    _repo.addBreedingAnnouncement(announcement);
    setState(() => _saving = false);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Подати на вязку',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.pets,
                          color: AppTheme.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.pet.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 15)),
                        Text(
                          '${widget.pet.speciesLabel}${widget.pet.breed != null ? ' · ${widget.pet.breed}' : ''}',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Контактна інформація',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _ownerNameController,
              decoration: const InputDecoration(
                  labelText: "Ваше ім'я *",
                  prefixIcon: Icon(Icons.person_outline)),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "Введіть ім'я" : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                  labelText: 'Телефон *',
                  prefixIcon: Icon(Icons.phone_outlined)),
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Введіть номер телефону'
                  : null,
            ),
            const SizedBox(height: 16),
            Text('Умови вязки',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _conditionsController,
              decoration: const InputDecoration(
                labelText: 'Умови',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Text('Додатково',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            CityAutocompleteField(controller: _locationController),
            const SizedBox(height: 10),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Опис',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check),
              label: const Text('Опублікувати оголошення'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
