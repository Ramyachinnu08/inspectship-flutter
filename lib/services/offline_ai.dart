/// On-device AI (Gemma 3 1B via flutter_gemma ^1.6 / MediaPipe LLM Inference).
///
/// Used when the phone has NO internet:
///   • AI comment button  (comment + typical finding + suggested answer)
///   • Grammar auto-fix   (full sentence rewrite)
///
/// The model file (~550 MB) is downloaded once from your backend
/// (`ApiConfig.offlineModelUrl`) over Wi-Fi from the Profile screen.
/// Android 8+ (4 GB RAM) and iPhone 12+ only. Not available on web.
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import '../api_config.dart';
import '../offline_store.dart';

class OfflineAI {
  OfflineAI._();
  static final OfflineAI instance = OfflineAI._();

  /// Must match the file name at the end of [ApiConfig.offlineModelUrl].
  static String get modelId => ApiConfig.offlineModelUrl.split('/').last;

  InferenceModel? _model;
  bool _loading = false;

  /// Progress 0-100 while downloading, null when idle.
  final ValueNotifier<int?> downloadProgress = ValueNotifier<int?>(null);

  bool get supported => !kIsWeb;

  Future<bool> isInstalled() async {
    if (!supported) return false;
    try {
      return await FlutterGemma.isModelInstalled(modelId);
    } catch (_) {
      return false;
    }
  }

  /// Download + install the model file from the backend. Returns true on success.
  Future<bool> download() async {
    if (!supported) return false;
    try {
      downloadProgress.value = 0;
      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
        fileType: ModelFileType.task,
      )
          .fromNetwork(ApiConfig.offlineModelUrl)
          .withProgress((p) => downloadProgress.value = p)
          .install();
      downloadProgress.value = null;
      return true;
    } catch (e) {
      debugPrint('[OfflineAI] download failed: $e');
      downloadProgress.value = null;
      return false;
    }
  }

  Future<void> delete() async {
    try {
      await _model?.close();
      _model = null;
      await FlutterGemma.uninstallModel(modelId);
    } catch (e) {
      debugPrint('[OfflineAI] delete failed: $e');
    }
  }

  Future<InferenceModel?> _load() async {
    if (_model != null) return _model;
    if (_loading) {
      while (_loading) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
      return _model;
    }
    if (!await isInstalled()) return null;
    _loading = true;
    try {
      _model = await FlutterGemma.getActiveModel(
        maxTokens: 1024,
        preferredBackend: PreferredBackend.gpu,
      );
    } catch (e) {
      debugPrint('[OfflineAI] gpu load failed, trying cpu: $e');
      try {
        _model = await FlutterGemma.getActiveModel(
          maxTokens: 1024,
          preferredBackend: PreferredBackend.cpu,
        );
      } catch (e2) {
        debugPrint('[OfflineAI] cpu load failed: $e2');
      }
    }
    _loading = false;
    return _model;
  }

  /// Single-turn generation. Returns null if the model is not available.
  Future<String?> generate(String prompt, {double temperature = 0.2}) async {
    final model = await _load();
    if (model == null) return null;
    InferenceModelSession? session;
    try {
      session = await model.createSession(
        temperature: temperature,
        randomSeed: 1,
        topK: 40,
      );
      await session.addQueryChunk(Message.text(text: prompt, isUser: true));
      final out = await session.getResponse();
      return out.trim();
    } catch (e) {
      debugPrint('[OfflineAI] generate failed: $e');
      return null;
    } finally {
      try {
        await session?.close();
      } catch (_) {}
    }
  }

  /// Full grammar rewrite on device.
  Future<String?> fixGrammar(String text) async {
    final p = 'Correct the spelling, grammar and word order of this marine inspection text so it '
        'reads as proper professional English. Keep the same meaning, facts and numbers. Do not add '
        'anything. Keep it a question if it is a question. Reply with ONLY the corrected text.\n\n'
        'Text: $text';
    final out = await generate(p, temperature: 0.1);
    if (out == null) return null;
    return out.replaceAll('"', '').split('\n').first.trim();
  }

  /// AI comment using the knowledge documents cached on the phone.
  Future<String?> commentWithDocs(String basePrompt, String question) async {
    final hits = OfflineStore.instance.searchKnowledge(question, topK: 3);
    final b = StringBuffer();
    if (hits.isNotEmpty) {
      b.writeln('Reference material from the company knowledge base (use its wording style):');
      for (final h in hits) {
        var c = h['chunk'] ?? '';
        if (c.length > 700) c = c.substring(0, 700);
        b.writeln('- [${h['title']}] $c');
      }
      b.writeln();
    }
    b.write(basePrompt);
    return generate(b.toString(), temperature: 0.2);
  }
}