import 'package:flutter/material.dart';

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SectionPage(
      title: 'التنزيلات',
      icon: Icons.download_outlined,
      heading: 'لا توجد تنزيلات',
      description: 'عند بدء تنزيل حقيقي ستظهر حالته هنا مع التقدم والسرعة والتحكم.',
    );
  }
}

class _SectionPage extends StatelessWidget {
  const _SectionPage({required this.title, required this.icon, required this.heading, required this.description});
  final String title;
  final IconData icon;
  final String heading;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 52, color: theme.colorScheme.primary),
              const SizedBox(height: 18),
              Text(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 28),
              Text(heading, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(description, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
