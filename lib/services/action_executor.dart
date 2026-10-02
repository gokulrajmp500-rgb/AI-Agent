import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/agent_command.dart';
import 'windows_service.dart';
import 'application_service.dart';
import 'browser_tab_service.dart';
import 'web_research_service.dart';
import '../safety/safety_validator.dart';

class ActionExecutor {
  final WindowsService _windowsService;
  final ApplicationService _applicationService;
  final BrowserTabService _browserTabService;
  final WebResearchService _webResearchService;

  ActionExecutor()
    : _windowsService = WindowsService(),
      _applicationService = ApplicationService(WindowsService()),
      _browserTabService = BrowserTabService(),
      _webResearchService = WebResearchService();

  Future<String> execute(AgentCommand command, BuildContext context) async {
    if (SafetyValidator.isBlockedAction(command)) {
      return command.reason.isNotEmpty
          ? command.reason
          : 'Blocked action detected. I cannot execute that.';
    }

    if (kIsWeb && _requiresWindowsDesktop(command.action)) {
      return 'This Windows action is available in the Windows desktop app, not in a browser.';
    }

    if (command.requiresConfirmation) {
      final confirmed = await _requestConfirmation(context, command);
      if (!confirmed) {
        return 'Action cancelled.';
      }
    }

    switch (command.action) {
      case AgentAction.openApp:
        return _openApp(command.target);
      case AgentAction.openFile:
        return _openFile(command.target);
      case AgentAction.openFolder:
        return _openFolder(command.target);
      case AgentAction.openUrl:
        return _openUrl(command.target);
      case AgentAction.searchOnline:
        return _searchOnline(command.target);
      case AgentAction.showTime:
        return _showTime();
      case AgentAction.openSettings:
        return _openSettings();
      case AgentAction.openControlPanel:
        return _openControlPanel();
      case AgentAction.openTaskManager:
        return _openTaskManager();
      case AgentAction.openBrowser:
        return kIsWeb ? _openUrl('https://www.google.com') : _openBrowser();
      case AgentAction.openTab:
        return _openNewBrowserTab(command);
      case AgentAction.closeCurrentTab:
        return _closeCurrentBrowserTab();
      case AgentAction.closeTab:
        return _closeBrowserTab(command);
      case AgentAction.closeAllTabs:
        return _closeAllBrowserTabs();
      case AgentAction.switchTab:
        return _switchBrowserTab(command);
      case AgentAction.reopenTab:
        return _reopenBrowserTab();
      case AgentAction.listTabs:
        return _listBrowserTabs();
      case AgentAction.openWebsite:
        return _openWebsite(command);
      case AgentAction.searchWeb:
        return _searchWeb(command);
      case AgentAction.researchWeb:
        return _researchWeb(command);
      case AgentAction.volumeUp:
        return _changeVolume('up');
      case AgentAction.volumeDown:
        return _changeVolume('down');
      case AgentAction.muteVolume:
        return _toggleMuteVolume();
      case AgentAction.openWifiSettings:
        return _openWifiSettings();
      case AgentAction.openBluetoothSettings:
        return _openBluetoothSettings();
      case AgentAction.openWord:
        if (kIsWeb) return _openUrl('https://www.office.com/launch/word');
        return _launchApplication('winword.exe', 'Microsoft Word');
      case AgentAction.openExcel:
        if (kIsWeb) return _openUrl('https://www.office.com/launch/excel');
        return _launchApplication('excel.exe', 'Microsoft Excel');
      case AgentAction.openPowerPoint:
        if (kIsWeb) return _openUrl('https://www.office.com/launch/powerpoint');
        return _launchApplication('powerpnt.exe', 'Microsoft PowerPoint');
      case AgentAction.openGmail:
        return _openUrl('https://mail.google.com');
      case AgentAction.openDrive:
        return _openUrl('https://drive.google.com');
      case AgentAction.changeWallpaper:
        return _changeWallpaper(command.target);
      case AgentAction.createFolder:
        return _createFolder(command.target);
      case AgentAction.createFile:
        return _createFile(command.target);
      case AgentAction.restoreFile:
        return _restoreFile(command.target);
      case AgentAction.openRecycleBin:
        return _openRecycleBin();
      case AgentAction.clearRecycleBin:
        return _clearRecycleBin();
      case AgentAction.deleteAll:
        return _deleteAll(command.target);
      case AgentAction.clearAll:
        return _clearAll(command.target);
      case AgentAction.deleteFile:
      case AgentAction.deleteFolder:
        return _deleteFile(command.target);
      case AgentAction.chat:
        return command.target.isEmpty
            ? 'Sorry, I did not receive an answer.'
            : command.target;
      default:
        return 'I could not understand that command. Please try a safe Windows action.';
    }
  }

