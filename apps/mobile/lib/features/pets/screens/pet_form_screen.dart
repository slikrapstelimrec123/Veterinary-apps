import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../data/pet_repository.dart';
import '../domain/pet.dart';

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
  final birthDateController = TextEditingController();
  final weightController = TextEditingController();
  final colorController = TextEditingController();
  final microchipController = TextEditingController();
  final avatarController = TextEditingController();
  final notesController = TextEditingController();
  final allergiesController = TextEditingController();
  final chronicConditionsController = TextEditingController();
  final ownerContactNameController = TextEditingController();
  final ownerContactPhoneController = TextEditingController();
  final ownerContactEmailController = TextEditingController();
  final emergencyContactController = TextEditingController();

  String species = 'dog';
  String sex = 'unknown';
  bool sterilized = false;
  String? error;
  bool isSaving = false;

  static const speciesOptions = ['dog', 'cat', 'rabbit', 'bird', 'rodent', 'reptile', 'other'];
  static const sexOptions = ['male', 'female', 'unknown'];

  String speciesLabel(String value) {
    return switch (value) {
      'dog' => 'Собака',
      'cat' => 'Кіт',
      'rabbit' => 'Кролик',
      'bird' => 'Птах',
      'rodent' => 'Гризун',
      'reptile' => 'Рептилія',
      'other' => 'Інше',
      _ => value,
    };
  }

  String sexLabel(String value) {
    return switch (value) {
      'male' => 'Самець',
      'female' => 'Самка',
      'unknown' => 'Не вказано',
      _ => value,
    };
  }

  @override
  void initState() {
    super.initState();
    final pet = widget.pet;
    if (pet != null) {
      nameController.text = pet.name;
      species = pet.species.isEmpty ? 'dog' : pet.species;
      breedController.text = pet.breed ?? '';
      sex = pet.sex ?? 'unknown';
      birthDateController.text = pet.birthDate?.toIso8601String().split('T').first ?? '';
      weightController.text = pet.weightKg?.toString() ?? '';
      colorController.text = pet.color ?? '';
      microchipController.text = pet.microchipNumber ?? '';
      avatarController.text = pet.avatarUrl ?? '';
      notesController.text = pet.notes ?? '';
      sterilized = pet.sterilized ?? false;
      allergiesController.text = pet.allergies ?? '';
      chronicConditionsController.text = pet.chronicConditions ?? '';
      ownerContactNameController.text = pet.ownerContactName ?? '';
      ownerContactPhoneController.text = pet.ownerContactPhone ?? '';
      ownerContactEmailController.text = pet.ownerContactEmail ?? '';
      emergencyContactController.text = pet.emergencyContact ?? '';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    breedController.dispose();
    birthDateController.dispose();
    weightController.dispose();
    colorController.dispose();
    microchipController.dispose();
    avatarController.dispose();
    notesController.dispose();
    allergiesController.dispose();
    chronicConditionsController.dispose();
    ownerContactNameController.dispose();
    ownerContactPhoneController.dispose();
    ownerContactEmailController.dispose();
    emergencyContactController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final name = nameController.text.trim();
    final birthDateText = birthDateController.text.trim();
    final weightText = weightController.text.trim();
    final parsedBirthDate = birthDateText.isEmpty ? null : DateTime.tryParse(birthDateText);
    final parsedWeight = weightText.isEmpty ? null : double.tryParse(weightText.replaceAll(',', '.'));

    if (name.isEmpty) {
      setState(() => error = 'Вкажіть ім’я тварини.');
      return;
    }

    if (species.isEmpty) {
      setState(() => error = 'Оберіть вид тварини.');
      return;
    }

    if (birthDateText.isNotEmpty && parsedBirthDate == null) {
      setState(() => error = 'Дата народження має бути у форматі РРРР-ММ-ДД.');
      return;
    }

    if (parsedBirthDate != null && parsedBirthDate.isAfter(DateTime.now())) {
      setState(() => error = 'Дата народження не може бути в майбутньому.');
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

    final pet = Pet(
      id: widget.pet?.id ?? '',
      name: name,
      species: species,
      breed: breedController.text.trim().isEmpty ? null : breedController.text.trim(),
      sex: sex,
      birthDate: parsedBirthDate,
      weightKg: parsedWeight,
      color: colorController.text.trim().isEmpty ? null : colorController.text.trim(),
      microchipNumber: microchipController.text.trim().isEmpty ? null : microchipController.text.trim(),
      avatarUrl: avatarController.text.trim().isEmpty ? null : avatarController.text.trim(),
      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
      sterilized: sterilized,
      allergies: allergiesController.text.trim().isEmpty ? null : allergiesController.text.trim(),
      chronicConditions: chronicConditionsController.text.trim().isEmpty ? null : chronicConditionsController.text.trim(),
      ownerContactName: ownerContactNameController.text.trim().isEmpty ? null : ownerContactNameController.text.trim(),
      ownerContactPhone: ownerContactPhoneController.text.trim().isEmpty ? null : ownerContactPhoneController.text.trim(),
      ownerContactEmail: ownerContactEmailController.text.trim().isEmpty ? null : ownerContactEmailController.text.trim(),
      emergencyContact: emergencyContactController.text.trim().isEmpty ? null : emergencyContactController.text.trim(),
    );

    try {
      final saved = widget.pet == null ? await repository.createPet(pet) : await repository.updatePet(pet);
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (_) {
      setState(() => error = 'Не вдалося зберегти тварину. Спробуйте ще раз.');
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.pet == null ? 'Додати тварину' : 'Редагувати тварину',
      subtitle: 'Підтримуйте медичну картку зрозумілою. Деталі можна додати пізніше.',
      children: [
        if (error != null) ...[
          Text(error!, style: const TextStyle(color: Color(0xFF9F1239))),
          const SizedBox(height: 12),
        ],
        TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Ім’я тварини *')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: species,
          decoration: const InputDecoration(labelText: 'Вид *'),
          items: speciesOptions.map((value) => DropdownMenuItem(value: value, child: Text(speciesLabel(value)))).toList(),
          onChanged: (value) => setState(() => species = value ?? 'dog'),
        ),
        const SizedBox(height: 12),
        TextField(controller: breedController, decoration: const InputDecoration(labelText: 'Порода')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: sex,
          decoration: const InputDecoration(labelText: 'Стать'),
          items: sexOptions.map((value) => DropdownMenuItem(value: value, child: Text(sexLabel(value)))).toList(),
          onChanged: (value) => setState(() => sex = value ?? 'unknown'),
        ),
        const SizedBox(height: 12),
        TextField(controller: birthDateController, decoration: const InputDecoration(labelText: 'Дата народження РРРР-ММ-ДД')),
        const SizedBox(height: 12),
        TextField(controller: weightController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Вага, кг')),
        const SizedBox(height: 12),
        TextField(controller: colorController, decoration: const InputDecoration(labelText: 'Колір')),
        const SizedBox(height: 12),
        TextField(controller: microchipController, decoration: const InputDecoration(labelText: 'Номер мікрочипа')),
        const SizedBox(height: 12),
        TextField(controller: avatarController, decoration: const InputDecoration(labelText: 'URL фото (тимчасово)')),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Стерилізовано'),
          value: sterilized,
          onChanged: (value) => setState(() => sterilized = value),
        ),
        const SizedBox(height: 12),
        TextField(controller: allergiesController, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Алергії')),
        const SizedBox(height: 12),
        TextField(controller: chronicConditionsController, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Хронічні стани')),
        const SizedBox(height: 12),
        TextField(controller: ownerContactNameController, decoration: const InputDecoration(labelText: 'Контакт власника для QR')),
        const SizedBox(height: 12),
        TextField(controller: ownerContactPhoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Телефон власника для QR')),
        const SizedBox(height: 12),
        TextField(controller: ownerContactEmailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email власника для QR')),
        const SizedBox(height: 12),
        TextField(controller: emergencyContactController, decoration: const InputDecoration(labelText: 'Екстрений контакт')),
        const SizedBox(height: 12),
        TextField(controller: notesController, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'Нотатки')),
        const SizedBox(height: 20),
        FilledButton(onPressed: isSaving ? null : save, child: Text(isSaving ? 'Збереження...' : 'Зберегти тварину')),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: isSaving ? null : () => Navigator.of(context).pop(), child: const Text('Скасувати')),
      ],
    );
  }
}
