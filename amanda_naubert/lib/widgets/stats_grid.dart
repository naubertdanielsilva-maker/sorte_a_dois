import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'premium_card.dart';

class StatsGrid extends StatelessWidget {
  final String raffles;
  final String ideas;
  final String memories;
  final String points;

  const StatsGrid({
    super.key,
    this.raffles = '0',
    this.ideas = '0',
    this.memories = '0',
    this.points = '0',
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        StatCard(value: raffles, label: 'Sorteios'),
        StatCard(value: ideas, label: 'Ideias'),
        StatCard(value: memories, label: 'Memórias'),
        StatCard(value: points, label: 'Pontos'),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final String value;
  final String label;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.purple,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppTheme.mutedText),
          ),
        ],
      ),
    );
  }
}