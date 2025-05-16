import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/biometric_provider.dart';
import 'auth/auth_screen.dart';
import 'auth/master_password_setup_screen.dart';
import 'password/password_list_screen.dart';
import 'password/password_form_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (user) {
        // 마스터 비밀번호가 설정되어 있지 않으면 초기 설정 화면
        if (!user.isMasterPasswordSet) {
          return const MasterPasswordSetupScreen();
        }

        // 마스터 비밀번호가 설정되어 있으면 인증 화면
        return const AuthScreen();
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Text('오류가 발생했습니다: $error'),
        ),
      ),
    );
  }
}

// 홈 화면 - 인증 성공 후 보여질 화면
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: const PasswordListScreen(),
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_screen_fab',
        onPressed: () {
          Navigator.pushNamed(context, '/add-password');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
