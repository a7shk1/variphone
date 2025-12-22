import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  static const String devEmail = 'ahmed.289ahmed@gmail.com';
  AutovalidateMode _auto = AutovalidateMode.disabled;

  Future<void> _sendEmail() async {
    if (!mounted) return;

    setState(() => _auto = AutovalidateMode.onUserInteraction);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final subject = Uri.encodeComponent("رسالة من تطبيق Var IPTV");
    final body = Uri.encodeComponent(
      "الاسم: ${_nameController.text}\n"
          "الإيميل: ${_emailController.text}\n\n"
          "الرسالة:\n${_messageController.text}",
    );

    final mailtoUri = Uri(
      scheme: 'mailto',
      path: devEmail,
      query: 'subject=$subject&body=$body',
    );

    // 1) Mail app
    if (await canLaunchUrl(mailtoUri)) {
      final ok = await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
      if (ok) return;
    }

    // 2) Gmail compose page
    final gmail = Uri.parse(
      'https://mail.google.com/mail/?view=cm&fs=1&to=$devEmail&su=$subject&body=$body',
    );
    if (await canLaunchUrl(gmail)) {
      final ok = await launchUrl(gmail, mode: LaunchMode.externalApplication);
      if (ok) return;
    }

    // 3) Copy fallback
    await Clipboard.setData(
      ClipboardData(
        text: "إلى: $devEmail\n\nالموضوع: رسالة من تطبيق Var IPTV\n\n"
            "الاسم: ${_nameController.text}\n"
            "الإيميل: ${_emailController.text}\n\n"
            "الرسالة:\n${_messageController.text}",
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ما لكيت تطبيق بريد — تم نسخ الرسالة للحافظة.')),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تواصل معنا")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: _auto,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: "الاسم"),
                validator: (v) => (v == null || v.trim().isEmpty) ? "رجاءً أدخل اسمك" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: "البريد الإلكتروني"),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  final s = (v ?? '').trim();
                  return (s.isEmpty || !s.contains("@")) ? "إيميل غير صالح" : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _messageController,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(labelText: "الرسالة"),
                maxLines: 5,
                validator: (v) => (v == null || v.trim().isEmpty) ? "رجاءً اكتب رسالتك" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text("إرسال"),
                onPressed: _sendEmail,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
