import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const OfflineAIApp());

class OfflineAIApp extends StatefulWidget {
  const OfflineAIApp({super.key});
  @override
  State<OfflineAIApp> createState() => _OfflineAIAppState();
}

class _OfflineAIAppState extends State<OfflineAIApp> {
  ThemeMode _mode = ThemeMode.dark;

  ThemeData _theme(Brightness b) => ThemeData(
        useMaterial3: true,
        brightness: b,
        colorSchemeSeed: const Color(0xFF6C5CE7),
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline AI',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: _mode,
      home: ChatScreen(
        isDark: _mode == ThemeMode.dark,
        onToggleTheme: () => setState(() =>
            _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark),
      ),
    );
  }
}

class Message {
  final String text;
  final bool isUser;
  final DateTime time = DateTime.now();
  Message(this.text, this.isUser);
}

class ChatScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  const ChatScreen({super.key, required this.isDark, required this.onToggleTheme});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<Message> _messages = [];
  bool _thinking = false;

  final _suggestions = const [
    'Mujhe ek joke sunao 😄',
    'Python kya hai?',
    'Study tips do 📚',
    'Ek chhoti kahani likho',
  ];

  // TODO: Yahan asli offline AI model (Gemma / Llama) jodna hai.
  Future<String> getAIReply(String userText) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    return 'Tumne pucha: "$userText"\n\n(Yahan offline AI model ka jawab aayega)';
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _thinking) return;
    setState(() {
      _messages.add(Message(text, true));
      _thinking = true;
    });
    _controller.clear();
    _scrollDown();
    final reply = await getAIReply(text);
    if (!mounted) return;
    setState(() {
      _messages.add(Message(reply, false));
      _thinking = false;
    });
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent + 80,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  String _fmt(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(children: [
          CircleAvatar(
            backgroundColor: s.primary,
            child: Icon(Icons.auto_awesome, color: s.onPrimary, size: 20),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Offline AI',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            Row(children: [
              const Icon(Icons.circle, size: 8, color: Colors.green),
              const SizedBox(width: 4),
              Text('Offline mode • Private',
                  style: TextStyle(fontSize: 12, color: s.onSurfaceVariant)),
            ]),
          ]),
        ]),
        actions: [
          IconButton(
            tooltip: 'Theme',
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
          IconButton(
            tooltip: 'Clear chat',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => setState(() => _messages.clear()),
          ),
        ],
      ),
      body: Column(children: [
        Expanded(child: _messages.isEmpty ? _welcome(s) : _chatList(s)),
        _inputBar(s),
      ]),
    );
  }

  Widget _welcome(ColorScheme s) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [s.primary, s.tertiary]),
            ),
            child: Icon(Icons.auto_awesome, size: 40, color: s.onPrimary),
          ),
          const SizedBox(height: 20),
          const Text('Namaste! 👋',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Main bina internet ke chalta hoon.\nKuch bhi p
