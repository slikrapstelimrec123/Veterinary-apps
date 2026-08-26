import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/auth/auth_state.dart';
import '../../../core/auth/current_user.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/private_pet_storage.dart';
import '../../../shared/widgets/city_autocomplete_field.dart';
import '../../pets/data/pet_repository.dart';
import '../../pets/domain/pet.dart';
import '../../pets/widgets/breed_autocomplete_field.dart';

enum _OnboardingStep {
  petQuestion,
  profile,
  petBasics,
  petDetails,
}

class OwnerOnboardingScreen extends StatefulWidget {
  const OwnerOnboardingScreen({super.key});

  @override
  State<OwnerOnboardingScreen> createState() => _OwnerOnboardingScreenState();
}

class _OwnerOnboardingScreenState extends State<OwnerOnboardingScreen> {
  final _petRepository = PetRepository();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _petNameController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();
  final _colorController = TextEditingController();
  final _microchipController = TextEditingController();
  final _notesController = TextEditingController();

  _OnboardingStep _step = _OnboardingStep.petQuestion;
  bool _initialized = false;
  bool _loadingPets = true;
  bool _hasExistingPet = false;
  bool _wantsToAddPet = false;
  bool _profileStepCompleted = false;
  bool _missingName = false;
  bool _missingPhone = false;
  bool _missingCity = false;
  bool _saving = false;
  String _species = 'dog';
  String _sex = 'unknown';
  String _neutered = 'unknown';
  DateTime? _birthDate;
  File? _avatarFile;
  Pet? _createdPet;
  String? _error;

