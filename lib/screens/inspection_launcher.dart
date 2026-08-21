import 'package:flutter/material.dart';
import '../models/models.dart';
import '../api_service.dart';
import '../offline_store.dart';
import 'inspection_screen.dart';
import 'inspection_session.dart';

/// Converts a real backend assignment map into the Assignment model
/// (used by the original InspectionScreen design), starts/resumes the
/// inspection on the backend, then opens the original inspection screen.
class InspectionLauncher {
  /// Call this from the Start/Resume button.
  static Future<void> open(BuildContext context, Map<String, dynamic> a) async {
    final backendId = a['id'];
    final int assignmentId =
    backendId is int ? backendId : int.tryParse('$backendId') ?? 0;
    final String assignmentKey = assignmentId.toString();

    final bool online = await OfflineStore.instance.isOnline();

    dynamic savedAnswers;
    int? inspectionId;

    if (online) {
      // Show a brief loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00))),
      );

      final startData = await ApiService.startInspection(assignmentId);

      if (context.mounted) Navigator.pop(context); // close loader

      if (startData != null) {
        inspectionId = startData['inspection_id'];
        savedAnswers = startData['answers'];
        // merge any locally-saved (offline) answers over backend answers
        final local = OfflineStore.instance.getLocalInspection(assignmentKey);
        if (local != null && local['answers'] != null) {
          savedAnswers = local['answers'];
        }
      } else {
        // backend failed → fall back to local
        final local = OfflineStore.instance.getLocalInspection(assignmentKey);
        savedAnswers = local?['answers'];
        inspectionId = local?['inspection_id'];
      }
    } else {
      // OFFLINE: load any locally saved answers
      final local = OfflineStore.instance.getLocalInspection(assignmentKey);
      savedAnswers = local?['answers'];
      inspectionId = local?['inspection_id'];
    }

    InspectionSession.currentInspectionId = inspectionId;

    // Build the Assignment model from real template + saved answers
    final assignment = _buildAssignment(a, savedAnswers);

