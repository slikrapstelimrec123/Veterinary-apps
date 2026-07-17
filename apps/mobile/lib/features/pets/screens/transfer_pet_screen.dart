import 'package:flutter/material.dart';

import '../../../core/auth/auth_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/pet_avatar.dart';
import '../../pet_transfer/data/pet_transfer_repository.dart';
import '../domain/pet.dart';

class TransferPetScreen extends StatefulWidget {
  const TransferPetScreen({super.key, required this.pet});
  final Pet pet;

  @override
  State<TransferPetScreen> createState() => _TransferPetScreenState();
}

class _TransferPetScreenState extends State<TransferPetScreen> {
  final _repo = PetTransferRepository();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);

    String? error;
    try {
      final authState = AuthScope.of(context);
      final fromName = authState.currentUser?.fullName ??
          '\u0413\u043e\u0441\u043f\u043e\u0434\u0430\u0440';
      error = await _repo.sendTransfer(
        pet: widget.pet,
        toEmail: _emailController.text.trim(),
        fromUserName: fromName,
      );
    } catch (_) {
      error =
          '\u041d\u0435 \u0432\u0434\u0430\u043b\u043e\u0441\u044f \u043d\u0430\u0434\u0456\u0441\u043b\u0430\u0442\u0438 \u0437\u0430\u043f\u0438\u0442. \u0421\u043f\u0440\u043e\u0431\u0443\u0439\u0442\u0435 \u0449\u0435 \u0440\u0430\u0437.';
    } finally {
      if (mounted) setState(() => _sending = false);
    }

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppTheme.danger),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text(
            '\u0417\u0430\u043f\u0438\u0442 \u043d\u0430\u0434\u0456\u0441\u043b\u0430\u043d\u043e'),
        content: Text(
          '\u0417\u0430\u043f\u0438\u0442 \u043d\u0430 \u043f\u0435\u0440\u0435\u0434\u0430\u0447\u0443 ${widget.pet.name} \u043d\u0430\u0434\u0456\u0441\u043b\u0430\u043d\u043e \u043d\u0430 ${_emailController.text.trim()}.\n\n'
          '\u041d\u043e\u0432\u0438\u0439 \u0433\u043e\u0441\u043f\u043e\u0434\u0430\u0440 \u043f\u043e\u0431\u0430\u0447\u0438\u0442\u044c \u0441\u043f\u043e\u0432\u0456\u0449\u0435\u043d\u043d\u044f \u0432 \u0437\u0430\u0441\u0442\u043e\u0441\u0443\u043d\u043a\u0443 Lappo.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(true);
            },
            child: const Text(
                '\u0417\u0440\u043e\u0437\u0443\u043c\u0456\u043b\u043e'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text(
            '\u041f\u0435\u0440\u0435\u0434\u0430\u0442\u0438 \u0442\u0432\u0430\u0440\u0438\u043d\u0443',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    PetAvatar(
                        name: widget.pet.name,
                        avatarUrl: widget.pet.avatarUrl,
                        size: 56),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.pet.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16)),
                          Text(
                            '${widget.pet.speciesLabel}${widget.pet.breed != null ? " \u00b7 ${widget.pet.breed}" : ""}',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Email \u043d\u043e\u0432\u043e\u0433\u043e \u0433\u043e\u0441\u043f\u043e\u0434\u0430\u0440\u044f',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              '\u041d\u043e\u0432\u0438\u0439 \u0433\u043e\u0441\u043f\u043e\u0434\u0430\u0440 \u043f\u043e\u0432\u0438\u043d\u0435\u043d \u0431\u0443\u0442\u0438 \u0437\u0430\u0440\u0435\u0454\u0441\u0442\u0440\u043e\u0432\u0430\u043d\u0438\u0439 \u0432 Lappo. \u041f\u0456\u0441\u043b\u044f \u043f\u0456\u0434\u0442\u0432\u0435\u0440\u0434\u0436\u0435\u043d\u043d\u044f \u043a\u0430\u0440\u0442\u043a\u0430 \u0442\u0432\u0430\u0440\u0438\u043d\u0438 \u043f\u0435\u0440\u0435\u0439\u0434\u0435 \u0434\u043e \u0439\u043e\u0433\u043e \u0430\u043a\u0430\u0443\u043d\u0442\u0443.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText:
                    'Email \u043d\u043e\u0432\u043e\u0433\u043e \u0433\u043e\u0441\u043f\u043e\u0434\u0430\u0440\u044f *',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return '\u0412\u0432\u0435\u0434\u0456\u0442\u044c email';
                }
                if (!v.contains('@') || !v.contains('.')) {
                  return '\u041d\u0435\u0432\u0456\u0440\u043d\u0438\u0439 \u0444\u043e\u0440\u043c\u0430\u0442 email';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '\u0429\u043e \u043f\u0435\u0440\u0435\u0434\u0430\u0454\u0442\u044c\u0441\u044f',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    SizedBox(height: 12),
                    _InfoRow(
                        icon: Icons.pets_outlined,
                        text:
                            '\u041f\u0440\u043e\u0444\u0456\u043b\u044c \u0442\u0432\u0430\u0440\u0438\u043d\u0438 (\u0456\u043c\u02bc\u044f, \u043f\u043e\u0440\u043e\u0434\u0430, \u0432\u0456\u043a)'),
                    _InfoRow(
                        icon: Icons.badge_outlined,
                        text:
                            '\u041f\u0430\u0441\u043f\u043e\u0440\u0442\u043d\u0456 \u0434\u0430\u043d\u0456 \u0442\u0430 \u043c\u0456\u043a\u0440\u043e\u0447\u0456\u043f'),
                    _InfoRow(
                        icon: Icons.history_outlined,
                        text:
                            '\u0417\u0430\u043f\u0438\u0441\u0438 \u043f\u0440\u043e \u043f\u0440\u0438\u0439\u043e\u043c\u0438 \u0443 \u0432\u0435\u0442\u0435\u0440\u0438\u043d\u0430\u0440\u0430'),
                    _InfoRow(
                        icon: Icons.medication_outlined,
                        text:
                            '\u041f\u0440\u0435\u043f\u0430\u0440\u0430\u0442\u0438 \u0442\u0430 \u043b\u0456\u043a\u0438'),
                    _InfoRow(
                        icon: Icons.folder_outlined,
                        text:
                            '\u041c\u0435\u0434\u0438\u0447\u043d\u0456 \u0434\u043e\u043a\u0443\u043c\u0435\u043d\u0442\u0438'),
                    _InfoRow(
                        icon: Icons.restaurant_outlined,
                        text:
                            '\u0414\u0430\u043d\u0456 \u043f\u0440\u043e \u0445\u0430\u0440\u0447\u0443\u0432\u0430\u043d\u043d\u044f'),
                    _InfoRow(
                        icon: Icons.emoji_events_outlined,
                        text:
                            '\u0414\u043e\u0441\u044f\u0433\u043d\u0435\u043d\u043d\u044f'),
                    _InfoRow(
                        icon: Icons.book_outlined,
                        text:
                            '\u0412\u0435\u0442\u0435\u0440\u0438\u043d\u0430\u0440\u043d\u0438\u0439 \u043f\u0430\u0441\u043f\u043e\u0440\u0442'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: AppTheme.warning.withValues(alpha: 0.08),
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_outlined,
                        color: AppTheme.warning, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '\u041f\u0456\u0441\u043b\u044f \u043f\u0440\u0438\u0439\u043d\u044f\u0442\u0442\u044f \u0437\u0430\u043f\u0438\u0442\u0443 \u043d\u043e\u0432\u0438\u043c \u0433\u043e\u0441\u043f\u043e\u0434\u0430\u0440\u0435\u043c \u0442\u0432\u0430\u0440\u0438\u043d\u0430 \u0437\u043d\u0438\u043a\u043d\u0435 \u0437 \u0432\u0430\u0448\u043e\u0433\u043e \u0430\u043a\u0430\u0443\u043d\u0442\u0443.',
                        style: TextStyle(
                            fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _sending ? null : _submit,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_outlined),
              label: const Text(
                  '\u041d\u0430\u0434\u0456\u0441\u043b\u0430\u0442\u0438 \u0437\u0430\u043f\u0438\u0442 \u043d\u0430 \u043f\u0435\u0440\u0435\u0434\u0430\u0447\u0443'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
