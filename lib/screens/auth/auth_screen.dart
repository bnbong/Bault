import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/biometric_provider.dart';
import '../../models/auth_type.dart';

class AuthScreen extends ConsumerStatefulWidget {
  final AuthScreenType authType;
  final VoidCallback? onAuthSuccess;
  final String? nextRoute;

  const AuthScreen({
    super.key,
    this.authType = AuthScreenType.appStart,
    this.onAuthSuccess,
    this.nextRoute,
  });

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lockoutUntil;
  bool _isBiometricsAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    // 생체인식 가능 여부 확인
    if (!kIsWeb) {
      _isBiometricsAvailable =
          await ref.read(biometricProvider.notifier).isAvailable();
    }

    // 로그인 제한 확인
    final isLocked = await ref.read(authProvider.notifier).isLoginLocked();
    if (isLocked) {
      final lockoutTime =
          await ref.read(authProvider.notifier).getLoginLockoutUntil();
      if (mounted) {
        setState(() {
          _lockoutUntil = lockoutTime;
        });
      }
    }

    // 생체인식 자동 시도 (웹 환경 아니고, 생체인식 사용 가능한 경우만)
    if (!kIsWeb && _isBiometricsAvailable) {
      final biometricState = ref.read(biometricProvider);
      biometricState.when(
        data: (isEnabled) {
          if (isEnabled) {
            _authenticateWithBiometrics();
          }
        },
        loading: () {},
        error: (_, __) {},
      );
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    // 웹 환경에서는 생체인식 시도하지 않음
    if (kIsWeb) return;

    try {
      String reason;
      switch (widget.authType) {
        case AuthScreenType.appStart:
          reason = '앱에 로그인하려면 생체인식으로 인증해주세요.';
          break;
        case AuthScreenType.passwordAdd:
          reason = '비밀번호를 추가하려면 생체인식으로 인증해주세요.';
          break;
        case AuthScreenType.passwordView:
          reason = '비밀번호를 확인하려면 생체인식으로 인증해주세요.';
          break;
      }

      final isAuthenticated =
          await ref.read(biometricProvider.notifier).authenticate(reason);

      if (isAuthenticated && mounted) {
        debugPrint('생체인식 인증 성공: ${widget.authType} 인증 완료');
        _handleAuthSuccess();
      }
    } catch (e) {
      debugPrint('생체인식 인증 중 오류 발생: $e');
      // 오류 발생 시 마스터 비밀번호로 인증하도록 안내
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('생체인식을 사용할 수 없습니다. 마스터 비밀번호를 입력해주세요.')),
        );
      }
    }
  }

  Future<void> _verifyPassword() async {
    if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = '비밀번호를 입력해주세요.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final isLocked = await ref.read(authProvider.notifier).isLoginLocked();
    if (isLocked) {
      final lockoutTime =
          await ref.read(authProvider.notifier).getLoginLockoutUntil();
      setState(() {
        _isLoading = false;
        _lockoutUntil = lockoutTime;
        _errorMessage = '로그인이 제한되었습니다. 나중에 다시 시도해주세요.';
      });
      return;
    }

    final password = _passwordController.text;
    debugPrint('비밀번호 검증 시도: $password');

    final isValid =
        await ref.read(authProvider.notifier).verifyMasterPassword(password);

    debugPrint('비밀번호 검증 결과: $isValid');

    setState(() {
      _isLoading = false;
    });

    if (isValid && mounted) {
      debugPrint('비밀번호 인증 성공: ${widget.authType} 인증 완료');
      _handleAuthSuccess();
    } else if (mounted) {
      final attempts = await ref.read(authProvider.notifier).getLoginAttempts();
      setState(() {
        _errorMessage = '비밀번호가 올바르지 않습니다. ($attempts/5)';
      });

      // 로그인 제한 확인
      final isNowLocked = await ref.read(authProvider.notifier).isLoginLocked();
      if (isNowLocked) {
        final lockoutTime =
            await ref.read(authProvider.notifier).getLoginLockoutUntil();
        setState(() {
          _lockoutUntil = lockoutTime;
        });
      }
    }
  }

  void _handleAuthSuccess() {
    // 인증 유형에 따라 다른 동작 수행
    if (widget.onAuthSuccess != null) {
      // 콜백이 제공된 경우 콜백 실행
      widget.onAuthSuccess!();
    } else if (widget.nextRoute != null) {
      // 다음 라우트가 제공된 경우 해당 라우트로 이동
      Navigator.pushReplacementNamed(context, widget.nextRoute!);
    } else {
      // 기본 동작: 앱 인증 후 홈 화면으로 이동
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  String _formatRemainingTime() {
    if (_lockoutUntil == null) return '';

    final now = DateTime.now();
    if (now.isAfter(_lockoutUntil!)) {
      // 락아웃 시간이 지났으면 메시지 초기화
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _lockoutUntil = null;
          _errorMessage = null;
        });
      });
      return '';
    }

    final difference = _lockoutUntil!.difference(now);
    final minutes = difference.inMinutes;
    final seconds = difference.inSeconds % 60;
    return '$minutes분 $seconds초';
  }

  String _getAuthTitle() {
    switch (widget.authType) {
      case AuthScreenType.appStart:
        return '앱에 로그인하세요';
      case AuthScreenType.passwordAdd:
        return '비밀번호 추가를 위해 인증하세요';
      case AuthScreenType.passwordView:
        return '비밀번호 확인을 위해 인증하세요';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.authType != AuthScreenType.appStart
          ? AppBar(
              title: Text(_getAuthTitle()),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock,
                size: 64,
                color: Colors.blue,
              ),
              const SizedBox(height: 32),
              Text(
                _getAuthTitle(),
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: '마스터 비밀번호',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  errorText: _errorMessage,
                ),
                obscureText: !_isPasswordVisible,
                onSubmitted: (_) => _verifyPassword(),
                enabled: _lockoutUntil == null,
              ),
              const SizedBox(height: 24),
              if (_lockoutUntil != null) ...[
                Text(
                  '로그인이 제한되었습니다. 남은 시간: ${_formatRemainingTime()}',
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: _isLoading || _lockoutUntil != null
                    ? null
                    : _verifyPassword,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('로그인'),
              ),

              // 웹 환경이 아니고 생체인식 사용 가능한 경우에만 생체인식 버튼 표시
              if (!kIsWeb && _isBiometricsAvailable) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('생체인식으로 로그인'),
                  onPressed: _authenticateWithBiometrics,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
