import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/biometric_provider.dart';

class BiometricAuthScreen extends ConsumerStatefulWidget {
  const BiometricAuthScreen({super.key});

  @override
  ConsumerState<BiometricAuthScreen> createState() =>
      _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends ConsumerState<BiometricAuthScreen> {
  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    final isAuthenticated = await ref
        .read(biometricProvider.notifier)
        .authenticate('생체인식으로 인증해주세요.');

    if (isAuthenticated && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.fingerprint,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text(
              '생체인식으로 인증해주세요',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _authenticate,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
