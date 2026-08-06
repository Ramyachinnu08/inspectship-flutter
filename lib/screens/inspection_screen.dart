import 'package:flutter/material.dart';
import '../models/models.dart';
import 'signoff_screen.dart';
import 'photo_editor_screen.dart';

class InspectionScreen extends StatefulWidget {
  final Assignment assignment;
  const InspectionScreen({super.key, required this.assignment});

  @override
  State<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends State<InspectionScreen> {
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

  void _addMockPhoto(Question q) {
    setState(() {
      q.photos.add(EvidencePhoto(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        url: 'https://picsum.photos/400/300?random=${q.photos.length + 1}',
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
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

  Widget _topBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFDDDDDD), width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF555555)),
              onPressed: () => Navigator.of(context).maybePop(),
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
                      color: Color(0xFF111111)),
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 12),
            Text('$_answered/$_total answered',
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF6B7280))),
            const SizedBox(width: 12),
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
      color: const Color(0xFF1A2A5E),
      child: Column(
        children: [
          Container(
            color: const Color(0xFFFF6B00),
            padding: const EdgeInsets.only(left: 14),
            child: Row(
              children: [
                const Expanded(
                  child: Text('SEA SECURE',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 1)),
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
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? Colors.black.withOpacity(0.25)
              : Colors.black.withOpacity(0.1),
          border: Border(
            left: const BorderSide(color: Colors.white24, width: 1),
            bottom: BorderSide(
                color: active ? Colors.white : Colors.transparent, width: 2),
          ),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : Colors.white70,
                fontSize: 10,
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
                              : const Color(0xFF94A3B8),
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
                    color: const Color(0xFF475569),
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
          ansColor = const Color(0xFF94A3B8);
          ansText = 'N/A';
          break;
        case AnswerValue.nv:
          ansColor = const Color(0xFF94A3B8);
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
                      fontSize: 10, color: Color(0xFF475569))),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(q.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11,
                      color: isActive
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFF64748B),
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
      color: const Color(0xFFF0F2F5),
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
              Icon(Icons.arrow_back, size: 40, color: Color(0xFF9CA3AF)),
              SizedBox(height: 12),
              Text('Select a question from the left panel',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9CA3AF))),
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
      color: Colors.white,
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.title,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFF6B00))),
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
                color: Color(0xFF1A2A5E)),
            children: [
              TextSpan(text: '${q.id} ${q.text}'),
              const TextSpan(text: ': '),
              if (q.required)
                const TextSpan(
                    text: '(M)',
                    style: TextStyle(color: Color(0xFF1A2A5E))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: isEditing
                  ? TextField(
                controller: TextEditingController(text: q.comment)
                  ..selection = TextSelection.collapsed(
                      offset: q.comment.length),
                autofocus: true,
                onChanged: (v) => q.comment = v,
                onSubmitted: (_) => setState(() {
                  _editingField[q.id] = false;
                  q.answer = AnswerValue.pass;
                }),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide:
                    const BorderSide(color: Color(0xFF1A2A5E)),
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
                  color: const Color(0xFFF3F4F6),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                    q.comment.isEmpty ? '(No value)' : q.comment,
                    style: TextStyle(
                        fontSize: 14,
                        color: q.comment.isEmpty
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF111111))),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 150,
              height: 44,
              child: ElevatedButton(
                onPressed: () => setState(() {
                  _editingField[q.id] = !isEditing;
                  if (isEditing && q.comment.isNotEmpty) {
                    q.answer = AnswerValue.pass;
                  }
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF3F4F6),
                  foregroundColor: const Color(0xFF111111),
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  textStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                child: Text(isEditing ? 'Done' : 'Edit'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Additional comment',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A2A5E))),
        const SizedBox(height: 8),
        TextField(
          maxLines: 4,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 20),
        Container(height: 1, color: const Color(0xFFE5E7EB)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStandardQuestionLayout(Section s, Question q) {
    final sectionIdx = widget.assignment.sections.indexOf(s);
    final col = _sectionColors[sectionIdx % _sectionColors.length];
    final selected = q.answer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: col.bg,
            border: Border(left: BorderSide(color: col.border, width: 4)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.title,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: col.text)),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      border: Border.all(color: col.border),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(q.id,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: col.border)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(q.text,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A2A5E),
                            height: 1.5)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Answer',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151))),
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
              borderRadius: BorderRadius.circular(4),
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
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFE5E7EB)),
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
                          color: Color(0xFF1A2A5E))),
                  if (selected == AnswerValue.na ||
                      selected == AnswerValue.nv)
                    const Text(' *',
                        style: TextStyle(color: Color(0xFFEF4444))),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                maxLines: 4,
                controller: TextEditingController(text: q.comment)
                  ..selection = TextSelection.collapsed(offset: q.comment.length),
                onChanged: (v) => q.comment = v,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                style: const TextStyle(fontSize: 13),
              ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Evidence',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A2A5E))),
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
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
                    borderRadius: BorderRadius.circular(4)),
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
                    borderRadius: BorderRadius.circular(4)),
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

  Widget _photoCard(Question q, EvidencePhoto photo, int idx) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFFF3F4F6),
              alignment: Alignment.center,
              child: photo.url.startsWith('http')
                  ? Image.network(
                photo.url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.image_outlined,
                    size: 40,
                    color: Color(0xFF9CA3AF)),
              )
                  : const Icon(Icons.image_outlined,
                  size: 40, color: Color(0xFF9CA3AF)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                  top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
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
          child: ElevatedButton(
            onPressed: prev == null
                ? null
                : () => setState(() {
              _activeSectionId = prev.sectionId;
              _activeQuestionId = prev.q.id;
            }),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B00),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE5E7EB),
              disabledForegroundColor: const Color(0xFF9CA3AF),
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
              textStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700),
            ),
            child: const Text('← Previous'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: next == null
                ? _goToSignOff
                : () => setState(() {
              _activeSectionId = next.sectionId;
              _activeQuestionId = next.q.id;
            }),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B00),
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
              textStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700),
            ),
            child: Text(next != null ? 'Next →' : 'Sign Off →'),
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
        borderColor = isSel ? const Color(0xFF22C55E) : const Color(0xFFD1D5DB);
        bgColor = isSel ? const Color(0xFFDCFCE7) : Colors.white;
        textColor = isSel ? const Color(0xFF166534) : const Color(0xFF6B7280);
        break;
      case AnswerValue.fail:
        borderColor = isSel ? const Color(0xFFEF4444) : const Color(0xFFD1D5DB);
        bgColor = isSel ? const Color(0xFFFEE2E2) : Colors.white;
        textColor = isSel ? const Color(0xFF991B1B) : const Color(0xFF6B7280);
        break;
      default:
        borderColor = isSel ? const Color(0xFF9CA3AF) : const Color(0xFFD1D5DB);
        bgColor = isSel ? const Color(0xFFF3F4F6) : Colors.white;
        textColor = isSel ? const Color(0xFF374151) : const Color(0xFF6B7280);
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
            borderRadius: BorderRadius.circular(4),
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
        color: Color(0xFFF8FAFC),
        border: Border(left: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF1A2A5E),
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
                        fontSize: 11, color: Color(0xFF64748B))),
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
              style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
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
              color: const Color(0xFFE0E7FF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Question ${q.id}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A2A5E))),
                const SizedBox(height: 4),
                Text(q.text,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF374151),
                        height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (q.guide.isNotEmpty)
            Text(q.guide,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF374151), height: 1.8))
          else
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Center(
                child: Text('No guide available for this question.',
                    style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9CA3AF),
                        fontStyle: FontStyle.italic)),
              ),
            ),
        ],
      ),
    );
  }
}