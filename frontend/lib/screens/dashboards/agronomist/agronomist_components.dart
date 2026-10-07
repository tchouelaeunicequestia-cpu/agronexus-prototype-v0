import 'package:flutter/material.dart';

abstract final class AgronomistPalette {
  static const surface = Color(0xFF121D2D);
  static const surfaceRaised = Color(0xFF1B2939);
  static const primary = Color(0xFF4EDEA3);
  static const secondary = Color(0xFF45DFA4);
  static const warning = Color(0xFFFFB95F);
  static const error = Color(0xFFFF7C76);
  static const text = Color(0xFFE5EEE9);
  static const muted = Color(0xFFB4C2BD);
  static const border = Color(0xFF40534C);
}

class AgronomistPanel extends StatelessWidget {
  const AgronomistPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor = AgronomistPalette.surface,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: backgroundColor.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: AgronomistPalette.border.withValues(alpha: 0.6),
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 14,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

class AgronomistPageHeading extends StatelessWidget {
  const AgronomistPageHeading({
    required this.eyebrow,
    required this.title,
    required this.description,
    super.key,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        eyebrow.toUpperCase(),
        style: const TextStyle(
          color: AgronomistPalette.primary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
      const SizedBox(height: 7),
      Text(
        title,
        style: const TextStyle(
          color: AgronomistPalette.text,
          fontSize: 23,
          height: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        description,
        style: const TextStyle(
          color: AgronomistPalette.muted,
          fontSize: 13,
          height: 1.45,
        ),
      ),
    ],
  );
}

class AgronomistMetricCard extends StatelessWidget {
  const AgronomistMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.accent = AgronomistPalette.primary,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) => AgronomistPanel(
    padding: const EdgeInsets.all(14),
    backgroundColor: AgronomistPalette.surfaceRaised,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AgronomistPalette.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(icon, size: 17, color: accent),
          ],
        ),
        const SizedBox(height: 11),
        Text(
          value,
          style: TextStyle(
            color: accent,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class AgronomistSectionTitle extends StatelessWidget {
  const AgronomistSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      color: AgronomistPalette.text,
      fontSize: 16,
      fontWeight: FontWeight.w700,
    ),
  );
}

String agronomistTimestamp(Object? value) {
  if (value == null) return 'Time unavailable';
  final date = DateTime.tryParse(value.toString())?.toLocal();
  if (date == null) return value.toString();
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')} '
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}

String agronomistErrorMessage(Object error) =>
    error.toString().replaceFirst('Exception: ', '');
