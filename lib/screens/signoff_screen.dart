import 'package:flutter/material.dart';
import '../models/models.dart';
import '../data/mock_store.dart';
import '../api_service.dart';
import '../offline_store.dart';
import 'inspection_session.dart';


class SignOffScreen extends StatefulWidget {
  final Assignment assignment;
  const SignOffScreen({super.key, required this.assignment});

  @override
  State<SignOffScreen> createState() => _SignOffScreenState();
}

class _SignOffScreenState extends State<SignOffScreen> {
  final TextEditingController _masterNameCtrl = TextEditingController();
  final TextEditingController _masterEmailCtrl = TextEditingController();
  late final TextEditingController _inspectorNameCtrl;

  final List<Offset?> _masterStrokes = [];
  final List<Offset?> _inspectorStrokes = [];
  bool _couldntObtainSig = false;
  DateTime _completionDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _inspectorNameCtrl = TextEditingController(text: 'Mick Darcey');
  }

  @override
  void dispose() {
    _masterNameCtrl.dispose();
    _masterEmailCtrl.dispose();
    _inspectorNameCtrl.dispose();
    super.dispose();
  }

  int get _answered =>
      widget.assignment.sections.fold(0, (t, s) => t + s.answered);
  int get _total => widget.assignment.totalQuestions;

  String _fmtDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day}/${m[d.month - 1]}/${d.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _completionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _completionDate = picked);
  }

  void _submit() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Submit Inspection?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You have answered $_answered of $_total questions.',
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            const Text('⚠️ Once submitted, this cannot be undone.',
                style: TextStyle(fontSize: 13, color: Color(0xFF8A6A4E))),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              widget.assignment.status = AssignmentStatus.submitted;
              widget.assignment.pendingSync = false;
              widget.assignment.masterSignName = _masterNameCtrl.text;
              widget.assignment.masterSigned = !_couldntObtainSig;
              widget.assignment.inspectorSigned = _inspectorStrokes.isNotEmpty;
              Navigator.of(context).pop(); // close dialog

              // Submit to backend
              final inspectionId = InspectionSession.currentInspectionId;
              bool ok = false;
              if (inspectionId != null) {
                // build answers from the assignment model
                final answers = <String, dynamic>{};
                for (final s in widget.assignment.sections) {
                  for (final q in s.questions) {
                    if (q.answer == null) continue;
                    String ans;
                    switch (q.answer!) {
                      case AnswerValue.pass: ans = 'yes'; break;
                      case AnswerValue.fail: ans = 'no'; break;
                      case AnswerValue.na: ans = 'na'; break;
                      case AnswerValue.nv: ans = 'nv'; break;
                    }
                    final curKey = Question.keyFor(q.answer);
                    if (curKey != 'none') {
                      q.commentByAnswer[curKey] = q.comment;
                      q.photosByAnswer[curKey] = List<EvidencePhoto>.from(q.photos);
                    }
                    final photosByAns = <String, List<String>>{};
                    q.photosByAnswer.forEach((k, list) {
                      photosByAns[k] = list.map((p) => p.url).toList();
                    });
                    answers[q.id] = {
                      'answer': ans,
                      'comment': q.comment,
                      'question_text': q.text,
                      'photos': q.photos.map((p) => p.url).toList(),
                      'commentByAnswer': q.commentByAnswer,
                      'photosByAnswer': photosByAns,
                    };
                  }
                }
                answers['__cover_image__'] = {'url': widget.assignment.coverImage};

                final assignmentKey = widget.assignment.id.toString();
                final online = await OfflineStore.instance.isOnline();

                if (online) {
                  await ApiService.saveAnswers(inspectionId, answers,
                      masterName: _masterNameCtrl.text, masterEmail: _masterEmailCtrl.text);
                  final result = await ApiService.submitInspection(inspectionId);
                  ok = result != null;
                  // save local copy as submitted
                  await OfflineStore.instance.saveLocalInspection(
                    assignmentKey,
                    answers: answers,
                    coverImage: widget.assignment.coverImage,
                    localStatus: ok ? 'submitted' : 'in_progress',
                    pendingSync: !ok,
                    inspectionId: inspectionId,
                    masterName: _masterNameCtrl.text,
                    masterEmail: _masterEmailCtrl.text,
                  );
                  if (!ok) await OfflineStore.instance.queueForSync(assignmentKey);
                } else {
                  // OFFLINE: save locally + queue for sync
                  await OfflineStore.instance.saveLocalInspection(
                    assignmentKey,
                    answers: answers,
                    coverImage: widget.assignment.coverImage,
                    localStatus: 'submitted',
                    pendingSync: true,
                    inspectionId: inspectionId,
                    masterName: _masterNameCtrl.text,
                    masterEmail: _masterEmailCtrl.text,
                  );
                  await OfflineStore.instance.queueForSync(assignmentKey);
                  ok = true; // saved offline successfully
                }
              }

              if (!mounted) return;
              final wasOnline = await OfflineStore.instance.isOnline();
              // pop back to assignments list
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(!wasOnline
                        ? 'Saved offline ✅ Will sync when back online (Drafts → Sync Now).'
                        : ok
                        ? 'Inspection submitted ✅ Report created for admin review.'
                        : 'Saved offline. Sync from Drafts when online.'),
                    backgroundColor: ok ? const Color(0xFF22C55E) : const Color(0xFFF59E0B)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8630A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EBDD),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with back + centered title
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios,
                        color: Color(0xFF5C2E0E), size: 20),
                    onPressed: () => Navigator.of(context).maybePop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const Spacer(),
                  Text(
                      'Inspection of ${widget.assignment.vesselName.toUpperCase()} (IMO: ${widget.assignment.imo.replaceAll("IMO ", "")})',
                      style: const TextStyle(
                          fontFamily: 'Georgia',
                          fontFamilyFallback: ['Times New Roman', 'serif'],
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF3D2817))),
                  const Spacer(),
                ],
              ),
            ),
            // Dark brown banner with RightKnot badge
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF241008), Color(0xFF4A2410)],
                ),
              ),
              padding:
              const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8630A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.anchor, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text('RIGHTKNOT',
                            style: TextStyle(
                                fontFamily: 'Georgia',
                                fontFamilyFallback: ['Times New Roman', 'serif'],
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                letterSpacing: 1.5)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Text('Sign Off',
                      style: TextStyle(
                          fontFamily: 'Georgia',
                          fontFamilyFallback: ['Times New Roman', 'serif'],
                          color: Color(0xFFD9B98F),
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _labeledField("Vessel's Master Name", _masterNameCtrl),
                    const SizedBox(height: 20),
                    _labeledField(
                        "Vessel's Master Email Address", _masterEmailCtrl),
                    const SizedBox(height: 30),
                    _sectionTitle("Vessel's Master Signature:"),
                    const SizedBox(height: 12),
                    _clearButton(
                        onTap: () =>
                            setState(() => _masterStrokes.clear())),
                    const SizedBox(height: 12),
                    _signaturePad(_masterStrokes),
                    const SizedBox(height: 24),
                    // Divider
                    Container(
                        height: 1, color: const Color(0xFFE8D9C0)),
                    const SizedBox(height: 20),
                    // Couldn't obtain checkbox
                    Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            activeColor: const Color(0xFFE8630A),
                            value: _couldntObtainSig,
                            onChanged: (v) => setState(
                                    () => _couldntObtainSig = v ?? false),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text("Couldn't obtain the signature",
                            style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF5C2E0E))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                        height: 1, color: const Color(0xFFE8D9C0)),
                    const SizedBox(height: 20),
                    _labeledField("Inspector Name", _inspectorNameCtrl),
                    const SizedBox(height: 30),
                    _sectionTitle("Inspector's Signature:"),
                    const SizedBox(height: 12),
                    _clearButton(
                        onTap: () => setState(
                                () => _inspectorStrokes.clear())),
                    const SizedBox(height: 12),
                    _signaturePad(_inspectorStrokes),
                    const SizedBox(height: 30),
                    // Completion date
                    _sectionTitle("Inspection Completion Date"),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _pickDate,
                      child: Container(
                        width: 300,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDF8ED),
                          border: Border.all(color: const Color(0xFFDECBAB)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Text(_fmtDate(_completionDate),
                                style: const TextStyle(
                                    fontSize: 14, color: Color(0xFF2E1F12))),
                            const Spacer(),
                            const Icon(Icons.calendar_month,
                                size: 18, color: Color(0xFF5C2E0E)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Two option cards
                    Row(
                      children: [
                        Expanded(child: _optionCard(
                          title: 'Confirm and to submit the list of N/Cs and email to Vessel\'s Master',
                          onTap: _submit,
                        )),
                        const SizedBox(width: 16),
                        Expanded(child: _optionCard(
                          title: 'Submit a fully completed response',
                          subtitle: 'This option will close this audit',
                          onTap: _submit,
                        )),
                      ],
                    ),
                    const SizedBox(height: 30),
                    // Back / Save / Submit buttons
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _bottomBtn('← Back',
                                  () => Navigator.of(context).maybePop()),
                          const SizedBox(width: 12),
                          _bottomBtn('Save', () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Saved as draft')),
                            );
                          }),
                          const SizedBox(width: 12),
                          _bottomBtn('Submit', _submit),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _labeledField(String label, TextEditingController ctrl) {
    return Row(
      children: [
        SizedBox(
          width: 250,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5C2E0E))),
        ),
        Expanded(
          child: TextField(
            controller: ctrl,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFFDF8ED),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFDECBAB)),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) => Text(text,
      style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Color(0xFF5C2E0E)));

  Widget _clearButton({required VoidCallback onTap}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE8630A),
        foregroundColor: Colors.white,
        minimumSize: const Size(90, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle:
        const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      child: const Text('Clear'),
    );
  }

  Widget _signaturePad(List<Offset?> strokes) {
    return Container(
      width: 450,
      height: 200,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFFDF8ED),
        border: Border.all(color: const Color(0xFFDECBAB), width: 1.4),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7A3A12).withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: GestureDetector(
        onPanStart: (d) => setState(() => strokes.add(d.localPosition)),
        onPanUpdate: (d) => setState(() => strokes.add(d.localPosition)),
        onPanEnd: (_) => setState(() => strokes.add(null)),
        child: CustomPaint(
          painter: _SignaturePainter(strokes),
          size: const Size(450, 200),
        ),
      ),
    );
  }

  Widget _optionCard(
      {required String title, String? subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF8ED),
          border: Border.all(color: const Color(0xFFDECBAB)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5C2E0E))),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFFE8630A))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bottomBtn(String label, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE8630A),
        foregroundColor: Colors.white,
        minimumSize: const Size(100, 42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle:
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> strokes;
  _SignaturePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2E1F12)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < strokes.length - 1; i++) {
      final p1 = strokes[i];
      final p2 = strokes[i + 1];
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}