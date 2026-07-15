import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../data/pet_transfer_repository.dart';
import '../domain/pet_transfer.dart';

class IncomingTransfersScreen extends StatefulWidget {
  const IncomingTransfersScreen({super.key});

  @override
  State<IncomingTransfersScreen> createState() =>
      _IncomingTransfersScreenState();
}

class _IncomingTransfersScreenState extends State<IncomingTransfersScreen> {
  final _repo = PetTransferRepository();
  late Future<List<PetTransfer>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.getIncomingTransfers();
  }

  void _refresh() {
    setState(() {
      _future = _repo.getIncomingTransfers();
    });
  }

  Future<void> _accept(PetTransfer transfer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
            '\u041f\u0440\u0438\u0439\u043d\u044f\u0442\u0438 \u0442\u0432\u0430\u0440\u0438\u043d\u0443?'),
        content: Text(
            '${transfer.petName} \u0431\u0443\u0434\u0435 \u0434\u043e\u0434\u0430\u043d\u043e \u0434\u043e \u0432\u0430\u0448\u043e\u0433\u043e \u0441\u043f\u0438\u0441\u043a\u0443 \u0442\u0432\u0430\u0440\u0438\u043d.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                  '\u0421\u043a\u0430\u0441\u0443\u0432\u0430\u0442\u0438')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                  '\u041f\u0440\u0438\u0439\u043d\u044f\u0442\u0438')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _repo.acceptTransfer(transfer.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${transfer.petName} \u0434\u043e\u0434\u0430\u043d\u043e \u0434\u043e \u0432\u0430\u0448\u043e\u0433\u043e \u0430\u043a\u0430\u0443\u043d\u0442\u0443'),
            backgroundColor: AppTheme.success),
      );
      _refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                '\u041d\u0435 \u0432\u0434\u0430\u043b\u043e\u0441\u044f \u043f\u0440\u0438\u0439\u043d\u044f\u0442\u0438 \u0437\u0430\u043f\u0438\u0442. \u0421\u043f\u0440\u043e\u0431\u0443\u0439\u0442\u0435 \u0449\u0435 \u0440\u0430\u0437.'),
            backgroundColor: AppTheme.danger),
      );
    }
  }

  Future<void> _decline(PetTransfer transfer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
            '\u0412\u0456\u0434\u0445\u0438\u043b\u0438\u0442\u0438 \u0437\u0430\u043f\u0438\u0442?'),
        content: Text(
            '\u0412\u0438 \u0432\u0456\u0434\u043c\u043e\u0432\u043b\u044f\u0454\u0442\u0435\u0441\u044c \u0432\u0456\u0434 \u043f\u0440\u0438\u0439\u043d\u044f\u0442\u0442\u044f ${transfer.petName}.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('\u041d\u0430\u0437\u0430\u0434')),
          OutlinedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                  '\u0412\u0456\u0434\u0445\u0438\u043b\u0438\u0442\u0438')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _repo.declineTransfer(transfer.id);
      _refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                '\u041d\u0435 \u0432\u0434\u0430\u043b\u043e\u0441\u044f \u0432\u0456\u0434\u0445\u0438\u043b\u0438\u0442\u0438 \u0437\u0430\u043f\u0438\u0442. \u0421\u043f\u0440\u043e\u0431\u0443\u0439\u0442\u0435 \u0449\u0435 \u0440\u0430\u0437.'),
            backgroundColor: AppTheme.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title:
          '\u0417\u0430\u043f\u0438\u0442\u0438 \u043d\u0430 \u043f\u0435\u0440\u0435\u0434\u0430\u0447\u0443',
      children: [
        FutureBuilder<List<PetTransfer>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final transfers = snapshot.data ?? [];
            if (transfers.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined,
                        size: 56, color: AppTheme.textSecondary),
                    SizedBox(height: 12),
                    Text(
                        '\u041d\u0435\u043c\u0430\u0454 \u0432\u0445\u0456\u0434\u043d\u0438\u0445 \u0437\u0430\u043f\u0438\u0442\u0456\u0432',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
              );
            }
            return Column(
              children: transfers
                  .map((t) => _TransferCard(
                        transfer: t,
                        onAccept: () => _accept(t),
                        onDecline: () => _decline(t),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _TransferCard extends StatelessWidget {
  const _TransferCard(
      {required this.transfer,
      required this.onAccept,
      required this.onDecline});
  final PetTransfer transfer;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      const Icon(Icons.pets, color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          transfer.petName ??
                              '\u0422\u0432\u0430\u0440\u0438\u043d\u0430',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                      if (transfer.fromUserName != null)
                        Text('\u0412\u0456\u0434: ${transfer.fromUserName}',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDecline,
                    child: const Text(
                        '\u0412\u0456\u0434\u0445\u0438\u043b\u0438\u0442\u0438'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: onAccept,
                    child: const Text(
                        '\u041f\u0440\u0438\u0439\u043d\u044f\u0442\u0438'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
