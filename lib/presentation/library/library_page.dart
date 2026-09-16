import 'package:flutter/material.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المكتبة', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ابحث في مكتبتك')),
            const SizedBox(height: 18),
            Expanded(
              child: Center(
                child: Text('مكتبتك فارغة حالياً\nالتنزيلات المكتملة ستظهر هنا.', textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
