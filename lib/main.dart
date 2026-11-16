import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PosKdsApp());
}

/// Root widget sementara untuk memverifikasi fondasi tema dan struktur proyek.
class PosKdsApp extends StatelessWidget {
  const PosKdsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS & KDS Supply Chain',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const _InitialSetupScreen(),
    );
  }
}

class _InitialSetupScreen extends StatelessWidget {
  const _InitialSetupScreen();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('POS & KDS Supply Chain')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          child: Text(
            'POS & KDS Supply Chain - Initial Setup Ready',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
        ),
      ),
    );
  }
}