  static const _speciesOptions = [
    'dog',
    'cat',
    'rabbit',
    'bird',
    'rodent',
    'reptile',
    'other',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final user = AuthScope.of(context).currentUser!;
    _missingName = !_hasMeaningfulName(user);
    _missingPhone = user.phone?.trim().isEmpty ?? true;
    _missingCity = user.city?.trim().isEmpty ?? true;
    _fullNameController.text =
        _hasMeaningfulName(user) ? user.fullName.trim() : '';
    _phoneController.text = user.phone?.trim() ?? '';
    _cityController.text = user.city?.trim() ?? '';
    _loadPets();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _petNameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _colorController.dispose();
    _microchipController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadPets() async {
    try {
      final pets = await _petRepository.getPets();
      if (!mounted) return;
      setState(() => _hasExistingPet = pets.isNotEmpty);
    } catch (_) {
      // A temporary pet-list error must not block account setup. Pet creation
      // remains protected by the normal repository and database policies.
    } finally {
      if (mounted) setState(() => _loadingPets = false);
    }
  }

  bool _hasMeaningfulName(CurrentUser user) {
    final name = user.fullName.trim();
    final emailPrefix = user.email.split('@').first.toLowerCase();
    return name.length >= 2 &&
        name.toLowerCase() != 'pet owner' &&
        name.toLowerCase() != emailPrefix;
  }

  bool get _needsProfileStep {
    return !_profileStepCompleted &&
        (_missingName || _missingPhone || _missingCity);
  }

  void _answerPetQuestion(bool hasPet) {
    setState(() {
      _wantsToAddPet = hasPet;
      _error = null;
    });

    if (_needsProfileStep) {
      _goTo(_OnboardingStep.profile);
    } else if (hasPet && !_hasExistingPet) {
      _goTo(_OnboardingStep.petBasics);
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _saveProfile() async {
    final name = _fullNameController.text.trim();
    if (name.length < 2) {
      setState(() => _error = "Вкажіть ваше ім'я.");
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AuthScope.of(context).updateProfile(
        fullName: name,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        city: _cityController.text.trim(),
      );
      if (!mounted) return;
      _profileStepCompleted = true;
      if (_wantsToAddPet && !_hasExistingPet) {
        _goTo(_OnboardingStep.petBasics);
      } else {
        await _finishOnboarding();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Не вдалося зберегти профіль. Перевірте з’єднання та спробуйте ще раз.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _continuePetBasics() {
    if (_petNameController.text.trim().isEmpty) {
      setState(() => _error = "Вкажіть ім'я тварини.");
      return;
    }
    setState(() => _error = null);
    _goTo(_OnboardingStep.petDetails);
  }

  Future<void> _savePetAndFinish() async {
    final weightText = _weightController.text.trim();
    final weight = weightText.isEmpty
        ? null
        : double.tryParse(weightText.replaceAll(',', '.'));
    if (weightText.isNotEmpty && (weight == null || weight <= 0)) {
      setState(() => _error = 'Вага має бути додатним числом.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      var saved = _createdPet;
      if (saved == null) {
        saved = await _petRepository.createPet(
          Pet(
            id: '',
            name: _petNameController.text.trim(),
            species: _species,
            breed: _optional(_breedController.text),
            sex: _sex,
            birthDate: _birthDate,
            weightKg: weight,
            color: _optional(_colorController.text),
            microchipNumber: _optional(_microchipController.text),
            notes: _optional(_notesController.text),
            isNeutered: switch (_neutered) {
              'yes' => true,
              'no' => false,
              _ => null,
            },
          ),
        );
        _createdPet = saved;
      }

      if (_avatarFile != null &&
          saved.avatarStoragePath == null &&
          !SupabaseConfig.useMockData) {
        try {
          final path = await PrivatePetStorage.uploadImage(
            petId: saved.id,
            category: 'avatar',
            file: _avatarFile!,
            upsert: true,
          );
          saved = await _petRepository.updatePet(
            saved.copyWith(avatarStoragePath: path),
          );
          _createdPet = saved;
        } catch (_) {
          // The card is already valid. A failed optional photo upload should
          // never duplicate the pet or trap the owner in onboarding.
        }
      }

      await _finishOnboarding();
    } catch (_) {
      if (mounted) {
        setState(() =>
            _error = 'Не вдалося створити картку тварини. Спробуйте ще раз.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _finishOnboarding() async {
    if (!_saving) setState(() => _saving = true);
    try {
      await AuthScope.of(context).completeOnboarding();
    } catch (_) {
      if (mounted) {
        setState(() =>
            _error = 'Не вдалося завершити налаштування. Спробуйте ще раз.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _optional(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  void _goTo(_OnboardingStep step) {
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _step = step;
      _error = null;
    });
  }

  void _back() {
    switch (_step) {
      case _OnboardingStep.petQuestion:
        AuthScope.of(context).logout();
      case _OnboardingStep.profile:
        _goTo(_OnboardingStep.petQuestion);
      case _OnboardingStep.petBasics:
        _goTo(_needsProfileStep
            ? _OnboardingStep.profile
            : _OnboardingStep.petQuestion);
      case _OnboardingStep.petDetails:
        _goTo(_OnboardingStep.petBasics);
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 1),
      firstDate: DateTime(1990),
      lastDate: now,
      locale: const Locale('uk'),
      helpText: 'Дата народження',
      cancelText: 'Скасувати',
      confirmText: 'Обрати',
    );
    if (picked != null && mounted) setState(() => _birthDate = picked);
  }

  Future<void> _pickAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
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
    final image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (image != null && mounted) {
      setState(() => _avatarFile = File(image.path));
    }
  }

  String _speciesLabel(String value) => switch (value) {
        'dog' => 'Собака',
        'cat' => 'Кіт',
        'rabbit' => 'Кролик',
        'bird' => 'Птах',
        'rodent' => 'Гризун',
        'reptile' => 'Рептилія',
        'other' => 'Інше',
        _ => value,
      };

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_saving) _back();
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  _OnboardingHeader(
                    step: _step,
                    onBack: _saving ? null : _back,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: KeyedSubtree(
                          key: ValueKey(_step),
                          child: _buildStep(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    if (_loadingPets && _step == _OnboardingStep.petQuestion) {
      return const Padding(
        padding: EdgeInsets.only(top: 120),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return switch (_step) {
      _OnboardingStep.petQuestion => _PetQuestionStep(
          hasExistingPet: _hasExistingPet,
          saving: _saving,
          error: _error,
          onAnswer: _answerPetQuestion,
        ),
      _OnboardingStep.profile => _ProfileStep(
          fullNameController: _fullNameController,
          phoneController: _phoneController,
          cityController: _cityController,
          showName: _missingName,
          showPhone: _missingPhone,
          showCity: _missingCity,
          saving: _saving,
          error: _error,
          onContinue: _saveProfile,
        ),
      _OnboardingStep.petBasics => _PetBasicsStep(
          nameController: _petNameController,
          breedController: _breedController,
          species: _species,
          sex: _sex,
          error: _error,
          speciesOptions: _speciesOptions,
          speciesLabel: _speciesLabel,
          onSpeciesChanged: (value) => setState(() {
            _species = value;
            _breedController.clear();
          }),
          onSexChanged: (value) => setState(() => _sex = value),
          onContinue: _continuePetBasics,
        ),
      _OnboardingStep.petDetails => _PetDetailsStep(
          birthDate: _birthDate,
          avatarFile: _avatarFile,
          weightController: _weightController,
          colorController: _colorController,
          microchipController: _microchipController,
          notesController: _notesController,
          neutered: _neutered,
          saving: _saving,
          error: _error,
          onPickBirthDate: _pickBirthDate,
          onPickAvatar: _pickAvatar,
          onNeuteredChanged: (value) => setState(() => _neutered = value),
          onSave: _savePetAndFinish,
        ),
    };
  }
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({
    required this.step,
    required this.onBack,
  });

  final _OnboardingStep step;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final progress = switch (step) {
      _OnboardingStep.petQuestion => 0.2,
      _OnboardingStep.profile => 0.4,
      _OnboardingStep.petBasics => 0.65,
      _OnboardingStep.petDetails => 0.9,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 24, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: step == _OnboardingStep.petQuestion ? 'Вийти' : 'Назад',
            icon: Icon(step == _OnboardingStep.petQuestion
                ? Icons.logout
                : Icons.arrow_back_ios_new),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppTheme.border,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Image.asset(
            'assets/lappo_wordmark_transparent.png',
            height: 28,
          ),
        ],
      ),
    );
  }
}

class _PetQuestionStep extends StatelessWidget {
  const _PetQuestionStep({
    required this.hasExistingPet,
    required this.saving,
    required this.error,
    required this.onAnswer,
  });

  final bool hasExistingPet;
  final bool saving;
  final String? error;
  final ValueChanged<bool> onAnswer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        const _PawHeroIcon(icon: Icons.pets),
        const SizedBox(height: 28),
        Text(
          'У вас є домашня тварина?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Text(
          hasExistingPet
              ? 'Ми вже знайшли картку вашої тварини. Допоможемо завершити налаштування профілю.'
              : 'Допоможемо швидко створити медичну картку та зберігати важливе в одному місці.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        if (error != null) ...[
          const SizedBox(height: 20),
          _ErrorText(error!),
        ],
        const SizedBox(height: 36),
        FilledButton.icon(
          onPressed: saving ? null : () => onAnswer(true),
          icon: const Icon(Icons.pets),
          label: const Text('Так, є'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: saving ? null : () => onAnswer(false),
          child: const Text('Поки немає'),
        ),
      ],
    );
  }
}

class _ProfileStep extends StatelessWidget {
  const _ProfileStep({
    required this.fullNameController,
    required this.phoneController,
    required this.cityController,
    required this.showName,
    required this.showPhone,
    required this.showCity,
    required this.saving,
    required this.error,
    required this.onContinue,
  });

  final TextEditingController fullNameController;
  final TextEditingController phoneController;
  final TextEditingController cityController;
  final bool showName;
  final bool showPhone;
  final bool showCity;
  final bool saving;
  final String? error;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Трохи про вас',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Заповніть лише те, чого бракує. Ці дані завжди можна змінити в налаштуваннях.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 24),
        _OnboardingCard(
          child: Column(
            children: [
              if (showName) ...[
                TextField(
                  controller: fullNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: "Ваше ім'я *"),
                ),
                if (showPhone || showCity) const SizedBox(height: 14),
              ],
              if (showPhone) ...[
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Телефон',
                    hintText: 'Необов’язково',
                  ),
                ),
                if (showCity) const SizedBox(height: 14),
              ],
              if (showCity)
                CityAutocompleteField(
                  controller: cityController,
                  label: 'Місто',
                ),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 16),
          _ErrorText(error!),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: saving ? null : onContinue,
          child: Text(saving ? 'Збереження...' : 'Продовжити'),
        ),
      ],
    );
  }
}

class _PetBasicsStep extends StatelessWidget {
  const _PetBasicsStep({
    required this.nameController,
    required this.breedController,
    required this.species,
    required this.sex,
    required this.error,
    required this.speciesOptions,
    required this.speciesLabel,
    required this.onSpeciesChanged,
    required this.onSexChanged,
    required this.onContinue,
  });

  final TextEditingController nameController;
  final TextEditingController breedController;
  final String species;
  final String sex;
  final String? error;
  final List<String> speciesOptions;
  final String Function(String) speciesLabel;
  final ValueChanged<String> onSpeciesChanged;
  final ValueChanged<String> onSexChanged;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Розкажіть про улюбленця',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Почнемо з основного. Інші подробиці можна додати пізніше.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 24),
        _OnboardingCard(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: "Ім'я тварини *",
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: species,
                decoration: const InputDecoration(labelText: 'Вид *'),
                items: speciesOptions
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(speciesLabel(value)),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) onSpeciesChanged(value);
                },
              ),
              const SizedBox(height: 14),
              BreedAutocompleteField(
                key: ValueKey(species),
                controller: breedController,
                species: species,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: sex,
                decoration: const InputDecoration(labelText: 'Стать'),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Самець')),
                  DropdownMenuItem(value: 'female', child: Text('Самка')),
                  DropdownMenuItem(value: 'unknown', child: Text('Не знаю')),
                ],
                onChanged: (value) {
                  if (value != null) onSexChanged(value);
                },
              ),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 16),
          _ErrorText(error!),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: onContinue,
          child: const Text('Продовжити'),
        ),
      ],
    );
  }
}

