import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AgentService {
  final String baseUrl;
  final String modelName;

  static const _allowedActions = {
    'open_file',
    'open_folder',
    'open_app',
    'open_url',
    'search_online',
    'close_app',
    'create_folder',
    'search_file',
    'delete_file',
    'delete_folder',
    'restore_file',
    'install_app',
    'uninstall_app',
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
    'transfer_file',
    'create_file',
    'open_recycle_bin',
    'clear_recycle_bin',
    'delete_all',
    'clear_all',
    'run_safe_command',
    'chat',
  };

  AgentService({
    this.baseUrl = 'http://localhost:11434',
    this.modelName = 'llama3',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  /// Sends the user's command to Ollama and asks the local model to return
  /// structured JSON only.
  Future<Map<String, dynamic>> getAction(String userCommand) async {
    final direct = _resolveDirectCommand(userCommand);
    if (direct != null) {
      return direct;
    }

    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': modelName,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a Windows desktop assistant. Return only one valid JSON object with exactly these keys: action, target, requires_confirmation. '
                  'Allowed actions: open_file, open_folder, open_app, open_url, search_online, close_app, create_folder, search_file, delete_file, delete_folder, restore_file, install_app, uninstall_app, show_time, open_settings, open_control_panel, open_task_manager, open_browser, open_word, open_excel, open_powerpoint, open_gmail, open_drive, change_wallpaper, transfer_file, create_file, open_recycle_bin, clear_recycle_bin, delete_all, clear_all, run_safe_command, chat. '
                  'Use create_folder when the user wants to create a new folder. Use close_app when the user wants to close an application or window. Use open_folder when the target is a folder path or folder name. Use open_file when the target is a file path or filename. Use open_app when the user wants to launch a program. Use open_url when the user provides a web link. Use search_online when the user requests a web search or install link. Use chat when the user asks a normal conversational question that is not a Windows action. '
                  'For safe, read-only actions set requires_confirmation to false. For create_folder, open_folder, open_app, open_url, search_online, open_file, show_time, open_settings, open_control_panel, open_task_manager, open_browser, open_word, open_excel, open_powerpoint, open_gmail, open_drive, and chat, use requires_confirmation false. For actions that close apps, remove files, install or uninstall software, restore items, or execute unsafe commands, set requires_confirmation to true. '
                  'Return only the JSON object. Do not include any extra text, markdown, explanation, or lists. '
                  'If the request is not one of the supported actions, return action:"error" and target with a brief explanation. '
                  'Example valid responses:\n'
                  '{"action":"open_folder","target":"C:\\Users\\gokul\\Documents","requires_confirmation":false}\n'
                  '{"action":"create_folder","target":"C:\\Users\\gokul\\Documents\\NewFolder","requires_confirmation":false}\n'
                  '{"action":"search_online","target":"visual studio code install link","requires_confirmation":false}\n'
                  '{"action":"open_url","target":"https://www.microsoft.com","requires_confirmation":false}\n'
                  '{"action":"delete_file","target":"C:\\Users\\gokul\\Desktop\\test.txt","requires_confirmation":true}\n'
                  '{"action":"install_app","target":"7zip.7zip","requires_confirmation":true}\n'
                  '{"action":"close_app","target":"notepad.exe","requires_confirmation":true}\n'
                  '{"action":"chat","target":"Python is a programming language...","requires_confirmation":false}',
            },
            {'role': 'user', 'content': userCommand},
          ],
          'stream': false,
        }),
      );

      if (response.statusCode != 200) {
        return {
          'action': 'error',
          'target':
              'Ollama is not running. Please start Ollama first and try again.',
          'requires_confirmation': false,
        };
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final ollamaMessage = payload['message'];
      final choices = payload['choices'] as List?;
      final rawContent = ollamaMessage is Map
          ? ollamaMessage['content']?.toString() ?? '{}'
          : choices?.firstOrNull?['message']?['content']?.toString() ?? '{}';
      return parseActionResponse(rawContent);
    } on SocketException {
      return {
        'action': 'error',
        'target':
            'Ollama is not running. Please start Ollama first and try again.',
        'requires_confirmation': false,
      };
    } catch (e) {
      return {
        'action': 'error',
        'target': 'Unable to understand that command. Please try again.',
        'requires_confirmation': false,
      };
    }
  }

  /// Parses the model output and normalizes it into a predictable map.
  Map<String, dynamic> parseActionResponse(String rawContent) {
    final cleaned = rawContent.trim();
    final jsonBlock = RegExp(r'\{.*\}', dotAll: true).firstMatch(cleaned);
    final jsonText = jsonBlock?.group(0) ?? cleaned;

    try {
      final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
      final action = _normalizeAction(
        (decoded['action'] ?? 'unknown').toString(),
      );
      final target = decoded['target']?.toString() ?? '';
      final rawConfirmation = decoded['requires_confirmation'];
      final requiresConfirmation =
          rawConfirmation == true ||
          rawConfirmation?.toString().toLowerCase() == 'true';

      if (!_allowedActions.contains(action)) {
        return {
          'action': 'error',
          'target':
              'The assistant suggested an unsupported action. Please rephrase your command to a safe Windows action.',
          'requires_confirmation': false,
        };
      }

      return {
        'action': action,
        'target': target,
        'requires_confirmation': requiresConfirmation,
      };
    } catch (_) {
      return {
        'action': 'error',
        'target':
            'Unable to understand that command. Please say something like "open folder Documents" or "delete file C:\\Users\\gokul\\Desktop\\test.txt".',
        'requires_confirmation': false,
      };
    }
  }

  Map<String, dynamic>? _resolveDirectCommand(String userCommand) {
    final text = userCommand.trim().toLowerCase();

    final browserCommands = [
      'open browser',
      'launch browser',
      'open web browser',
      'open internet',
    ];

    if (browserCommands.contains(text)) {
      return {
        'action': 'open_browser',
        'target': text,
        'requires_confirmation': false,
      };
    }

    if (text.startsWith('open chrome') || text.startsWith('launch chrome')) {
      return {
        'action': 'open_app',
        'target': 'chrome',
        'requires_confirmation': false,
      };
    }

    if (text.startsWith('open edge') || text.startsWith('launch edge')) {
      return {
        'action': 'open_app',
        'target': 'edge',
        'requires_confirmation': false,
      };
    }

    if (text.startsWith('open firefox') || text.startsWith('launch firefox')) {
      return {
        'action': 'open_app',
        'target': 'firefox',
        'requires_confirmation': false,
      };
    }

    if (text.startsWith('open this pc') ||
        text.startsWith('open computer') ||
        text.startsWith('show this pc')) {
      return {
        'action': 'open_app',
        'target': 'explorer.exe',
        'requires_confirmation': false,
      };
    }

    if (text.startsWith('open file explorer') ||
        text.startsWith('open explorer') ||
        text.startsWith('open windows explorer')) {
      return {
        'action': 'open_app',
        'target': 'explorer.exe',
        'requires_confirmation': false,
      };
    }

    return null;
  }

  String _normalizeAction(String action) {
    final cleaned = action.trim().toLowerCase();
    switch (cleaned) {
      case 'open':
      case 'open_app':
      case 'run':
      case 'launch_app':
      case 'start app':
        return 'open_app';
      case 'open_folder':
      case 'open folder':
      case 'folder':
      case 'browse folder':
      case 'open directory':
        return 'open_folder';
      case 'open_file':
      case 'open file':
      case 'file':
      case 'view file':
        return 'open_file';
      case 'close':
      case 'close_app':
      case 'close application':
      case 'terminate_app':
      case 'kill app':
        return 'close_app';
      case 'search':
      case 'search_file':
      case 'find':
      case 'find file':
      case 'lookup file':
        return 'search_file';
      case 'open_url':
      case 'open link':
      case 'open_url_link':
      case 'visit':
      case 'go to':
        return 'open_url';
      case 'search_online':
      case 'web search':
      case 'search web':
      case 'search internet':
      case 'find online':
        return 'search_online';
      case 'delete':
      case 'delete_file':
      case 'remove':
      case 'delete folder':
      case 'delete_file_folder':
      case 'delete file':
      case 'remove file':
        return 'delete_file';
      case 'delete_folder':
      case 'remove folder':
      case 'remove directory':
        return 'delete_folder';
      case 'create_folder':
      case 'create folder':
      case 'make_folder':
      case 'make folder':
      case 'new folder':
      case 'mkdir':
      case 'create a folder':
      case 'make a folder':
      case 'create folder in desktop':
      case 'make folder on my desktop':
      case 'create folder on desktop':
      case 'make a folder on the desktop':
      case 'create a folder on the desktop':
      case 'make folder on my desk':
      case 'create folder on my desk':
        return 'create_folder';
      case 'restore':
      case 'restore_file':
      case 'undelete':
      case 'restore deleted file':
      case 'restore my deleted file':
      case 'restore deleted folder':
      case 'restore my deleted folder':
      case 'restore item from recycle bin':
      case 'restore from recycle bin':
      case 'restore the deleted file':
      case 'restore the deleted folder':
      case 'restore deleted items':
      case 'restore from trash':
        return 'restore_file';
      case 'install':
      case 'install_app':
      case 'add app':
      case 'install application':
        return 'install_app';
      case 'uninstall':
      case 'uninstall_app':
      case 'remove app':
      case 'remove application':
        return 'uninstall_app';
      case 'show_time':
      case 'what time':
      case 'current time':
        return 'show_time';
      case 'open_settings':
      case 'open settings':
      case 'settings':
        return 'open_settings';
      case 'open_control_panel':
      case 'control panel':
        return 'open_control_panel';
      case 'open_task_manager':
      case 'task manager':
      case 'taskmgr':
        return 'open_task_manager';
      case 'open_browser':
      case 'open browser':
      case 'browser':
      case 'open internet':
      case 'open web browser':
      case 'launch browser':
        return 'open_browser';
      case 'open_chrome':
      case 'open chrome':
      case 'chrome':
      case 'open_edge':
      case 'open edge':
      case 'edge':
      case 'open_firefox':
      case 'open firefox':
      case 'firefox':
      case 'launch chrome':
      case 'launch edge':
      case 'launch firefox':
      case 'launch chrome browser':
      case 'launch edge browser':
      case 'launch firefox browser':
        return 'open_app';
      case 'open_word':
      case 'word':
        return 'open_word';
      case 'open_excel':
      case 'excel':
        return 'open_excel';
      case 'open_powerpoint':
      case 'powerpoint':
      case 'ppt':
        return 'open_powerpoint';
      case 'open_gmail':
      case 'gmail':
        return 'open_gmail';
      case 'open_drive':
      case 'drive':
        return 'open_drive';
      case 'open_this_pc':
      case 'this_pc':
      case 'open_file_explorer':
      case 'file_explorer':
      case 'open_explorer':
        return 'open_app';
      case 'change_wallpaper':
      case 'set wallpaper':
      case 'wallpaper':
        return 'change_wallpaper';
      case 'transfer_file':
      case 'move file':
      case 'copy file':
        return 'transfer_file';
      case 'create_file':
      case 'new file':
      case 'create file':
      case 'make a new file':
      case 'create text file':
      case 'create a text file':
        return 'create_file';
      case 'open_recycle_bin':
      case 'recycle bin':
      case 'open recycle bin':
      case 'show recycle bin':
      case 'trash':
      case 'open my recycle bin':
        return 'open_recycle_bin';
      case 'clear_recycle_bin':
      case 'empty recycle bin':
      case 'clear recycle bin':
      case 'delete all in recycle bin':
      case 'empty my recycle bin':
        return 'clear_recycle_bin';
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
        return 'delete_all';
      case 'clear_all':
      case 'clear all':
      case 'empty all':
      case 'erase all':
      case 'delete everything':
      case 'clear the trash':
      case 'empty the trash':
      case 'clear this folder completely':
      case 'empty all trash':
        return 'clear_all';
      case 'run_safe_command':
      case 'run command':
      case 'execute safe command':
        return 'run_safe_command';
      case 'chat':
      case 'answer':
      case 'respond':
        return 'chat';
      default:
        return cleaned;
    }
  }
}
