// lib/screens/admin_screen.dart
import 'package:flutter/material.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin (مؤقتاً)')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'واجهة الإدارة متوقفة مؤقتاً لأن Firebase متعطّل.\n'
                'راح نرجعها بعد ما يثبت التطبيق الأساسي.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
