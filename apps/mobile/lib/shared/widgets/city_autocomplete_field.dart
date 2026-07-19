import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

const supportedUkrainianCities = [
  'Київ',
  'Харків',
  'Одеса',
  'Дніпро',
  'Запоріжжя',
  'Львів',
  'Миколаїв',
  'Вінниця',
  'Херсон',
  'Полтава',
  'Чернігів',
  'Черкаси',
  'Житомир',
  'Суми',
  'Хмельницький',
  'Рівне',
  'Луцьк',
  'Ужгород',
  'Тернопіль',
  'Бровари',
  'Ірпінь',
  'Буча',
  'Бориспіль',
  'Івано-Франківськ',
  'Кропивницький',
  'Мукачево',
  'Дрогобич',
  'Нікополь',
  'Павлоград',
];

Future<String?> _showCityPicker(BuildContext context, String current) {
  final search = TextEditingController(text: current);
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setInner) {
        final q = search.text.trim().toLowerCase();
        final filtered = q.isEmpty
            ? supportedUkrainianCities
            : supportedUkrainianCities
                .where((c) => c.toLowerCase().contains(q))
                .toList();
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SizedBox(
            height: 420,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: search,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Пошук міста...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: AppTheme.background,
                    ),
                    onChanged: (_) => setInner(() {}),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => ListTile(
                      leading: const Icon(Icons.location_on_outlined,
                          color: AppTheme.primary, size: 18),
                      title: Text(filtered[i]),
                      onTap: () => Navigator.of(ctx).pop(filtered[i]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      });
    },
  );
}

class CityAutocompleteField extends StatelessWidget {
  const CityAutocompleteField({
    super.key,
    required this.controller,
    this.label = 'Місто',
    this.validator,
    this.filled = false,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final city = await _showCityPicker(context, controller.text);
        if (city != null) controller.text = city;
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          validator: validator,
          decoration: filled
              ? InputDecoration(
                  labelText: label,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppTheme.surface,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                )
              : InputDecoration(
                  labelText: label,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                ),
        ),
      ),
    );
  }
}
