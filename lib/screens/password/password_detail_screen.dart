import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/password_entry.dart';
import '../../providers/password_provider.dart';
import '../../services/service_locator.dart';
import 'password_form_screen.dart';

class PasswordDetailScreen extends ConsumerWidget {
  final PasswordEntry entry;

  const PasswordDetailScreen({
    super.key,
    required this.entry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(entry.serviceName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PasswordFormScreen(entry: entry),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('비밀번호 삭제'),
                  content: const Text('이 비밀번호를 삭제하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('삭제'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                await ref
                    .read(passwordListProvider.notifier)
                    .deletePassword(entry.id);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: const Text('비밀번호'),
              subtitle: Text(entry.password),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () async {
                  await ref
                      .read(passwordListProvider.notifier)
                      .copyPasswordToClipboard(entry.password);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('비밀번호가 복사되었습니다')),
                    );
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('생성일'),
              subtitle: Text(entry.createdAt.toString()),
            ),
            ListTile(
              title: const Text('수정일'),
              subtitle: Text(entry.updatedAt.toString()),
            ),
          ],
        ),
      ),
    );
  }
}
