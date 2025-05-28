import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider_pkg;
import '../../providers/auth_provider.dart';
import '../../providers/biometric_provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/sync_service_factory.dart';

class AuthSettingsScreen extends ConsumerWidget {
  const AuthSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final biometricState = ref.watch(biometricProvider);
    final syncProvider = provider_pkg.Provider.of<SyncProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('인증 설정'),
      ),
      body: authState == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
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

                // 동기화 설정
                ListTile(
                  title: const Text('데이터 동기화 설정'),
                  leading: const Icon(Icons.sync),
                  subtitle: Text(
                    syncProvider.isSyncEnabled
                        ? '동기화가 활성화되어 있습니다. (${syncProvider.currentSyncType == SyncType.googleDrive ? '구글 드라이브' : '로컬 저장소'})'
                        : '데이터 동기화 설정을 구성합니다.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pushNamed(context, '/sync-settings');
                  },
                ),
                const Divider(),

                // 구글 계정 연동
                ListTile(
                  title: Text(
                    authState.isGoogleAccountLinked
                        ? '구글 계정 연동 해제'
                        : '구글 계정 연동',
                  ),
                  leading: const Icon(Icons.account_circle),
                  subtitle: Text(
                    authState.isGoogleAccountLinked
                        ? '구글 계정 연동이 활성화되어 있습니다.'
                        : '구글 계정으로 로그인하여 데이터를 백업할 수 있습니다.',
                  ),
                  trailing: authState.isGoogleAccountLinked
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.chevron_right),
                  onTap: () async {
                    debugPrint(
                        '구글 계정 연동 버튼 클릭: ${authState.isGoogleAccountLinked}');

                    if (authState.isGoogleAccountLinked) {
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
                        await ref
                            .read(authProvider.notifier)
                            .signOutFromGoogle();

                        // 구글 드라이브 동기화 중이었다면 로컬 동기화로 변경
                        if (syncProvider.currentSyncType ==
                            SyncType.googleDrive) {
                          await syncProvider.changeSyncType(SyncType.local);
                        }
                      }
                    } else {
                      // 시뮬레이터/웹에서 실행 중인지 확인
                      if (Theme.of(context).platform == TargetPlatform.iOS &&
                          !await ref
                              .read(authProvider.notifier)
                              .isGoogleAuthAvailable()) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'iOS 시뮬레이터에서는 구글 계정 연동이 제한됩니다. 실제 기기에서 사용해주세요.'),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                        return;
                      }

                      // 구글 로그인 시도
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('구글 계정 연동 중...'),
                              duration: Duration(seconds: 1)),
                        );
                      }

                      final success = await ref
                          .read(authProvider.notifier)
                          .signInWithGoogle();

                      if (context.mounted) {
                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('구글 계정 연동에 실패했습니다.')),
                          );
                          return;
                        }
                      }

                      // 구글 로그인 성공 시 동기화 방식 선택 제안
                      if (success && context.mounted) {
                        _showSyncTypeSelectionDialog(context, syncProvider);
                      }
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
            ),
    );
  }

  // 구글 계정 연동 후 동기화 방식 선택 다이얼로그
  void _showSyncTypeSelectionDialog(
      BuildContext context, SyncProvider syncProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('구글 드라이브 동기화'),
        content: const Text(
          '구글 계정 연동이 성공했습니다. 구글 드라이브를 이용하여 데이터를 동기화하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('나중에'),
          ),
          TextButton(
            onPressed: () async {
              await syncProvider.changeSyncType(SyncType.googleDrive);
              await syncProvider.enableSync();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('구글 드라이브 동기화가 활성화되었습니다.')),
                );
              }
            },
            child: const Text('활성화'),
          ),
        ],
      ),
    );
  }
}
