import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../data/review_repository.dart';
import '../widgets/rating_widgets.dart';
import 'review_success_screen.dart';

class LeaveReviewScreen extends StatefulWidget {
  const LeaveReviewScreen({
    super.key,
    required this.clinicId,
    required this.clinicName,
    required this.appointmentId,
    required this.petId,
    this.doctorId,
    this.doctorName,
    this.visitRecordId,
  });

  final String clinicId;
  final String clinicName;
  final String appointmentId;
  final String petId;
  final String? doctorId;
  final String? doctorName;
  final String? visitRecordId;

  @override
  State<LeaveReviewScreen> createState() => _LeaveReviewScreenState();
}

class _LeaveReviewScreenState extends State<LeaveReviewScreen> {
  final repository = ReviewRepository();
  final commentController = TextEditingController();
  int rating = 0;
  int doctorRating = 0;
  int serviceQualityRating = 0;
  bool isAnonymous = false;
  bool isSubmitting = false;
  String? error;

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final comment = commentController.text.trim();
    if (rating < 1 || rating > 5) {
      setState(() => error = 'Оберіть загальну оцінку від 1 до 5.');
      return;
    }

    if (comment.length > 1000) {
      setState(() => error = 'Коментар має бути не довшим за 1000 символів.');
      return;
    }

    setState(() {
      error = null;
      isSubmitting = true;
    });

    try {
      await repository.submitReview(
        clinicId: widget.clinicId,
        doctorId: widget.doctorId,
        appointmentId: widget.appointmentId,
        visitRecordId: widget.visitRecordId,
        petId: widget.petId,
        rating: rating,
        doctorRating: doctorRating == 0 ? null : doctorRating,
        clinicRating: rating,
        serviceQualityRating: serviceQualityRating == 0 ? null : serviceQualityRating,
        comment: comment.isEmpty ? null : comment,
        isAnonymous: isAnonymous,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ReviewSuccessScreen()));
    } catch (_) {
      setState(() => error = 'Не вдалося зберегти відгук. Перевірте, чи цей запис ще не був оцінений.');
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Залишити відгук',
      subtitle: widget.clinicName,
      children: [
        if (error != null) ...[
          Text(error!, style: const TextStyle(color: Color(0xFF9F1239))),
          const SizedBox(height: 12),
        ],
        StarRatingInput(value: rating, onChanged: (value) => setState(() => rating = value), label: 'Загальна оцінка *'),
        const SizedBox(height: 12),
        if (widget.doctorId != null) ...[
          StarRatingInput(value: doctorRating, onChanged: (value) => setState(() => doctorRating = value), label: 'Оцінка лікаря'),
          const SizedBox(height: 12),
        ],
        StarRatingInput(value: serviceQualityRating, onChanged: (value) => setState(() => serviceQualityRating = value), label: 'Якість сервісу'),
        const SizedBox(height: 12),
        TextField(
          controller: commentController,
          minLines: 4,
          maxLines: 7,
          maxLength: 1000,
          decoration: const InputDecoration(labelText: 'Коментар', hintText: 'Що було корисним для вас і тварини?'),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          value: isAnonymous,
          onChanged: (value) => setState(() => isAnonymous = value),
          title: const Text('Опублікувати анонімно'),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: isSubmitting ? null : submit, child: Text(isSubmitting ? 'Надсилання...' : 'Надіслати відгук')),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: isSubmitting ? null : () => Navigator.of(context).pop(), child: const Text('Скасувати')),
      ],
    );
  }
}
