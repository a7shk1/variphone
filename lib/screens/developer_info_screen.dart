import 'package:flutter/material.dart';

class DeveloperInfoScreen extends StatelessWidget {
  const DeveloperInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('عن المطوّر'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: cs.primary.withOpacity(.15),
                      child: Icon(Icons.storefront, color: cs.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'عين ستور',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'المطوّر الرسمي لتطبيق VAR IPTV',
                            style: TextStyle(
                              fontSize: 14,
                              color: cs.onSurface.withOpacity(.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'نبذة',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            const Text(
              'عين ستور هي صفحة مختصة بتطوير وتوفير تطبيقات عملية تخلي حياتك الرقمية أبسط وأسرع. '
                  'تطبيق VAR IPTV هو واحد من مشاريعنا، صُمم ليقدّم تجربة مشاهدة أنيقة وسلسة مع تحديثات مباشرة للمباريات والقنوات.\n\n'
                  'نهتم دائماً إنو يكون التطبيق ثابت، سريع، وبواجهة عصرية تحافظ على راحة المستخدم. '
                  'مع VAR IPTV راح تلاگي المتعة والجودة بمكان واحد، وبأسلوب يلبّي احتياجاتك اليومية من البث المباشر.',
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 18),

            // أزرار سريعة (اختياري) — إذا ما تريدها احذف هذا البلوك كله
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/contact'),
                  icon: const Icon(Icons.mail_outline),
                  label: const Text('تواصل معنا'),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/privacy'),
                  icon: const Icon(Icons.privacy_tip_outlined),
                  label: const Text('سياسة الخصوصية'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
