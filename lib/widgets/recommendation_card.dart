import 'package:flutter/material.dart';

class RecommendationCard extends StatelessWidget {
  final String text;

  const RecommendationCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.tips_and_updates),
        title: Text(text),
      ),
    );
  }
}
