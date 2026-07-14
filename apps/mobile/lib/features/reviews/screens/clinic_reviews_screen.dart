import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../data/review_repository.dart';
import '../domain/review.dart';
import '../widgets/rating_widgets.dart';

class ClinicReviewsScreen extends StatefulWidget {
  const ClinicReviewsScreen(
      {super.key, required this.clinicId, required this.clinicName});

  final String clinicId;
  final String clinicName;

  @override
  State<ClinicReviewsScreen> createState() => _ClinicReviewsScreenState();
}

class _ClinicReviewsScreenState extends State<ClinicReviewsScreen> {
  final repository = ReviewRepository();
  late Future<List<Review>> future =
      repository.getClinicReviews(widget.clinicId);

  void refresh() {
    setState(() => future = repository.getClinicReviews(widget.clinicId));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Review>>(
      future: future,
      builder: (context, snapshot) {
        final reviews = snapshot.data ?? [];
        return AppScaffold(
          title: 'Відгуки клініки',
          subtitle: widget.clinicName,
          children: [
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              ErrorState(
                  message: 'Не вдалося завантажити відгуки.', onRetry: refresh)
            else if (reviews.isEmpty)
              const EmptyState(
                  title: 'Відгуків ще немає',
                  message: 'Відгуки з’являться після завершених записів.',
                  icon: Icons.star_border)
            else
              ...reviews.map((review) => ReviewCard(review: review)),
          ],
        );
      },
    );
  }
}
