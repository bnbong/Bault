import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../providers/biometric_provider.dart';

class BiometricSettingsScreen extends ConsumerWidget {
  const BiometricSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biometricState = ref.watch(biometricProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('생체인식 설정'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: kIsWeb
            // 웹 환경에서는 생체인식을 사용할 수 없음을 안내
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.no_accounts,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '웹 환경에서는 생체인식 기능을 사용할 수 없습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '모바일 앱에서 사용해주세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('확인'),
                  ),
                ],
              )
            // 모바일 환경에서는 정상적으로 설정 화면 표시
            : biometricState.when(
                data: (isEnabled) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SwitchListTile(
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
                    const SizedBox(height: 16),
                    if (!isEnabled)
                      ElevatedButton(
                        onPressed: () async {
                          await ref
                              .read(biometricProvider.notifier)
                              .enrollBiometrics();
                        },
                        child: const Text('생체인식 등록하기'),
                      ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('오류가 발생했습니다: $error'),
                ),
              ),
      ),
    );
  }
}
