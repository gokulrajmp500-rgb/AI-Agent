import 'dart:io';
import 'package:path/path.dart' as path;

class WindowsService {
  Future<bool> isWindows() async => Platform.isWindows;

  String normalizePath(String input) {
    var result = input.trim();
    result = result.replaceAll('/', '\\');
    if (result.startsWith('\\\\')) {
      return result;
    }
    if (result.length >= 2 && result[1] == ':') {
      return path.normalize(result);
    }
    return result;
  }

  String resolvePath(String input, {bool defaultToNewFolder = false}) {
    final raw = input.trim().replaceAll('"', '').replaceAll("'", '');
    if (raw.isEmpty) {
      if (defaultToNewFolder) {
        final userProfile = Platform.environment['USERPROFILE'] ?? r'C:\Users\Default';
        return path.join(userProfile, 'Desktop', 'NewFolder');
      }
      return '';
    }

    final normalized = normalizePath(raw);
    final lower = normalized.toLowerCase();
    final userProfile = Platform.environment['USERPROFILE'] ?? r'C:\Users\Default';
    final commonFolders = {
      'desktop': path.join(userProfile, 'Desktop'),
      'documents': path.join(userProfile, 'Documents'),
      'downloads': path.join(userProfile, 'Downloads'),
      'pictures': path.join(userProfile, 'Pictures'),
      'music': path.join(userProfile, 'Music'),
      'videos': path.join(userProfile, 'Videos'),
      'home': userProfile,
    };

    final alias = commonFolders.keys.firstWhere(
      (key) => lower == key || lower.endsWith('\\$key') || lower.endsWith('/$key'),
      orElse: () => '',
    );

    if (alias.isNotEmpty) {
      final base = commonFolders[alias]!;
      if (defaultToNewFolder && !lower.contains('\\') && !lower.contains('/')) {
        return path.join(base, 'NewFolder');
      }
      return base;
    }

    if (lower == 'desktop' || lower.endsWith('\\desktop') || lower.endsWith('/desktop')) {
      final base = path.join(userProfile, 'Desktop');
      return defaultToNewFolder ? path.join(base, 'NewFolder') : base;
    }

    if (raw.startsWith('~')) {
      final home = Platform.environment['USERPROFILE'] ?? '';
      if (home.isNotEmpty) {
        return path.join(home, raw.substring(1).replaceAll('/', '\\'));
      }
    }

    if (normalized.length >= 2 && normalized[1] == ':') {
      return path.normalize(normalized);
    }

    final isSimpleName = !normalized.contains('\\') && !normalized.contains('/') && !normalized.startsWith('.');
    if (defaultToNewFolder || isSimpleName) {
      final base = path.join(userProfile, 'Desktop');
      return path.join(base, normalized);
    }

    return normalized;
  }

  bool fileExists(String filePath) => File(filePath).existsSync();

  bool directoryExists(String directoryPath) => Directory(directoryPath).existsSync();

  Future<void> openExplorer(String target) async {
    if (target.trim().isEmpty) {
      await Process.start('explorer.exe', []);
      return;
    }
    await Process.start('explorer.exe', [target]);
  }

  Future<bool> launchProcess(String executable, List<String> arguments) async {
    await Process.start(executable, arguments);
    return true;
  }
}
