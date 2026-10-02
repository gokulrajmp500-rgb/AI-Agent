import '../agent_service.dart' as ollama_agent;
import '../models/agent_command.dart';
import '../safety/safety_validator.dart';

class AgentService {
  final ollama_agent.AgentService _ollamaService;

  AgentService({ollama_agent.AgentService? ollamaService})
    : _ollamaService = ollamaService ?? ollama_agent.AgentService();

  Future<AgentCommand> getCommand(String userInput) async {
    final direct = _resolveDirectCommand(userInput);
    if (direct != null) {
      return direct;
    }

    final parsed = await _ollamaService.getAction(userInput);
    if (parsed['action'] == 'error') {
      final errorMessage = parsed['target']?.toString().trim();
      return AgentCommand(
        action: AgentAction.chat,
        target: errorMessage?.isNotEmpty == true
            ? errorMessage!
            : 'I could not process that request. Please try again.',
        reason: 'Model request failed',
      );
    }

    final command = AgentCommand.fromMap(parsed);

    if (SafetyValidator.isBlockedAction(command)) {
      return const AgentCommand(
        action: AgentAction.unknown,
        target: '',
        reason: 'Blocked or unsupported action detected.',
      );
    }

    final requiresConfirmation =
        command.requiresConfirmation ||
        SafetyValidator.requiresConfirmation(command);
    return command.copyWith(requiresConfirmation: requiresConfirmation);
  }

  AgentCommand? _resolveDirectCommand(String userCommand) {
    final text = userCommand
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\b(the|my)\b'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (text.isEmpty) {
      return null;
    }

    if (RegExp(
      r'^(hi|hello|hey|good morning|good afternoon|good evening)[!. ]*$',
    ).hasMatch(text)) {
      return const AgentCommand(
        action: AgentAction.chat,
        target:
            'Hello! I am NEXORA. I can help with Windows tasks, files, web searches, and everyday questions.',
        reason: 'Offline greeting',
      );
    }

    if (text.contains('what can you do') ||
        text.contains('what can you help') ||
        text == 'help') {
      return const AgentCommand(
        action: AgentAction.chat,
        target:
            'I can open apps and folders, search the web, manage supported Windows tasks, and answer everyday questions. Deleting, installing, and other sensitive actions require confirmation.',
        reason: 'Offline capabilities response',
      );
    }

    if (text.contains('what time is it') ||
        text == 'what time' ||
        text == 'current time') {
      return const AgentCommand(
        action: AgentAction.showTime,
        reason: 'Offline time intent',
      );
    }

    if (RegExp(
      r'\b(open|launch|start)\s+(?:the\s+)?(power\s*point|powerpoint|ppt)\b',
    ).hasMatch(text)) {
      return const AgentCommand(
        action: AgentAction.openPowerPoint,
        reason: 'Offline PowerPoint intent',
      );
    }

    if (RegExp(r'\b(open|show|browse)\b').hasMatch(text) &&
        RegExp(
          r'\b(downloads?|download folder|download directory)\b',
        ).hasMatch(text)) {
      return const AgentCommand(
        action: AgentAction.openFolder,
        target: 'downloads',
        reason: 'Offline Downloads folder intent',
      );
    }

    final directBrowser = [
      'open browser',
      'launch browser',
      'open web browser',
      'open internet',
    ];

    if (directBrowser.any(text.contains)) {
      return const AgentCommand(
        action: AgentAction.openBrowser,
        target: '',
        requiresConfirmation: false,
        reason: 'Direct browser intent',
      );
    }

    if (text.contains('website') ||
        text.contains('site') ||
        text.contains('www.') ||
        text.contains('.com') ||
        text.contains('.net') ||
        text.contains('.org')) {
      final target = _extractWebsiteTarget(userCommand);
      if (target.isNotEmpty) {
        return AgentCommand(
          action: AgentAction.openWebsite,
          target: target,
          requiresConfirmation: false,
          reason: 'Direct website open intent',
        );
      }
    }

