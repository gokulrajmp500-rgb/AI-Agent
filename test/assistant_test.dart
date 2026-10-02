import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_agent/agent_service.dart';
import 'package:ai_agent/system_actions.dart';
import 'package:ai_agent/services/agent_service.dart' as command_agent;

void main() {
  group('Agent parsing', () {
    test('reads model output from the Ollama chat response format', () async {
      final service = AgentService(
        client: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'message': {
                'content':
                    '{"action":"chat","target":"Hello there.","requires_confirmation":false}',
              },
            }),
            200,
          ),
        ),
      );

      final parsed = await service.getAction('Say hello');

      expect(parsed['action'], 'chat');
      expect(parsed['target'], 'Hello there.');
    });

    test('parses safe JSON action output', () {
      final service = AgentService();
      final parsed = service.parseActionResponse(
        '{"action":"open_app","target":"Chrome","requires_confirmation":false}',
      );

      expect(parsed['action'], 'open_app');
      expect(parsed['target'], 'Chrome');
      expect(parsed['requires_confirmation'], false);
    });

    test('flags destructive actions for confirmation', () {
      final service = AgentService();
      final parsed = service.parseActionResponse(
        '{"action":"delete_file","target":"C:/Temp/demo.txt","requires_confirmation":true}',
      );

      expect(parsed['requires_confirmation'], true);
    });

    test('parses recycle-bin and bulk-delete keywords', () {
      final service = AgentService();

      expect(
        service.parseActionResponse(
          '{"action":"open_recycle_bin","target":"","requires_confirmation":false}',
        )['action'],
        'open_recycle_bin',
      );
      expect(
        service.parseActionResponse(
          '{"action":"clear_recycle_bin","target":"","requires_confirmation":true}',
        )['action'],
        'clear_recycle_bin',
      );
      expect(
        service.parseActionResponse(
          '{"action":"delete_all","target":"D:/Downloads","requires_confirmation":true}',
        )['action'],
        'delete_all',
      );
      expect(
        service.parseActionResponse(
          '{"action":"clear_all","target":"D:/Downloads","requires_confirmation":true}',
        )['action'],
        'clear_all',
      );
    });

    test(
      'resolves desktop and downloads aliases to a valid user profile path',
      () {
        final actions = SystemActions();
        final desktopPath = actions.resolveTarget('desktop');
        final downloadsPath = actions.resolveTarget('downloads');

        expect(desktopPath.toLowerCase(), contains('desktop'));
        expect(downloadsPath.toLowerCase(), contains('downloads'));
        expect(desktopPath, isNotEmpty);
        expect(downloadsPath, isNotEmpty);
      },
    );
  });

  group('Offline assistant intents', () {
    final service = command_agent.AgentService(
      ollamaService: AgentService(
        client: MockClient((request) async => http.Response('', 503)),
      ),
    );

    test('answers greetings without contacting the model', () async {
      final command = await service.getCommand('hi');

      expect(command.action.name, 'chat');
      expect(command.target, contains('Hello'));
    });

    test('opens PowerPoint with natural phrasing', () async {
      final command = await service.getCommand('open the powerpoint');

      expect(command.action.name, 'openPowerPoint');
    });

    test('maps C drive download-folder phrasing to Downloads', () async {
      final command = await service.getCommand(
        'open the C drive download folder',
      );

      expect(command.action.name, 'openFolder');
      expect(command.target, 'downloads');
    });

    test(
      'returns the Ollama connection error as an assistant response',
      () async {
        final command = await service.getCommand('explain quantum computing');

        expect(command.action.name, 'chat');
        expect(command.target, contains('Ollama is not running'));
      },
    );
  });

  group('Safety rules', () {
    test('blocks protected Windows paths', () {
      final actions = SystemActions();
      expect(actions.isBlockedPath(r'C:\Windows\System32\cmd.exe'), isTrue);
      expect(
        actions.isBlockedPath(r'C:\Users\Alice\Desktop\note.txt'),
        isFalse,
      );
    });
  });
}
