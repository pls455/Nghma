import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        children: [
          Text('الإعدادات', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: const [
                ListTile(leading: Icon(Icons.palette_outlined), title: Text('المظهر'), subtitle: Text('سيتم ربط خيارات المظهر المحفوظة لاحقاً')),
                Divider(height: 1),
                ListTile(leading: Icon(Icons.storage_outlined), title: Text('التخزين'), subtitle: Text('سيتم اختيار مجلد المكتبة عند إضافة مدير التنزيل')),
                Divider(height: 1),
                ListTile(leading: Icon(Icons.info_outline), title: Text('حول نغمة'), subtitle: Text('صنع بواسطة كرم - أبو إبراهيم')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