  bool _requiresWindowsDesktop(AgentAction action) {
    return const {
      AgentAction.openApp,
      AgentAction.openFile,
      AgentAction.openFolder,
      AgentAction.searchFile,
      AgentAction.deleteFile,
      AgentAction.deleteFolder,
      AgentAction.restoreFile,
      AgentAction.installApp,
      AgentAction.uninstallApp,
      AgentAction.openSettings,
      AgentAction.openControlPanel,
      AgentAction.openTaskManager,
      AgentAction.changeWallpaper,
      AgentAction.transferFile,
      AgentAction.createFolder,
      AgentAction.createFile,
      AgentAction.openRecycleBin,
      AgentAction.clearRecycleBin,
      AgentAction.deleteAll,
      AgentAction.clearAll,
      AgentAction.runSafeCommand,
      AgentAction.closeApp,
      AgentAction.openTab,
      AgentAction.closeCurrentTab,
      AgentAction.closeTab,
      AgentAction.closeAllTabs,
      AgentAction.switchTab,
      AgentAction.reopenTab,
      AgentAction.listTabs,
      AgentAction.volumeUp,
      AgentAction.volumeDown,
      AgentAction.muteVolume,
      AgentAction.openWifiSettings,
      AgentAction.openBluetoothSettings,
    }.contains(action);
  }

