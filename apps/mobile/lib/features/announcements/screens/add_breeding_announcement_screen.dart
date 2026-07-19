import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/pet_avatar.dart';
import '../../../shared/widgets/city_autocomplete_field.dart';
import '../../../shared/services/private_pet_storage.dart';
import '../../../features/pets/domain/pet.dart';
import '../data/announcement_repository.dart';
import '../domain/breeding_announcement.dart';

class AddBreedingAnnouncementScreen extends StatefulWidget {
  const AddBreedingAnnouncementScreen({
    super.key,
    required this.pet,
    this.listingCreditId,
  });
  final Pet pet;
  final String? listingCreditId;

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
  final _imagePicker = ImagePicker();
  XFile? _selectedPhoto;

  @override
  void dispose() {
    _ownerNameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _conditionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final age = widget.pet.birthDate != null
        ? (DateTime.now().difference(widget.pet.birthDate!).inDays / 365)
            .floor()
        : 1;

    String? photoStoragePath = widget.pet.avatarStoragePath;
    String? photoUrl = widget.pet.avatarUrl;
    try {
      if (_selectedPhoto != null) {
        photoStoragePath = await PrivatePetStorage.uploadImage(
          petId: widget.pet.id,
          category: 'announcements',
          file: File(_selectedPhoto!.path),
        );
        photoUrl = await PrivatePetStorage.signedUrl(photoStoragePath);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Не вдалося завантажити фото. Спробуйте ще раз.'),
      ));
      return;
    }

    final announcement = BreedingAnnouncement(
      id: 'user_br_${DateTime.now().millisecondsSinceEpoch}',
      ownerName: _ownerNameController.text.trim(),
      phone: _phoneController.text.trim(),
      breed: widget.pet.breed ?? widget.pet.speciesLabel,
      myDogName: widget.pet.name,
      myDogGender: widget.pet.sex ?? 'unknown',
      myDogAge: age.clamp(0, 30),
      myDogPhotoUrl: photoUrl,
      photoStoragePath: photoStoragePath,
      petAvatarUrl: widget.pet.avatarUrl,
      petAvatarStoragePath: widget.pet.avatarStoragePath,
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
      ownerId: _repo.currentUserId,
      petId: widget.pet.id,
      listingCreditId: widget.listingCreditId,
    );

    try {
      await _repo.addBreedingAnnouncement(announcement);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Не вдалося опублікувати оголошення. Спробуйте ще раз.')),
      );
    }
  }

  Future<void> _pickPhoto() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 78,
      maxWidth: 1400,
      maxHeight: 1400,
    );
    if (image != null && mounted) {
      setState(() => _selectedPhoto = image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _selectedPhoto != null
                            ? Image.file(File(_selectedPhoto!.path),
                                fit: BoxFit.cover)
                            : widget.pet.avatarUrl?.isNotEmpty == true
                                ? Image.network(widget.pet.avatarUrl!,
                                    fit: BoxFit.cover)
                                : Center(
                                    child: PetAvatar(
                                      name: widget.pet.name,
                                      avatarUrl: widget.pet.avatarUrl,
                                      size: 96,
                                    ),
                                  ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _pickPhoto,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: Text(_selectedPhoto == null
                          ? 'Обрати квадратне фото'
                          : 'Змінити фото'),
                    ),
                    const SizedBox(height: 10),
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
