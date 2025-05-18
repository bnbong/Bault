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
  bool _isAuthenticating = false;
  bool _authFailed = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // 화면 로드를 위한 지연시간
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _authenticate();
      }
    });
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _authFailed = false;
      _errorMessage = '';
    });

    try {
      final platform = Theme.of(context).platform;

      final isBiometricsAvailable =
          await ref.read(biometricProvider.notifier).isAvailable();

      if (!isBiometricsAvailable) {
        setState(() {
          _authFailed = true;
          _errorMessage = '이 기기에서는 생체인식을 사용할 수 없습니다.';
          _isAuthenticating = false;
        });
        return;
      }

      debugPrint('생체인식 인증 시작: ${platform.toString()}');

      final isAuthenticated = await ref
          .read(biometricProvider.notifier)
          .authenticate('생체인식으로 인증해주세요.');

      debugPrint('생체인식 인증 완료: $isAuthenticated');

      if (mounted) {
        if (isAuthenticated) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          setState(() {
            _authFailed = true;
            _errorMessage = '생체인식 인증에 실패했습니다.';
            _isAuthenticating = false;
          });
        }
      }
    } catch (e) {
      debugPrint('생체인식 인증 중 예외 발생: $e');
      if (mounted) {
        setState(() {
          _authFailed = true;
          _errorMessage = '인증 중 오류가 발생했습니다.';
          _isAuthenticating = false;
        });
      }
    }
  }

  void _goToPasswordLogin() {
    Navigator.pushReplacementNamed(context, '/login');
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
            Text(
              _authFailed ? _errorMessage : '생체인식으로 인증해주세요',
              style: TextStyle(
                fontSize: 18,
                color: _authFailed ? Colors.red : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_isAuthenticating)
              const CircularProgressIndicator()
            else
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _authenticate,
                    child: const Text('다시 시도'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _goToPasswordLogin,
                    child: const Text('비밀번호로 로그인'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
