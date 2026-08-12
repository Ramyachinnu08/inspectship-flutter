import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../api_service.dart';

const _kPrimary = Color(0xFFF06B26);
const _kNavy = Color(0xFF1A2A5E);

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});
  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<_Msg> _messages = [];
  bool _busy = false;

  Box? _chatBox;
  String _currentChatId = '';
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    try {
      _chatBox = await Hive.openBox('ai_chats');
    } catch (_) {
      _chatBox = Hive.box('ai_chats');
    }
    _loadHistory();
    _startNewChat();
  }

  void _loadHistory() {
    if (_chatBox == null) return;
    final raw = _chatBox!.get('index');
    if (raw != null) {
      final List list = jsonDecode(raw);
      _history = list.map((e) => Map<String, dynamic>.from(e)).toList();
      _history.sort((a, b) => (b['updated'] ?? '').compareTo(a['updated'] ?? ''));
    }
    if (mounted) setState(() {});
  }

  void _startNewChat() {
    _currentChatId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _messages = [
        _Msg(fromUser: false, text: "Hi! I'm your inspection assistant. Ask me anything about vessel inspections, or attach a photo and I'll analyze it for issues."),
      ];
    });
  }

  Future<void> _saveCurrentChat() async {
    if (_chatBox == null || _messages.length <= 1) return;
    final msgs = _messages.map((m) => {'fromUser': m.fromUser, 'text': m.text}).toList();
    await _chatBox!.put('chat_$_currentChatId', jsonEncode(msgs));
    final title = _messages.firstWhere((m) => m.fromUser, orElse: () => _Msg(fromUser: true, text: 'New chat')).text;
    final shortTitle = title.length > 40 ? '${title.substring(0, 40)}…' : title;
    _history.removeWhere((h) => h['id'] == _currentChatId);
    _history.insert(0, {'id': _currentChatId, 'title': shortTitle, 'updated': DateTime.now().toIso8601String()});
    await _chatBox!.put('index', jsonEncode(_history));
    if (mounted) setState(() {});
  }

  void _openChat(String id) {
    if (_chatBox == null) return;
    final raw = _chatBox!.get('chat_$id');
    if (raw == null) return;
    final List list = jsonDecode(raw);
    setState(() {
      _currentChatId = id;
      _messages = list.map((e) => _Msg(fromUser: e['fromUser'] == true, text: e['text']?.toString() ?? '')).toList();
    });
    Navigator.pop(context);
    _scrollToBottom();
  }

  Future<void> _deleteChat(String id) async {
    if (_chatBox == null) return;
    await _chatBox!.delete('chat_$id');
    _history.removeWhere((h) => h['id'] == id);
    await _chatBox!.put('index', jsonEncode(_history));
    if (id == _currentChatId) _startNewChat();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _saveCurrentChat();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _sendQuestion() async {
    final q = _msgCtrl.text.trim();
    if (q.isEmpty || _busy) return;
    setState(() {
      _messages.add(_Msg(fromUser: true, text: q));
      _busy = true;
      _msgCtrl.clear();
    });
    _scrollToBottom();
    final result = await ApiService.aiAsk(q);
    if (!mounted) return;
    setState(() {
      _messages.add(_Msg(fromUser: false, text: result['answer']?.toString() ?? 'No response'));
      _busy = false;
    });
    _scrollToBottom();
    _saveCurrentChat();
  }

  Future<void> _analyzePhoto(ImageSource source) async {
    if (_busy) return;
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: source, imageQuality: 70);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final b64 = base64Encode(bytes);

    setState(() {
      _messages.add(_Msg(fromUser: true, text: '[Photo attached]', imageBytes: bytes));
      _busy = true;
    });
    _scrollToBottom();

    final result = await ApiService.aiAnalyzeImage(b64);
    if (!mounted) return;
    setState(() {
      _messages.add(_Msg(fromUser: false, text: result['analysis']?.toString() ?? 'No analysis'));
      _busy = false;
    });
    _scrollToBottom();
    _saveCurrentChat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      drawer: _buildHistoryDrawer(),
      appBar: AppBar(
        backgroundColor: _kNavy,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('AI Assistant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined, color: Colors.white),
            tooltip: 'New chat',
            onPressed: () async { await _saveCurrentChat(); _startNewChat(); },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_busy ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length && _busy) {
                  return const _TypingBubble();
                }
                return _MsgBubble(msg: _messages[i]);
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildHistoryDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: _kNavy,
              child: Row(
                children: const [
                  Icon(Icons.history, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text('Chat History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                onPressed: () async { await _saveCurrentChat(); _startNewChat(); Navigator.pop(context); },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('New Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _history.isEmpty
                  ? const Center(child: Text('No previous chats', style: TextStyle(color: Color(0xFF9CA3AF))))
                  : ListView.builder(
                itemCount: _history.length,
                itemBuilder: (context, i) {
                  final h = _history[i];
                  final selected = h['id'] == _currentChatId;
                  return ListTile(
                    leading: const Icon(Icons.chat_bubble_outline, size: 20),
                    title: Text(h['title']?.toString() ?? 'Chat', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                    selected: selected,
                    selectedTileColor: const Color(0xFFFFF3EC),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF9CA3AF)),
                      onPressed: () => _deleteChat(h['id'].toString()),
                    ),
                    onTap: () => _openChat(h['id'].toString()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.camera_alt_outlined, color: _kNavy),
              onPressed: _busy ? null : () => _analyzePhoto(ImageSource.camera),
              tooltip: 'Analyze photo (camera)',
            ),
            IconButton(
              icon: const Icon(Icons.image_outlined, color: _kNavy),
              onPressed: _busy ? null : () => _analyzePhoto(ImageSource.gallery),
              tooltip: 'Analyze photo (gallery)',
            ),
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendQuestion(),
                decoration: InputDecoration(
                  hintText: 'Ask about inspections…',
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _busy ? null : _sendQuestion,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: _busy ? Colors.grey : _kPrimary, shape: BoxShape.circle),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Msg {
  final bool fromUser;
  final String text;
  final Uint8List? imageBytes;
  _Msg({required this.fromUser, required this.text, this.imageBytes});
}

class _MsgBubble extends StatelessWidget {
  final _Msg msg;
  const _MsgBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.fromUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser ? _kNavy : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.imageBytes != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(msg.imageBytes!, width: 180, height: 180, fit: BoxFit.cover),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              msg.text,
              style: TextStyle(
                color: isUser ? Colors.white : const Color(0xFF111111),
                fontSize: 14, height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const SizedBox(
          width: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_Dot(), _Dot(), _Dot()],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8, height: 8,
      decoration: const BoxDecoration(color: Color(0xFF9CA3AF), shape: BoxShape.circle),
    );
  }
}