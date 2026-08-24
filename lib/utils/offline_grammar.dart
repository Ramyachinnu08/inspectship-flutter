/// Offline (rules-based) grammar / spelling clean-up for inspector text.
///
/// Used when the device has no internet and the Gemini fix cannot run.
/// It does NOT reorder words; it only:
///   • fixes common inspector typos (satisfactry -> satisfactory)
///   • expands short forms (C/O -> Chief Officer, PMS -> planned maintenance system)
///   • tidies spacing / punctuation, capitalises sentence starts
///   • capitalises ranks and well-known acronyms (solas -> SOLAS)
///   • adds a full stop at the end
class OfflineGrammar {
  // common misspellings -> correct (lower-case keys, matched whole-word, case-insensitive)
  static const Map<String, String> _typos = {
    'satisfactry': 'satisfactory', 'satisfactary': 'satisfactory', 'satisfatory': 'satisfactory',
    'satifactory': 'satisfactory', 'unsatisfactry': 'unsatisfactory',
    'certficate': 'certificate', 'certifcate': 'certificate', 'certificat': 'certificate',
    'certficates': 'certificates', 'certifcates': 'certificates',
    'maintainance': 'maintenance', 'maintenence': 'maintenance', 'maintanance': 'maintenance',
    'maintained': 'maintained', 'maintaned': 'maintained', 'mantained': 'maintained',
    'seperately': 'separately', 'seperate': 'separate',
    'recieved': 'received', 'recieve': 'receive',
    'occured': 'occurred', 'occurence': 'occurrence',
    'equipement': 'equipment', 'equiptment': 'equipment', 'equipmnt': 'equipment',
    'procedur': 'procedure', 'proceedure': 'procedure', 'proceedures': 'procedures',
    'accomodation': 'accommodation', 'acommodation': 'accommodation',
    'availabe': 'available', 'avalable': 'available', 'availble': 'available',
    'vessle': 'vessel', 'vesel': 'vessel', 'vessal': 'vessel',
    'enginee': 'engine', 'engin': 'engine',
    'machinary': 'machinery', 'machinry': 'machinery',
    'inspecton': 'inspection', 'inspction': 'inspection', 'insepction': 'inspection',
    'inspeced': 'inspected', 'inspeted': 'inspected',
    'verifed': 'verified', 'verfied': 'verified',
    'observd': 'observed', 'obsreved': 'observed',
    'corroded': 'corroded', 'corrode': 'corroded', 'corossion': 'corrosion', 'corrossion': 'corrosion',
    'leakge': 'leakage', 'lekage': 'leakage',
    'hydralic': 'hydraulic', 'hydrolic': 'hydraulic',
    'electical': 'electrical', 'electricle': 'electrical',
    'emergncy': 'emergency', 'emergancy': 'emergency',
    'lifeboat': 'lifeboat', 'life boat': 'lifeboat',
    'fire fighting': 'firefighting', 'firefightng': 'firefighting',
    'ballast': 'ballast', 'balast': 'ballast',
    'bunkring': 'bunkering', 'bunkerng': 'bunkering',
    'navigaton': 'navigation', 'navigtion': 'navigation',
    'comunication': 'communication', 'communcation': 'communication',
    'documnet': 'document', 'documet': 'document', 'documnets': 'documents',
    'recored': 'recorded', 'recoded': 'recorded',
    'checkd': 'checked', 'cheked': 'checked',
    'foud': 'found', 'fond': 'found',
    'condtion': 'condition', 'conditon': 'condition',
    'presense': 'presence', 'presnce': 'presence',
    'wich': 'which', 'whcih': 'which',
    'teh': 'the', 'hte': 'the', 'adn': 'and', 'nad': 'and', 'thier': 'their',
    'becuase': 'because', 'becasue': 'because',
    'untill': 'until', 'allready': 'already', 'alot': 'a lot',
    'definately': 'definitely', 'neccessary': 'necessary', 'necesary': 'necessary',
    'sucessfully': 'successfully', 'succesfully': 'successfully',
    'aproved': 'approved', 'approvd': 'approved',
    'expird': 'expired', 'expried': 'expired',
    'calibrated': 'calibrated', 'calibratd': 'calibrated', 'calibrtion': 'calibration',
  };

  // short forms -> full form (only when written exactly as the key, whole word)
  static const Map<String, String> _shortForms = {
    'c/o': 'Chief Officer', 'c/e': 'Chief Engineer', '2/o': 'Second Officer', '3/o': 'Third Officer',
    '2/e': 'Second Engineer', '3/e': 'Third Engineer', 'e/r': 'engine room', 'l/b': 'lifeboat',
    'ch off': 'Chief Officer', 'ch eng': 'Chief Engineer', 'ch.off': 'Chief Officer',
    'ok': 'satisfactory', 'okay': 'satisfactory', 'n/a': 'not applicable',
    'w/': 'with', 'w/o': 'without', 'approx': 'approximately', 'pcs': 'pieces', 'nos': 'numbers',
  };

