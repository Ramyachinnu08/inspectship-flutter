import 'package:flutter/material.dart';
import '../api_service.dart';

const _kOrange = Color(0xFFFF6B00);
const _kNavy = Color(0xFF1A2A5E);

class RealInspectionScreen extends StatefulWidget {
  final Map<String, dynamic> assignment;
  const RealInspectionScreen({super.key, required this.assignment});

  @override
  State<RealInspectionScreen> createState() => _RealInspectionScreenState();
}

class _RealInspectionScreenState extends State<RealInspectionScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;

  int? _inspectionId;
  List<Map<String, dynamic>> _questions = [];
  // answers[qid] = { "answer": "yes"/"no", "comment": "...", "question_text": "..." }
  final Map<String, Map<String, dynamic>> _answers = {};
  final Map<String, TextEditingController> _commentCtrls = {};
  final Set<String> _guideOpen = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    for (final c in _commentCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _init() async {
    setState(() { _loading = true; _error = null; });

    // Extract questions from the template
    _questions = _extractQuestions(widget.assignment['template_sections']);

    // Start / resume the inspection on the backend
    final backendId = widget.assignment['id'];
    if (backendId == null) {
      setState(() { _loading = false; _error = 'Assignment id missing'; });
      return;
    }
    final data = await ApiService.startInspection(backendId is int ? backendId : int.tryParse('$backendId') ?? 0);
    if (data == null) {
      setState(() { _loading = false; _error = 'Could not start inspection. Please sign out and sign in again, then retry.'; });
      return;
    }
    _inspectionId = data['inspection_id'];

    // Pre-fill any saved answers
    final saved = data['answers'];
    if (saved is Map) {
      saved.forEach((k, v) {
        if (v is Map) {
          _answers['$k'] = Map<String, dynamic>.from(v);
        }
      });
    }

    // Build comment controllers
    for (final q in _questions) {
      final qid = _qid(q);
      final existing = _answers[qid];
      _commentCtrls[qid] = TextEditingController(text: existing?['comment']?.toString() ?? '');
    }

    setState(() => _loading = false);
  }

  List<Map<String, dynamic>> _extractQuestions(dynamic templateSections) {
    final result = <Map<String, dynamic>>[];
    if (templateSections is Map && templateSections['draftVersions'] is List) {
      final drafts = templateSections['draftVersions'] as List;
      // published version first, else last
      Map? chosen;
      for (final d in drafts) {
        if (d is Map && d['status'] == 'Published' && d['structure'] is List) {
          chosen = d;
          break;
        }
      }
      chosen ??= (drafts.isNotEmpty && drafts.last is Map) ? drafts.last as Map : null;
      if (chosen != null && chosen['structure'] is List) {
        for (final q in chosen['structure'] as List) {
          if (q is Map) result.add(Map<String, dynamic>.from(q));
        }
      }
    } else if (templateSections is List) {
      for (final q in templateSections) {
        if (q is Map) result.add(Map<String, dynamic>.from(q));
      }
    }
    return result;
  }

  String _qid(Map<String, dynamic> q) {
    return (q['sub_number'] ?? q['subNumber'] ?? q['id'] ?? '').toString();
  }

  String _qtext(Map<String, dynamic> q) {
    return (q['question'] ?? q['text'] ?? '').toString();
  }

  String _qguide(Map<String, dynamic> q) {
    return (q['guide_to_inspection'] ?? q['inspectionGuide'] ?? '').toString();
  }

  bool _qevidence(Map<String, dynamic> q) {
    return q['evidence_required'] == true || q['evidenceRequired'] == true;
  }

  int get _answeredCount => _questions.where((q) => _answers.containsKey(_qid(q)) && _answers[_qid(q)]!['answer'] != null).length;

  void _setAnswer(Map<String, dynamic> q, String value) {
    final qid = _qid(q);
    setState(() {
      _answers[qid] = {
        'answer': value,
        'comment': _commentCtrls[qid]?.text ?? '',
        'question_text': _qtext(q),
      };
    });
  }

  void _syncComments() {
    for (final q in _questions) {
      final qid = _qid(q);
      if (_answers.containsKey(qid)) {
        _answers[qid]!['comment'] = _commentCtrls[qid]?.text ?? '';
      }
    }
  }

  Future<void> _saveDraft({bool silent = false}) async {
    if (_inspectionId == null) return;
    _syncComments();
    setState(() => _saving = true);
    final ok = await ApiService.saveAnswers(_inspectionId!, _answers);
    setState(() => _saving = false);
    if (!mounted) return;
    if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Draft saved' : 'Failed to save draft')),
      );
    }
  }

  Future<void> _submit() async {
    if (_inspectionId == null) return;

    final unanswered = _questions.length - _answeredCount;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit inspection?'),
        content: Text(unanswered > 0
            ? 'You have $unanswered unanswered question(s). Submit anyway?'
            : 'All questions answered. Submit this inspection for review?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
        ],
      ),
    );
    if (confirm != true) return;

    _syncComments();
    setState(() => _saving = true);
    // save first, then submit
    await ApiService.saveAnswers(_inspectionId!, _answers);
    final result = await ApiService.submitInspection(_inspectionId!);
    setState(() => _saving = false);
    if (!mounted) return;

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submit failed. Please try again.')),
      );
      return;
    }

    final findings = result['findings'] ?? 0;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submitted ✅'),
        content: Text('Inspection submitted for review.\n\nFindings recorded: $findings\n\nA report has been created in the admin Review Queue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.pop(context, true); // return to assignments, signal refresh
  }

  @override
  Widget build(BuildContext context) {
    final vessel = (widget.assignment['vessel'] ?? 'Vessel').toString();
    final template = (widget.assignment['template'] ?? '').toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _kNavy,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(vessel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111111))),
            if (template.isNotEmpty)
              Text(template, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          if (!_loading && _error == null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text('$_answeredCount/${_questions.length}',
                    style: const TextStyle(color: _kNavy, fontWeight: FontWeight.w800, fontSize: 14)),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kOrange))
          : _error != null
          ? _errorView()
          : _content(),
      bottomNavigationBar: (_loading || _error != null) ? null : _bottomBar(),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: Color(0xFF374151))),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _init,
              style: ElevatedButton.styleFrom(backgroundColor: _kOrange, foregroundColor: Colors.white),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    if (_questions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'This template has no published questions.\nAsk the admin to publish the template with questions.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _questions.length,
      itemBuilder: (context, i) => _questionCard(_questions[i], i),
    );
  }

  Widget _questionCard(Map<String, dynamic> q, int index) {
    final qid = _qid(q);
    final text = _qtext(q);
    final guide = _qguide(q);
    final evidence = _qevidence(q);
    final category = (q['category'] ?? '').toString();
    final severity = (q['severity'] ?? '').toString();
    final answer = _answers[qid]?['answer']?.toString();
    final guideOpen = _guideOpen.contains(qid);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // number + category/severity chips
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: _kNavy, borderRadius: BorderRadius.circular(6)),
                child: Text(qid.isEmpty ? '${index + 1}' : qid,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 8),
              if (category.isNotEmpty)
                _chip(category, const Color(0xFFEEF2FF), const Color(0xFF3730A3)),
              if (severity.isNotEmpty) ...[
                const SizedBox(width: 6),
                _chip(severity, const Color(0xFFFEF3C7), const Color(0xFF92400E)),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // question text
          Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111111), height: 1.4)),
          // guide toggle
          if (guide.isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => setState(() {
                if (guideOpen) {
                  _guideOpen.remove(qid);
                } else {
                  _guideOpen.add(qid);
                }
              }),
              child: Row(
                children: [
                  Icon(guideOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 18, color: _kOrange),
                  const SizedBox(width: 4),
                  Text(guideOpen ? 'Hide guide' : 'Show guide',
                      style: const TextStyle(fontSize: 13, color: _kOrange, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            if (guideOpen)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)),
                child: Text(guide, style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), height: 1.5)),
              ),
          ],
          const SizedBox(height: 14),
          // Yes / No buttons
          Row(
            children: [
              Expanded(child: _answerBtn('Yes', answer == 'yes', const Color(0xFF22C55E), () => _setAnswer(q, 'yes'))),
              const SizedBox(width: 10),
              Expanded(child: _answerBtn('No', answer == 'no', const Color(0xFFEF4444), () => _setAnswer(q, 'no'))),
            ],
          ),
          if (answer == 'no') ...[
            const SizedBox(height: 6),
            const Text('⚠ "No" is recorded as a finding and creates a CAPA.',
                style: TextStyle(fontSize: 11, color: Color(0xFFB45309))),
          ],
          const SizedBox(height: 12),
          // comment
          TextField(
            controller: _commentCtrls[qid],
            minLines: 1,
            maxLines: 4,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: evidence ? 'Comment (evidence required)' : 'Comment (optional)',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kOrange)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _answerBtn(String label, bool selected, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color : const Color(0xFFE5E7EB), width: 1.5),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : const Color(0xFF6B7280))),
      ),
    );
  }

  Widget _bottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2))],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _saving ? null : () => _saveDraft(),
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Save Draft'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kNavy,
                  side: const BorderSide(color: _kNavy),
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check, size: 18),
                label: const Text('Submit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kOrange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}