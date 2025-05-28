import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'routes.dart';
import 'services/service_locator.dart';
import 'providers/auth_provider.dart';
import 'providers/sync_provider.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/auth/master_password_setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ServiceLocator().initialize();
  runApp(
    ProviderScope(
      child: provider_pkg.MultiProvider(
        providers: [
          provider_pkg.ChangeNotifierProvider(create: (_) => SyncProvider()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Bault',
      theme: ThemeData(
        fontFamily: 'NotoSansKR',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        fontFamily: 'NotoSansKR',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      routes: getAppRoutes(),
      home: FutureBuilder<bool>(
        future: ref.read(authProvider.notifier).isMasterPasswordSet(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final hasMasterPassword = snapshot.data ?? false;
          if (hasMasterPassword) {
            return const AuthScreen();
          } else {
            return const MasterPasswordSetupScreen();
          }
        },
      ),
    );
  }
}