  // words / acronyms that must keep fixed capitalisation
  static const List<String> _caps = [
    'SOLAS', 'MARPOL', 'STCW', 'MLC', 'ISM', 'ISPS', 'IMO', 'IMSBC', 'IMDG', 'ECDIS', 'GMDSS',
    'EPIRB', 'SART', 'AIS', 'VDR', 'BNWAS', 'GPS', 'GNSS', 'UMS', 'PMS', 'SMS', 'SOPEP', 'SEEMP',
    'OWS', 'ODME', 'BWTS', 'EEBD', 'SCBA', 'PPE', 'MSDS', 'SDS', 'LSA', 'FFA', 'CO2', 'OCIMF',
    'RISQ', 'PSC', 'CAPA', 'ISGOTT', 'IGF', 'IGC', 'IBC', 'DPA', 'SSO', 'CSO', 'SSAS', 'UHF', 'VHF',
    'MF', 'HF', 'UKC', 'WIDS', 'LOTO', 'SWL', 'MAWP', 'BLU', 'VSP', 'HRU', 'TEMPSC',
    'Master', 'Chief Officer', 'Chief Engineer', 'Second Officer', 'Third Officer',
    'Second Engineer', 'Third Engineer', 'Chief Mate', 'Chief Cook', 'Bosun', 'Electrical Officer',
  ];

  static String fix(String input) {
    var t = input;
    if (t.trim().isEmpty) return t;

    // 1. tidy whitespace
    t = t.replaceAll(RegExp(r'[ \t]+'), ' ').trim();
    t = t.replaceAll(RegExp(r' +([,.;:!?])'), r'$1');           // no space before punctuation
    t = t.replaceAllMapped(RegExp(r'([,.;:!?])(?=[A-Za-z])'), (m) => '${m[1]} '); // space after
    t = t.replaceAll(RegExp(r'\.{2,}'), '.');
    t = t.replaceAll(RegExp(r',{2,}'), ',');

    // 2. short forms (longest keys first so "ch off" beats "ok")
    final sf = _shortForms.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
    for (final k in sf) {
      t = t.replaceAllMapped(
          RegExp('(?<![A-Za-z0-9/])${RegExp.escape(k)}(?![A-Za-z0-9/])', caseSensitive: false),
              (_) => _shortForms[k]!);
    }

    // 3. typos
    final ty = _typos.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
    for (final k in ty) {
      t = t.replaceAllMapped(
          RegExp('\\b${RegExp.escape(k)}\\b', caseSensitive: false),
              (m) => _matchCase(m[0]!, _typos[k]!));
    }

    // 4. "a" vs "an"
    t = t.replaceAllMapped(RegExp(r'\b([Aa]) (?=[aeiouAEIOU]\w)'), (m) => '${m[1]}n ');
    t = t.replaceAllMapped(RegExp(r'\b([Aa])n (?=[^aeiouAEIOU\W]\w)'), (m) => '${m[1]} ');

    // 5. "i" -> "I"
    t = t.replaceAllMapped(RegExp(r"\bi\b(?!')"), (_) => 'I');

    // 6. fixed capitalisation words
    for (final w in _caps) {
      t = t.replaceAllMapped(RegExp('\\b${RegExp.escape(w)}\\b', caseSensitive: false), (_) => w);
    }

    // 7. capitalise sentence starts
    t = t.replaceAllMapped(RegExp(r'(^|[.!?]\s+)([a-z])'),
            (m) => '${m[1]}${m[2]!.toUpperCase()}');

    // 8. end with a full stop (unless question / already punctuated / very short number-only)
    if (!RegExp(r'[.!?]$').hasMatch(t) && RegExp(r'[A-Za-z]').hasMatch(t)) {
      final lower = t.toLowerCase();
      final isQuestion = RegExp(r'^(what|where|when|why|how|is|are|was|were|do|does|did|can|could|has|have|should|which|who)\b')
          .hasMatch(lower);
      t += isQuestion ? '?' : '.';
    }
    return t;
  }

  static String _matchCase(String original, String replacement) {
    if (original.toUpperCase() == original && original.length > 1) return replacement.toUpperCase();
    if (original[0].toUpperCase() == original[0]) {
      return replacement[0].toUpperCase() + replacement.substring(1);
    }
    return replacement;
  }
}