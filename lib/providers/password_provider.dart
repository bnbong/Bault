import 'package:flutter/foundation.dart';
import '../models/password_entry.dart';
import '../services/password_service.dart';
import '../services/clipboard_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/service_locator.dart';

class PasswordProvider extends ChangeNotifier {
  final PasswordService _passwordService;
  final ClipboardService _clipboardService;
  List<PasswordEntry> _passwords = [];
  bool _isLoading = false;
  String? _error;

  PasswordProvider({
    required PasswordService passwordService,
    required ClipboardService clipboardService,
  })  : _passwordService = passwordService,
        _clipboardService = clipboardService;

  List<PasswordEntry> get passwords => _passwords;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPasswords() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _passwords = await _passwordService.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPassword(PasswordEntry entry) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _passwordService.add(entry);
      await loadPasswords();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updatePassword(PasswordEntry entry) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _passwordService.update(entry);
      await loadPasswords();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deletePassword(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _passwordService.delete(id);
      await loadPasswords();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> searchPasswords(String query) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _passwords = await _passwordService.search(query);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> copyPasswordToClipboard(String password) async {
    try {
      await _clipboardService.copyToClipboard(password);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}

final passwordListProvider = StateNotifierProvider<PasswordListNotifier,
    AsyncValue<List<PasswordEntry>>>((ref) {
  return PasswordListNotifier();
});

class PasswordListNotifier
    extends StateNotifier<AsyncValue<List<PasswordEntry>>> {
  PasswordListNotifier() : super(const AsyncValue.loading()) {
    _loadPasswords();
  }

  Future<void> _loadPasswords() async {
    try {
      final passwords = await ServiceLocator().passwordService.getAll();
      state = AsyncValue.data(passwords);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addPassword(PasswordEntry password) async {
    try {
      await ServiceLocator().passwordService.add(password);
      await _loadPasswords();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updatePassword(PasswordEntry password) async {
    try {
      await ServiceLocator().passwordService.update(password);
      await _loadPasswords();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deletePassword(String id) async {
    try {
      await ServiceLocator().passwordService.delete(id);
      await _loadPasswords();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<List<PasswordEntry>> searchPasswords(String query) async {
    try {
      return await ServiceLocator().passwordService.search(query);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> copyPasswordToClipboard(String password) async {
    try {
      await ServiceLocator().clipboardService.copyToClipboard(password);
    } catch (e) {
      rethrow;
    }
  }
}
