import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../data/review_repository.dart';
import '../domain/review.dart';
import '../widgets/rating_widgets.dart';

class DoctorReviewsScreen extends StatefulWidget {
  const DoctorReviewsScreen(
      {super.key, required this.doctorId, required this.doctorName});

  final String doctorId;
  final String doctorName;

  @override
  State<DoctorReviewsScreen> createState() => _DoctorReviewsScreenState();
}

class _DoctorReviewsScreenState extends State<DoctorReviewsScreen> {
  final repository = ReviewRepository();
  late Future<List<Review>> future =
      repository.getDoctorReviews(widget.doctorId);

  void refresh() {
    setState(() => future = repository.getDoctorReviews(widget.doctorId));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Review>>(
      future: future,
      builder: (context, snapshot) {
        final reviews = snapshot.data ?? [];
        return AppScaffold(
          title: 'Відгуки лікаря',
          subtitle: widget.doctorName,
          children: [
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              ErrorState(
                  message: 'Не вдалося завантажити відгуки лікаря.',
                  onRetry: refresh)
            else if (reviews.isEmpty)
              const EmptyState(
                  title: 'Відгуків про лікаря ще немає',
                  message: 'Відгуки з’являться після завершених прийомів.',
                  icon: Icons.star_border)
            else
              ...reviews.map((review) => ReviewCard(review: review)),
          ],
        );
      },
    );
  }
}
