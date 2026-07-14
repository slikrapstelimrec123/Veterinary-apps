import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_state.dart';
import '../../../core/config/supabase_config.dart';
import '../../../shared/widgets/city_autocomplete_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController = TextEditingController();
  late final TextEditingController _phoneController = TextEditingController();
  late final TextEditingController _emailController = TextEditingController();
  late final TextEditingController _cityController = TextEditingController();
  bool _saving = false;
  bool _initialized = false;
  String _currentEmail = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final user = AuthScope.of(context).currentUser;
      _nameController.text = user?.fullName ?? '';
      _phoneController.text = user?.phone ?? '';
      _cityController.text = user?.city ?? '';
      if (!SupabaseConfig.useMockData) {
        _currentEmail = Supabase.instance.client.auth.currentUser?.email ?? '';
      } else {
        _currentEmail = user?.email ?? '';
      }
      _emailController.text = _currentEmail;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = AuthScope.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Підтвердження'),
        content: const Text('Зберегти зміни профілю?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Скасувати')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Зберегти')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _saving = true);

    try {
      final newEmail = _emailController.text.trim();
      final emailChanged = newEmail.isNotEmpty && newEmail != _currentEmail;

      await auth.updateProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        city: _cityController.text.trim(),
      );

      if (!SupabaseConfig.useMockData) {
        if (emailChanged) {
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(email: newEmail),
          );
        }
      }

      if (mounted) {
        if (emailChanged) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Профіль оновлено. На нову адресу надіслано лист для підтвердження.'),
              duration: Duration(seconds: 6),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Профіль оновлено.')),
          );
        }
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Помилка: $e'),
              duration: const Duration(seconds: 8)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редагувати профіль'),
        actions: [
          if (_saving)
            const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)))
          else
            TextButton(onPressed: _save, child: const Text('Зберегти')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Повне ім'я *",
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? "Введіть ім'я"
                          : null,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const Divider(),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Телефон (необов\'язково)',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.phone_outlined),
                        hintText: '+380...',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const Divider(),
                    CityAutocompleteField(
                      controller: _cityController,
                      label: 'Місто *',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Оберіть місто'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Електронна адреса',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Введіть email';
                    }
                    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!emailRegex.hasMatch(v.trim())) {
                      return 'Некоректний email';
                    }
                    return null;
                  },
                ),
              ),
            ),
            if (_emailController.text.trim() != _currentEmail &&
                _emailController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 14, color: Colors.orange),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Після збереження на нову адресу буде надіслано лист для підтвердження.',
                        style: TextStyle(
                            fontSize: 12, color: Colors.orange.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: const Text('Зберегти зміни'),
            ),
          ],
        ),
      ),
    );
  }
}