    // Open the ORIGINAL inspection screen
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InspectionScreen(assignment: assignment),
      ),
    );

    // When the inspector returns, save answers (online → backend, always → local cache)
    final answersMap = _extractAnswers(assignment);
    final nowOnline = await OfflineStore.instance.isOnline();

    // always keep a local copy so drafts survive offline
    await OfflineStore.instance.saveLocalInspection(
      assignmentKey,
      answers: answersMap,
      coverImage: assignment.coverImage,
      localStatus: 'in_progress',
      pendingSync: !nowOnline,
      inspectionId: inspectionId,
    );

    if (nowOnline && inspectionId != null) {
      await ApiService.saveAnswers(inspectionId, answersMap);
    }
  }

  /// Build Assignment model from real backend data.
  static Assignment _buildAssignment(Map<String, dynamic> a, dynamic savedAnswers) {
    final vessel = (a['vessel'] ?? 'Unknown').toString();
    final imo = (a['vessel_imo'] ?? '').toString();
    final template = (a['template'] ?? 'Inspection').toString();

    DateTime due = DateTime.now();
    if (a['due_date'] != null) {
      due = DateTime.tryParse(a['due_date']) ?? DateTime.now();
    }

    // Map saved answers by question id for pre-fill
    final Map<String, Map> savedById = {};
    if (savedAnswers is Map) {
      savedAnswers.forEach((k, v) {
        if (v is Map) savedById['$k'] = v;
      });
    }

    final sections = _buildSections(a['template_sections'], savedById);

    // restore cover image if present
    String coverImage = '';
    if (savedAnswers is Map && savedAnswers['__cover_image__'] is Map) {
      coverImage = (savedAnswers['__cover_image__']['url'] ?? '').toString();
    }

    AssignmentStatus status;
    switch ((a['status'] ?? 'upcoming').toString()) {
      case 'in_progress':
        status = AssignmentStatus.inProgress;
        break;
      case 'submitted':
        status = AssignmentStatus.submitted;
        break;
      case 'overdue':
        status = AssignmentStatus.overdue;
        break;
      default:
        status = AssignmentStatus.upcoming;
    }

    return Assignment(
      id: 'INS-${a['id']}',
      vesselName: vessel,
      imo: imo.isEmpty ? 'IMO —' : (imo.startsWith('IMO') ? imo : 'IMO $imo'),
      templateName: template,
      dueDate: due,
      port: 'Port',
      scope: 'standard',
      status: status,
      sections: sections,
      coverImage: coverImage,
    );
  }

  static List<Section> _buildSections(dynamic templateSections, Map<String, Map> savedById) {
    // Get the published structure (flat list of questions)
    List<dynamic>? structure;
    if (templateSections is Map && templateSections['draftVersions'] is List) {
      final drafts = templateSections['draftVersions'] as List;
      Map? chosen;
      for (final d in drafts) {
        if (d is Map && d['status'] == 'Published' && d['structure'] is List) {
          chosen = d;
          break;
        }
      }
      chosen ??= (drafts.isNotEmpty && drafts.last is Map) ? drafts.last as Map : null;
      if (chosen != null && chosen['structure'] is List) {
        structure = chosen['structure'] as List;
      }
    } else if (templateSections is List) {
      structure = templateSections;
    }

    if (structure == null || structure.isEmpty) {
      // no questions -> single empty section
      return [
        Section(
          id: 'sec_empty',
          title: 'No Questions',
          colorHex: 0xFF3B82F6,
          questions: [],
        ),
      ];
    }

    // Group questions by category into sections (nice for the 3-panel design)
    final Map<String, List<Question>> byCategory = {};
    final List<String> order = [];

    for (final item in structure) {
      if (item is! Map) continue;
      // Group by SUB-AREA (e.g. "Section 1: General Information");
      // falls back to category if sub-area is empty.
      final subArea = (item['sub_area'] ?? item['subArea'] ?? '').toString().trim();
      final category = (item['category'] ?? 'General').toString().trim();
      final cat = subArea.isNotEmpty ? subArea : (category.isEmpty ? 'General' : category);
      if (!byCategory.containsKey(cat)) {
        byCategory[cat] = [];
        order.add(cat);
      }

      final qid = (item['sub_number'] ?? item['subNumber'] ?? item['id'] ?? '').toString();
      final text = (item['question'] ?? item['text'] ?? '').toString();
      final guide = (item['guide_to_inspection'] ?? item['inspectionGuide'] ?? '').toString();
      final required = item['evidence_required'] == true || item['evidenceRequired'] == true;

      // Pre-fill from saved answers
      AnswerValue? answer;
      String comment = '';
      final saved = savedById[qid];
      if (saved != null) {
        final ans = (saved['answer'] ?? '').toString();
        if (ans == 'yes') answer = AnswerValue.pass;
        if (ans == 'no') answer = AnswerValue.fail;
        if (ans == 'na') answer = AnswerValue.na;
        if (ans == 'nv') answer = AnswerValue.nv;
        comment = (saved['comment'] ?? '').toString();
      }

      final photoList = <EvidencePhoto>[];
      if (saved != null && saved['photos'] is List) {
        for (final url in saved['photos'] as List) {
          photoList.add(EvidencePhoto(
            id: DateTime.now().microsecondsSinceEpoch.toString() + url.hashCode.toString(),
            url: url.toString(),
          ));
        }
      }
      // restore per-answer comment map
      final Map<String, String> commentByAns = {};
      if (saved != null && saved['commentByAnswer'] is Map) {
        (saved['commentByAnswer'] as Map).forEach((k, v) {
          commentByAns['$k'] = v.toString();
        });
      }
      // restore the General Information "Additional comment"
      if (saved != null && (saved['extra_comment'] ?? '').toString().isNotEmpty) {
        commentByAns['__extra__'] = saved['extra_comment'].toString();
      }
      // restore the Observation box (No answers)
      if (saved != null && (saved['observation'] ?? '').toString().isNotEmpty) {
        commentByAns['__observation__'] = saved['observation'].toString();
      }
      // restore per-answer photos map
      final Map<String, List<EvidencePhoto>> photosByAns = {};
      if (saved != null && saved['photosByAnswer'] is Map) {
        (saved['photosByAnswer'] as Map).forEach((k, v) {
          if (v is List) {
            photosByAns['$k'] = v.map((url) => EvidencePhoto(
              id: DateTime.now().microsecondsSinceEpoch.toString() + url.hashCode.toString(),
              url: url.toString(),
            )).toList();
          }
        });
      }
      byCategory[cat]!.add(Question(
        id: qid.isEmpty ? 'q${byCategory[cat]!.length + 1}' : qid,
        text: text,
        guide: guide,
        required: required,
        answer: answer,
        comment: comment,
        photos: photoList,
        commentByAnswer: commentByAns,
        photosByAnswer: photosByAns,
      ));
    }

    final palette = [0xFF3B82F6, 0xFFF59E0B, 0xFF22C55E, 0xFF8B5CF6, 0xFFEC4899, 0xFFEF4444];
    final sections = <Section>[];
    // Sort sections into correct numeric order: Section 1, 2, 3, ...
    int sectionNum(String title) {
      final m = RegExp(r'section\s*(\d+)', caseSensitive: false)
          .firstMatch(title);
      return m != null ? int.parse(m.group(1)!) : 999999;
    }
    order.sort((a, b) {
      final na = sectionNum(a);
      final nb = sectionNum(b);
      if (na != nb) return na.compareTo(nb);
      return a.compareTo(b);
    });

    // Sort questions inside each group numerically: 9.1, 9.2 ... 9.12
    List<int> numParts(String id) {
      return RegExp(r'\d+')
          .allMatches(id)
          .map((m) => int.parse(m.group(0)!))
          .toList();
    }
    int compareIds(String a, String b) {
      final pa = numParts(a);
      final pb = numParts(b);
      for (var i = 0; i < pa.length && i < pb.length; i++) {
        if (pa[i] != pb[i]) return pa[i].compareTo(pb[i]);
      }
      if (pa.length != pb.length) return pa.length.compareTo(pb.length);
      return a.compareTo(b);
    }
    for (final list in byCategory.values) {
      list.sort((qa, qb) => compareIds(qa.id, qb.id));
    }

    for (int i = 0; i < order.length; i++) {
      final cat = order[i];
      final alreadyNumbered = RegExp(r'^section\s*\d+', caseSensitive: false).hasMatch(cat);
      sections.add(Section(
        id: 'sec_$i',
        title: alreadyNumbered ? cat : 'Section ${i + 1}: $cat',
        colorHex: palette[i % palette.length],
        questions: byCategory[cat]!,
      ));
    }
    return sections;
  }

  /// Extract answers from Assignment model back into backend format.
  static Map<String, dynamic> _extractAnswers(Assignment assignment) {
    final Map<String, dynamic> out = {};
    for (final s in assignment.sections) {
      for (final q in s.questions) {
        if (q.answer == null) continue;
        String ans;
        switch (q.answer!) {
          case AnswerValue.pass:
            ans = 'yes';
            break;
          case AnswerValue.fail:
            ans = 'no';
            break;
          case AnswerValue.na:
            ans = 'na';
            break;
          case AnswerValue.nv:
            ans = 'nv';
            break;
        }
        // ensure current active data is folded into the map before saving
        final curKey = Question.keyFor(q.answer);
        if (curKey != 'none') {
          q.commentByAnswer[curKey] = q.comment;
          q.photosByAnswer[curKey] = List<EvidencePhoto>.from(q.photos);
        }
        final photosByAns = <String, List<String>>{};
        q.photosByAnswer.forEach((k, list) {
          photosByAns[k] = list.map((p) => p.url).toList();
        });
        out[q.id] = {
          'answer': ans,
          'comment': q.comment,
          'question_text': q.text,
          'photos': q.photos.map((p) => p.url).toList(),
          'commentByAnswer': q.commentByAnswer,
          'photosByAnswer': photosByAns,
        };
      }
    }
    out['__cover_image__'] = {'url': assignment.coverImage};
    return out;
  }
}