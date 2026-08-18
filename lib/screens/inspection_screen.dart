import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../api_service.dart';
import 'inspection_session.dart';
import 'signoff_screen.dart';
import 'photo_editor_screen.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'ai_assistant_screen.dart';

class InspectionScreen extends StatefulWidget {
  final Assignment assignment;
  const InspectionScreen({super.key, required this.assignment});

  @override
  State<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends State<InspectionScreen> {
  String _coverImage = '';
  final Map<String, TextEditingController> _commentControllers = {};

  TextEditingController _commentCtrl(Question q) {
    return _commentControllers.putIfAbsent(q.id, () => TextEditingController(text: q.comment));
  }
  String _leftTab = 'sections';
  String? _activeSectionId;
  String? _activeQuestionId;
  final Map<String, bool> _expanded = {};
  final Map<String, bool> _editingField = {};

  static const _sectionColors = [
    (bg: Color(0xFFDBEAFE), border: Color(0xFF3B82F6), text: Color(0xFF1E40AF)),
    (bg: Color(0xFFFEF3C7), border: Color(0xFFF59E0B), text: Color(0xFF92400E)),
    (bg: Color(0xFFDCFCE7), border: Color(0xFF22C55E), text: Color(0xFF166534)),
    (bg: Color(0xFFEDE9FE), border: Color(0xFF8B5CF6), text: Color(0xFF5B21B6)),
    (bg: Color(0xFFFCE7F3), border: Color(0xFFEC4899), text: Color(0xFF9D174D)),
    (bg: Color(0xFFFEE2E2), border: Color(0xFFEF4444), text: Color(0xFF991B1B)),
  ];

  @override
  void initState() {
    super.initState();
    _coverImage = widget.assignment.coverImage;
    if (widget.assignment.sections.isNotEmpty) {
      _activeSectionId = widget.assignment.sections.first.id;
      _expanded[_activeSectionId!] = true;
      if (widget.assignment.sections.first.questions.isNotEmpty) {
        _activeQuestionId = widget.assignment.sections.first.questions.first.id;
      }
    }
  }

  Section? get _activeSection {
    if (_activeSectionId == null) return null;
    for (final s in widget.assignment.sections) {
      if (s.id == _activeSectionId) return s;
    }
    return null;
  }

  Question? get _activeQuestion {
    final s = _activeSection;
    if (s == null || _activeQuestionId == null) return null;
    for (final q in s.questions) {
      if (q.id == _activeQuestionId) return q;
    }
    return null;
  }

  List<({Question q, String sectionId})> get _allFlat {
    final list = <({Question q, String sectionId})>[];
    for (final s in widget.assignment.sections) {
      for (final q in s.questions) {
        list.add((q: q, sectionId: s.id));
      }
    }
    return list;
  }

  int get _answered =>
      widget.assignment.sections.fold(0, (t, s) => t + s.answered);
  int get _total => widget.assignment.totalQuestions;

  void _goToSignOff() {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => SignOffScreen(assignment: widget.assignment)));
  }

  bool _isGeneralInfo(Section s) =>
      s.title.toLowerCase().contains('general information');

  Future<void> _pickCoverImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1400, imageQuality: 65);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _coverImage = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      widget.assignment.coverImage = _coverImage;
    });
  }

  void _openCoverDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Vessel Image'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('This image appears as the background on the report cover page.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF8A6A4E))),
                const SizedBox(height: 12),
                if (_coverImage.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: _coverImage.startsWith('data:image')
                        ? Image.memory(base64Decode(_coverImage.split(',').last), height: 140, width: double.infinity, fit: BoxFit.cover)
                        : Image.network(_coverImage, height: 140, width: double.infinity, fit: BoxFit.cover),
                  ),
              ],
            ),
          ),
          actions: [
            if (_coverImage.isNotEmpty)
              TextButton(
                onPressed: () { setState(() { _coverImage = ''; widget.assignment.coverImage = ''; }); Navigator.pop(ctx); },
                child: const Text('Remove', style: TextStyle(color: Color(0xFFEF4444))),
              ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            ElevatedButton(
              onPressed: () async { await _pickCoverImage(); setD(() {}); },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B00), foregroundColor: Colors.white),
              child: Text(_coverImage.isEmpty ? 'Upload' : 'Change'),
            ),
          ],
        ),
      ),
    );
  }

  // AI: analyse a photo for THIS question and show the result in a separate box
  bool _aiBusy = false;
  final Map<String, String> _aiAnswers = {}; // questionId -> AI analysis text

  // Strip markdown symbols from AI text
  String _cleanMd(String s) {
    return s
        .replaceAll(RegExp(r'\*\*'), '')
        .replaceAll(RegExp(r'#+\s*'), '')
        .replaceAll(RegExp(r'^\s*[>*-]\s*', multiLine: true), '')
        .trim();
  }

  // Split AI answer into titled boxes. Very forgiving - splits on any line that
  // starts with 1/2/3 and looks like a short heading (What to Check / Typical Finding / etc.)
  List<Map<String, String>> _aiSections(String raw) {
    // First strip markdown symbols entirely
    String text = raw.replaceAll(RegExp(r'[#*>`]'), '');
    final lines = text.split('\n');
    final result = <Map<String, String>>[];
    String? curTitle;
    final buffer = StringBuffer();

    void flush() {
      if (curTitle != null) {
        result.add({'title': curTitle!, 'body': buffer.toString().trim()});
      }
      buffer.clear();
    }

    for (final rawLine in lines) {
      final line = rawLine.trim();
      // Heading = starts with 1-5 then . or ) then a SHORT title (<= 6 words, no ending period)
      final m = RegExp(r'^([1-5])\s*[.)]\s*(.{2,50})$').firstMatch(line);
      bool isHeading = false;
      String title = '';
      if (m != null) {
        final candidate = m.group(2)!.trim();
        final wordCount = candidate.split(RegExp(r'\s+')).length;
        // a heading is short and doesn't end with a period/colon-sentence
        if (wordCount <= 6 && !candidate.endsWith('.')) {
          isHeading = true;
          title = candidate;
        }
      }
      if (isHeading) {
        flush();
        curTitle = title;
      } else {
        buffer.writeln(rawLine);
      }
    }
    flush();

    if (result.length >= 2) return result;
    // fallback: single box
    return [{'title': 'AI Analysis', 'body': text.trim()}];
  }

  // Answer the question text (uses attached photo if one exists, else text-only)
  Future<void> _aiGenerateComment(Question q) async {
    if (_aiBusy) return;
    setState(() => _aiBusy = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI is thinking…'), duration: Duration(seconds: 1)),
    );

    Map<String, dynamic> result;
    if (q.photos.isNotEmpty) {
      // use the question's attached photo + question text
      String b64 = q.photos.last.url;
      if (b64.contains(',')) b64 = b64.split(',').last;
      result = await ApiService.aiAnalyzeImage(b64, question: q.text);
      if (!mounted) return;
      setState(() {
        _aiBusy = false;
        if (result['success'] == true) {
          _aiAnswers[q.id] = result['analysis']?.toString() ?? '';
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['analysis']?.toString() ?? 'AI failed')),
          );
        }
      });
    } else {
      // no photo -> answer the question as text
      final prompt = 'You are a marine vessel inspector. For this inspection question: "${q.text}", answer in EXACTLY 3 numbered sections. '
          'Do NOT use asterisks, hashes or any markdown. Plain text only. Use these exact headings:\n'
          '1. What to Check\n(your points here)\n\n'
          '2. Typical Finding\n(a realistic example finding here)\n\n'
          '3. Suggested Answer/Comment\n(a ready-to-use inspector comment here)';
      result = await ApiService.aiAsk(prompt);
      if (!mounted) return;
      setState(() {
        _aiBusy = false;
        if (result['success'] == true) {
          _aiAnswers[q.id] = result['answer']?.toString() ?? '';
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['answer']?.toString() ?? 'AI failed')),
          );
        }
      });
    }
  }

  Future<void> _addMockPhoto(Question q) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      imageQuality: 60,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final base64Str = base64Encode(bytes);
    setState(() {
      q.photos.add(EvidencePhoto(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        url: 'data:image/jpeg;base64,$base64Str',
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF2EBDD),
      body: Column(
        children: [
          _topBar(),
          Expanded(
            child: isWide
                ? Row(
              children: [
                SizedBox(width: 260, child: _leftPanel()),
                Expanded(child: _middlePanel()),
                SizedBox(width: 300, child: _rightPanel()),
              ],
            )
                : _middlePanel(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (final ctrl in _commentControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _saveAndExit() async {
    final inspectionId = InspectionSession.currentInspectionId;
    if (inspectionId != null) {
      final answers = <String, dynamic>{};
      for (final s in widget.assignment.sections) {
        for (final q in s.questions) {
          if (q.answer == null && q.comment.isEmpty && q.photos.isEmpty) continue;
          String? ans;
          if (q.answer != null) {
            switch (q.answer!) {
              case AnswerValue.pass: ans = 'yes'; break;
              case AnswerValue.fail: ans = 'no'; break;
              case AnswerValue.na: ans = 'na'; break;
              case AnswerValue.nv: ans = 'nv'; break;
            }
          }
          answers[q.id] = {
            'answer': ans,
            'comment': q.comment,
            'question_text': q.text,
            'photos': q.photos.map((p) => p.url).toList(),
            'photo_captions': q.photos.map((p) => p.caption).toList(),
          };
        }
      }
      answers['__cover_image__'] = {'url': _coverImage};
      await ApiService.saveAnswers(inspectionId, answers);
    }
    if (mounted) Navigator.of(context).maybePop();
  }

  Widget _topBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: const Color(0xFFFDF8ED),
        border: Border(bottom: BorderSide(color: Color(0xFFE8D9C0), width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF555555)),
              onPressed: _saveAndExit,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                  'Inspection of ${widget.assignment.vesselName} (${widget.assignment.imo})',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E1F12)),
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 12),
            Text('$_answered/$_total answered',
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF8A6A4E))),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiAssistantScreen())),
              icon: const Icon(Icons.auto_awesome, size: 16, color: Color(0xFFFF6B00)),
              label: const Text('AI', style: TextStyle(fontSize: 12, color: Color(0xFFFF6B00))),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 40),
                side: const BorderSide(color: Color(0xFFFF6B00)),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _openCoverDialog,
              icon: Icon(Icons.image_outlined, size: 16,
                  color: _coverImage.isEmpty ? const Color(0xFF8A6A4E) : const Color(0xFFFF6B00)),
              label: Text(_coverImage.isEmpty ? 'Vessel Image' : 'Vessel Image ✓',
                  style: TextStyle(fontSize: 12, color: _coverImage.isEmpty ? const Color(0xFF8A6A4E) : const Color(0xFFFF6B00))),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 40),
                side: BorderSide(color: _coverImage.isEmpty ? const Color(0xFFE8D9C0) : const Color(0xFFFF6B00)),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _goToSignOff,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                foregroundColor: Colors.white,
                minimumSize: const Size(110, 40),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
              child: const Text('Submit →'),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════ LEFT PANEL ═══════════════
  Widget _leftPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF241008), Color(0xFF3A1D0C)],
        ),
      ),
      child: Column(
        children: [
          Container(
            color: const Color(0xFF1C0D06),
            padding: const EdgeInsets.only(left: 14),
            child: Row(
              children: [
                const Icon(Icons.anchor, color: Color(0xFFE8630A), size: 16),
                const SizedBox(width: 7),
                const Expanded(
                  child: Text('RIGHTKNOT',
                      style: TextStyle(
                          fontFamily: 'Georgia',
                          fontFamilyFallback: ['Times New Roman', 'serif'],
                          color: Color(0xFFF5EBDD),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 1.5)),
                ),
                _tabButton('sections', 'Sections'),
                _tabButton('all', "All Q's"),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (_leftTab == 'sections')
                  ...widget.assignment.sections
                      .asMap()
                      .entries
                      .map((e) => _sectionItem(e.value, e.key))
                else
                  ...widget.assignment.sections
                      .asMap()
                      .entries
                      .expand((e) => _allQuestionsForSection(e.value, e.key)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String id, String label) {
    final active = _leftTab == id;
    return GestureDetector(
      onTap: () => setState(() => _leftTab = id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE8630A) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : const Color(0xFFCBA87E),
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _sectionItem(Section s, int idx) {
    final col = _sectionColors[idx % _sectionColors.length];
    final isActive = _activeSectionId == s.id;
    final isExpanded = _expanded[s.id] ?? false;

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expanded[s.id] = !isExpanded;
              _activeSectionId = s.id;
              if (s.questions.isNotEmpty && !isExpanded) {
                _activeQuestionId = s.questions.first.id;
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? col.bg : Colors.white.withOpacity(0.03),
              border: Border(
                left: BorderSide(
                    color: isActive ? col.border : Colors.transparent,
                    width: 3),
                bottom: BorderSide(
                    color: Colors.white.withOpacity(0.06), width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(s.title,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? col.text
                              : const Color(0xFFD9B98F),
                          height: 1.4)),
                ),
                if (s.complete)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.check_circle,
                        color: Color(0xFF22C55E), size: 14),
                  ),
                Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: const Color(0xFFC49A6C),
                    size: 14),
              ],
            ),
          ),
        ),
        if (isExpanded)
          ...s.questions.map((q) => _questionItem(q, s.id, col)),
      ],
    );
  }

  List<Widget> _allQuestionsForSection(Section s, int idx) {
    if (s.questions.isEmpty) return [];
    final col = _sectionColors[idx % _sectionColors.length];
    return [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: col.bg,
          border: Border(
            left: BorderSide(color: col.border, width: 3),
            bottom: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
          ),
        ),
        child: Text(s.title,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: col.text)),
      ),
      ...s.questions.map((q) => _questionItem(q, s.id, col)),
    ];
  }

  Widget _questionItem(Question q, String sectionId,
      ({Color bg, Color border, Color text}) col) {
    final isActive = _activeQuestionId == q.id;
    Color? ansColor;
    String? ansText;
    if (q.answer != null) {
      switch (q.answer!) {
        case AnswerValue.pass:
          ansColor = const Color(0xFF22C55E);
          ansText = 'Yes';
          break;
        case AnswerValue.fail:
          ansColor = const Color(0xFFEF4444);
          ansText = 'No';
          break;
        case AnswerValue.na:
          ansColor = const Color(0xFFD9B98F);
          ansText = 'N/A';
          break;
        case AnswerValue.nv:
          ansColor = const Color(0xFFD9B98F);
          ansText = 'N/V';
          break;
      }
    }

    return InkWell(
      onTap: () => setState(() {
        _activeSectionId = sectionId;
        _activeQuestionId = q.id;
      }),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 7, 12, 7),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withOpacity(0.1)
              : Colors.white.withOpacity(0.02),
          border: Border(
            left: BorderSide(
                color: isActive ? col.border : Colors.transparent, width: 3),
            bottom:
            BorderSide(color: Colors.white.withOpacity(0.03), width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              child: Text(q.id,
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xFFC49A6C))),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(q.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11,
                      color: isActive
                          ? const Color(0xFFE8D9C0)
                          : const Color(0xFFCBA87E),
                      height: 1.4)),
            ),
            if (ansText != null) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(ansText,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: ansColor)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════ MIDDLE PANEL ═══════════════
  Widget _middlePanel() {
    return Container(
      color: const Color(0xFFF2EBDD),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _buildQuestionArea(),
      ),
    );
  }

  Widget _buildQuestionArea() {
    final q = _activeQuestion;
    final s = _activeSection;

    if (q == null || s == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 100),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.arrow_back, size: 40, color: Color(0xFFB59D7E)),
              SizedBox(height: 12),
              Text('Select a question from the left panel',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB59D7E))),
            ],
          ),
        ),
      );
    }

    if (_isGeneralInfo(s)) {
      return _buildGeneralInfoLayout(s);
    }

    return _buildStandardQuestionLayout(s, q);
  }

  Widget _buildGeneralInfoLayout(Section s) {
    return Container(
      color: const Color(0xFFFDF8ED),
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.title,
              style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontFamilyFallback: ['Times New Roman', 'serif'],
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFE8630A))),
          const SizedBox(height: 30),
          ...s.questions.map((q) => _buildGeneralInfoQuestion(q)),
          const SizedBox(height: 20),
          _buildNavButtons(),
        ],
      ),
    );
  }

  Widget _buildGeneralInfoQuestion(Question q) {
    final isEditing = _editingField[q.id] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5C2E0E)),
            children: [
              TextSpan(text: '${q.id} ${q.text}'),
              const TextSpan(text: ': '),
              if (q.required)
                const TextSpan(
                    text: '(M)',
                    style: TextStyle(color: Color(0xFF5C2E0E))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: isEditing
                  ? TextField(
                controller: _commentCtrl(q),
                autofocus: true,
                onChanged: (v) => q.comment = v,
                onSubmitted: (_) => setState(() {
                  _editingField[q.id] = false;
                  q.answer = AnswerValue.pass;
                }),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFFDF8ED),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                    const BorderSide(color: Color(0xFF5C2E0E)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
                style: const TextStyle(fontSize: 14),
              )
                  : Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E7D3),
                  border: Border.all(color: const Color(0xFFE8D9C0)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                    q.comment.isEmpty ? '(No value)' : q.comment,
                    style: TextStyle(
                        fontSize: 14,
                        color: q.comment.isEmpty
                            ? const Color(0xFFB59D7E)
                            : const Color(0xFF2E1F12))),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 150,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => setState(() {
                  _editingField[q.id] = !isEditing;
                  if (isEditing && q.comment.isNotEmpty) {
                    q.answer = AnswerValue.pass;
                  }
                }),
                icon: Icon(isEditing ? Icons.check : Icons.edit,
                    size: 17, color: const Color(0xFFE8630A)),
                label: Text(isEditing ? 'Done' : 'Edit'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFFDF8ED),
                  foregroundColor: const Color(0xFFE8630A),
                  side: const BorderSide(color: Color(0xFFE8630A), width: 1.3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Additional comment',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5C2E0E))),
        const SizedBox(height: 8),
        TextField(
          maxLines: 4,
          maxLength: 1000,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFFDF8ED),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFDECBAB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFDECBAB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE8630A), width: 1.4),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 20),
        Container(height: 1, color: const Color(0xFFE8D9C0)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStandardQuestionLayout(Section s, Question q) {
    final selected = q.answer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title (orange serif, like General Information page)
        Text(s.title,
            style: const TextStyle(
                fontFamily: 'Georgia',
                fontFamilyFallback: ['Times New Roman', 'serif'],
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFFE8630A))),
        const SizedBox(height: 20),
        // Question heading: "2.1.1  Are all fire extinguishers..." plain on cream
        Text('${q.id}  ${q.text}',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3D2817),
                height: 1.5)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF8ED),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE8D9C0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Answer',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A3624))),
              const SizedBox(height: 10),
              Row(
                children: [
                  _answerBtn('Yes', AnswerValue.pass, selected),
                  const SizedBox(width: 8),
                  _answerBtn('No', AnswerValue.fail, selected),
                  const SizedBox(width: 8),
                  _answerBtn('N/A', AnswerValue.na, selected),
                  const SizedBox(width: 8),
                  _answerBtn('N/V', AnswerValue.nv, selected),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (selected == AnswerValue.fail)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F5),
              border: Border.all(color: const Color(0xFFFCA5A5)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Observation',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF991B1B))),
                const SizedBox(height: 10),
                TextField(
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Enter observation details...',
                    filled: true,
                    fillColor: const Color(0xFFFDF8ED),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFFCA5A5)),
                    ),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        // Comment section
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF8ED),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE8D9C0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Comment:',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF5C2E0E))),
                  if (selected == AnswerValue.na ||
                      selected == AnswerValue.nv)
                    const Text(' *',
                        style: TextStyle(color: Color(0xFFEF4444))),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: _aiBusy ? null : () => _aiGenerateComment(q),
                    icon: const Icon(Icons.auto_awesome, size: 15, color: Color(0xFFFF6B00)),
                    label: Text(_aiBusy ? 'Thinking…' : 'AI Answer',
                        style: const TextStyle(fontSize: 12, color: Color(0xFFFF6B00), fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      side: const BorderSide(color: Color(0xFFFF6B00)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                maxLines: 4,
                maxLength: 1000,
                controller: _commentCtrl(q),
                onChanged: (v) => q.comment = v,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFFDF8ED),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFDECBAB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFDECBAB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE8630A), width: 1.4),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                style: const TextStyle(fontSize: 13),
              ),
              // ─── AI answer: 3 separate boxes, each copyable ───
              if (_aiAnswers[q.id] != null && _aiAnswers[q.id]!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 15, color: Color(0xFFFF6B00)),
                    const SizedBox(width: 6),
                    const Text('AI Analysis',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFFF6B00))),
                    const Spacer(),
                    InkWell(
                      onTap: () => setState(() => _aiAnswers.remove(q.id)),
                      child: const Icon(Icons.close, size: 16, color: Color(0xFFB59D7E)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...(() {
                  final sections = _aiSections(_aiAnswers[q.id] ?? '');
                  return List.generate(sections.length, (idx) {
                    final title = sections[idx]['title'] ?? 'Section ${idx + 1}';
                    final body = sections[idx]['body'] ?? '';
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3EC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFF6B00)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B00),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('${idx + 1}. $title',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                              ),
                              const Spacer(),
                              InkWell(
                                onTap: () {
                                  final txt = _commentCtrl(q).text;
                                  final merged = txt.isEmpty ? body : '$txt\n$body';
                                  _commentCtrl(q).text = merged;
                                  q.comment = merged;
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Copied "$title" to comment'), duration: const Duration(seconds: 1)),
                                  );
                                },
                                child: Row(
                                  children: const [
                                    Icon(Icons.copy, size: 13, color: Color(0xFF5C2E0E)),
                                    SizedBox(width: 3),
                                    Text('Copy',
                                        style: TextStyle(fontSize: 11, color: Color(0xFF5C2E0E), fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(body, style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF2E1F12))),
                        ],
                      ),
                    );
                  });
                })(),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        // NEW Evidence section
        _buildEvidenceSection(q),
        const SizedBox(height: 16),
        _buildNavButtons(),
      ],
    );
  }

  // ═══════════════ EVIDENCE SECTION (RightShip style) ═══════════════
  Widget _buildEvidenceSection(Question q) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF8ED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8D9C0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Evidence',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5C2E0E))),
          const SizedBox(height: 14),
          // Existing photos grid
          if (q.photos.isNotEmpty) ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
              itemCount: q.photos.length,
              itemBuilder: (context, idx) =>
                  _photoCard(q, q.photos[idx], idx),
            ),
            const SizedBox(height: 14),
          ],
          // Two "photo slots" boxes with Take Photo + Choose File buttons
          Row(
            children: [
              Expanded(child: _photoSlot(q)),
              const SizedBox(width: 12),
              Expanded(child: _photoSlot(q)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _photoSlot(Question q) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFFFDF8ED),
        border: Border.all(color: const Color(0xFFE8D9C0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _addMockPhoto(q),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
              child: const Text('Take Photo'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _addMockPhoto(q),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
              child: const Text('Choose File'),
            ),
          ),
        ],
      ),
    );
  }

  final Map<String, String> _photoAiAnswers = {}; // photoId -> AI text
  bool _photoAiBusy = false;

  Future<void> _aiAnalyzeEvidence(Question q, EvidencePhoto photo) async {
    if (_photoAiBusy) return;
    setState(() => _photoAiBusy = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI analysing evidence…'), duration: Duration(seconds: 1)),
    );
    String b64 = photo.url;
    if (b64.contains(',')) b64 = b64.split(',').last;
    final result = await ApiService.aiAnalyzeImage(b64, question: q.text);
    if (!mounted) return;
    setState(() {
      _photoAiBusy = false;
      if (result['success'] == true) {
        final analysis = _cleanMd(result['analysis']?.toString() ?? '');
        _photoAiAnswers[photo.id] = analysis;
        photo.caption = analysis; // SAVE it on the photo so it persists + shows in PDF
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['analysis']?.toString() ?? 'AI failed')),
        );
      }
    });
  }

  Widget _photoCard(Question q, EvidencePhoto photo, int idx) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE8D9C0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFFF3E7D3),
              alignment: Alignment.center,
              child: photo.url.startsWith('data:image')
                  ? Image.memory(base64Decode(photo.url.split(',').last), fit: BoxFit.cover, width: double.infinity,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, size: 40, color: Color(0xFFB59D7E)))
                  : photo.url.startsWith('http')
                  ? Image.network(photo.url, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined, size: 40, color: Color(0xFFB59D7E)))
                  : const Icon(Icons.image_outlined, size: 40, color: Color(0xFFB59D7E)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                  top: BorderSide(color: Color(0xFFE8D9C0), width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _photoActionBtn(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  color: const Color(0xFF3B82F6),
                  onTap: () =>
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => PhotoEditorScreen(
                          imageUrl: photo.url,
                          initialCaption: photo.caption,
                          onSave: (url, caption) {
                            setState(() {
                              photo.url = url;
                              photo.caption = caption;
                            });
                          },
                        ),
                      )),
                ),
                _photoActionBtn(
                  icon: Icons.auto_awesome,
                  label: 'AI',
                  color: const Color(0xFFFF6B00),
                  onTap: () => _aiAnalyzeEvidence(q, photo),
                ),
                _photoActionBtn(
                  icon: Icons.download_outlined,
                  label: 'Download',
                  color: const Color(0xFF3B82F6),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Download started...')),
                    );
                  },
                ),
                _photoActionBtn(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  color: const Color(0xFFEF4444),
                  onTap: () => setState(() => q.photos.removeAt(idx)),
                ),
              ],
            ),
          ),
          if (_photoAiAnswers[photo.id] != null && _photoAiAnswers[photo.id]!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF3EC),
                border: Border(top: BorderSide(color: Color(0xFFFF6B00))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 13, color: Color(0xFFFF6B00)),
                      const SizedBox(width: 5),
                      const Text('AI Analysis',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFFF6B00))),
                      const Spacer(),
                      InkWell(
                        onTap: () => setState(() => _photoAiAnswers.remove(photo.id)),
                        child: const Icon(Icons.close, size: 13, color: Color(0xFFB59D7E)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(_photoAiAnswers[photo.id] ?? '',
                      style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF2E1F12))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _photoActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }

  Widget _buildNavButtons() {
    final q = _activeQuestion;
    if (q == null) return const SizedBox.shrink();
    final all = _allFlat;
    final currentIdx = all.indexWhere((e) => e.q.id == q.id);
    final prev = currentIdx > 0 ? all[currentIdx - 1] : null;
    final next = currentIdx < all.length - 1 ? all[currentIdx + 1] : null;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: prev == null
                ? null
                : () => setState(() {
              _activeSectionId = prev.sectionId;
              _activeQuestionId = prev.q.id;
            }),
            icon: const Icon(Icons.arrow_back, size: 17),
            label: const Text('Previous'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF9E3CD),
              foregroundColor: const Color(0xFF8A4A1B),
              disabledBackgroundColor: const Color(0xFFF0E6D2),
              disabledForegroundColor: const Color(0xFFB59D7E),
              elevation: 0,
              minimumSize: const Size(0, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: next == null
                ? _goToSignOff
                : () => setState(() {
              _activeSectionId = next.sectionId;
              _activeQuestionId = next.q.id;
            }),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8630A),
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(0, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700),
            ),
            child: Text(next != null ? 'Next  →' : 'Sign Off  →'),
          ),
        ),
      ],
    );
  }

  Widget _answerBtn(String label, AnswerValue value, AnswerValue? selected) {
    final isSel = selected == value;
    Color borderColor;
    Color bgColor;
    Color textColor;
    switch (value) {
      case AnswerValue.pass:
        borderColor = isSel ? const Color(0xFF22C55E) : const Color(0xFFDECBAB);
        bgColor = isSel ? const Color(0xFFDCFCE7) : Colors.white;
        textColor = isSel ? const Color(0xFF166534) : const Color(0xFF8A6A4E);
        break;
      case AnswerValue.fail:
        borderColor = isSel ? const Color(0xFFEF4444) : const Color(0xFFDECBAB);
        bgColor = isSel ? const Color(0xFFFEE2E2) : Colors.white;
        textColor = isSel ? const Color(0xFF991B1B) : const Color(0xFF8A6A4E);
        break;
      default:
        borderColor = isSel ? const Color(0xFFB59D7E) : const Color(0xFFDECBAB);
        bgColor = isSel ? const Color(0xFFF3E7D3) : Colors.white;
        textColor = isSel ? const Color(0xFF4A3624) : const Color(0xFF8A6A4E);
    }

    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          final q = _activeQuestion;
          if (q != null) {
            q.answer = q.answer == value ? null : value;
          }
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor, width: isSel ? 2 : 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                  color: textColor)),
        ),
      ),
    );
  }

  // ═══════════════ RIGHT PANEL ═══════════════
  Widget _rightPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF7EFE0),
        border: Border(left: BorderSide(color: Color(0xFFE8D9C0), width: 1)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF5C2E0E),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('GUIDE TO INSPECTION',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFF6B00),
                        letterSpacing: 1)),
                SizedBox(height: 2),
                Text('Reference for selected question',
                    style: TextStyle(
                        fontSize: 11, color: Color(0xFFCBA87E))),
              ],
            ),
          ),
          Expanded(child: _buildGuideContent()),
        ],
      ),
    );
  }

  Widget _buildGuideContent() {
    final q = _activeQuestion;
    if (q == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No question selected',
              style: TextStyle(fontSize: 13, color: Color(0xFFB59D7E))),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9E3CD),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Question ${q.id}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5C2E0E))),
                const SizedBox(height: 4),
                Text(q.text,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4A3624),
                        height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (q.guide.isNotEmpty)
            Text(q.guide,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF4A3624), height: 1.8))
          else
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Center(
                child: Text('No guide available for this question.',
                    style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFB59D7E),
                        fontStyle: FontStyle.italic)),
              ),
            ),
        ],
      ),
    );
  }
}