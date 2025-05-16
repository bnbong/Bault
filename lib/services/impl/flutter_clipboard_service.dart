import 'package:flutter/services.dart';
import '../clipboard_service.dart';

class FlutterClipboardService implements ClipboardService {
  @override
  Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  @override
  Future<String?> getFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }
}
