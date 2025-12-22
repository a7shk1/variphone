import 'package:flutter/material.dart';

import 'channels_screen.dart';
import 'matches_screen.dart';
import 'subscription_screen.dart';
import '../widgets/app_menu_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  final List<Widget> screens = const [
    ChannelsScreen(),
    MatchesScreen(),
    AccountScreen(), // Me (نسخة بسيطة بدون فايربيس)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppMenuDrawer(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        titleSpacing: 0,
        title: Row(
          children: [
            const DrawerButton(),
            const SizedBox(width: 6),
            Image.asset('assets/images/logo.png', height: 24),
            const SizedBox(width: 8),
            const Text(
              'VAR IP TV',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              );
            },
          ),
        ],
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8A2BE2), Color(0xFF1E1E2C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 8,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: IndexedStack(index: index, children: screens),
      ),
      bottomNavigationBar: NavigationBar(
        height: 68,
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.live_tv_outlined),
            selectedIcon: Icon(Icons.live_tv),
            label: 'Channels',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_soccer_outlined),
            selectedIcon: Icon(Icons.sports_soccer),
            label: 'Matches',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Me',
          ),
        ],
      ),
    );
  }
}

/// =====================
/// تبويب "Me" (بدون Firebase)
/// =====================
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Card(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            ListTile(
              leading: Icon(Icons.info, color: Colors.blue),
              title: Text(
                "معلومات الحساب",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text("الوضع الحالي"),
              subtitle: Text("✅ التطبيق يعمل بدون Firebase حالياً"),
            ),
            SizedBox(height: 12),
            Text(
              "ملاحظة:\n"
                  "حالياً تم إيقاف Firebase بالكامل.\n"
                  "راح نرجعه لاحقاً بعد ما نثبت تشغيل المشغل والواجهات.",
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
