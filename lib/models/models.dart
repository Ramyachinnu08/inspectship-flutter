enum AnswerValue { pass, fail, na, nv }

class EvidencePhoto {
  final String id;
  String url; // for mocking - stores blob-like url or path
  String caption;
  bool uploading;

  EvidencePhoto({
    required this.id,
    required this.url,
    this.caption = '',
    this.uploading = false,
  });
}

class Question {
  final String id;
  final String text;
  final String guide;
  final bool required;
  AnswerValue? answer;
  String comment;
  int evidenceCount; // legacy - kept for backwards compat
  List<EvidencePhoto> photos;

  // Per-answer storage: each answer option keeps its own comment + photos
  Map<String, String> commentByAnswer;
  Map<String, List<EvidencePhoto>> photosByAnswer;

  Question({
    required this.id,
    required this.text,
    required this.guide,
    this.required = false,
    this.answer,
    this.comment = '',
    this.evidenceCount = 0,
    List<EvidencePhoto>? photos,
    Map<String, String>? commentByAnswer,
    Map<String, List<EvidencePhoto>>? photosByAnswer,
  })  : photos = photos ?? [],
        commentByAnswer = commentByAnswer ?? {},
        photosByAnswer = photosByAnswer ?? {};

  bool get isAnswered => answer != null;

  // Key helper for the current answer
  static String keyFor(AnswerValue? a) {
    switch (a) {
      case AnswerValue.pass: return 'yes';
      case AnswerValue.fail: return 'no';
      case AnswerValue.na: return 'na';
      case AnswerValue.nv: return 'nv';
      default: return 'none';
    }
  }
}

class Section {
  final String id;
  final String title;
  final int colorHex;
  final List<Question> questions;
  Section({
    required this.id,
    required this.title,
    required this.colorHex,
    required this.questions,
  });

  int get answered => questions.where((q) => q.isAnswered).length;
  bool get complete => answered == questions.length;
}

enum AssignmentStatus { upcoming, inProgress, overdue, submitted }

class Assignment {
  final String id;
  final String vesselName;
  final String imo;
  final String templateName;
  final DateTime dueDate;
  final String port;
  final String scope;
  AssignmentStatus status;
  final List<Section> sections;
  String masterSignName;
  bool masterSigned;
  bool inspectorSigned;
  bool pendingSync;
  String coverImage;

  Assignment({
    required this.id,
    required this.vesselName,
    required this.imo,
    required this.templateName,
    required this.dueDate,
    required this.port,
    this.scope = 'standard',
    this.status = AssignmentStatus.upcoming,
    required this.sections,
    this.masterSignName = '',
    this.masterSigned = false,
    this.inspectorSigned = false,
    this.pendingSync = false,
    this.coverImage = '',
  });

  int get totalQuestions =>
      sections.fold(0, (t, s) => t + s.questions.length);
  int get answeredQuestions => sections.fold(0, (t, s) => t + s.answered);
  double get progress =>
      totalQuestions == 0 ? 0 : answeredQuestions / totalQuestions;
  int get findings => sections
      .fold<List<Question>>([], (l, s) => l..addAll(s.questions))
      .where((q) => q.answer == AnswerValue.fail)
      .length;

  List<Question> get allQuestions =>
      sections.expand((s) => s.questions).toList();
}

class ChatMessage {
  final String text;
  final bool fromUser;
  final String? source;
  ChatMessage(this.text, {required this.fromUser, this.source});
}