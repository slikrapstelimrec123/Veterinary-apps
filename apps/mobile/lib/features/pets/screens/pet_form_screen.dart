import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/supabase_config.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/services/private_pet_storage.dart';
import '../data/pet_repository.dart';
import '../domain/pet.dart';
import '../widgets/breed_autocomplete_field.dart';

class PetFormScreen extends StatefulWidget {
  const PetFormScreen({super.key, this.pet});

  final Pet? pet;

  @override
  State<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends State<PetFormScreen> {
  final repository = PetRepository();
  final nameController = TextEditingController();
  final breedController = TextEditingController();
  final weightController = TextEditingController();
  final colorController = TextEditingController();
  final microchipController = TextEditingController();
  final notesController = TextEditingController();

  String species = 'dog';
  String sex = 'unknown';
  bool isNeutered = false;
  DateTime? birthDate;
  File? avatarFile;
  String? existingAvatarUrl;
  String? existingAvatarStoragePath;
  String? error;
  bool isSaving = false;

  static const speciesOptions = [
    'dog',
    'cat',
    'rabbit',
    'bird',
    'rodent',
    'reptile',
    'other'
  ];
  static const sexOptions = ['male', 'female', 'unknown'];

  List<String> get _breedsForSpecies {
    return breedsForSpecies(species);
  }

  String speciesLabel(String value) => switch (value) {
        'dog' => 'Собака',
        'cat' => 'Кіт',
        'rabbit' => 'Кролик',
        'bird' => 'Птах',
        'rodent' => 'Гризун',
        'reptile' => 'Рептилія',
        'other' => 'Інше',
        _ => value,
      };

  String sexLabel(String value) => switch (value) {
        'male' => 'Самець',
        'female' => 'Самка',
        'unknown' => 'Не вказано',
        _ => value,
      };

  @override
  void initState() {
    super.initState();
    final pet = widget.pet;
    if (pet != null) {
      nameController.text = pet.name;
      species = pet.species.isEmpty ? 'dog' : pet.species;
      breedController.text = pet.breed ?? '';
      sex = pet.sex ?? 'unknown';
      isNeutered = pet.isNeutered ?? false;
      birthDate = pet.birthDate;
      existingAvatarUrl = pet.avatarUrl;
      existingAvatarStoragePath = pet.avatarStoragePath;
      weightController.text = pet.weightKg?.toString() ?? '';
      colorController.text = pet.color ?? '';
      microchipController.text = pet.microchipNumber ?? '';
      notesController.text = pet.notes ?? '';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    breedController.dispose();
    weightController.dispose();
    colorController.dispose();
    microchipController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: birthDate ?? DateTime(DateTime.now().year - 1),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Дата народження',
      cancelText: 'Скасувати',
      confirmText: 'Обрати',
      locale: const Locale('uk'),
    );
    if (picked != null) {
      setState(() => birthDate = picked);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Зробити фото'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Вибрати з галереї'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) setState(() => avatarFile = File(picked.path));
  }

  Future<String?> _uploadAvatar(String petId) async {
    if (avatarFile == null) return existingAvatarStoragePath;
    if (SupabaseConfig.useMockData) return null;
    return PrivatePetStorage.uploadImage(
      petId: petId,
      category: 'avatar',
      file: avatarFile!,
      upsert: true,
    );
  }

  Future<void> save() async {
    final name = nameController.text.trim();
    final breedText = breedController.text.replaceAll('\u200B', '').trim();
    final weightText = weightController.text.trim();
    final parsedWeight = weightText.isEmpty
        ? null
        : double.tryParse(weightText.replaceAll(',', '.'));

    if (name.isEmpty) {
      setState(() => error = "Вкажіть ім'я тварини.");
      return;
    }

    if (species.isEmpty) {
      setState(() => error = 'Оберіть вид тварини.');
      return;
    }

    if (weightText.isNotEmpty && (parsedWeight == null || parsedWeight <= 0)) {
      setState(() => error = 'Вага має бути додатним числом.');
      return;
    }

    setState(() {
      error = null;
      isSaving = true;
    });

    try {
      final pet = Pet(
        id: widget.pet?.id ?? '',
        name: name,
        species: species,
        breed: breedText.isEmpty
            ? null
            : breedText,
        sex: sex,
        isNeutered: isNeutered,
        birthDate: birthDate,
        weightKg: parsedWeight,
        color: colorController.text.trim().isEmpty
            ? null
            : colorController.text.trim(),
        microchipNumber: microchipController.text.trim().isEmpty
            ? null
            : microchipController.text.trim(),
        avatarUrl: widget.pet?.avatarStoragePath == null
            ? widget.pet?.avatarUrl
            : null,
        avatarStoragePath: existingAvatarStoragePath,
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
        emergencyAllergies: widget.pet?.emergencyAllergies,
        emergencyConditions: widget.pet?.emergencyConditions,
        emergencySurgeries: widget.pet?.emergencySurgeries,
        emergencyContraindications: widget.pet?.emergencyContraindications,
        emergencyBehaviorNotes: widget.pet?.emergencyBehaviorNotes,
        emergencyBloodType: widget.pet?.emergencyBloodType,
        emergencyNotes: widget.pet?.emergencyNotes,
        passportPhotoUrl: widget.pet?.passportStoragePath == null
            ? widget.pet?.passportPhotoUrl
            : null,
        passportStoragePath: widget.pet?.passportStoragePath,
      );

      Pet saved;
      if (widget.pet == null) {
        saved = await repository.createPet(pet);
        if (avatarFile != null && !SupabaseConfig.useMockData) {
          final avatarPath = await _uploadAvatar(saved.id);
          saved = await repository.updatePet(
            saved.copyWith(avatarStoragePath: avatarPath),
          );
        }
      } else {
        final avatarPath = await _uploadAvatar(widget.pet!.id);
        saved = await repository.updatePet(
          pet.copyWith(avatarStoragePath: avatarPath),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (saveError) {
      final planLimitReached =
          saveError.toString().contains('PET_PLAN_LIMIT_REACHED');
      setState(
        () => error = planLimitReached
            ? 'Досягнуто ліміт тварин вашого тарифу. '
                'Змініть тариф у налаштуваннях, щоб додати ще одну.'
            : 'Не вдалося зберегти тварину. '
                'Перевірте дані та спробуйте ще раз.',
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final breeds = _breedsForSpecies;

    return AppScaffold(
      title: widget.pet == null ? 'Додати тварину' : 'Редагувати тварину',
      subtitle: 'Деталі можна додати або змінити пізніше.',
      children: [
        if (error != null) ...[
          Text(error!, style: const TextStyle(color: Color(0xFF9F1239))),
          const SizedBox(height: 12),
        ],

        // Name
        TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Ім'я тварини *"),
        ),
        const SizedBox(height: 12),

        // Species
        DropdownButtonFormField<String>(
          initialValue: species,
          decoration: const InputDecoration(labelText: 'Вид *'),
          items: speciesOptions
              .map((v) =>
                  DropdownMenuItem(value: v, child: Text(speciesLabel(v))))
              .toList(),
          onChanged: (v) => setState(() {
            species = v ?? 'dog';
            breedController.clear();
          }),
        ),
        const SizedBox(height: 12),

        // Breed — searchable dropdown for dogs/cats, plain text otherwise
        if (breeds.isNotEmpty)
          BreedAutocompleteField(
            key: ValueKey('$species-${breeds.length}'),
            controller: breedController,
            species: species,
          )
        else
          TextField(
            controller: breedController,
            decoration: const InputDecoration(labelText: 'Порода'),
          ),
        const SizedBox(height: 12),

        // Sex
        DropdownButtonFormField<String>(
          initialValue: sex,
          decoration: const InputDecoration(labelText: 'Стать'),
          items: sexOptions
              .map((v) => DropdownMenuItem(value: v, child: Text(sexLabel(v))))
              .toList(),
          onChanged: (v) => setState(() => sex = v ?? 'unknown'),
        ),
        const SizedBox(height: 4),

        // Neutered
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Стерилізовано'),
          value: isNeutered,
          onChanged: (v) => setState(() => isNeutered = v),
        ),
        const SizedBox(height: 4),

        // Birth date — tap to open date picker
        GestureDetector(
          onTap: pickDate,
          child: AbsorbPointer(
            child: TextField(
              controller: TextEditingController(
                text: birthDate == null
                    ? ''
                    : '${birthDate!.day.toString().padLeft(2, '0')}.${birthDate!.month.toString().padLeft(2, '0')}.${birthDate!.year}',
              ),
              decoration: const InputDecoration(
                labelText: 'Дата народження',
                hintText: 'Натисніть, щоб обрати дату',
                suffixIcon: Icon(Icons.calendar_today_outlined),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Weight
        TextField(
          controller: weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Вага, кг'),
        ),
        const SizedBox(height: 12),

        // Color
        TextField(
          controller: colorController,
          decoration: const InputDecoration(labelText: 'Колір'),
        ),
        const SizedBox(height: 12),

        // Microchip
        TextField(
          controller: microchipController,
          decoration: const InputDecoration(labelText: 'Номер мікрочипа'),
        ),
        const SizedBox(height: 12),

        // Photo
        if (avatarFile != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(avatarFile!,
                height: 160, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickAvatar,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Змінити фото'),
          ),
        ] else if (existingAvatarUrl != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(existingAvatarUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickAvatar,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Змінити фото'),
          ),
        ] else
          OutlinedButton.icon(
            onPressed: _pickAvatar,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Додати фото тварини'),
          ),
        const SizedBox(height: 12),

        // Notes
        TextField(
          controller: notesController,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'Нотатки'),
        ),
        const SizedBox(height: 20),

        FilledButton(
          onPressed: isSaving ? null : save,
          child: Text(isSaving ? 'Збереження...' : 'Зберегти тварину'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Скасувати'),
        ),
        if (widget.pet != null) ...[
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: isSaving ? null : _confirmDelete,
            icon: const Icon(Icons.delete_outline, color: Color(0xFFE35D6A)),
            label: const Text('Видалити картку тварини',
                style: TextStyle(color: Color(0xFFE35D6A))),
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE35D6A))),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Future<void> _confirmDelete() async {
    final step1 = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Видалити тварину?'),
        content: const Text(
          'Ви збираєтесь видалити картку "".\n\n'
          'Вся інформація буде безповоротно видалена:\n'
          '\u2022 Профіль тварини\n\u2022 Записи про прийоми\n\u2022 Препарати та ліки\n'
          '\u2022 Медичні документи\n\u2022 Досягнення\n\n'
          'Для підтвердження на вашу електронну пошту буде надіслано лист.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Скасувати')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Надіслати підтвердження',
                style: TextStyle(color: Color(0xFFE35D6A))),
          ),
        ],
      ),
    );
    if (step1 != true || !mounted) return;

    final step2 = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Підтвердіть видалення'),
        content: const Text(
          'На вашу електронну пошту надіслано лист з підтвердженням.\n\n'
          'Натисніть "Видалити" лише якщо ви підтвердили дію в листі.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Скасувати')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Видалити',
                style: TextStyle(color: Color(0xFFE35D6A))),
          ),
        ],
      ),
    );
    if (step2 != true || !mounted) return;

    setState(() => isSaving = true);
    try {
      await repository.deletePet(widget.pet!.id);
      if (!mounted) return;
      Navigator.of(context).pop('deleted');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isSaving = false;
        error = 'Не вдалося видалити тварину.';
      });
    }
  }
}
