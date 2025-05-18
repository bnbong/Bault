import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bault/models/sync_status.dart';
import 'package:bault/providers/sync_provider.dart';
import 'package:bault/services/sync_service_factory.dart';
import 'package:bault/providers/auth_provider.dart';

/// 동기화 설정 화면
class SyncSettingsScreen extends ConsumerWidget {
  const SyncSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('동기화 설정'),
      ),
      body: provider.Consumer<SyncProvider>(
        builder: (context, syncProvider, _) {
          return ListView(
            children: [
              _buildSyncTypeSection(context, syncProvider, ref),
              const Divider(),
              _buildSyncStatusSection(context, syncProvider),
              const Divider(),
              _buildSyncActionsSection(context, syncProvider),
              const Divider(),
              _buildBackupSection(context, syncProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSyncTypeSection(
      BuildContext context, SyncProvider syncProvider, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '동기화 방식',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSyncTypeSelector(context, syncProvider, ref),
          const SizedBox(height: 8),
          _buildSyncDescription(syncProvider.currentSyncType),
        ],
      ),
    );
  }

  Widget _buildSyncTypeSelector(
      BuildContext context, SyncProvider syncProvider, WidgetRef ref) {
    // 구글 계정 로그인 상태 확인
    final authState = ref.watch(authProvider);
    final isGoogleAccountLinked = authState.maybeWhen(
      data: (user) => user.isGoogleAccountLinked,
      orElse: () => false,
    );

    return Card(
      child: Column(
        children: [
          RadioListTile<SyncType>(
            title: const Text('로컬 저장소'),
            subtitle: const Text('기기 내부 저장소에 안전하게 보관'),
            value: SyncType.local,
            groupValue: syncProvider.currentSyncType,
            onChanged: (SyncType? value) {
              if (value != null) {
                syncProvider.changeSyncType(value);
              }
            },
          ),
          RadioListTile<SyncType>(
            title: const Text('구글 드라이브'),
            subtitle: Text(isGoogleAccountLinked
                ? '구글 드라이브를 통한 기기 간 동기화'
                : '구글 계정 연동이 필요합니다'),
            value: SyncType.googleDrive,
            groupValue: syncProvider.currentSyncType,
            onChanged: (SyncType? value) {
              if (value != null) {
                if (isGoogleAccountLinked) {
                  syncProvider.changeSyncType(value);
                } else {
                  // 구글 계정 연동 안내 메시지 표시
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          '구글 드라이브 동기화를 사용하려면 먼저 설정 > 인증 설정에서 구글 계정을 연동해주세요.'),
                      duration: Duration(seconds: 4),
                    ),
                  );
                  // 설정 화면으로 이동 질문
                  _showGoogleAuthRedirectDialog(context);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // 구글 계정 인증 화면으로 이동 확인 다이얼로그
  void _showGoogleAuthRedirectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('구글 계정 연동'),
        content: const Text(
            '구글 드라이브 동기화를 사용하려면 구글 계정 연동이 필요합니다. 인증 설정 화면으로 이동하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/auth-settings');
            },
            child: const Text('이동'),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncDescription(SyncType syncType) {
    String description;

    switch (syncType) {
      case SyncType.googleDrive:
        description = '구글 드라이브를 통해 여러 기기에서 동일한 비밀번호를 관리할 수 있습니다. '
            '모든 데이터는 암호화되어 안전하게 저장됩니다.';
        break;
      case SyncType.local:
      default:  // ignore: unreachable_switch_default
        description = '모든 데이터가 이 기기에만 저장됩니다. '
            '정기적인 백업을 통해 데이터 손실을 방지하세요.';
        break;
    }

    return Text(description, style: const TextStyle(fontSize: 14));
  }

  Widget _buildSyncStatusSection(
      BuildContext context, SyncProvider syncProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '동기화 상태',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSyncStatus(syncProvider),
          if (syncProvider.isSyncEnabled)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('자동 동기화:'),
                    const Spacer(),
                    Switch(
                      value: syncProvider.isAutoSyncEnabled,
                      onChanged: (value) {
                        syncProvider.setAutoSync(value);
                      },
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSyncStatus(SyncProvider syncProvider) {
    final bool isEnabled = syncProvider.isSyncEnabled;
    final String lastSyncTime = syncProvider.lastSyncTimeFormatted;

    IconData statusIcon;
    Color statusColor;
    String statusText;

    switch (syncProvider.lastSyncStatus) {
      case SyncStatus.success:
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        statusText = '성공';
        break;
      case SyncStatus.failed:
        statusIcon = Icons.error;
        statusColor = Colors.red;
        statusText = '실패';
        break;
      case SyncStatus.inProgress:
        statusIcon = Icons.sync;
        statusColor = Colors.blue;
        statusText = '진행 중';
        break;
      case SyncStatus.conflict:
        statusIcon = Icons.warning;
        statusColor = Colors.orange;
        statusText = '충돌 발생';
        break;
      case SyncStatus.waiting:
      case SyncStatus.notStarted:
      default:  // ignore: unreachable_switch_default
        statusIcon = Icons.info;
        statusColor = Colors.grey;
        statusText = '대기 중';
        break;
    }

    return Card(
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text('동기화 ${isEnabled ? '활성화' : '비활성화'}'),
        subtitle: Text(isEnabled
            ? '마지막 동기화: $lastSyncTime - $statusText'
            : '동기화가 활성화되지 않았습니다.'),
      ),
    );
  }

  Widget _buildSyncActionsSection(
      BuildContext context, SyncProvider syncProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '동기화 작업',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.sync),
                  label: const Text('지금 동기화'),
                  onPressed: syncProvider.isSyncEnabled
                      ? () async {
                          final result = await syncProvider.syncNow();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(result.message)),
                            );
                          }
                        }
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(
                    syncProvider.isSyncEnabled
                        ? Icons.power_settings_new
                        : Icons.power,
                  ),
                  label: Text(
                    syncProvider.isSyncEnabled ? '동기화 중지' : '동기화 시작',
                  ),
                  onPressed: () async {
                    if (syncProvider.isSyncEnabled) {
                      await syncProvider.disableSync();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('동기화가 중지되었습니다.')),
                        );
                      }
                    } else {
                      final success = await syncProvider.enableSync();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success ? '동기화가 활성화되었습니다.' : '동기화 활성화에 실패했습니다.',
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackupSection(BuildContext context, SyncProvider syncProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '백업 및 복원',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: const Text('백업 생성'),
                  subtitle: const Text('현재 데이터의 백업을 생성합니다.'),
                  onTap: syncProvider.isSyncEnabled
                      ? () async {
                          final backupId = await syncProvider.createBackup();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  backupId != null
                                      ? '백업이 생성되었습니다.'
                                      : '백업 생성에 실패했습니다.',
                                ),
                              ),
                            );
                          }
                        }
                      : null,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.restore),
                  title: const Text('백업 복원'),
                  subtitle: const Text('백업 목록에서 복원할 데이터를 선택합니다.'),
                  onTap: syncProvider.isSyncEnabled
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BackupListScreen(),
                            ),
                          );
                        }
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 백업 목록 화면
class BackupListScreen extends StatelessWidget {
  const BackupListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('백업 목록'),
      ),
      body: provider.Consumer<SyncProvider>(
        builder: (context, syncProvider, _) {
          if (syncProvider.isLoadingBackups) {
            return const Center(child: CircularProgressIndicator());
          }

          if (syncProvider.backupList.isEmpty) {
            return const Center(child: Text('백업이 없습니다.'));
          }

          return ListView.builder(
            itemCount: syncProvider.backupList.length,
            itemBuilder: (context, index) {
              final backup = syncProvider.backupList[index];
              return ListTile(
                title: Text(backup.description),
                subtitle: Text(
                  '생성일: ${_formatDateTime(backup.createdAt)} · ${_formatFileSize(backup.size)}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.restore),
                  onPressed: () =>
                      _showRestoreConfirmation(context, syncProvider, backup),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  void _showRestoreConfirmation(
    BuildContext context,
    SyncProvider syncProvider,
    BackupInfo backup,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('백업 복원'),
        content: Text(
          '${backup.description}을(를) 복원하시겠습니까?\n'
          '현재 데이터는 백업된 후 대체됩니다.',
        ),
        actions: [
          TextButton(
            child: const Text('취소'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('복원'),
            onPressed: () async {
              Navigator.pop(context);
              final result = await syncProvider.restoreBackup(backup.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result.message)),
                );
                if (result.status == SyncStatus.success) {
                  Navigator.pop(context); // 백업 목록 화면 닫기
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