class _PetDetailsStep extends StatelessWidget {
  const _PetDetailsStep({
    required this.birthDate,
    required this.avatarFile,
    required this.weightController,
    required this.colorController,
    required this.microchipController,
    required this.notesController,
    required this.neutered,
    required this.saving,
    required this.error,
    required this.onPickBirthDate,
    required this.onPickAvatar,
    required this.onNeuteredChanged,
    required this.onSave,
  });

  final DateTime? birthDate;
  final File? avatarFile;
  final TextEditingController weightController;
  final TextEditingController colorController;
  final TextEditingController microchipController;
  final TextEditingController notesController;
  final String neutered;
  final bool saving;
  final String? error;
  final VoidCallback onPickBirthDate;
  final VoidCallback onPickAvatar;
  final ValueChanged<String> onNeuteredChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final formattedDate = birthDate == null
        ? null
        : '${birthDate!.day.toString().padLeft(2, '0')}.'
            '${birthDate!.month.toString().padLeft(2, '0')}.'
            '${birthDate!.year}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Ще трохи важливого',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Усі поля на цьому кроці необов’язкові.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 24),
        _OnboardingCard(
          child: Column(
            children: [
              InkWell(
                onTap: onPickAvatar,
                borderRadius: BorderRadius.circular(16),
                child: avatarFile == null
                    ? Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceSoft,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                color: AppTheme.primary, size: 32),
                            SizedBox(height: 8),
                            Text('Додати фото',
                                style: TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          avatarFile!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: onPickBirthDate,
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Дата народження'),
                subtitle: Text(formattedDate ?? 'Не знаю'),
                trailing: const Icon(Icons.chevron_right),
              ),
              const Divider(),
              TextField(
                controller: weightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Вага, кг'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: colorController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Колір'),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: neutered,
                decoration: const InputDecoration(labelText: 'Стерилізовано'),
                items: const [
                  DropdownMenuItem(value: 'yes', child: Text('Так')),
                  DropdownMenuItem(value: 'no', child: Text('Ні')),
                  DropdownMenuItem(value: 'unknown', child: Text('Не знаю')),
                ],
                onChanged: (value) {
                  if (value != null) onNeuteredChanged(value);
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: microchipController,
                decoration: const InputDecoration(labelText: 'Номер мікрочипа'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: notesController,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Важливі нотатки про здоров’я',
                  hintText: 'Алергії, хронічні стани або інші особливості',
                ),
              ),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 16),
          _ErrorText(error!),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: saving ? null : onSave,
          child: Text(saving ? 'Створення картки...' : 'Створити картку'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: saving ? null : onSave,
          child: const Text('Пропустити необов’язкові поля'),
        ),
      ],
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: child,
      ),
    );
  }
}

class _PawHeroIcon extends StatelessWidget {
  const _PawHeroIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 88,
        height: 88,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFEDEAFF),
        ),
        child: Icon(icon, size: 40, color: AppTheme.primary),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEF0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
  }
}
