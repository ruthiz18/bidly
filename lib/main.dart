import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'repositories/auth_repository.dart';
import 'repositories/bid_repository.dart';
import 'repositories/item_repository.dart';
import 'state/auction_state.dart';
import 'screens/auth_gate.dart';
import 'state/auth_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState(AuthRepository())),
        ChangeNotifierProvider(create: (_) => AuctionState(ItemRepository(), BidRepository())),
      ],
      child: const BidlyApp(),
    ),
  );
}

class BidlyApp extends StatelessWidget {
  const BidlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bidly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}
