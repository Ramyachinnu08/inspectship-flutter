import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});
  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _thinking = false;

  final List<ChatMessage> _messages = [
    ChatMessage(
      'Hello! I\'m your inspection assistant. Ask me anything from the company manuals — e.g. "What should I check in ballast tanks?"',
      fromUser: false,
    ),
  ];

  String _mockAnswer(String q) {
    final lower = q.toLowerCase();
    if (lower.contains('ballast')) {
      return 'For ballast tank checks: verify the Ballast Water Management Plan is approved and on board, confirm the record book entries match actual operations, inspect tank coatings for breakdown, and test the treatment system alarms. Ask the duty officer to demonstrate BWTS start-up.';
    }
    if (lower.contains('fire')) {
      return 'Fire safety checks: extinguisher service dates and seals, damper operation (random-test two), fire main pressure test, escape route lighting, and crew familiarity with muster duties.';
    }
    if (lower.contains('lifeboat') || lower.contains('life boat')) {
      return 'Lifeboat readiness: check gripes and release gear condition, davit limit switches, engine start (within 2 minutes when cold), and last lowering-to-water date in the planned maintenance record.';
    }
    return 'Based on the inspection manuals: focus on documentation first (certificates, record books), then physical condition, then crew familiarity. Ask me about a specific system — ballast, fire, lifeboats, pollution prevention…';
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _thinking) return;
    setState(() {
      _messages.add(ChatMessage(text, fromUser: true));
      _input.clear();
      _thinking = true;
    });
    _scrollDown();
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(
        _mockAnswer(text),
        fromUser: false,
        source: 'Company Inspection Manual (mock source)',
      ));
      _thinking = false;
    });
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.smart_toy, size: 22),
            SizedBox(width: 8),
            Text('AI Assistant'),
          ],
        ),
      ),
      body: ConstrainedContent(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: EdgeInsets.all(Responsive.pagePad(context)),
                itemCount: _messages.length + (_thinking ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i == _messages.length) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(children: [
                        SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2)),
                        SizedBox(width: 10),
                        Text('Searching manuals…',
                            style: TextStyle(color: AppColors.inkSoft)),
                      ]),
                    );
                  }
                  final m = _messages[i];
                  return Align(
                    alignment: m.fromUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      constraints: BoxConstraints(
                          maxWidth:
                          MediaQuery.of(context).size.width * .82),
                      decoration: BoxDecoration(
                        color:
                        m.fromUser ? AppColors.navy : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft:
                          Radius.circular(m.fromUser ? 16 : 4),
                          bottomRight:
                          Radius.circular(m.fromUser ? 4 : 16),
                        ),
                        border: m.fromUser
                            ? null
                            : Border.all(color: AppColors.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.text,
                              style: TextStyle(
                                  fontSize: 14,
                                  height: 1.45,
                                  color: m.fromUser
                                      ? Colors.white
                                      : AppColors.ink)),
                          if (m.source != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.menu_book,
                                    size: 14,
                                    color: AppColors.inkSoft),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(m.source!,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.inkSoft)),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              child: Container(
                padding: EdgeInsets.fromLTRB(
                    Responsive.pagePad(context), 8, Responsive.pagePad(context), 12),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                          hintText: 'Ask from inspection manuals…',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.signal,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _send,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
