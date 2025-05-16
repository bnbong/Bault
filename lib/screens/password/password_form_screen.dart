import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/password_entry.dart';
import '../../providers/password_provider.dart';
import 'package:uuid/uuid.dart';

class PasswordFormScreen extends ConsumerStatefulWidget {
  final PasswordEntry? entry;

  const PasswordFormScreen({
    super.key,
    this.entry,
  });

  @override
  ConsumerState<PasswordFormScreen> createState() => _PasswordFormScreenState();
}

class _PasswordFormScreenState extends ConsumerState<PasswordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serviceNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _serviceNameController.text = widget.entry!.serviceName;
      _passwordController.text = widget.entry!.password;
    }
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? '새 비밀번호' : '비밀번호 수정'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _serviceNameController,
              decoration: const InputDecoration(
                labelText: '서비스명',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '서비스명을 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: '비밀번호',
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
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _savePassword,
              child: Text(widget.entry == null ? '저장' : '수정'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePassword() async {
    if (_formKey.currentState!.validate()) {
      final entry = PasswordEntry(
        id: widget.entry?.id ?? const Uuid().v4(),
        serviceName: _serviceNameController.text,
        password: _passwordController.text,
        createdAt: widget.entry?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        if (widget.entry == null) {
          await ref.read(passwordListProvider.notifier).addPassword(entry);
        } else {
          await ref.read(passwordListProvider.notifier).updatePassword(entry);
        }

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류가 발생했습니다: $e')),
          );
        }
      }
    }
  }
}
