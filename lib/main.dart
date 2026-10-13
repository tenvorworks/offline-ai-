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
    return 'Tumne pucha: "$userText" - (Yahan offline AI model ka jawab aayega)';
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
  }Widget _welcome(ColorScheme s) {
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
          Text('Main bina internet ke chalta hoon. Kuch bhi pucho!',
              textAlign: TextAlign.center,
              style: TextStyle(color: s.onSurfaceVariant, height: 1.4)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _suggestions
                .map((q) => ActionChip(label: Text(q), onPressed: () => _send(q)))
                .toList(),
          ),
        ]),
      ),
    );
  }

  Widget _chatList(ColorScheme s) {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      itemCount: _messages.length + (_thinking ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == _messages.length) return _bubble(s, null);
        return _bubble(s, _messages[i]);
      },
    );
  }

  Widget _bubble(ColorScheme s, Message? m) {
    final isUser = m?.isUser ?? false;
    final maxW = MediaQuery.of(context).size.width * 0.75;
    final content = Container(
      constraints: BoxConstraints(maxWidth: maxW),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      decoration: BoxDecoration(
        gradient: isUser ? LinearGradient(colors: [s.primary, s.tertiary]) : null,
        color: isUser ? null : s.surfaceContainerHighest,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 18),
        ),
      ),
      child: m == null
          ? const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: TypingDots())
          : Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(m.text,
                  style: TextStyle(
                      fontSize: 15,
                      height: 1.35,
                      color: isUser ? s.onPrimary : s.onSurface)),
              const SizedBox(height: 4),
              Text(_fmt(m.time),
                  style: TextStyle(
                      fontSize: 10,
                      color: (isUser ? s.onPrimary : s.onSurfaceVariant)
                          .withOpacity(0.7))),
            ]),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: s.primary,
              child: Icon(Icons.auto_awesome, size: 14, color: s.onPrimary),
            ),
            const SizedBox(width: 8),
          ],
          GestureDetector(
            onLongPress: m == null
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: m.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Copy ho gaya ✅'),
                          duration: Duration(seconds: 1)),
                    );
                  },
            child: content,
          ),
        ],
      ),
    );
  }Widget _inputBar(ColorScheme s) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Message likho...',
                filled: true,
                fillColor: s.surfaceContainerHighest,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(26),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            iconSize: 24,
            onPressed: _thinking ? null : () => _send(),
            icon: const Icon(Icons.arrow_upward),
          ),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }
}

class TypingDots extends StatefulWidget {
  const TypingDots({super.key});
  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }@override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final t = (_c.value - i * 0.2) % 1.0;
          final o = 0.3 + 0.7 * (t < 0.5 ? t * 2 : (1 - t) * 2);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: color.withOpacity(o), shape: BoxShape.circle),
          );
        }),
      ),
    );
  }
}
