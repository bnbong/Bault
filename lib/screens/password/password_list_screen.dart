import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../models/password_entry.dart';
import '../../providers/password_provider.dart';
import 'password_detail_screen.dart';
import 'password_form_screen.dart';

class PasswordListScreen extends ConsumerStatefulWidget {
  const PasswordListScreen({super.key});

  @override
  ConsumerState<PasswordListScreen> createState() => _PasswordListScreenState();
}

class _PasswordListScreenState extends ConsumerState<PasswordListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _deletePassword(String id) async {
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

    if (confirmed == true) {
      ref.read(passwordListProvider.notifier).deletePassword(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final passwordsState = ref.watch(passwordListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('비밀번호 목록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: '비밀번호 검색',
                hintText: '서비스명으로 검색',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: passwordsState.when(
              data: (passwords) {
                final filteredList = _searchQuery.isEmpty
                    ? passwords
                    : passwords
                        .where((p) => p.serviceName
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()))
                        .toList();

                if (filteredList.isEmpty) {
                  return const Center(
                    child: Text('저장된 비밀번호가 없습니다.'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final password = filteredList[index];
                    return Slidable(
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (_) => _deletePassword(password.id),
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: '삭제',
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.key),
                        title: Text(password.serviceName),
                        subtitle:
                            Text('마지막 수정: ${password.updatedAt.toString()}'),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/password-view-auth',
                            arguments: password,
                          );
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) => Center(
                child: Text('오류가 발생했습니다: $error'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'password_list_fab',
        onPressed: () {
          Navigator.pushNamed(context, '/password-add-auth');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
