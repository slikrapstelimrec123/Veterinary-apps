import 'package:flutter/material.dart';

import '../domain/review.dart';

class StarRatingInput extends StatelessWidget {
  const StarRatingInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
        ],
        Row(
          children: List.generate(5, (index) {
            final rating = index + 1;
            return IconButton(
              tooltip: '$rating з 5',
              onPressed: () => onChanged(rating),
              icon: Icon(rating <= value ? Icons.star : Icons.star_border),
              color: const Color(0xFFF59E0B),
            );
          }),
        ),
      ],
    );
  }
}

class RatingSummaryCard extends StatelessWidget {
  const RatingSummaryCard(
      {super.key, required this.summary, required this.emptyText});

  final RatingSummary summary;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: summary.hasReviews
            ? Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  Text(summary.averageRating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(width: 8),
                  Text('на основі ${summary.reviewCount} відгуків'),
                ],
              )
            : Text(emptyText),
      ),
    );
  }
}

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final date = review.createdAt.toIso8601String().split('T').first;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ...List.generate(
                    5,
                    (index) => Icon(
                        index < review.rating ? Icons.star : Icons.star_border,
                        color: const Color(0xFFF59E0B),
                        size: 18)),
                const Spacer(),
                Text(date, style: const TextStyle(color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 8),
            Text(review.authorLabel,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            if (review.doctorName != null)
              Text('Лікар: ${review.doctorName}',
                  style: const TextStyle(color: Colors.black54)),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review.comment!),
            ],
          ],
        ),
      ),
    );
  }
}
