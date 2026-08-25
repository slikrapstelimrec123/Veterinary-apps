import 'package:flutter/material.dart';

const dogBreeds = [
  'Лабрадор ретрівер',
  'Німецька вівчарка',
  'Золотистий ретрівер',
  'Французький бульдог',
  'Бульдог',
  'Пудель',
  'Бігль',
  'Ротвейлер',
  'Йоркширський тер\'єр',
  'Боксер',
  'Доберман',
  'Сибірський хаскі',
  'Австралійська вівчарка',
  'Бордер-коллі',
  'Кавалер кінг-чарлз спанієль',
  'Шіба-іну',
  'Джек рассел тер\'єр',
  'Мальтезе',
  'Чіхуахуа',
  'Такса',
  'Шотландський коллі',
  'Самоєд',
  'Акіта',
  'Далматинець',
  'Вельш-коргі',
  'Шпіц',
  'Мопс',
  'Бельгійська малінуа',
  'Ірландський сеттер',
  'Американський стаффордширський тер\'єр',
  'Бернський зенненгунд',
  'Великий шнауцер',
  'Мініатюрний шнауцер',
  'Кане-корсо',
  'Мастиф',
  'Ньюфаундленд',
  'Сенбернар',
  'Веймаранер',
  'Бассет-хаунд',
  'Спанієль',
  'Грейхаунд',
  'Борза',
  'Афганський хорт',
  'Чау-чау',
  'Шарпей',
  'Бультер\'єр',
  'Бедлінгтон-тер\'єр',
  'Левретка',
  'Помераніан',
  'Метис',
  'Інша порода',
];

const catBreeds = [
  'Британська короткошерста',
  'Шотландська висловуха',
  'Мейн-кун',
  'Перська',
  'Регдол',
  'Бенгальська',
  'Сіамська',
  'Абіссінська',
  'Сфінкс',
  'Бірманська',
  'Норвезька лісова',
  'Сибірська',
  'Орієнтальна',
  'Корніш рекс',
  'Девон рекс',
  'Балінезійська',
  'Турецька ангора',
  'Руська блакитна',
  'Бурманська',
  'Американська короткошерста',
  'Метис',
  'Інша порода',
];

const rabbitBreeds = [
  'Нідерландський карлик',
  'Баран карликовий',
  'Рекс',
  'Ангора',
  'Каліфорнійський',
  'Новозеландський білий',
  'Фландрський велетень',
  'Метис',
  'Інша порода',
];

const birdBreeds = [
  'Хвилястий папужка',
  'Корела',
  'Нерозлучник',
  'Канарка',
  'Амадина',
  'Жако',
  'Ара',
  'Какаду',
  'Олександрійський папуга',
  'Інший вид',
];

const rodentBreeds = [
  'Сирійський хом’як',
  'Джунгарський хом’як',
  'Морська свинка',
  'Декоративний пацюк',
  'Декоративна миша',
  'Шиншила',
  'Дегу',
  'Тхір',
  'Інший вид',
];

const reptileBreeds = [
  'Черепаха',
  'Бородата агама',
  'Леопардовий гекон',
  'Ігуана',
  'Хамелеон',
  'Маїсовий полоз',
  'Королівський пітон',
  'Інший вид',
];

const otherAnimalBreeds = [
  'Кінь',
  'Поні',
  'Коза',
  'Вівця',
  'Свиня',
  'Корова',
  'Інший вид',
];

List<String> breedsForSpecies(String species) => switch (species) {
      'dog' => dogBreeds,
      'cat' => catBreeds,
      'rabbit' => rabbitBreeds,
      'bird' => birdBreeds,
      'rodent' => rodentBreeds,
      'reptile' => reptileBreeds,
      'other' => otherAnimalBreeds,
      _ => const [],
    };

class BreedAutocompleteField extends StatefulWidget {
  const BreedAutocompleteField({
    super.key,
    required this.controller,
    required this.species,
  });

  final TextEditingController controller;
  final String species;

  @override
  State<BreedAutocompleteField> createState() => _BreedAutocompleteFieldState();
}

class _BreedAutocompleteFieldState extends State<BreedAutocompleteField> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final breeds = breedsForSpecies(widget.species);
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) return breeds;
        return breeds.where((breed) => breed.toLowerCase().contains(query));
      },
      onSelected: (value) {
        widget.controller.value = TextEditingValue(
          text: value,
          selection: TextSelection.collapsed(offset: value.length),
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Порода',
            hintText: breeds.isEmpty
                ? 'Вкажіть породу'
                : 'Почніть вводити назву породи',
            suffixIcon: breeds.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Показати породи',
                    onPressed: focusNode.requestFocus,
                    icon: const Icon(Icons.arrow_drop_down),
                  ),
          ),
          onSubmitted: (_) => onSubmitted(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final values = options.toList(growable: false);
        if (values.isEmpty) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, maxWidth: 420),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: values.length,
                itemBuilder: (context, index) {
                  final value = values[index];
                  return ListTile(
                    dense: true,
                    title: Text(value),
                    onTap: () => onSelected(value),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
