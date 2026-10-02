import '../models/agent_command.dart';

class SafetyValidator {
  static const blockedPaths = <String>{
    r'c:\windows',
    r'c:\windows\system32',
    r'c:\program files',
    r'c:\program files (x86)',
    r'c:\programdata',
    r'c:\$recycle.bin',
  };

  static bool isBlockedPath(String target) {
    final normalized = target.trim().toLowerCase().replaceAll('/', r'\\');
    for (final blocked in blockedPaths) {
      if (normalized == blocked || normalized.startsWith('$blocked\\')) {
        return true;
      }
    }
    return false;
  }

  static bool requiresConfirmation(AgentCommand command) {
    switch (command.action) {
      case AgentAction.deleteFile:
      case AgentAction.deleteFolder:
      case AgentAction.restoreFile:
      case AgentAction.installApp:
      case AgentAction.uninstallApp:
      case AgentAction.closeApp:
      case AgentAction.runSafeCommand:
      case AgentAction.openSettings:
      case AgentAction.openControlPanel:
      case AgentAction.openTaskManager:
        return true;
      default:
        return false;
    }
  }

  static bool isBlockedAction(AgentCommand command) {
    return command.action == AgentAction.unknown;
  }
}
