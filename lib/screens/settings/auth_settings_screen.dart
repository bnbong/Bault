import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/biometric_provider.dart';

class AuthSettingsScreen extends ConsumerWidget {
  const AuthSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final biometricState = ref.watch(biometricProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('인증 설정'),
      ),
      body: authState.when(
        data: (user) {
          return ListView(
            children: [
              // 마스터 비밀번호 변경
              ListTile(
                title: const Text('마스터 비밀번호 변경'),
                leading: const Icon(Icons.lock),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(context, '/change-password');
                },
              ),
              const Divider(),

              // 생체인식 설정
              biometricState.when(
                data: (isEnabled) => SwitchListTile(
                  title: const Text('생체인식 사용'),
                  subtitle: const Text('앱 실행 시 생체인식으로 인증합니다.'),
                  value: isEnabled,
                  onChanged: (value) async {
                    if (value) {
                      await ref
                          .read(biometricProvider.notifier)
                          .enrollBiometrics();
                    } else {
                      await ref
                          .read(biometricProvider.notifier)
                          .removeBiometrics();
                    }
                  },
                ),
                loading: () => const ListTile(
                  title: Text('생체인식 설정'),
                  subtitle: Text('로딩 중...'),
                ),
                error: (error, _) => ListTile(
                  title: const Text('생체인식 설정'),
                  subtitle: Text('오류: $error'),
                ),
              ),
              const Divider(),

              // 구글 계정 연동
              ListTile(
                title: Text(
                  user.isGoogleAccountLinked ? '구글 계정 연동 해제' : '구글 계정 연동',
                ),
                leading: const Icon(Icons.account_circle),
                subtitle: Text(
                  user.isGoogleAccountLinked
                      ? '구글 계정 연동이 활성화되어 있습니다.'
                      : '구글 계정으로 로그인하여 데이터를 백업할 수 있습니다.',
                ),
                trailing: user.isGoogleAccountLinked
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.chevron_right),
                onTap: () async {
                  if (user.isGoogleAccountLinked) {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('구글 계정 연동 해제'),
                        content: const Text(
                          '구글 계정 연동을 해제하시겠습니까? '
                          '구글 드라이브에 저장된 데이터는 유지되지만, '
                          '앱에서는 더 이상 접근할 수 없게 됩니다.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('취소'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('연동 해제'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await ref.read(authProvider.notifier).signOutFromGoogle();
                    }
                  } else {
                    await ref.read(authProvider.notifier).signInWithGoogle();
                  }
                },
              ),
              const Divider(),

              // 앱 데이터 초기화
              ListTile(
                title: const Text('앱 데이터 초기화'),
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('앱 데이터 초기화'),
                      content: const Text(
                        '앱의 모든 데이터를 삭제하시겠습니까? '
                        '이 작업은 되돌릴 수 없습니다.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('취소'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('초기화',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    // TODO: 앱 데이터 초기화 구현
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('데이터가 초기화되었습니다.')),
                    );
                  }
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('오류가 발생했습니다: $error'),
        ),
      ),
    );
  }
}
