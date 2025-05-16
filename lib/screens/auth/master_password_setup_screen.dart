import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/biometric_provider.dart';

class MasterPasswordSetupScreen extends ConsumerStatefulWidget {
  const MasterPasswordSetupScreen({super.key});

  @override
  ConsumerState<MasterPasswordSetupScreen> createState() =>
      _MasterPasswordSetupScreenState();
}

class _MasterPasswordSetupScreenState
    extends ConsumerState<MasterPasswordSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _setupPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final password = _passwordController.text;
      final success =
          await ref.read(authProvider.notifier).setMasterPassword(password);

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        // 웹 환경에서는 생체인식 설정 화면으로 이동하지 않음
        if (kIsWeb) {
          debugPrint('웹 환경: 마스터 비밀번호 설정 완료 후 홈 화면으로 이동');
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          // 모바일 환경에서는 생체인식 설정 화면으로 이동
          final biometricState = ref.read(biometricProvider);
          biometricState.when(
            data: (isEnabled) async {
              final isAvailable =
                  await ref.read(biometricProvider.notifier).isAvailable();
              if (isAvailable && mounted) {
                Navigator.pushReplacementNamed(context, '/biometric-setup');
              } else if (mounted) {
                Navigator.pushReplacementNamed(context, '/home');
              }
            },
            loading: () {
              // 로딩 중인 경우 홈 화면으로 이동
              Navigator.pushReplacementNamed(context, '/home');
            },
            error: (_, __) {
              // 오류 발생 시 홈 화면으로 이동
              Navigator.pushReplacementNamed(context, '/home');
            },
          );
        }
      } else if (mounted) {
        setState(() {
          _errorMessage = '비밀번호 설정 중 오류가 발생했습니다.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('마스터 비밀번호 설정'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock,
                  size: 64,
                  color: Colors.blue,
                ),
                const SizedBox(height: 32),
                const Text(
                  '마스터 비밀번호를 설정해주세요',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '모든 비밀번호를 보호하는 마스터 비밀번호입니다.\n잊어버리면 복구할 수 없으니 주의하세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                TextFormField(
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
                  ),
                  obscureText: !_isPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력해주세요';
                    }
                    if (value.length < 6) {
                      return '비밀번호는 6자 이상이어야 합니다';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: '비밀번호 확인',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                    errorText: _errorMessage,
                  ),
                  obscureText: !_isConfirmPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 다시 입력해주세요';
                    }
                    if (value != _passwordController.text) {
                      return '비밀번호가 일치하지 않습니다';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _setupPassword,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('비밀번호 설정'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
