import 'package:flutter/material.dart';
import 'services/agent_service.dart';
import 'services/action_executor.dart';
import 'voice_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEXORA AI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        fontFamily: 'Arial',
        useMaterial3: true,
      ),
      home: const AgentHomePage(),
    );
  }
}

class AgentHomePage extends StatefulWidget {
  const AgentHomePage({super.key});

  @override
  State<AgentHomePage> createState() => _AgentHomePageState();
}

class _AgentHomePageState extends State<AgentHomePage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _commandController = TextEditingController();
  final AgentService _agentService = AgentService();
  final ActionExecutor _actionExecutor = ActionExecutor();
  final VoiceService _voiceService = VoiceService();
  final List<_ChatMessage> _messages = <_ChatMessage>[];

  bool _loading = false;
  bool _listening = false;
  bool _voiceReady = false;
  String? _voiceStatusMessage;

  @override
  void initState() {
    super.initState();
    _initializeVoice();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commandController.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  Future<void> _initializeVoice() async {
    final ready = await _voiceService.initialize();
    if (mounted) {
      setState(() {
        _voiceReady = ready;
        _voiceStatusMessage = ready
            ? 'Voice input is ready. Tap the mic and speak clearly.'
            : _voiceService.errorMessage ??
                  'Voice input is not ready. Please check microphone permissions.';
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _appendMessage(bool isUser, String text) {
    setState(() {
      _messages.add(_ChatMessage(isUser: isUser, text: text));
    });
    _scrollToBottom();
  }

  Future<void> _sendCommand({required String command}) async {
    final trimmedCommand = command.trim();
    if (trimmedCommand.isEmpty || _loading) {
      return;
    }

    _appendMessage(true, trimmedCommand);
    setState(() => _loading = true);

    try {
      final commandObject = await _agentService.getCommand(trimmedCommand);
      if (!mounted) return;

      final response = await _actionExecutor.execute(commandObject, context);
      if (!mounted) return;

      _appendMessage(false, response);
      await _voiceService.speak(response);
    } catch (_) {
      if (mounted) {
        _appendMessage(
          false,
          'I could not complete that request. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _toggleListening() async {
    if (_loading) {
      return;
    }

    if (!_voiceReady) {
      await _initializeVoice();
      if (!_voiceReady) {
        _appendMessage(
          false,
          _voiceService.errorMessage ??
              'Voice input is not ready yet. Please check microphone permissions.',
        );
        return;
      }
    }

    if (_listening) {
      await _voiceService.stopListening();
      setState(() => _listening = false);
      return;
    }

    final started = await _voiceService.startListening(
      (recognizedWords, isFinal) async {
        if (!mounted) return;

        setState(() {
          _voiceStatusMessage = isFinal
              ? 'Heard: ${recognizedWords.trim()}'
              : 'Listening... ${recognizedWords.trim()}';
        });

        if (isFinal) {
          final trimmed = recognizedWords.trim();
          if (trimmed.isEmpty) {
            _appendMessage(
              false,
              'I could not understand that. Please try again.',
            );
            return;
          }

          setState(() => _listening = false);
          await _sendCommand(command: trimmed);
        }
      },
      onError: (errorMessage) {
        if (!mounted) return;
        setState(() {
          _voiceStatusMessage = errorMessage;
          _listening = false;
        });
        _appendMessage(false, errorMessage);
      },
    );

    if (!started) {
      _appendMessage(
        false,
        _voiceService.errorMessage ??
            'Voice listening could not start. Please try again.',
      );
      return;
    }

    setState(() {
      _listening = true;
      _voiceStatusMessage = 'Listening... speak clearly now.';
    });
  }

  Future<void> _submitTypedCommand() async {
    final command = _commandController.text.trim();
    if (command.isEmpty || _loading) {
      return;
    }
    _commandController.clear();
    await _sendCommand(command: command);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F4),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 36 : 18,
                vertical: 20,
              ),
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _buildConversation(context)),
                        if (isWide) ...[
                          const SizedBox(width: 24),
                          SizedBox(
                            width: 280,
                            child: _buildSystemPanel(context),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF176B5B),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 23),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NEXORA',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'PERSONAL AI ASSISTANT',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.1,
                  color: Color(0xFF728079),
                ),
              ),
            ],
          ),
        ),
        if (MediaQuery.sizeOf(context).width >= 520)
          _StatusPill(
            icon: Icons.lock_outline,
            label: 'LOCAL WORKSPACE',
            color: const Color(0xFF176B5B),
          ),
      ],
    );
  }

  Widget _buildConversation(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? _buildWelcome(context)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 20),
                  itemCount: _messages.length + (_loading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) {
                      return const _TypingIndicator();
                    }
                    return _MessageBubble(message: _messages[index]);
                  },
                ),
        ),
        _buildComposer(context),
        if (_voiceStatusMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 9),
            child: Text(
              _voiceStatusMessage!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF728079)),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildWelcome(BuildContext context) {
    const suggestions = [
      'What can you help me with?',
      'Open Chrome',
      'Search online for Flutter documentation',
      'What time is it?',
    ];

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 44),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR DESKTOP,\nAT YOUR COMMAND',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF176B5B),
                    letterSpacing: 1.2,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'What can I take\noff your hands?',
                  style: TextStyle(
                    fontSize: 34,
                    height: 1.14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2925),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Ask naturally. I can help with Windows tasks, apps, files, web searches, and everyday questions.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: Color(0xFF66736D),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'TRY A PROMPT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: Color(0xFF87918C),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: suggestions
                      .map(
                        (suggestion) => ActionChip(
                          label: Text(suggestion),
                          onPressed: _loading
                              ? null
                              : () => _sendCommand(command: suggestion),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFDDE5E0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                          labelStyle: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF33413A),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComposer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFDDE5E0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D243B31),
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _commandController,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitTypedCommand(),
              decoration: const InputDecoration(
                hintText: 'Ask anything or give a Windows command...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _loading ? null : _toggleListening,
            tooltip: _listening ? 'Stop listening' : 'Start voice input',
            icon: Icon(
              _listening ? Icons.mic : Icons.mic_none,
              color: _listening
                  ? const Color(0xFFC4513D)
                  : const Color(0xFF53635A),
            ),
          ),
          const SizedBox(width: 3),
          IconButton.filled(
            onPressed: _loading ? null : _submitTypedCommand,
            tooltip: 'Send prompt',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF176B5B),
              foregroundColor: Colors.white,
            ),
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.arrow_upward),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0EC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE7E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SYSTEM STATUS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: Color(0xFF68766F),
            ),
          ),
          const SizedBox(height: 20),
          const _SystemRow(
            icon: Icons.memory,
            title: 'AI model',
            detail: 'Llama 3 · Ollama local',
          ),
          const SizedBox(height: 16),
          _SystemRow(
            icon: Icons.graphic_eq,
            title: 'Voice input',
            detail: _voiceReady ? 'Ready to listen' : 'Initializing',
            accent: _voiceReady
                ? const Color(0xFF176B5B)
                : const Color(0xFF89948E),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1, color: Color(0xFFD1DDD6)),
          ),
          const Text(
            'AVAILABLE SKILLS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: Color(0xFF68766F),
            ),
          ),
          const SizedBox(height: 13),
          const _SkillLine(
            icon: Icons.desktop_windows_outlined,
            label: 'Windows & apps',
          ),
          const _SkillLine(
            icon: Icons.folder_open_outlined,
            label: 'Files & folders',
          ),
          const _SkillLine(icon: Icons.travel_explore, label: 'Web search'),
          const _SkillLine(
            icon: Icons.chat_bubble_outline,
            label: 'Everyday questions',
          ),
          const Spacer(),
          const Row(
            children: [
              Icon(Icons.shield_outlined, size: 16, color: Color(0xFF176B5B)),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Sensitive actions ask before running.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: Color(0xFF53635A),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFDDE5E0)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: .7,
            color: Color(0xFF46554D),
          ),
        ),
      ],
    ),
  );
}

class _SystemRow extends StatelessWidget {
  const _SystemRow({
    required this.icon,
    required this.title,
    required this.detail,
    this.accent = const Color(0xFF176B5B),
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color accent;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: accent),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF27342D),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              detail,
              style: const TextStyle(fontSize: 11, color: Color(0xFF69766F)),
            ),
          ],
        ),
      ),
    ],
  );
}

class _SkillLine extends StatelessWidget {
  const _SkillLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF607168)),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF3F4D45)),
          ),
        ),
      ],
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .72,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 7),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: isUser ? const Color(0xFF176B5B) : Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: isUser ? null : Border.all(color: const Color(0xFFE1E8E3)),
          ),
          child: Text(
            message.text,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isUser ? Colors.white : const Color(0xFF28342D),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) => const Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF176B5B),
            ),
          ),
          SizedBox(width: 10),
          Text(
            'Thinking...',
            style: TextStyle(fontSize: 12, color: Color(0xFF728079)),
          ),
        ],
      ),
    ),
  );
}

class _ChatMessage {
  final bool isUser;
  final String text;

  const _ChatMessage({required this.isUser, required this.text});
}
