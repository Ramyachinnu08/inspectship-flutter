import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
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

  // Cached controllers for the Observation boxes (No answers)
  // so typed text is never lost.
  final Map<String, TextEditingController> _obsControllers = {};
  TextEditingController _obsCtrl(Question q) {
    return _obsControllers.putIfAbsent(
        q.id,
            () => TextEditingController(
            text: q.commentByAnswer['__observation__'] ?? ''));
  }

  // Separate cached controllers for the General Information
  // "Additional comment" boxes so typed text is never lost.
  final Map<String, TextEditingController> _extraControllers = {};
  TextEditingController _extraCtrl(Question q) {
    return _extraControllers.putIfAbsent(
        q.id,
            () => TextEditingController(
            text: q.commentByAnswer['__extra__'] ?? ''));
  }
  String _leftTab = 'sections';
  String? _activeSectionId;
  String? _activeQuestionId;
  final ItemScrollController _itemScroll = ItemScrollController();
  final ItemPositionsListener _itemPositions = ItemPositionsListener.create();
  int _scrollReq = 0;   // bumped when sidebar/nav explicitly repositions the list
  int _initialIdx = 0;  // where the list should open on reposition
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
    // Guide panel follows scrolling: track the topmost visible question.
    _itemPositions.itemPositions.addListener(() {
      final s = _activeSection;
      if (s == null) return;
      final positions = _itemPositions.itemPositions.value;
      if (positions.isEmpty) return;
      // Topmost question that occupies real screen space: an item barely
      // hanging in from above (last few pixels) doesn't count, so the
      // guide matches the question whose heading you actually see.
      int? topIndex;
      double best = double.infinity;
      for (final p in positions) {
        if (p.itemTrailingEdge <= 0.12) continue; // must cover >12% line
        if (p.itemLeadingEdge < best) {
          best = p.itemLeadingEdge;
          topIndex = p.index;
        }
      }
      if (topIndex == null) return;
      final qIdx = topIndex - 1; // index 0 is the section title
      if (qIdx < 0 || qIdx >= s.questions.length) return;
      final qid = s.questions[qIdx].id;
      if (qid != _activeQuestionId) {
        setState(() => _activeQuestionId = qid);
      }
    });
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


  /// RightShip / RISQ style comment prompt. The comment MUST agree with the
  /// selected answer (yes/no/na/nv) and with the finding text for a No.
  static String _buildCommentPrompt({
    required String question,
    required String section,
    required String answer,
    required String finding,
  }) {
    final b = StringBuffer();
    b.writeln('You are a senior marine vessel inspector writing a formal RightShip (RISQ) style '
        'inspection report. Plain text only - no asterisks, hashes or markdown.');
    if (section.isNotEmpty) b.writeln('Section: $section');
    b.writeln('Question: "$question"');
    switch (answer) {
      case 'yes': b.writeln('Selected answer: YES (in order / satisfactory).'); break;
      case 'no': b.writeln('Selected answer: NO (deficiency observed).'); break;
      case 'na': b.writeln('Selected answer: NOT APPLICABLE.'); break;
      case 'nv': b.writeln('Selected answer: NOT VIEWED.'); break;
      default: b.writeln('Selected answer: not yet chosen - assume YES.');
    }
    if (answer == 'no' && finding.isNotEmpty) {
      b.writeln('Finding already recorded by the inspector: "$finding"');
    }
    b.writeln();
    b.writeln('Answer in EXACTLY 3 numbered sections with these exact headings:');
    b.writeln('1. What to Check');
    b.writeln('(short practical checklist of what to verify on board)');
    b.writeln();
    b.writeln('2. Typical Finding');
    if (answer == 'no') {
      b.writeln(finding.isNotEmpty
          ? '(Rewrite the recorded finding above as ONE factual deficiency statement in past '
          'tense. Keep the same defect, location and component - do not invent a different one.)'
          : '(ONE factual deficiency statement in past tense: location + component + defect + '
          'consequence, e.g. "One air pipe on the forward main deck leading to the forepeak '
          'ballast tank was heavily corroded with a through-thickness hole near the deck '
          'penetration.")');
    } else {
      b.writeln('(Write exactly: "No deficiency observed.")');
    }
    b.writeln();
    b.writeln('3. Suggested Answer/Comment');
    b.writeln('(a ready-to-use inspector comment, past tense, factual record, maximum 2 sentences.)');
    switch (answer) {
      case 'no':
        b.writeln('Structure: what was checked (quantities, e.g. "2 x 35 persons lifeboats"), how, '
            'and by whom ("in the presence of the Chief Officer"), THEN end with the deficiency '
            'from section 2. The comment must describe the SAME defect as the finding. Never say '
            '"found in satisfactory condition" for the item that is defective.');
        break;
      case 'na':
        b.writeln('Write 1-2 sentences as a factual record: state what arrangement the vessel has '
            'or does not have and WHY this question does not apply (e.g. "Vessel is not fitted '
            'with an exhaust gas cleaning system; compliant low-sulphur fuel is used and no EGCS '
            'procedures are required in the SMS."). You may mention the document or person who '
            'confirmed it ("confirmed with the Chief Engineer"). Do NOT write that the item was '
            'inspected or tested, and do NOT use "found in satisfactory condition".');
        break;
      case 'nv':
        b.writeln('Write 1-2 sentences as a factual record: state WHY the item could not be '
            'sighted (e.g. cargo operations in progress, space not accessible, vessel at sea, '
            'weather) and what supporting evidence WAS available (e.g. PMS records, last '
            'inspection report, photographs, officer statement). Example: "Duct keel was not '
            'entered as cargo operations were in progress. PMS records showed the last internal '
            'inspection completed by ship staff with no defects recorded." Do NOT use the words '
            'inspected, tested or satisfactory for the item itself.');
        break;
      default:
        b.writeln('Structure: quantities/inventory, what was checked and how ("were checked at '
            'random and found in order"), and by whom if relevant ("in the presence of the Chief '
            'Engineer"). The answer is YES, so do NOT use: missing, incomplete, unsatisfactory, '
            'not in satisfactory condition, failed, lacked, overdue, except, "except for", '
            '"as noted in the findings", "noted above", "previously noted", or any deficiency.');
    }
    b.writeln();
    b.writeln('STRICT WORDING RULES:');
    b.writeln('- Certificates, records, plans, manuals, logbooks and agreements are "found valid", '
        '"found in order" or "found up to date" - never "in satisfactory condition".');
    b.writeln('- Use "at random" only when several items were checked, and never together with '
        '"All" (write "All 5 hatch covers were checked" OR "3 x hatch covers were checked at random").');
    b.writeln('- Do not prefix a single document with "1 x"; use counts only for equipment.');
    b.writeln('- Neutral voice: write "no documented measures were in place", never "the Master failed to".');
    b.writeln('- No dates, serial numbers, makers or models unless given in the question. '
        'No placeholders such as __/__/____, DD/MM/YYYY, [Date] or N/A fields.');
    b.writeln('- Record observations only. No recommendations, "should", "must", "immediately", '
        '"prior to departure" or corrective actions.');
    return b.toString();
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
      // Tell the AI which answer was selected and what the observation
      // (finding) says, so comment / answer / finding never contradict.
      final ansKey = Question.keyFor(q.answer);
      final finding = (q.commentByAnswer['__observation__'] ?? '').trim();
      String secTitle = '';
      for (final s in widget.assignment.sections) {
        if (s.questions.any((x) => x.id == q.id)) { secTitle = s.title; break; }
      }
      final prompt = _buildCommentPrompt(
          question: q.text, section: secTitle, answer: ansKey, finding: finding);
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

  Future<void> _addMockPhoto(Question q,
      {ImageSource source = ImageSource.gallery}) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
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
    _scheduleAutoSave();
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
    _autoSaveTimer?.cancel();
    for (final ctrl in _commentControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _collectAnswers() {
    final answers = <String, dynamic>{};
    for (final s in widget.assignment.sections) {
      for (final q in s.questions) {
        final extra = q.commentByAnswer['__extra__'] ?? '';
        final obs = q.commentByAnswer['__observation__'] ?? '';
        if (q.answer == null && q.comment.isEmpty && q.photos.isEmpty && extra.isEmpty && obs.isEmpty) continue;
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
          'extra_comment': q.commentByAnswer['__extra__'] ?? '',
          'observation': q.commentByAnswer['__observation__'] ?? '',
          'question_text': q.text,
          'photos': q.photos.map((p) => p.url).toList(),
          'photo_captions': q.photos.map((p) => p.caption).toList(),
        };
      }
    }
    answers['__cover_image__'] = {'url': _coverImage};
    return answers;
  }

  Timer? _autoSaveTimer;

  /// Auto-save: called on every answer/comment/photo change.
  /// Waits 2s of quiet before saving so we don't save on every keystroke.
  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () async {
      final inspectionId = InspectionSession.currentInspectionId;
      if (inspectionId == null) return;
      try {
        await ApiService.saveAnswers(inspectionId, _collectAnswers());
      } catch (_) {/* silent; next change retries */}
    });
  }

  Future<void> _saveAndExit() async {
    _autoSaveTimer?.cancel();
    final inspectionId = InspectionSession.currentInspectionId;
    if (inspectionId != null) {
      await ApiService.saveAnswers(inspectionId, _collectAnswers());
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
                  child: Text('RIGHTKNOTS',
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      softWrap: false,
                      style: TextStyle(
                          fontFamily: 'Georgia',
                          fontFamilyFallback: ['Times New Roman', 'serif'],
                          color: Color(0xFFF5EBDD),
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                          letterSpacing: 0.8)),
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
      onTap: () {
        // find the question's position in its section for the list opening
        int idx = 0;
        for (final sec in widget.assignment.sections) {
          if (sec.id == sectionId) {
            final i = sec.questions.indexWhere((x) => x.id == q.id);
            if (i >= 0) idx = i + 1; // index 0 is the title
            break;
          }
        }
        setState(() {
          _activeSectionId = sectionId;
          _activeQuestionId = q.id;
          _initialIdx = idx;
          _scrollReq++; // reposition the list
        });
      },
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
              child: Text(q.number,
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
    final q = _activeQuestion;
    final s = _activeSection;

    // Standard sections: lazy list — only visible questions are built,
    // so large sections stay fast while scrolling and answering.
    if (q != null && s != null && !_isGeneralInfo(s)) {
      final count = s.questions.length;
      // The list repositions only on explicit requests (sidebar click or
      // Next/Previous) via _scrollReq; guide updates from scrolling do not
      // recreate it.
      return Container(
        color: const Color(0xFFF2EBDD),
        child: ScrollablePositionedList.builder(
          key: ValueKey('sec-${s.id}-req-$_scrollReq'),
          itemScrollController: _itemScroll,
          itemPositionsListener: _itemPositions,
          initialScrollIndex: _initialIdx,
          initialAlignment: 0.02,
          padding: const EdgeInsets.all(24),
          itemCount: count + 2, // title + questions + nav buttons
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(s.title,
                    style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontFamilyFallback: ['Times New Roman', 'serif'],
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE8630A))),
              );
            }
            if (i == count + 1) {
              return Padding(
                padding: const EdgeInsets.only(top: 28, bottom: 8),
                child: _buildNavButtons(),
              );
            }
            final question = s.questions[i - 1];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStandardQuestionLayout(s, question),
                if (i < count)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 26),
                    child: Divider(
                        color: Color(0xFFE0CBA8), height: 1, thickness: 1),
                  ),
              ],
            );
          },
        ),
      );
    }

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

    // Standard sections are rendered lazily in _middlePanel.
    return const SizedBox.shrink();
  }

  /// Fill general-info fields the app already knows the answer to
  /// (vessel name, IMO, port, inspection scope/template, date).
  void _autoFillGeneralInfo(Section s) {
    final a = widget.assignment;
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final today = DateTime.now();
    final dateStr = '${today.day} ${months[today.month - 1]} ${today.year}';
    int filled = 0;
    for (final q in s.questions) {
      if (q.comment.isNotEmpty) continue; // never overwrite typed values
      final t = q.text.toLowerCase();
      String? value;
      if (t.contains('imo')) {
        value = a.imo.replaceAll('IMO ', '');
      } else if (t.contains('name')) {
        value = a.vesselName;
      } else if (t.contains('port')) {
        value = a.port;
      } else if (t.contains('scope') || t.contains('template') || t.contains('type of inspection')) {
        value = a.templateName;
      } else if (t.contains('date of inspection') || t.contains('inspection date')) {
        value = dateStr;
      }
      if (value != null && value.trim().isNotEmpty) {
        q.comment = value.trim();
        _commentCtrl(q).text = q.comment;
        q.answer = AnswerValue.pass;
        filled++;
      }
    }
    setState(() {});
    if (filled > 0) _scheduleAutoSave();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(filled > 0
              ? 'Auto-filled $filled field(s) from vessel data'
              : 'No matching empty fields to auto-fill'),
          duration: const Duration(seconds: 2)),
    );
  }

  Widget _buildGeneralInfoLayout(Section s) {
    return Container(
      color: const Color(0xFFFDF8ED),
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(s.title,
                    style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontFamilyFallback: ['Times New Roman', 'serif'],
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE8630A))),
              ),
              ElevatedButton.icon(
                onPressed: () => _autoFillGeneralInfo(s),
                icon: const Icon(Icons.bolt, size: 18, color: Colors.white),
                label: const Text('Auto-fill'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8630A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
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
              TextSpan(text: '${q.number} ${q.text}'),
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
                onChanged: (v) { q.comment = v; _scheduleAutoSave(); },
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
            const SizedBox(width: 12),
            // AI button: asks the AI about this field
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _aiBusy ? null : () => _aiGenerateComment(q),
                icon: const Icon(Icons.auto_awesome,
                    size: 16, color: Color(0xFFE8630A)),
                label: Text(_aiBusy ? '…' : 'AI'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFFDF8ED),
                  foregroundColor: const Color(0xFFE8630A),
                  side:
                  const BorderSide(color: Color(0xFFE8630A), width: 1.3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 10),
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
          controller: _extraCtrl(q),
          onChanged: (v) {
            q.commentByAnswer['__extra__'] = v;
            _scheduleAutoSave();
          },
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
        // ─── AI answer boxes (same as standard questions) ───
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
                              SnackBar(content: Text('Copied "$title" to field'), duration: const Duration(seconds: 1)),
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
        // Question heading: "2.1.1  Are all fire extinguishers..." plain on cream
        Text('${q.number}  ${q.text}',
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
                  _answerBtn(q, 'Yes', AnswerValue.pass, selected),
                  const SizedBox(width: 8),
                  _answerBtn(q, 'No', AnswerValue.fail, selected),
                  const SizedBox(width: 8),
                  _answerBtn(q, 'N/A', AnswerValue.na, selected),
                  const SizedBox(width: 8),
                  _answerBtn(q, 'N/V', AnswerValue.nv, selected),
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
                  controller: _obsCtrl(q),
                  onChanged: (v) {
                    q.commentByAnswer['__observation__'] = v;
                    _scheduleAutoSave();
                  },
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
                onChanged: (v) { q.comment = v; _scheduleAutoSave(); },
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
                                  final isFinding =
                                  title.toLowerCase().contains('finding');
                                  if (isFinding) {
                                    // Typical Finding -> Observation box
                                    final txt = _obsCtrl(q).text;
                                    final merged =
                                    txt.isEmpty ? body : '$txt\n$body';
                                    _obsCtrl(q).text = merged;
                                    q.commentByAnswer['__observation__'] =
                                        merged;
                                  } else {
                                    final txt = _commentCtrl(q).text;
                                    final merged =
                                    txt.isEmpty ? body : '$txt\n$body';
                                    _commentCtrl(q).text = merged;
                                    q.comment = merged;
                                  }
                                  setState(() {});
                                  _scheduleAutoSave();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(isFinding
                                            ? 'Copied "$title" to Observation'
                                            : 'Copied "$title" to comment'),
                                        duration:
                                        const Duration(seconds: 1)),
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
          // Existing photos grid (long-press a photo and drag to reorder)
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
                  _draggablePhotoTile(q, idx),
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

  /// Photo tile that can be long-pressed and dragged onto another tile
  /// to change the order of evidence photos.
  Widget _draggablePhotoTile(Question q, int idx) {
    // Plain photo tile — no overlay marks.
    return _photoCard(q, q.photos[idx], idx);
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
              onPressed: () =>
                  _addMockPhoto(q, source: ImageSource.camera),
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
                  onTap: () {
                    setState(() => q.photos.removeAt(idx));
                    _scheduleAutoSave();
                  },
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
    final sections = widget.assignment.sections;
    final idx = sections.indexWhere((sec) => sec.id == _activeSectionId);
    if (idx < 0) return const SizedBox.shrink();
    final prevSection = idx > 0 ? sections[idx - 1] : null;
    final nextSection = idx < sections.length - 1 ? sections[idx + 1] : null;

    void goTo(Section sec) {
      setState(() {
        _activeSectionId = sec.id;
        _activeQuestionId =
        sec.questions.isNotEmpty ? sec.questions.first.id : null;
        _initialIdx = 0;
        _scrollReq++; // reposition the list to the top of the section
      });
      // jump back to the top of the new section
      // (middle panel is a SingleChildScrollView; rebuild starts at top)
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: prevSection == null ? null : () => goTo(prevSection),
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
            onPressed: nextSection == null
                ? _goToSignOff
                : () => goTo(nextSection),
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
            child: Text(nextSection != null ? 'Next  →' : 'Sign Off  →'),
          ),
        ),
      ],
    );
  }

  Widget _answerBtn(Question q, String label, AnswerValue value, AnswerValue? selected) {
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
        onTap: () {
          setState(() {
            q.answer = q.answer == value ? null : value;
            _activeQuestionId = q.id; // guide shows this question
          });
          _scheduleAutoSave();
        },
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