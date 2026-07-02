import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../features/pets/domain/pet.dart';
import '../../../features/pets/data/pet_repository.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../core/theme/app_theme.dart';

class PetPassportScreen extends StatefulWidget {
  const PetPassportScreen({super.key, required this.petId, required this.petName});

  final String petId;
  final String petName;

  @override
  State<PetPassportScreen> createState() => _PetPassportScreenState();
}

class _PetPassportScreenState extends State<PetPassportScreen> {
  final _repository = PetRepository();
  late Future<Pet?> _petFuture = _repository.getPet(widget.petId);

  void _refresh() => setState(() => _petFuture = _repository.getPet(widget.petId));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Pet?>(
      future: _petFuture,
      builder: (context, snapshot) {
        final pet = snapshot.data;
        return AppScaffold(
          title: 'Цифровий паспорт',
          subtitle: widget.petName,
          children: [
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              ErrorState(message: 'Не вдалося завантажити паспорт.', onRetry: _refresh)
            else if (pet == null)
              const EmptyState(title: 'Тварину не знайдено', message: 'Профіль тварини недоступний.', icon: Icons.search_off_outlined)
            else
              _PassportContent(pet: pet),
          ],
        );
      },
    );
  }
}

class _PassportContent extends StatelessWidget {
  const _PassportContent({required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PassportCard(pet: pet),
        const SizedBox(height: 16),
        _QrSection(pet: pet),
        const SizedBox(height: 16),
        _InfoSection(pet: pet),
      ],
    );
  }
}

class _PassportCard extends StatelessWidget {
  const _PassportCard({required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primary.withOpacity(0.12),
                  child: Text(
                    pet.name.isNotEmpty ? pet.name[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.primary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pet.name, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text('${pet.speciesLabel} · ${pet.breed ?? 'Породу не вказано'}'),
                      Text(pet.ageLabel, style: const TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            if (pet.microchipNumber != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.memory_outlined, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text('Мікрочип: ', style: const TextStyle(color: AppTheme.textSecondary)),
                  Text(pet.microchipNumber!, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QrSection extends StatelessWidget {
  const _QrSection({required this.pet});
  final Pet pet;

  String _buildQrData() {
    final parts = [
      'Lappo Pet Passport',
      'Name: ${pet.name}',
      'Species: ${pet.speciesLabel}',
      if (pet.breed != null) 'Breed: ${pet.breed}',
      'Sex: ${pet.sexLabel}',
      if (pet.microchipNumber != null) 'Microchip: ${pet.microchipNumber}',
      if (pet.weightKg != null) 'Weight: ${pet.weightKg} kg',
      'ID: ${pet.id}',
    ];
    return parts.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('QR-код паспорта', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            QrImageView(
              data: _buildQrData(),
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 12),
            const Text(
              'Відскануйте QR-код для перегляду даних тварини',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final rows = <_InfoRow>[
      _InfoRow('Стать', pet.sexLabel),
      if (pet.birthDate != null) _InfoRow('Дата народження', _formatDate(pet.birthDate!)),
      if (pet.weightKg != null) _InfoRow('Вага', '${pet.weightKg} кг'),
      if (pet.color != null) _InfoRow('Колір', pet.color!),
      if (pet.notes != null && pet.notes!.isNotEmpty) _InfoRow('Нотатки', pet.notes!),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Дані паспорта', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...rows.map((r) => _InfoTile(label: r.label, value: r.value)),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

class _InfoRow {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
