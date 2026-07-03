import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../data/pet_repository.dart';
import '../domain/pet.dart';

const _dogBreeds = [
  'Лабрадор ретрівер', 'Німецька вівчарка', 'Золотистий ретрівер', 'Французький бульдог',
  'Бульдог', 'Пудель', 'Бігль', 'Ротвейлер', 'Йоркширський тер\'єр', 'Боксер',
  'Доберман', 'Сибірський хаскі', 'Австралійська вівчарка', 'Бордер-коллі',
  'Кавалер кінг-чарлз спанієль', 'Шіба-іну', 'Джек рассел тер\'єр', 'Мальтезе',
  'Чіхуахуа', 'Такса', 'Шотландський коллі', 'Самоєд', 'Акіта', 'Боксер',
  'Далматинець', 'Вельш-коргі', 'Шпіц', 'Мопс', 'Бельгійська малінуа',
  'Ірландський сеттер', 'Американський стаффордширський тер\'єр', 'Бернський зенненгунд',
  'Великий шнауцер', 'Мінімальний шнауцер', 'Кане-корсо', 'Мастиф',
  'Ньюфаундленд', 'Сенбернар', 'Веймаранер', 'Бассет-хаунд',
  'Спанієль', 'Грейхаунд', 'Борзая', 'Афганська хортиця',
  'Чау-чау', 'Шарпей', 'Бультер\'єр', 'Бедлінгтон-тер\'єр',
  'Вірменська гавча', 'Левретка', 'Помераніан', 'Шпіц',
  'Метис', 'Інша порода',
];

const _catBreeds = [
  'Британська короткошерста', 'Шотландська висловуха', 'Мейн-кун', 'Перська',
  'Регдол', 'Бенгальська', 'Сіамська', 'Абіссінська', 'Сфінкс', 'Бірманська',
  'Норвезька лісова', 'Сибірська', 'Орієнтальна', 'Корніш рекс', 'Девон рекс',
  'Балінезійська', 'Турецька ангора', 'Руська блакитна', 'Буrmанська',
  'Американська короткошерста', 'Метиска', 'Інша порода',
];

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
  String? error;
  bool isSaving = false;

  static const speciesOptions = ['dog', 'cat', 'rabbit', 'bird', 'rodent', 'reptile', 'other'];
  static const sexOptions = ['male', 'female', 'unknown'];

  List<String> get _breedsForSpecies {
    if (species == 'dog') return _dogBreeds;
    if (species == 'cat') return _catBreeds;
    return [];
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

  Future<void> save() async {
    final name = nameController.text.trim();
    final weightText = weightController.text.trim();
    final parsedWeight = weightText.isEmpty ? null : double.tryParse(weightText.replaceAll(',', '.'));

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

    final pet = Pet(
      id: widget.pet?.id ?? '',
      name: name,
      species: species,
      breed: breedController.text.trim().isEmpty ? null : breedController.text.trim(),
      sex: sex,
      isNeutered: isNeutered,
      birthDate: birthDate,
      weightKg: parsedWeight,
      color: colorController.text.trim().isEmpty ? null : colorController.text.trim(),
      microchipNumber: microchipController.text.trim().isEmpty ? null : microchipController.text.trim(),
      avatarUrl: null,
      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
    );

    try {
      final saved = widget.pet == null
          ? await repository.createPet(pet)
          : await repository.updatePet(pet);
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (e) {
      setState(() => error = 'Помилка збереження: ${e.toString()}');
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
          value: species,
          decoration: const InputDecoration(labelText: 'Вид *'),
          items: speciesOptions
              .map((v) => DropdownMenuItem(value: v, child: Text(speciesLabel(v))))
              .toList(),
          onChanged: (v) => setState(() {
            species = v ?? 'dog';
            breedController.clear();
          }),
        ),
        const SizedBox(height: 12),

        // Breed — searchable dropdown for dogs/cats, plain text otherwise
        if (breeds.isNotEmpty)
          _BreedAutocomplete(
            controller: breedController,
            breeds: breeds,
          )
        else
          TextField(
            controller: breedController,
            decoration: const InputDecoration(labelText: 'Порода'),
          ),
        const SizedBox(height: 12),

        // Sex
        DropdownButtonFormField<String>(
          value: sex,
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
          title: const Text('Кастровано / стерилізовано'),
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
              decoration: InputDecoration(
                labelText: 'Дата народження',
                hintText: 'Натисніть, щоб обрати дату',
                suffixIcon: const Icon(Icons.calendar_today_outlined),
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

        // Photo placeholder
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Завантаження фото буде доступне у наступному оновленні.'),
              ),
            );
          },
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Вибрати фото з галереї'),
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
      ],
    );
  }
}

class _BreedAutocomplete extends StatelessWidget {
  const _BreedAutocomplete({required this.controller, required this.breeds});

  final TextEditingController controller;
  final List<String> breeds;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (value) {
        if (value.text.isEmpty) return breeds;
        final query = value.text.toLowerCase();
        return breeds.where((b) => b.toLowerCase().contains(query));
      },
      onSelected: (value) => controller.text = value,
      optionsMaxHeight: 220,
      fieldViewBuilder: (context, fieldController, focusNode, onSubmitted) {
        // sync external controller
        fieldController.addListener(() => controller.text = fieldController.text);
        return TextField(
          controller: fieldController,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Порода',
            hintText: 'Почніть вводити породу...',
            suffixIcon: Icon(Icons.arrow_drop_down),
          ),
        );
      },
    );
  }
}
