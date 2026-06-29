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

  String species = 'dog';
  String sex = 'unknown';
  String? error;
  bool isSaving = false;

  static const speciesOptions = ['dog', 'cat', 'rabbit', 'bird', 'rodent', 'reptile', 'other'];
  static const sexOptions = ['male', 'female', 'unknown'];

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
    super.dispose();
  }

  Future<void> save() async {
    final name = nameController.text.trim();
    final birthDateText = birthDateController.text.trim();
    final weightText = weightController.text.trim();
    final parsedBirthDate = birthDateText.isEmpty ? null : DateTime.tryParse(birthDateText);
    final parsedWeight = weightText.isEmpty ? null : double.tryParse(weightText.replaceAll(',', '.'));

    if (name.isEmpty) {
      setState(() => error = 'Pet name is required.');
      return;
    }

    if (species.isEmpty) {
      setState(() => error = 'Species is required.');
      return;
    }

    if (birthDateText.isNotEmpty && parsedBirthDate == null) {
      setState(() => error = 'Birth date should use YYYY-MM-DD format.');
      return;
    }

    if (parsedBirthDate != null && parsedBirthDate.isAfter(DateTime.now())) {
      setState(() => error = 'Birth date cannot be in the future.');
      return;
    }

    if (weightText.isNotEmpty && (parsedWeight == null || parsedWeight <= 0)) {
      setState(() => error = 'Weight must be a positive number.');
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
    );

    try {
      final saved = widget.pet == null ? await repository.createPet(pet) : await repository.updatePet(pet);
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (_) {
      setState(() => error = 'Unable to save pet. Please try again.');
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.pet == null ? 'Add pet' : 'Edit pet',
      subtitle: 'Keep the medical card clear. You can add more details later.',
      children: [
        if (error != null) ...[
          Text(error!, style: const TextStyle(color: Color(0xFF9F1239))),
          const SizedBox(height: 12),
        ],
        TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Pet name *')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: species,
          decoration: const InputDecoration(labelText: 'Species *'),
          items: speciesOptions.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
          onChanged: (value) => setState(() => species = value ?? 'dog'),
        ),
        const SizedBox(height: 12),
        TextField(controller: breedController, decoration: const InputDecoration(labelText: 'Breed')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: sex,
          decoration: const InputDecoration(labelText: 'Sex'),
          items: sexOptions.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
          onChanged: (value) => setState(() => sex = value ?? 'unknown'),
        ),
        const SizedBox(height: 12),
        TextField(controller: birthDateController, decoration: const InputDecoration(labelText: 'Birth date YYYY-MM-DD')),
        const SizedBox(height: 12),
        TextField(controller: weightController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Weight kg')),
        const SizedBox(height: 12),
        TextField(controller: colorController, decoration: const InputDecoration(labelText: 'Color')),
        const SizedBox(height: 12),
        TextField(controller: microchipController, decoration: const InputDecoration(labelText: 'Microchip number')),
        const SizedBox(height: 12),
        TextField(controller: avatarController, decoration: const InputDecoration(labelText: 'Avatar URL placeholder')),
        const SizedBox(height: 12),
        TextField(controller: notesController, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'Notes')),
        const SizedBox(height: 20),
        FilledButton(onPressed: isSaving ? null : save, child: Text(isSaving ? 'Saving...' : 'Save pet')),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: isSaving ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
      ],
    );
  }
}

