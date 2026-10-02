enum AgentAction {
  chat,
  openApp,
  openFile,
  openFolder,
  searchFile,
  deleteFile,
  deleteFolder,
  restoreFile,
  installApp,
  uninstallApp,
  showTime,
  openSettings,
  openControlPanel,
  openTaskManager,
  openBrowser,
  openWord,
  openExcel,
  openPowerPoint,
  openGmail,
  openDrive,
  changeWallpaper,
  transferFile,
  createFolder,
  createFile,
  openRecycleBin,
  clearRecycleBin,
  deleteAll,
  clearAll,
  runSafeCommand,
  closeApp,
  searchOnline,
  openUrl,
  openTab,
  closeCurrentTab,
  closeTab,
  closeAllTabs,
  switchTab,
  reopenTab,
  listTabs,
  searchWeb,
  researchWeb,
  openWebsite,
  volumeUp,
  volumeDown,
  muteVolume,
  openWifiSettings,
  openBluetoothSettings,
  unknown,
}

class AgentCommand {
  final AgentAction action;
  final String target;
  final String query;
  final String url;
  final List<String> steps;
  final String riskLevel;
  final bool requiresConfirmation;
  final String confirmationReason;
  final String expectedResult;
  final Map<String, dynamic> parameters;
  final String reason;

  const AgentCommand({
    required this.action,
    this.target = '',
    this.query = '',
    this.url = '',
    this.steps = const [],
    this.riskLevel = 'safe',
    this.requiresConfirmation = false,
    this.confirmationReason = '',
    this.expectedResult = '',
    this.parameters = const {},
    this.reason = '',
  });

  bool get hasTarget => target.trim().isNotEmpty;

  AgentCommand copyWith({
    AgentAction? action,
    String? target,
    String? query,
    String? url,
    List<String>? steps,
    String? riskLevel,
    bool? requiresConfirmation,
    String? confirmationReason,
    String? expectedResult,
    Map<String, dynamic>? parameters,
    String? reason,
  }) {
    return AgentCommand(
      action: action ?? this.action,
      target: target ?? this.target,
      query: query ?? this.query,
      url: url ?? this.url,
      steps: steps ?? this.steps,
      riskLevel: riskLevel ?? this.riskLevel,
      requiresConfirmation: requiresConfirmation ?? this.requiresConfirmation,
      confirmationReason: confirmationReason ?? this.confirmationReason,
      expectedResult: expectedResult ?? this.expectedResult,
      parameters: parameters ?? this.parameters,
      reason: reason ?? this.reason,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'action': action.name,
      'target': target,
      'query': query,
      'url': url,
      'steps': steps,
      'risk_level': riskLevel,
      'requires_confirmation': requiresConfirmation,
      'confirmation_reason': confirmationReason,
      'expected_result': expectedResult,
      'parameters': parameters,
      'reason': reason,
    };
  }

  factory AgentCommand.fromMap(Map<String, dynamic> map) {
    return AgentCommand(
      action: AgentActionMapper.fromString(map['action']?.toString() ?? ''),
      target: map['target']?.toString() ?? '',
      query: map['query']?.toString() ?? '',
      url: map['url']?.toString() ?? '',
      steps: List<String>.from(map['steps'] ?? []),
      riskLevel: map['risk_level']?.toString() ?? 'safe',
      requiresConfirmation: map['requires_confirmation'] == true || map['requires_confirmation']?.toString().toLowerCase() == 'true',
      confirmationReason: map['confirmation_reason']?.toString() ?? '',
      expectedResult: map['expected_result']?.toString() ?? '',
      parameters: Map<String, dynamic>.from(map['parameters'] ?? {}),
      reason: map['reason']?.toString() ?? '',
    );
  }

  factory AgentCommand.unknown() {
    return const AgentCommand(action: AgentAction.unknown, target: '', requiresConfirmation: false);
  }
}

