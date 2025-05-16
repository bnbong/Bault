import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class MasterPasswordChangeScreen extends ConsumerStatefulWidget {
  const MasterPasswordChangeScreen({super.key});

  @override
  ConsumerState<MasterPasswordChangeScreen> createState() =>
      _MasterPasswordChangeScreenState();
}

class _MasterPasswordChangeScreenState
    extends ConsumerState<MasterPasswordChangeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;

    final success = await ref
        .read(authProvider.notifier)
        .changeMasterPassword(currentPassword, newPassword);

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 변경되었습니다.')),
      );
      Navigator.pop(context);
    } else if (mounted) {
      setState(() {
        _errorMessage = '현재 비밀번호가 올바르지 않습니다.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('비밀번호 변경'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            TextFormField(
              controller: _currentPasswordController,
              decoration: InputDecoration(
                labelText: '현재 비밀번호',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isCurrentPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                    });
                  },
                ),
              ),
              obscureText: !_isCurrentPasswordVisible,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '현재 비밀번호를 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newPasswordController,
              decoration: InputDecoration(
                labelText: '새 비밀번호',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isNewPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _isNewPasswordVisible = !_isNewPasswordVisible;
                    });
                  },
                ),
              ),
              obscureText: !_isNewPasswordVisible,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '새 비밀번호를 입력해주세요';
                }
                if (value.length < 8) {
                  return '비밀번호는 8자 이상이어야 합니다';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: '새 비밀번호 확인',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                ),
              ),
              obscureText: !_isConfirmPasswordVisible,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '새 비밀번호를 다시 입력해주세요';
                }
                if (value != _newPasswordController.text) {
                  return '새 비밀번호가 일치하지 않습니다';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _changePassword,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('비밀번호 변경'),
            ),
          ],
        ),
      ),
    );
  }
}
