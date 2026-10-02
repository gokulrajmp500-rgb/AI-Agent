import 'windows_service.dart';

class ApplicationService {
  final WindowsService _windowsService;

  ApplicationService(this._windowsService);

  Future<bool> launchIfInstalled(String appName) async {
    final normalized = appName.trim().toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }

    final knownExecutables = {
      'chrome': 'chrome.exe',
      'google chrome': 'chrome.exe',
      'edge': 'msedge.exe',
      'microsoft edge': 'msedge.exe',
      'firefox': 'firefox.exe',
      'notepad': 'notepad.exe',
      'calculator': 'calc.exe',
      'word': 'winword.exe',
      'microsoft word': 'winword.exe',
      'excel': 'excel.exe',
      'microsoft excel': 'excel.exe',
      'powerpoint': 'powerpnt.exe',
      'microsoft powerpoint': 'powerpnt.exe',
      'vscode': 'code.exe',
      'visual studio code': 'code.exe',
      'code': 'code.exe',
      'whatsapp': 'WhatsApp.exe',
      'whatsapp desktop': 'WhatsApp.exe',
    };

    for (final entry in knownExecutables.entries) {
      if (normalized == entry.key || normalized.contains(entry.key)) {
        try {
          await _windowsService.launchProcess('cmd.exe', ['/c', 'start', '', entry.value]);
          return true;
        } catch (_) {
          return false;
        }
      }
    }

    return false;
  }

  String? getWebFallbackUrl(String appName) {
    final normalized = appName.trim().toLowerCase();
    final knownFallbacks = {
      'whatsapp': 'https://web.whatsapp.com',
      'whatsapp desktop': 'https://web.whatsapp.com',
      'telegram': 'https://web.telegram.org',
      'teams': 'https://teams.microsoft.com',
      'zoom': 'https://zoom.us',
    };
    for (final entry in knownFallbacks.entries) {
      if (normalized == entry.key || normalized.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }
}