  Future<bool> _requestConfirmation(
    BuildContext context,
    AgentCommand command,
  ) async {
    final actionLabel = command.action.name.replaceAll('_', ' ');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm action'),
        content: Text('This will $actionLabel ${command.target}. Continue?'),
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

  Future<String> _openApp(String target) async {
    final normalized = target.trim();
    if (normalized.isEmpty) {
      return 'Please provide an app name.';
    }

    final lower = normalized.toLowerCase();
    if (lower == 'explorer.exe' || lower.contains('explorer')) {
      await _windowsService.openExplorer('');
      return 'Opened File Explorer.';
    }

    if (lower.contains('camera') ||
        lower == 'microsoft.windows.camera:' ||
        lower.contains('camera:')) {
      return _launchApplication('microsoft.windows.camera:', 'Camera');
    }

    if (await _applicationService.launchIfInstalled(normalized)) {
      return 'Opened $normalized.';
    }

    final fallbackUrl = _applicationService.getWebFallbackUrl(normalized);
    if (fallbackUrl != null && fallbackUrl.isNotEmpty) {
      final fallbackResult = await _openUrl(fallbackUrl);
      return 'Opened $normalized using online fallback. $fallbackResult';
    }

    if (lower.contains('.') || lower.startsWith('www.')) {
      return _openUrl(normalized);
    }

    try {
      await Process.start('cmd.exe', ['/c', 'start', '', normalized]);
      return 'Opened $normalized.';
    } catch (e) {
      return 'Could not open $normalized. $e';
    }
  }

  Future<String> _openFile(String target) async {
    final pathTarget = _windowsService.resolvePath(target);
    if (SafetyValidator.isBlockedPath(pathTarget)) {
      return 'That path is blocked for safety.';
    }
    if (!_windowsService.fileExists(pathTarget) &&
        !_windowsService.directoryExists(pathTarget)) {
      return 'I could not find that target path.';
    }
    try {
      await _windowsService.openExplorer(pathTarget);
      return 'Opened target: $pathTarget';
    } catch (e) {
      return 'Could not open target. $e';
    }
  }

  Future<String> _openFolder(String target) async {
    return _openFile(target);
  }

  Future<String> _openUrl(String target) async {
    final url = _buildUrl(target.trim());
    if (url.isEmpty) {
      return 'Please provide a valid URL.';
    }
    try {
      final launched = await launchUrl(
        Uri.parse(url),
        mode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
      return launched
          ? 'Opened URL.'
          : 'Could not open the URL in your browser.';
    } catch (e) {
      return 'Could not open URL. $e';
    }
  }

  String _buildUrl(String input) {
    if (input.isEmpty) {
      return '';
    }
    var url = input.trim();
    if (!url.contains('://')) {
      if (url.contains(' ')) {
        return '';
      }
      if (url.contains('.')) {
        url = 'https://$url';
      } else {
        url = 'https://$url.com';
      }
    }
    return url;
  }

  Future<String> _searchOnline(String target) async {
    final query = target.trim();
    if (query.isEmpty) {
      return 'Please provide a search query.';
    }
    final encoded = Uri.encodeComponent(query);
    return _openUrl('https://www.bing.com/search?q=$encoded');
  }

  Future<String> _showTime() async {
    final now = DateTime.now();
    return 'The current time is ${now.toLocal()}.';
  }

  Future<String> _searchWeb(AgentCommand command) async {
    if (command.query.isNotEmpty) {
      return _openUrl(
        'https://www.bing.com/search?q=${Uri.encodeComponent(command.query)}',
      );
    }
    return command.target.isNotEmpty
        ? _openUrl(
            'https://www.bing.com/search?q=${Uri.encodeComponent(command.target)}',
          )
        : 'Please provide a query for the web search.';
  }

  Future<String> _researchWeb(AgentCommand command) async {
    final query = command.query.isNotEmpty ? command.query : command.target;
    if (query.trim().isEmpty) {
      return 'Please provide a topic to research.';
    }
    return _webResearchService.research(query);
  }

  Future<String> _openWebsite(AgentCommand command) async {
    final rawTarget = command.url.isNotEmpty ? command.url : command.target;
    final target = rawTarget
        .toLowerCase()
        .replaceAll(
          RegExp(
            r'\b(website|web site|site|open|visit|go to|goto|launch|pannu|pannunga|panniten|panni|pannudhu)\b',
          ),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (target.isEmpty) {
      return 'Please provide a website to open.';
    }

    final url = _buildUrl(target);
    if (url.isEmpty) {
      final encoded = Uri.encodeComponent(target);
      return _openUrl('https://www.bing.com/search?q=$encoded');
    }

    return _openUrl(url);
  }

  Future<String> _listBrowserTabs() async {
    try {
      final available = await _browserTabService.isBrowserDebuggingAvailable();
      if (!available) {
        return 'Browser automation is unavailable. Please start Chrome or Edge with remote debugging enabled.';
      }
      final tabs = await _browserTabService.listTabs();
      if (tabs.isEmpty) {
        return 'No browser tabs were found.';
      }
      final lines = tabs.map((t) => '${t.index + 1}. ${t.title}').toList();
      return 'Open tabs:\n${lines.join('\n')}';
    } catch (e) {
      return 'Could not list browser tabs. $e';
    }
  }

  Future<String> _openNewBrowserTab(AgentCommand command) async {
    try {
      final available = await _browserTabService.isBrowserDebuggingAvailable();
      if (!available) {
        return _openBrowser();
      }
      final url = command.url.isNotEmpty ? command.url : 'about:blank';
      return _browserTabService.openNewTab(url);
    } catch (e) {
      return 'Could not open a new browser tab. $e';
    }
  }

  Future<String> _closeCurrentBrowserTab() async {
    try {
      final available = await _browserTabService.isBrowserDebuggingAvailable();
      if (!available) {
        return 'Browser debugging is unavailable. Cannot close the current tab safely.';
      }
      final tabs = await _browserTabService.listTabs();
      if (tabs.isEmpty) {
        return 'No browser tabs found.';
      }
      final activeTab = tabs.first;
      return _browserTabService.closeTab(activeTab.id);
    } catch (e) {
      return 'Could not close the current tab. $e';
    }
  }

  Future<String> _closeBrowserTab(AgentCommand command) async {
    try {
      final available = await _browserTabService.isBrowserDebuggingAvailable();
      if (!available) {
        return 'Browser debugging is unavailable. Cannot close the requested tab safely.';
      }
      final tabs = await _browserTabService.listTabs();
      final matches = tabs.where((tab) {
        final lowered = '${tab.title.toLowerCase()} ${tab.url.toLowerCase()}';
        return lowered.contains(command.target.toLowerCase());
      }).toList();

      if (matches.isEmpty) {
        return 'No matching tab was found for "${command.target}".';
      }
      if (matches.length > 1) {
        return 'Multiple tabs matched "${command.target}". Please specify the exact tab title or URL.';
      }

      return _browserTabService.closeTab(matches.first.id);
    } catch (e) {
      return 'Could not close the requested tab. $e';
    }
  }

  Future<String> _closeAllBrowserTabs() async {
    return 'Close all browser tabs is not implemented in this version. This action requires explicit browser automation setup.';
  }

  Future<String> _switchBrowserTab(AgentCommand command) async {
    try {
      final available = await _browserTabService.isBrowserDebuggingAvailable();
      if (!available) {
        return 'Browser debugging is unavailable. Cannot switch tabs safely.';
      }
      final tabs = await _browserTabService.listTabs();
      if (tabs.isEmpty) {
        return 'No browser tabs found.';
      }
      final target = command.target.toLowerCase();
      if (target.contains('next')) {
        final index = 1 < tabs.length ? 1 : 0;
        return _browserTabService.activateTab(tabs[index].id);
      }
      if (target.contains('previous') || target.contains('last tab')) {
        final index = tabs.length - 2 >= 0 ? tabs.length - 2 : tabs.length - 1;
        return _browserTabService.activateTab(tabs[index].id);
      }
      if (target.contains('first')) {
        return _browserTabService.activateTab(tabs.first.id);
      }
      if (target.contains('last')) {
        return _browserTabService.activateTab(tabs.last.id);
      }
      final match = tabs.firstWhere(
        (tab) =>
            tab.title.toLowerCase().contains(target) ||
            tab.url.toLowerCase().contains(target),
        orElse: () => tabs.first,
      );
      return _browserTabService.activateTab(match.id);
    } catch (e) {
      return 'Could not switch browser tab. $e';
    }
  }

  Future<String> _reopenBrowserTab() async {
    return 'Reopen last closed tab is not supported in this version.';
  }

  Future<String> _changeVolume(String direction) async {
    final keyCode = direction == 'up' ? 175 : 174;
    try {
      final script =
          '\$wshell = New-Object -ComObject WScript.Shell\n\$wshell.SendKeys([char]$keyCode)\n';
      final result = await Process.run('powershell.exe', [
        '-NoProfile',
        '-Command',
        script,
      ]);
      if (result.exitCode != 0) {
        return 'Could not change volume. Please open sound settings manually.';
      }
      return direction == 'up' ? 'Volume increased.' : 'Volume decreased.';
    } catch (e) {
      return 'Could not change volume. $e';
    }
  }

  Future<String> _toggleMuteVolume() async {
    try {
      final script =
          '\$wshell = New-Object -ComObject WScript.Shell\n\$wshell.SendKeys([char]173)\n';
      final result = await Process.run('powershell.exe', [
        '-NoProfile',
        '-Command',
        script,
      ]);
      if (result.exitCode != 0) {
        return 'Could not toggle mute. Please open sound settings manually.';
      }
      return 'Toggled mute/unmute.';
    } catch (e) {
      return 'Could not toggle mute. $e';
    }
  }

  Future<String> _openWifiSettings() async {
    try {
      await Process.start('cmd.exe', [
        '/c',
        'start',
        'ms-settings:network-wifi',
      ]);
      return 'Opened Wi-Fi settings.';
    } catch (e) {
      return 'Could not open Wi-Fi settings. $e';
    }
  }

  Future<String> _openBluetoothSettings() async {
    try {
      await Process.start('cmd.exe', ['/c', 'start', 'ms-settings:bluetooth']);
      return 'Opened Bluetooth settings.';
    } catch (e) {
      return 'Could not open Bluetooth settings. $e';
    }
  }

  Future<String> _openSettings() async {
    try {
      await Process.start('cmd.exe', ['/c', 'start', 'ms-settings:']);
      return 'Opened Windows Settings.';
    } catch (e) {
      return 'Could not open Settings. $e';
    }
  }

  Future<String> _openControlPanel() async {
    try {
      await Process.start('control.exe', []);
      return 'Opened Control Panel.';
    } catch (e) {
      return 'Could not open Control Panel. $e';
    }
  }

  Future<String> _openTaskManager() async {
    try {
      await Process.start('taskmgr.exe', []);
      return 'Opened Task Manager.';
    } catch (e) {
      return 'Could not open Task Manager. $e';
    }
  }

  Future<String> _openBrowser() async {
    try {
      await Process.start('cmd.exe', ['/c', 'start', '']);
      return 'Opened browser.';
    } catch (e) {
      return 'Could not open browser. $e';
    }
  }

  Future<String> _launchApplication(String executable, String label) async {
    try {
      await Process.start('cmd.exe', ['/c', 'start', '', executable]);
      return 'Opened $label.';
    } catch (e) {
      return 'Could not open $label. $e';
    }
  }

  Future<String> _changeWallpaper(String target) async {
    final trimmedTarget = target.trim();
    if (trimmedTarget.isEmpty) {
      try {
        await Process.start('cmd.exe', [
          '/c',
          'start',
          'ms-settings:personalization-background',
        ]);
        return 'Opened wallpaper settings.';
      } catch (e) {
        return 'Could not open wallpaper settings. $e';
      }
    }

    final pathTarget = _windowsService.normalizePath(trimmedTarget);
    if (SafetyValidator.isBlockedPath(pathTarget)) {
      return 'That path is blocked for safety.';
    }

    final file = File(pathTarget);
    if (!file.existsSync()) {
      return 'The selected wallpaper file was not found.';
    }

    try {
      final script =
          '''
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
  [DllImport("user32.dll", SetLastError=true)]
  public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@;
[Wallpaper]::SystemParametersInfo(20, 0, "$pathTarget", 3)
''';
      await Process.run('powershell.exe', ['-NoProfile', '-Command', script]);
      return 'Wallpaper changed successfully.';
    } catch (e) {
      return 'Could not change wallpaper. $e';
    }
  }

  Future<String> _createFolder(String target) async {
    final rawTarget = target.trim();
    final pathTarget = rawTarget.isEmpty
        ? _windowsService.resolvePath('', defaultToNewFolder: true)
        : _windowsService.resolvePath(rawTarget, defaultToNewFolder: true);
    if (pathTarget.isEmpty) {
      return 'Please provide a valid folder path.';
    }
    if (SafetyValidator.isBlockedPath(pathTarget)) {
      return 'That path is blocked for safety.';
    }
    try {
      final directory = Directory(pathTarget);
      if (directory.existsSync()) {
        return 'That folder already exists: $pathTarget';
      }
      directory.createSync(recursive: true);
      return 'Created folder: $pathTarget';
    } catch (e) {
      return 'Could not create folder. $e';
    }
  }

  Future<String> _createFile(String target) async {
    final rawTarget = target.trim();
    final pathTarget = rawTarget.isEmpty
        ? _windowsService.resolvePath('', defaultToNewFolder: false)
        : _windowsService.resolvePath(rawTarget, defaultToNewFolder: false);
    if (pathTarget.isEmpty) {
      return 'Please provide a valid file path.';
    }
    if (SafetyValidator.isBlockedPath(pathTarget)) {
      return 'That path is blocked for safety.';
    }
    try {
      final file = File(pathTarget);
      if (file.existsSync()) {
        return 'That file already exists: $pathTarget';
      }
      final parent = file.parent;
      if (!parent.existsSync()) {
        parent.createSync(recursive: true);
      }
      file.createSync(recursive: false);
      return 'Created file: $pathTarget';
    } catch (e) {
      return 'Could not create file. $e';
    }
  }

  Future<String> _restoreFile(String target) async {
    final itemName = target.trim();
    if (itemName.isEmpty) {
      return 'Please provide a deleted item name to restore.';
    }

    try {
      final shellName = itemName.replaceAll("'", "''");
      final script =
          """
\$shell = New-Object -ComObject Shell.Application
\$recycle = \$shell.Namespace(0x0a)
foreach (\$item in \$recycle.Items()) {
  if (\$item.Name.ToLower() -eq '$shellName'.ToLower()) {
    \$item.InvokeVerb('restore')
    exit 0
  }
}
exit 1
""";

      final result = await Process.run('powershell.exe', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        script,
      ]);
      if (result.exitCode == 0) {
        return 'Restored item: $itemName';
      }
      return 'I could not find that item in the Recycle Bin.';
    } catch (e) {
      return 'Restore failed. $e';
    }
  }

  Future<String> _openRecycleBin() async {
    try {
      await Process.start('explorer.exe', ['shell:RecycleBinFolder']);
      return 'Opened Recycle Bin.';
    } catch (e) {
      return 'Could not open Recycle Bin. $e';
    }
  }

  Future<String> _clearRecycleBin() async {
    try {
      final result = await Process.run('powershell.exe', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        'Clear-RecycleBin -Force',
      ]);
      if (result.exitCode == 0) {
        return 'Cleared the Recycle Bin.';
      }
      return 'Could not clear the Recycle Bin. ${result.stderr}';
    } catch (e) {
      return 'Could not clear the Recycle Bin. $e';
    }
  }

  Future<String> _deleteAll(String target) async {
    final pathTarget = target.trim().isEmpty
        ? Directory.current.path
        : _windowsService.normalizePath(target);
    if (SafetyValidator.isBlockedPath(pathTarget)) {
      return 'That path is blocked for safety.';
    }

    final directory = Directory(pathTarget);
    if (!directory.existsSync()) {
      return 'Folder not found: $pathTarget';
    }

    try {
      final items = directory.listSync(recursive: false, followLinks: false);
      if (items.isEmpty) {
        return 'The folder is already empty: $pathTarget';
      }

      for (final item in items) {
        if (item is File) {
          item.deleteSync();
        } else if (item is Directory) {
          item.deleteSync(recursive: true);
        }
      }

      return 'Deleted all items in: $pathTarget';
    } catch (e) {
      return 'Could not delete all items. $e';
    }
  }

  Future<String> _clearAll(String target) async => _deleteAll(target);

  Future<String> _deleteFile(String target) async {
    final pathTarget = _windowsService.normalizePath(target);
    if (SafetyValidator.isBlockedPath(pathTarget)) {
      return 'That path is blocked for safety.';
    }
    final file = File(pathTarget);
    final directory = Directory(pathTarget);
    if (!file.existsSync() && !directory.existsSync()) {
      return 'That file or folder was not found.';
    }
    try {
      if (file.existsSync()) {
        file.deleteSync();
        return 'Deleted file: $pathTarget';
      }
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
        return 'Deleted folder: $pathTarget';
      }
      return 'Could not delete the target.';
    } catch (e) {
      return 'Could not delete the target. $e';
    }
  }
}
