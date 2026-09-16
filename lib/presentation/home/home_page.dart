import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _looksLikeUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
  }

  void _validateLink() {
    final value = _controller.text.trim();
    if (!_looksLikeUrl(value)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل رابطاً صحيحاً يبدأ بـ http أو https.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('الرابط صالح مبدئياً. تحليل المصدر سيُربط بمحرك المصادر في المرحلة التالية.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('نغمة', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('نزّل ما تملك حق تنزيله، ثم احتفظ به في مكتبتك.', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 28),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('إضافة رابط', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text('الصق رابط المحتوى المسموح بتنزيله.', style: theme.textTheme.bodySmall),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _controller,
                            keyboardType: TextInputType.url,
                            textDirection: TextDirection.ltr,
                            decoration: const InputDecoration(
                              hintText: 'https://example.com/media',
                              prefixIcon: Icon(Icons.link),
                            ),
                            onSubmitted: (_) => _validateLink(),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _validateLink,
                              icon: const Icon(Icons.manage_search),
                              label: const Text('تحليل الرابط'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('النشاط الأخير', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  const _EmptySection(
                    icon: Icons.history,
                    title: 'لا يوجد نشاط بعد',
                    subtitle: 'التنزيلات المكتملة ستظهر هنا.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Icon(icon, size: 30, color: theme.colorScheme.primary),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(subtitle, style: theme.textTheme.bodySmall),
            ])),
          ],
        ),
      ),
    );
  }
}