class AgentActionMapper {
  static AgentAction fromString(String value) {
    switch (value.trim().toLowerCase()) {
      case 'chat':
        return AgentAction.chat;
      case 'open_app':
      case 'openapp':
      case 'run':
      case 'launch_app':
      case 'start app':
        return AgentAction.openApp;
      case 'open_folder':
      case 'open folder':
      case 'folder':
      case 'browse folder':
      case 'open directory':
        return AgentAction.openFolder;
      case 'open_file':
      case 'open file':
      case 'file':
      case 'view file':
        return AgentAction.openFile;
      case 'close_app':
      case 'close application':
      case 'terminate_app':
      case 'kill app':
        return AgentAction.closeApp;
      case 'search_file':
      case 'search':
      case 'find':
      case 'find file':
      case 'lookup file':
        return AgentAction.searchFile;
      case 'open_url':
      case 'open link':
      case 'visit':
      case 'go to':
        return AgentAction.openUrl;
      case 'search_online':
      case 'search internet':
      case 'find online':
        return AgentAction.searchOnline;
      case 'delete':
      case 'delete_file':
      case 'remove':
      case 'delete folder':
      case 'delete_file_folder':
      case 'delete file':
      case 'remove file':
        return AgentAction.deleteFile;
      case 'delete_folder':
      case 'remove folder':
      case 'remove directory':
        return AgentAction.deleteFolder;
      case 'restore':
      case 'undelete':
        return AgentAction.restoreFile;
      case 'install':
      case 'install_app':
      case 'add app':
      case 'install application':
        return AgentAction.installApp;
      case 'uninstall':
      case 'uninstall_app':
      case 'remove app':
      case 'remove application':
        return AgentAction.uninstallApp;
      case 'show_time':
      case 'what time':
      case 'current time':
        return AgentAction.showTime;
      case 'open_settings':
      case 'open settings':
      case 'settings':
        return AgentAction.openSettings;
      case 'open_control_panel':
      case 'control panel':
        return AgentAction.openControlPanel;
      case 'open_task_manager':
      case 'task manager':
      case 'taskmgr':
        return AgentAction.openTaskManager;
      case 'open_browser':
      case 'open browser':
      case 'browser':
      case 'open internet':
      case 'open web browser':
      case 'launch browser':
        return AgentAction.openBrowser;
      case 'open_word':
      case 'word':
        return AgentAction.openWord;
      case 'open_excel':
      case 'excel':
        return AgentAction.openExcel;
      case 'open_powerpoint':
      case 'powerpoint':
      case 'ppt':
        return AgentAction.openPowerPoint;
      case 'open_gmail':
      case 'gmail':
        return AgentAction.openGmail;
      case 'open_drive':
      case 'drive':
        return AgentAction.openDrive;
      case 'change_wallpaper':
      case 'set wallpaper':
      case 'wallpaper':
        return AgentAction.changeWallpaper;
      case 'open_tab':
      case 'new_tab':
      case 'open new tab':
        return AgentAction.openTab;
      case 'close_current_tab':
      case 'current tab close':
      case 'close this tab':
      case 'close current tab':
        return AgentAction.closeCurrentTab;
      case 'close_tab':
      case 'close tab':
        return AgentAction.closeTab;
      case 'close_all_tabs':
      case 'close all tabs':
      case 'close chrome tabs':
      case 'close all browser tabs':
        return AgentAction.closeAllTabs;
      case 'switch_tab':
      case 'next tab':
      case 'previous tab':
      case 'first tab':
      case 'last tab':
        return AgentAction.switchTab;
      case 'reopen_tab':
      case 'reopen last tab':
      case 'restore tab':
      case 'reopen tab':
        return AgentAction.reopenTab;
      case 'list_tabs':
      case 'show tabs':
      case 'open tabs list':
      case 'show open tabs':
        return AgentAction.listTabs;
      case 'search_web':
      case 'search online':
      case 'search web':
      case 'web search':
      case 'google search':
        return AgentAction.searchWeb;
      case 'research_web':
      case 'research':
      case 'deep research':
      case 'compare':
      case 'investigate':
        return AgentAction.researchWeb;
      case 'open_website':
      case 'open website':
        return AgentAction.openWebsite;
      case 'volume_up':
      case 'increase_volume':
      case 'increase sound':
      case 'sound up':
        return AgentAction.volumeUp;
      case 'volume_down':
      case 'decrease_volume':
      case 'reduce_volume':
      case 'reduce sound':
      case 'sound down':
        return AgentAction.volumeDown;
      case 'mute_volume':
      case 'mute':
      case 'mute sound':
      case 'unmute':
      case 'unmute sound':
        return AgentAction.muteVolume;
      case 'open_wifi_settings':
      case 'wifi':
      case 'wi-fi':
      case 'wifi settings':
      case 'turn wifi on':
      case 'turn wifi off':
        return AgentAction.openWifiSettings;
      case 'open_bluetooth_settings':
      case 'bluetooth':
      case 'bluetooth settings':
      case 'turn bluetooth on':
      case 'turn bluetooth off':
        return AgentAction.openBluetoothSettings;
      case 'transfer_file':
      case 'move file':
      case 'copy file':
        return AgentAction.transferFile;
      case 'create_file':
      case 'new file':
      case 'create file':
      case 'make a new file':
      case 'create text file':
      case 'create a text file':
        return AgentAction.createFile;
      case 'restore_file':
      case 'restore item':
      case 'restore deleted file':
      case 'restore deleted folder':
      case 'restore my deleted file':
      case 'restore my deleted folder':
      case 'restore item from recycle bin':
      case 'restore from recycle bin':
      case 'restore the deleted file':
      case 'restore the deleted folder':
      case 'restore deleted items':
      case 'restore from trash':
        return AgentAction.restoreFile;
      case 'open_recycle_bin':
      case 'recycle bin':
      case 'open recycle bin':
      case 'show recycle bin':
      case 'trash':
      case 'open my recycle bin':
        return AgentAction.openRecycleBin;
      case 'clear_recycle_bin':
      case 'empty recycle bin':
      case 'clear recycle bin':
      case 'delete all in recycle bin':
      case 'empty my recycle bin':
      case 'clear the trash':
      case 'empty the trash':
      case 'empty all trash':
        return AgentAction.clearRecycleBin;
      case 'delete_all':
      case 'delete all':
      case 'remove all':
      case 'delete everything in this folder':
      case 'clear this folder':
      case 'delete all files here':
      case 'remove all files here':
      case 'delete everything here':
      case 'clear this directory':
      case 'delete the whole folder':
      case 'remove the whole folder':
        return AgentAction.deleteAll;
      case 'clear_all':
      case 'clear all':
      case 'empty all':
      case 'erase all':
      case 'delete everything':
      case 'clear this folder completely':
        return AgentAction.clearAll;
      case 'run_safe_command':
      case 'run command':
      case 'execute safe command':
        return AgentAction.runSafeCommand;
      default:
        return AgentAction.unknown;
    }
  }
}
