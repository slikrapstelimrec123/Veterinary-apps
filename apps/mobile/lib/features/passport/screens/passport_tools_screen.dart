import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../pets/data/pet_repository.dart';
import '../../pets/domain/pet.dart';
import '../data/pet_passport_repository.dart';
import '../domain/pet_passport_models.dart';

class PassportToolsScreen extends StatefulWidget {
  const PassportToolsScreen({super.key, this.petId, this.petName});

  final String? petId;
  final String? petName;

  @override
  State<PassportToolsScreen> createState() => _PassportToolsScreenState();
}

class _PassportToolsScreenState extends State<PassportToolsScreen> {
  final petRepository = PetRepository();
  final passportRepository = PetPassportRepository();
  late Future<_PassportToolsData> dataFuture = loadData();

  Future<_PassportToolsData> loadData() async {
    final pets = <Pet>[];
    if (widget.petId == null) {
      pets.addAll(await petRepository.getPets());
    } else {
      final pet = await petRepository.getPet(widget.petId!);
      if (pet != null) {
        pets.add(pet);
      }
    }
    final selectedPet = pets.isEmpty ? null : pets.first;
    final profile = selectedPet == null ? null : await passportRepository.getPublicProfile(selectedPet.id);
    return _PassportToolsData(pets: pets, selectedPet: selectedPet, profile: profile);
  }

  void refresh() {
    setState(() => dataFuture = loadData());
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'QR / PDF',
      subtitle: 'Публічна мінікартка для нашийника та PDF-зведення медичного паспорта.',
      children: [
        FutureBuilder<_PassportToolsData>(
          future: dataFuture,
          builder: (context, snapshot) {
            final data = snapshot.data;
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ErrorState(message: 'Не вдалося завантажити інструменти паспорта.', onRetry: refresh);
            }
            if (data == null || data.selectedPet == null) {
              return const EmptyState(
                title: 'Додайте тварину',
                message: 'QR та PDF доступні після створення першого цифрового паспорта.',
                icon: Icons.qr_code_2_outlined,
              );
            }

            return _PassportToolsContent(pet: data.selectedPet!, profile: data.profile);
          },
        ),
      ],
    );
  }
}

class _PassportToolsData {
  const _PassportToolsData({required this.pets, required this.selectedPet, required this.profile});

  final List<Pet> pets;
  final Pet? selectedPet;
  final PetPublicProfile? profile;
}

class _PassportToolsContent extends StatelessWidget {
  const _PassportToolsContent({required this.pet, required this.profile});

  final Pet pet;
  final PetPublicProfile? profile;

  @override
  Widget build(BuildContext context) {
    final publicUrl = profile == null ? 'Публічна картка ще не створена' : 'vetcare.app/p/${profile!.publicSlug}';
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.qr_code_2, size: 54),
                const SizedBox(height: 12),
                Text('Публічна картка ${pet.name}', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(publicUrl),
                const SizedBox(height: 8),
                Text(profile?.isEnabled == true ? 'Увімкнено: показуються лише безпечні дані.' : 'Вимкнено або очікує налаштування.'),
                const SizedBox(height: 12),
                OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.copy), label: const Text('Скопіювати посилання')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PDF-зведення паспорта', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('${pet.speciesLabel} · ${pet.breed ?? 'Породу не вказано'}'),
                const SizedBox(height: 8),
                Text('Мікрочип: ${pet.microchipNumber ?? 'Не вказано'}'),
                Text('Алергії: ${pet.allergies ?? 'Не вказано'}'),
                Text('Хронічні стани: ${pet.chronicConditions ?? 'Не вказано'}'),
                const SizedBox(height: 12),
                FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.picture_as_pdf_outlined), label: const Text('Підготувати PDF')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
