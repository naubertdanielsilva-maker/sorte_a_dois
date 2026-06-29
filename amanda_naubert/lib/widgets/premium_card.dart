import 'package:flutter/material.dart';

class PremiumCard extends StatelessWidget {
  final Widget child;
  final List<Color>? gradient;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  const PremiumCard({
    super.key,
    required this.child,
    this.gradient,
    this.padding = const EdgeInsets.all(22),
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? Colors.white : null,
        gradient: gradient == null
            ? null
            : LinearGradient(
                colors: gradient!,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}