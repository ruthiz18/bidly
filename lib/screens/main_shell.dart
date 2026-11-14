import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/my_bids_state.dart';
import 'home_screen.dart';
import 'my_bids_screen.dart';
import 'my_sales_screen.dart';
import 'outbid_alert_host.dart';
import 'profile_screen.dart';

/// Signed-in shell: bottom navigation between Home, My Bids and My Sales,
/// with the outbid alert listener sitting above all of them.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final outbidCount = context.select<MyBidsState, int>((s) => s.outbid.length);
    return OutbidAlertHost(
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: const [
            HomeScreen(),
            MyBidsScreen(),
            MySalesScreen(),
            ProfileScreen(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: [
            const BottomNavigationBarItem(
                icon: Icon(Icons.storefront_outlined), label: 'Auctions'),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: outbidCount > 0,
                label: Text('$outbidCount'),
                child: const Icon(Icons.gavel),
              ),
              label: 'My Bids',
            ),
            const BottomNavigationBarItem(
                icon: Icon(Icons.sell_outlined), label: 'My Sales'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
