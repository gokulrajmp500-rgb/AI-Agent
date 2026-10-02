import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class SystemActions {
  /// Executes the requested action and shows confirmation for destructive tasks.
  Future<String> execute(Map<String, dynamic> actionData, BuildContext context) async {
    final action = (actionData['action'] ?? 'unknown').toString().toLowerCase();
    final target = (actionData['target'] ?? '').toString().trim();
    final requiresConfirmation = actionData['requires_confirmation'] == true;

    final targetOptionalActions = <String>{
      'show_time',
      'open_settings',
      'open_control_panel',
      'open_task_manager',
      'open_browser',
      'open_word',
      'open_excel',
      'open_powerpoint',
      'open_gmail',
      'open_drive',
      'change_wallpaper',
      'chat',
    };

    if (target.isEmpty && !targetOptionalActions.contains(action)) {
      return 'Please provide a valid target.';
    }

    if (action == 'delete_file' ||
        action == 'delete_folder' ||
        action == 'restore_file' ||
        action == 'install_app' ||
        action == 'uninstall_app' ||
        action == 'close_app' ||
        action == 'run_safe_command') {
      if (requiresConfirmation) {
        final confirmed = await confirmAction(context, action, target);
        if (!confirmed) {
          return 'Action cancelled.';
        }
      }
    }

    switch (action) {
      case 'open_file':
        return openFile(target);
      case 'open_folder':
        return openFolder(target);
      case 'open_app':
        return openApp(target);
      case 'open_url':
        return openUrl(target);
      case 'search_online':
        return searchOnline(target);
      case 'close_app':
        return closeApp(target);
      case 'create_folder':
        return createFolder(target);
      case 'search_file':
        return searchFile(target);
      case 'delete_file':
        return deleteFile(target);
      case 'delete_folder':
        return deleteFolder(target);
      case 'restore_file':
        return restoreFile(target);
      case 'install_app':
        return installApp(target);
      case 'uninstall_app':
        return uninstallApp(target);
      case 'show_time':
        return showTime();
      case 'open_settings':
        return openSettings();
      case 'open_control_panel':
        return openControlPanel();
      case 'open_task_manager':
        return openTaskManager();
      case 'open_browser':
        return openBrowser();
      case 'open_word':
        return openWord();
      case 'open_excel':
        return openExcel();
      case 'open_powerpoint':
        return openPowerPoint();
      case 'open_gmail':
        return openGmail();
      case 'open_drive':
        return openDrive();
      case 'change_wallpaper':
        return changeWallpaper();
      case 'transfer_file':
        return transferFile(target);
      case 'create_file':
        return createFile(target);
      case 'run_safe_command':
        return runSafeCommand(target);
      case 'chat':
        return target.isEmpty ? 'Sorry, I did not receive an answer.' : target;
      default:
        return 'I could not understand that command. Please try a safe Windows action.';
    }
  }

  /// Shows a confirmation dialog for destructive actions.
  Future<bool> confirmAction(BuildContext context, String action, String target) async {
    final label = _actionLabel(action);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm action'),
        content: Text(
          'This will $label "$target". Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    return confirmed == true;
  }

  String _actionLabel(String action) {
    switch (action) {
      case 'delete_file':
      case 'delete_folder':
        return 'delete';
      case 'restore_file':
        return 'restore';
      case 'install_app':
        return 'install';
      case 'uninstall_app':
        return 'uninstall';
      case 'close_app':
        return 'close';
      case 'create_folder':
        return 'create';
      default:
        return action;
    }
  }

  /// Opens a file or folder in Windows Explorer.
  Future<String> openFile(String target) async {
    try {
      final resolvedTarget = _resolveTarget(target);
      if (resolvedTarget.isEmpty) {
        return 'I could not understand the target path.';
      }
      if (isBlockedPath(resolvedTarget)) {
        return 'That path is blocked for safety.';
      }

      final file = File(resolvedTarget);
      final directory = Directory(resolvedTarget);
      if (file.existsSync()) {
        await Process.start('explorer.exe', [resolvedTarget]);
        return 'Opened file: $resolvedTarget';
      }
      if (directory.existsSync()) {
        await Process.start('explorer.exe', [resolvedTarget]);
        return 'Opened folder: $resolvedTarget';
      }

      await Process.start('explorer.exe', [resolvedTarget]);
      return 'Opened: $resolvedTarget';
    } catch (e) {
      return 'I could not open that target. $e';
    }
  }

  /// Opens an application by name or executable path.
  Future<String> openApp(String appName) async {
    try {
      final normalizedName = appName.trim();
      if (normalizedName.isEmpty) {
        return 'Please provide an app name.';
      }

      final lower = normalizedName.toLowerCase();
      if (lower == 'this pc' || lower == 'file explorer' || lower.contains('explorer')) {
        await Process.start('explorer.exe', []);
        return 'Opened File Explorer.';
      }
      if (lower.contains('settings')) {
        return openSettings();
      }
      if (lower.contains('control panel')) {
        return openControlPanel();
      }
      if (lower.contains('task manager') || lower.contains('taskmgr')) {
        return openTaskManager();
      }
      if (lower.contains('chrome') || lower.contains('edge') || lower.contains('firefox') || lower.contains('browser')) {
        if (await _launchKnownBrowser(lower)) {
          return 'Opened browser.';
        }
        return openBrowser();
      }
      if (lower.contains('word')) {
        return openWord();
      }
      if (lower.contains('excel')) {
        return openExcel();
      }
      if (lower.contains('powerpoint') || lower.contains('ppt')) {
        return openPowerPoint();
      }
      if (lower.contains('gmail')) {
        return openGmail();
      }
      if (lower.contains('drive')) {
        return openDrive();
      }

      final executablePath = _resolveTarget(normalizedName);
      if (executablePath.toLowerCase().endsWith('.exe') && File(executablePath).existsSync()) {
        await Process.start(executablePath, []);
        return 'Opened: $normalizedName';
      }

      if (await _launchInstalledApp(normalizedName)) {
        return 'Opened installed app: $normalizedName';
      }

      await Process.start('cmd.exe', ['/c', 'start', '', normalizedName]);
      return 'Opened app: $normalizedName';
    } catch (e) {
      return 'I could not open that app. $e';
    }
  }

  /// Closes an app or process using taskkill.
  Future<String> closeApp(String appName) async {
    try {
      final normalizedName = appName.trim();
      if (normalizedName.isEmpty) {
        return 'Please provide an app name to close.';
      }

      final processName = normalizedName.toLowerCase().endsWith('.exe')
          ? normalizedName
          : '$normalizedName.exe';

      final result = await Process.run('taskkill', ['/im', processName, '/f']);
      if (result.exitCode == 0) {
        return 'Closed app: $normalizedName';
      }

      return 'Could not close the app. Taskkill returned exit code ${result.exitCode}.';
    } catch (e) {
      return 'Close app failed. $e';
    }
  }

  /// Creates a folder at the requested target path.
  Future<String> createFolder(String target) async {
    try {
      final resolvedTarget = _resolveTarget(target);
      if (resolvedTarget.isEmpty) {
        return 'Please provide a valid folder path.';
      }
      if (isBlockedPath(resolvedTarget)) {
        return 'That path is blocked for safety.';
      }

      final directory = Directory(resolvedTarget);
      if (directory.existsSync()) {
        return 'That folder already exists: $resolvedTarget';
      }

      directory.createSync(recursive: true);
      return 'Created folder: $resolvedTarget';
    } catch (e) {
      return 'Could not create folder. $e';
    }
  }

  /// Searches for a file name recursively from a start location.
  Future<String> searchFile(String target) async {
    try {
      final parts = target.split(RegExp(r'\s+in\s+', caseSensitive: false));
      final query = parts.first.trim();
      final location = parts.length > 1 ? parts.last.trim() : Platform.environment['USERPROFILE'] ?? 'C:\\Users';
      final resolvedLocation = _resolveTarget(location);

      if (resolvedLocation.isEmpty) {
        return 'I could not understand the search location.';
      }
      if (isBlockedPath(resolvedLocation)) {
        return 'I cannot search inside protected system folders.';
      }

      final directory = Directory(resolvedLocation);
      if (!directory.existsSync()) {
        return 'The search location was not found.';
      }

      final matches = <String>[];
      await for (final entity in directory.list(recursive: true, followLinks: false)) {
        if (entity is File && entity.path.toLowerCase().contains(query.toLowerCase())) {
          matches.add(entity.path);
          if (matches.length >= 10) {
            break;
          }
        }
      }

      if (matches.isEmpty) {
        return 'No files matched "$query" in $resolvedLocation.';
      }

      return 'Found ${matches.length} match(es):\n${matches.join('\n')}';
    } catch (e) {
      return 'Search failed. $e';
    }
  }

  /// Moves a file or folder to the recycle bin using PowerShell.
  Future<String> deleteFile(String target) async {
    try {
      final resolvedTarget = _resolveTarget(target);
      if (resolvedTarget.isEmpty) {
        return 'Please provide a valid target.';
      }
      if (isBlockedPath(resolvedTarget)) {
        return 'That path is blocked for safety.';
      }

      final file = File(resolvedTarget);
      final directory = Directory(resolvedTarget);
      if (!file.existsSync() && !directory.existsSync()) {
        return 'That file or folder was not found.';
      }

      final escaped = resolvedTarget.replaceAll("'", "''");
      final script = file.existsSync()
          ? "[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null; [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile('$escaped', 'OnlyErrorDialogs', 'SendToRecycleBin')"
          : "[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null; [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory('$escaped', 'OnlyErrorDialogs', 'SendToRecycleBin')";

      await Process.run('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', script]);
      return 'Moved to the recycle bin: $resolvedTarget';
    } catch (e) {
      return 'Deletion failed. $e';
    }
  }

  /// Attempts to restore a deleted item from the recycle bin by name.
  Future<String> restoreFile(String target) async {
    try {
      final name = target.split(Platform.pathSeparator).last.trim();
      final escaped = name.replaceAll("'", "''");
      final script = """
\$shell = New-Object -ComObject Shell.Application
\$recycle = \$shell.Namespace(0x0a)
foreach (\$item in \$recycle.Items()) {
  if (\$item.Name -eq '$escaped') {
    \$item.InvokeVerb('restore')
    exit 0
  }
}
exit 1
""";

      final result = await Process.run('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', script]);
      if (result.exitCode == 0) {
        return 'Restored item: $name';
      }
      return 'I could not find that item in the recycle bin.';
    } catch (e) {
      return 'Restore failed. $e';
    }
  }

  /// Installs an app using Winget after user confirmation.
  Future<String> installApp(String appName) async {
    try {
      final normalized = appName.trim();
      if (normalized.isEmpty) {
        return 'Please provide an app name.';
      }
      final result = await Process.run('winget', ['install', normalized, '--accept-source-agreements', '--accept-package-agreements']);
      if (result.exitCode == 0) {
        return 'Install command completed for $normalized.';
      }
      return 'Installation failed. Winget returned exit code ${result.exitCode}.';
    } catch (e) {
      return 'Installation failed. $e';
    }
  }

  /// Uninstalls an app using Winget.
  Future<String> uninstallApp(String appName) async {
    try {
      final normalized = appName.trim();
      if (normalized.isEmpty) {
        return 'Please provide an app name.';
      }
      final result = await Process.run('winget', ['uninstall', normalized, '--accept-source-agreements', '--accept-package-agreements']);
      if (result.exitCode == 0) {
        return 'Uninstall command completed for $normalized.';
      }
      return 'Uninstall failed. Winget returned exit code ${result.exitCode}.';
    } catch (e) {
      return 'Uninstall failed. $e';
    }
  }

  /// Opens a URL in the default browser.
  Future<String> openUrl(String targetUrl) async {
    try {
      final url = targetUrl.trim();
      if (url.isEmpty) {
        return 'Please provide a valid URL or link.';
      }

      final normalized = _normalizeUrl(url);
      await Process.start('cmd.exe', ['/c', 'start', '', normalized]);
      return 'Opened browser link: $normalized';
    } catch (e) {
      return 'Could not open the link. $e';
    }
  }

  Future<String> openFolder(String target) async {
    return openFile(target);
  }

  Future<String> deleteFolder(String target) async {
    return deleteFile(target);
  }

  Future<String> openBrowser() async {
    try {
      await Process.start('cmd.exe', ['/c', 'start', '']);
      return 'Opened your default browser.';
    } catch (e) {
      return 'Could not open browser. $e';
    }
  }

  Future<String> showTime() async {
    final now = DateTime.now();
    return 'The current time is ${now.toLocal()}.';
  }

  Future<String> openSettings() async {
    try {
      await Process.start('cmd.exe', ['/c', 'start', 'ms-settings:']);
      return 'Opened Windows Settings.';
    } catch (e) {
      return 'Could not open Windows Settings. $e';
    }
  }

  Future<String> openControlPanel() async {
    try {
      await Process.start('control.exe', []);
      return 'Opened Control Panel.';
    } catch (e) {
      return 'Could not open Control Panel. $e';
    }
  }

  Future<String> openTaskManager() async {
    try {
      await Process.start('taskmgr.exe', []);
      return 'Opened Task Manager.';
    } catch (e) {
      return 'Could not open Task Manager. $e';
    }
  }

  Future<String> openWord() async {
    try {
      await Process.start('winword.exe', []);
      return 'Opened Microsoft Word.';
    } catch (e) {
      return 'Could not open Microsoft Word. $e';
    }
  }

  Future<String> openExcel() async {
    try {
      await Process.start('excel.exe', []);
      return 'Opened Microsoft Excel.';
    } catch (e) {
      return 'Could not open Microsoft Excel. $e';
    }
  }

  Future<String> openPowerPoint() async {
    try {
      await Process.start('powerpnt.exe', []);
      return 'Opened Microsoft PowerPoint.';
    } catch (e) {
      return 'Could not open Microsoft PowerPoint. $e';
    }
  }

  Future<String> openGmail() async {
    return openUrl('https://mail.google.com');
  }

  Future<String> openDrive() async {
    return openUrl('https://drive.google.com');
  }

  Future<String> changeWallpaper() async {
    try {
      await Process.start('cmd.exe', ['/c', 'start', 'ms-settings:personalization-background']);
      return 'Opened wallpaper settings. You can change your wallpaper there.';
    } catch (e) {
      return 'Could not open wallpaper settings. $e';
    }
  }

  Future<String> createFile(String target) async {
    try {
      final resolvedTarget = _resolveTarget(target);
      if (resolvedTarget.isEmpty) {
        return 'Please provide a valid file path.';
      }
      if (isBlockedPath(resolvedTarget)) {
        return 'That path is blocked for safety.';
      }

      final file = File(resolvedTarget);
      if (file.existsSync()) {
        return 'That file already exists: $resolvedTarget';
      }

      file.createSync(recursive: true);
      return 'Created file: $resolvedTarget';
    } catch (e) {
      return 'Could not create file. $e';
    }
  }

  Future<String> transferFile(String target) async {
    try {
      final lower = target.toLowerCase();
      final separator = lower.contains(' to ') ? ' to ' : lower.contains(' -> ') ? ' -> ' : ''; 
      if (separator.isEmpty) {
        return 'Please provide a source and destination using "to" or "->".';
      }
      final parts = target.split(RegExp(r'\s+to\s+|\s+->\s+', caseSensitive: false));
      if (parts.length != 2) {
        return 'Please provide a source and destination in the format "source to destination".';
      }

      final sourcePath = _resolveTarget(parts.first.trim());
      final destinationPath = _resolveTarget(parts.last.trim());
      if (sourcePath.isEmpty || destinationPath.isEmpty) {
        return 'Please provide both source and destination paths.';
      }
      if (isBlockedPath(sourcePath) || isBlockedPath(destinationPath)) {
        return 'That path is blocked for safety.';
      }

      final sourceFile = File(sourcePath);
      if (!sourceFile.existsSync()) {
        return 'The source file was not found.';
      }

      final destinationDir = Directory(path.dirname(destinationPath));
      if (!destinationDir.existsSync()) {
        destinationDir.createSync(recursive: true);
      }

      await sourceFile.copy(destinationPath);
      return 'Copied file to $destinationPath';
    } catch (e) {
      return 'Could not transfer file. $e';
    }
  }

  Future<String> runSafeCommand(String commandText) async {
    try {
      final command = commandText.trim();
      if (command.isEmpty) {
        return 'Please provide a command to run.';
      }

      final safeCommands = <String>{'dir', 'whoami', 'ipconfig', 'systeminfo', 'tasklist', 'ver'};
      final firstToken = command.split(RegExp(r'\s+')).first.toLowerCase();
      if (!safeCommands.contains(firstToken)) {
        return 'That command is not allowed for safety reasons. Allowed commands include dir, whoami, ipconfig, systeminfo, tasklist, ver.';
      }

      final result = await Process.run('cmd.exe', ['/c', command]);
      if (result.exitCode == 0) {
        final output = result.stdout.toString().trim();
        return output.isEmpty ? 'Command completed successfully.' : output;
      }
      return 'Command failed with exit code ${result.exitCode}: ${result.stderr}';
    } catch (e) {
      return 'Could not execute command safely. $e';
    }
  }

  /// Searches online for the requested query.
  Future<String> searchOnline(String query) async {
    try {
      final cleaned = query.trim();
      if (cleaned.isEmpty) {
        return 'Please provide something to search for online.';
      }
      final encoded = Uri.encodeComponent(cleaned);
      final searchUrl = 'https://www.bing.com/search?q=$encoded';
      await Process.start('cmd.exe', ['/c', 'start', '', searchUrl]);
      return 'Searching online for: $cleaned';
    } catch (e) {
      return 'Could not perform the online search. $e';
    }
  }

  Future<bool> _launchInstalledApp(String appName) async {
    try {
      final programFiles = Platform.environment['ProgramFiles'] ?? 'C:\\Program Files';
      final programFilesX86 = Platform.environment['ProgramFiles(x86)'] ?? 'C:\\Program Files (x86)';
      final candidates = <String>[
        '$programFiles\\$appName\\$appName.exe',
        '$programFilesX86\\$appName\\$appName.exe',
        '$programFiles\\$appName.exe',
        '$programFilesX86\\$appName.exe',
      ];

      for (final candidate in candidates) {
        if (File(candidate).existsSync()) {
          await Process.start(candidate, []);
          return true;
        }
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _launchKnownBrowser(String lower) async {
    final knownPaths = <String>[
      'Google\\Chrome\\Application\\chrome.exe',
      'Microsoft\\Edge\\Application\\msedge.exe',
      'Mozilla Firefox\\firefox.exe',
      'BraveSoftware\\Brave-Browser\\Application\\brave.exe',
      'Opera\\launcher.exe',
    ];

    final programFiles = Platform.environment['ProgramFiles'] ?? 'C:\\Program Files';
    final programFilesX86 = Platform.environment['ProgramFiles(x86)'] ?? 'C:\\Program Files (x86)';
    final roots = <String>[programFiles, programFilesX86];

    for (final root in roots) {
      for (final relative in knownPaths) {
        final candidate = path.join(root, relative);
        if (File(candidate).existsSync()) {
          await Process.start(candidate, []);
          return true;
        }
      }
    }

    if (lower.contains('chrome')) {
      return _launchExecutableIfAvailable('chrome.exe');
    }
    if (lower.contains('edge')) {
      return _launchExecutableIfAvailable('msedge.exe');
    }
    if (lower.contains('firefox')) {
      return _launchExecutableIfAvailable('firefox.exe');
    }
    return false;
  }

  Future<bool> _launchExecutableIfAvailable(String executable) async {
    try {
      final result = await Process.run('cmd.exe', ['/c', 'where', executable]);
      final pathResult = result.stdout.toString().trim();
      if (result.exitCode == 0 && pathResult.isNotEmpty) {
        final exePath = pathResult.split(RegExp(r'\\r?\\n')).first.trim();
        if (exePath.isNotEmpty && File(exePath).existsSync()) {
          await Process.start(exePath, []);
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  String _normalizeUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return 'https://$trimmed';
  }

  /// Normalizes the target into a Windows-friendly path when possible.
  String resolveTarget(String rawPath) {
    final value = rawPath.trim().replaceAll('"', '').replaceAll("'", '');
    if (value.isEmpty) {
      return '';
    }

    final normalized = value.replaceAll('/', '\\');
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

    if (commonFolders.containsKey(lower)) {
      return path.join(commonFolders[lower]!, 'NewFolder');
    }

    for (final entry in commonFolders.entries) {
      final key = entry.key;
      if (lower == key || lower.endsWith('\\$key') || lower.endsWith('/$key')) {
        return entry.value;
      }
    }

    if (value.startsWith('~')) {
      final home = Platform.environment['USERPROFILE'] ?? '';
      return home.isNotEmpty ? '$home${value.substring(1)}' : value;
    }

    final hasDrive = normalized.length >= 2 && normalized[1] == ':';
    final isSimpleName = !normalized.contains('\\') && !normalized.contains('/') && !hasDrive && !normalized.startsWith('.');
    if (isSimpleName) {
      return path.join(userProfile, 'Desktop', normalized);
    }

    return normalized;
  }

  String _resolveTarget(String rawPath) => resolveTarget(rawPath);

  /// Hard-blocks system-critical routes regardless of the requested action.
  bool isBlockedPath(String target) {
    final normalized = target.trim().toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }

    final blockedPrefixes = <String>[
      'c:\\windows',
      'c:\\program files\\windows',
      'c:\\program files (x86)\\windows',
      'c:\\windows\\system32',
      'c:\\system volume information',
    ];

    return blockedPrefixes.any(normalized.startsWith);
  }
}

Future<String> handleAction(Map<String, dynamic> actionData, BuildContext context) async {
  final actions = SystemActions();
  return actions.execute(actionData, context);
}