    if (text.contains('open whatsapp') ||
        text.contains('launch whatsapp') ||
        text.contains('whatsapp open')) {
      return const AgentCommand(
        action: AgentAction.openApp,
        target: 'whatsapp',
        requiresConfirmation: false,
        reason: 'Direct WhatsApp intent',
      );
    }
    if (text.contains('open chrome') ||
        text.contains('launch chrome') ||
        text.contains('chrome open') ||
        text.contains('chrome launch')) {
      return const AgentCommand(
        action: AgentAction.openApp,
        target: 'chrome',
        requiresConfirmation: false,
        reason: 'Direct Chrome intent',
      );
    }
    if (text.contains('open edge') ||
        text.contains('launch edge') ||
        text.contains('edge open')) {
      return const AgentCommand(
        action: AgentAction.openApp,
        target: 'msedge',
        requiresConfirmation: false,
        reason: 'Direct Edge intent',
      );
    }
    if (text.contains('open firefox') ||
        text.contains('launch firefox') ||
        text.contains('firefox open')) {
      return const AgentCommand(
        action: AgentAction.openApp,
        target: 'firefox',
        requiresConfirmation: false,
        reason: 'Direct Firefox intent',
      );
    }
    if (text.contains('open camera') ||
        text.contains('launch camera') ||
        text.contains('camera open')) {
      return const AgentCommand(
        action: AgentAction.openApp,
        target: 'microsoft.windows.camera:',
        requiresConfirmation: false,
        reason: 'Direct Camera intent',
      );
    }
    if (text.contains('open powerpoint') ||
        text.contains('launch powerpoint') ||
        text.contains('open ppt') ||
        text.contains('ppt open')) {
      return const AgentCommand(
        action: AgentAction.openPowerPoint,
        requiresConfirmation: false,
        reason: 'Direct PowerPoint intent',
      );
    }
    if (text.contains('open excel') || text.contains('excel open')) {
      return const AgentCommand(
        action: AgentAction.openExcel,
        requiresConfirmation: false,
        reason: 'Direct Excel intent',
      );
    }
    if (text.contains('open word') || text.contains('word open')) {
      return const AgentCommand(
        action: AgentAction.openWord,
        requiresConfirmation: false,
        reason: 'Direct Word intent',
      );
    }
    if (text.contains('open gmail') || text.contains('gmail open')) {
      return const AgentCommand(
        action: AgentAction.openGmail,
        requiresConfirmation: false,
        reason: 'Direct Gmail intent',
      );
    }
    if (text.contains('open drive') || text.contains('drive open')) {
      return const AgentCommand(
        action: AgentAction.openDrive,
        requiresConfirmation: false,
        reason: 'Direct Drive intent',
      );
    }
    if (text.contains('open settings') ||
        text.contains('launch settings') ||
        text.contains('settings open')) {
      return const AgentCommand(
        action: AgentAction.openSettings,
        requiresConfirmation: false,
        reason: 'Direct Settings intent',
      );
    }
    if (text.contains('open control panel') ||
        text.contains('control panel open')) {
      return const AgentCommand(
        action: AgentAction.openControlPanel,
        requiresConfirmation: false,
        reason: 'Direct Control Panel intent',
      );
    }
    if (text.contains('open task manager') ||
        text.contains('launch task manager') ||
        text.contains('open taskmgr') ||
        text.contains('task manager open')) {
      return const AgentCommand(
        action: AgentAction.openTaskManager,
        requiresConfirmation: false,
        reason: 'Direct Task Manager intent',
      );
    }
    if (text.contains('change wallpaper') ||
        text.contains('set wallpaper') ||
        text.contains('wallpaper change') ||
        text.contains('wallpaper open') ||
        text.contains('background change') ||
        text.contains('change background')) {
      return const AgentCommand(
        action: AgentAction.changeWallpaper,
        requiresConfirmation: false,
        reason: 'Direct Wallpaper intent',
      );
    }
    if (text.contains('open this pc') ||
        text.contains('open computer') ||
        text.contains('show this pc')) {
      return const AgentCommand(
        action: AgentAction.openApp,
        target: 'explorer.exe',
        requiresConfirmation: false,
        reason: 'Direct File Explorer intent',
      );
    }
    if (text.contains('open file explorer') ||
        text.contains('open explorer') ||
        text.contains('open windows explorer')) {
      return const AgentCommand(
        action: AgentAction.openApp,
        target: 'explorer.exe',
        requiresConfirmation: false,
        reason: 'Direct File Explorer intent',
      );
    }
    if (text.contains('open tab') ||
        text.contains('new tab') ||
        text.contains('open another tab')) {
      return const AgentCommand(
        action: AgentAction.openTab,
        requiresConfirmation: false,
        reason: 'Direct browser tab open intent',
      );
    }
    if (text.contains('reduce sound') ||
        text.contains('volume down') ||
        text.contains('decrease volume') ||
        text.contains('lower volume')) {
      return const AgentCommand(
        action: AgentAction.volumeDown,
        requiresConfirmation: false,
        reason: 'Direct volume down intent',
      );
    }
    if (text.contains('increase sound') ||
        text.contains('volume up') ||
        text.contains('raise volume')) {
      return const AgentCommand(
        action: AgentAction.volumeUp,
        requiresConfirmation: false,
        reason: 'Direct volume up intent',
      );
    }
    if (text.contains('mute sound') ||
        text.contains('mute') ||
        text.contains('sound off') ||
        text.contains('unmute sound')) {
      return const AgentCommand(
        action: AgentAction.muteVolume,
        requiresConfirmation: false,
        reason: 'Direct mute intent',
      );
    }
    if (text.contains('wifi settings') ||
        text.contains('open wifi') ||
        text.contains('wifi on') ||
        text.contains('wifi off')) {
      return const AgentCommand(
        action: AgentAction.openWifiSettings,
        requiresConfirmation: false,
        reason: 'Direct Wi-Fi settings intent',
      );
    }
    if (text.contains('bluetooth settings') ||
        text.contains('open bluetooth') ||
        text.contains('bluetooth on') ||
        text.contains('bluetooth off')) {
      return const AgentCommand(
        action: AgentAction.openBluetoothSettings,
        requiresConfirmation: false,
        reason: 'Direct Bluetooth settings intent',
      );
    }
    if (text.contains('close this tab') ||
        text.contains('current tab close') ||
        text.contains('close current tab')) {
      return const AgentCommand(
        action: AgentAction.closeCurrentTab,
        requiresConfirmation: false,
        reason: 'Direct close current tab intent',
      );
    }
    if (text.contains('close all tabs') ||
        text.contains('ella tabs close') ||
        text.contains('close all browser tabs')) {
      return const AgentCommand(
        action: AgentAction.closeAllTabs,
        requiresConfirmation: true,
        confirmationReason: 'Close all browser tabs',
        reason: 'Direct close all tabs intent',
      );
    }
    if ((text.contains('close tab') && text.contains('youtube')) ||
        text.contains('youtube tab close')) {
      return const AgentCommand(
        action: AgentAction.closeTab,
        target: 'youtube',
        requiresConfirmation: false,
        reason: 'Direct close YouTube tab intent',
      );
    }
    if (text.contains('switch to next tab') ||
        text.contains('next tab') ||
        text.contains('switch tab')) {
      return const AgentCommand(
        action: AgentAction.switchTab,
        requiresConfirmation: false,
        reason: 'Direct switch tab intent',
      );
    }
    if (text.contains('list tabs') ||
        text.contains('open tabs list') ||
        text.contains('show open tabs')) {
      return const AgentCommand(
        action: AgentAction.listTabs,
        requiresConfirmation: false,
        reason: 'Direct list tabs intent',
      );
    }

    return null;
  }

  String _extractWebsiteTarget(String userCommand) {
    var normalized = userCommand.toLowerCase();
    normalized = normalized.replaceAll(
      RegExp(
        r'\b(pannu|pannunga|panniten|panni|pannudhu|open|launch|go to|goto|visit|show|website|site|web site|website la|site la|open website|open site)\b',
      ),
      '',
    );
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9\.\s\-]'), ' ');
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalized;
  }
}
