import 'package:flutter/material.dart';

class PlayerPage extends StatelessWidget {
  const PlayerPage({super.key});

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
              Icon(Icons.graphic_eq, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 20),
              Text('المشغل', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text('لا يوجد ملف صوتي قيد التشغيل.', textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 8),
              Text('سيتم ربط التشغيل المحلي وعناصر التحكم بعد بناء طبقة المكتبة والمشغل.', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
