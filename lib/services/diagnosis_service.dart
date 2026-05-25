import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/diagnosis.dart';
import '../models/print_knowledge.dart';

abstract class DiagnosisService {
  Future<DiagnosisResult> analyze(DiagnosisRequest request);
}

enum DiagnosisEngine {
  local('本地规则', '离线快'),
  ai('AI 分析', '联网精准');

  const DiagnosisEngine(this.label, this.badge);

  final String label;
  final String badge;
}

class AIDiagnosisConfig {
  const AIDiagnosisConfig({
    this.endpoint = defaultEndpoint,
    this.model = defaultModel,
    this.apiKey = defaultApiKey,
  });

  static const defaultEndpoint = String.fromEnvironment(
    'AI_DIAGNOSIS_ENDPOINT',
    defaultValue: '/api/diagnosis',
  );
  static const defaultModel = String.fromEnvironment(
    'AI_DIAGNOSIS_MODEL',
    defaultValue: 'gpt-5.5',
  );
  static const defaultApiKey = String.fromEnvironment('OPENAI_API_KEY');

  final String endpoint;
  final String model;
  final String apiKey;

  // 线上部署时默认请求同源 /api/diagnosis，让 Vercel 函数代持 token。
  // 本地临时调试才通过 --dart-define 直连中转站并携带 OPENAI_API_KEY。
  bool get isProxyEndpoint => endpoint.trim().startsWith('/');

  bool get isConfigured =>
      endpoint.trim().isNotEmpty &&
      (isProxyEndpoint || apiKey.trim().isNotEmpty);
}

class AIDiagnosisService implements DiagnosisService {
  const AIDiagnosisService({
    required this.knowledge,
    this.config = const AIDiagnosisConfig(),
    http.Client? client,
  }) : _client = client;

  final PrintKnowledge knowledge;
  final AIDiagnosisConfig config;
  final http.Client? _client;

  @override
  Future<DiagnosisResult> analyze(DiagnosisRequest request) async {
    if (!config.isConfigured) {
      throw const AIDiagnosisException(
        'AI 引擎未配置。请通过 --dart-define 或代理服务配置 endpoint/API key。',
      );
    }

    final client = _client ?? http.Client();
    final stopwatch = Stopwatch()..start();
    final prompt = _buildPrompt(request);
    _logAiRequest(request: request, prompt: prompt);
    try {
      final response = await client.post(
        Uri.parse(config.endpoint),
        headers: _buildHeaders(),
        body: jsonEncode(_buildPayload(request, prompt)),
      );
      debugPrint(
        '[PrintDoctor][AI] HTTP ${response.statusCode} in ${stopwatch.elapsedMilliseconds}ms',
        wrapWidth: 1024,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AIDiagnosisException(
          'AI 请求失败：HTTP ${response.statusCode} ${response.body}',
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final content = _extractOutputText(decoded);
      final json = _extractJsonObject(content);
      final result = _resultFromAiJson(request, json);
      debugPrint(
        '[PrintDoctor][AI] Parsed result in ${stopwatch.elapsedMilliseconds}ms: ${result.title}',
        wrapWidth: 1024,
      );
      return result;
    } on AIDiagnosisException {
      rethrow;
    } catch (error) {
      throw AIDiagnosisException('AI 诊断失败：$error');
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }

  Map<String, String> _buildHeaders() {
    final headers = {'Content-Type': 'application/json'};
    // 请求同源代理时不能把 key 放进前端请求；代理函数会从服务端环境变量读取。
    if (!config.isProxyEndpoint && config.apiKey.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${config.apiKey}';
    }
    return headers;
  }

  Map<String, dynamic> _buildPayload(
    DiagnosisRequest request,
    String textInput,
  ) {
    final content = <Map<String, dynamic>>[
      {'type': 'input_text', 'text': textInput},
    ];

    if (request.hasImage) {
      final mimeType = request.imageMimeType ?? 'image/png';
      content.add({
        'type': 'input_image',
        'detail': 'auto',
        'image_url': 'data:$mimeType;base64,${request.imageBase64}',
      });
    }

    return {
      'model': config.model,
      'input': [
        {'role': 'user', 'content': content},
      ],
    };
  }

  String _buildPrompt(DiagnosisRequest request) {
    // 这里控制 AI 输入体积：只取前 20 条知识库问题，避免 prompt 过长拖慢响应。
    final material = knowledge.materials
        .where((item) => item.name == request.material)
        .map(
          (item) =>
              '${item.name}: 喷嘴 ${item.nozzleTemp}, 热床 ${item.bedTemp}, 风扇 ${item.fan}, '
              '特性 ${item.traits.join('、')}, 常见问题 ${item.commonIssues.join('、')}, 提示 ${item.tips}',
        )
        .join('\n');
    final issueKnowledge = knowledge.issues
        .take(20)
        .map((item) => '- ${item.problem}: ${item.solution}')
        .join('\n');
    return '''
你是一个面向 3D 打印用户的诊断助手。请基于用户输入、日志、材料上下文和知识库，输出严格 JSON，不要输出 Markdown。

输出 schema:
{
  "title": "短标题",
  "summary": "一句话诊断摘要",
  "severity": "low|medium|high",
  "confidence": 0-100,
  "evidenceQuality": "证据充分|证据可用|需要补充",
  "evidenceHints": ["还缺什么信息"],
  "materialNotes": ["材料/参数上下文"],
  "causes": [{"title":"原因","reason":"理由","score":0-100}],
  "actions": ["按优先级排序的排查步骤"],
  "report": "可复制给售后/论坛的中文报告"
}

用户输入：
问题类型：${request.issueType}
机型/品牌：${request.printer}
材料：${request.material}
切片软件：${request.slicer}
故障描述：${request.description}
日志：${request.log}
是否上传图片：${request.hasImage ? '是，文件名 ${request.imageName ?? '未命名'}' : '否'}

材料上下文：
$material

知识库：
$issueKnowledge
''';
  }

  void _logAiRequest({
    required DiagnosisRequest request,
    required String prompt,
  }) {
    // 调试慢请求时只打印图片大小，不打印 base64 内容，避免控制台被刷爆。
    final imageSize = request.imageBase64 == null
        ? 0
        : request.imageBase64!.length;
    debugPrint(
      '========== PrintDoctor AI Diagnosis Prompt ==========',
      wrapWidth: 1024,
    );
    debugPrint(
      '[PrintDoctor][AI] endpoint=${config.endpoint}, model=${config.model}, hasImage=${request.hasImage}, imageBase64Length=$imageSize',
      wrapWidth: 1024,
    );
    debugPrint(prompt, wrapWidth: 1024);
    debugPrint(
      '========== End PrintDoctor AI Diagnosis Prompt ==========',
      wrapWidth: 1024,
    );
  }

  String _extractOutputText(Map<String, dynamic> decoded) {
    final outputText = decoded['output_text'];
    if (outputText is String && outputText.trim().isNotEmpty) {
      return outputText;
    }

    final output = decoded['output'];
    if (output is List) {
      final buffer = StringBuffer();
      for (final item in output.whereType<Map<String, dynamic>>()) {
        final content = item['content'];
        if (content is List) {
          for (final part in content.whereType<Map<String, dynamic>>()) {
            final text = part['text'];
            if (text is String) {
              buffer.write(text);
            }
          }
        }
      }
      if (buffer.isNotEmpty) {
        return buffer.toString();
      }
    }

    throw const AIDiagnosisException('AI 响应中没有可解析文本。');
  }

  Map<String, dynamic> _extractJsonObject(String content) {
    final trimmed = content.trim();
    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start == -1 || end <= start) {
      throw AIDiagnosisException('AI 响应不是有效 JSON：$content');
    }
    return jsonDecode(trimmed.substring(start, end + 1))
        as Map<String, dynamic>;
  }

  DiagnosisResult _resultFromAiJson(
    DiagnosisRequest request,
    Map<String, dynamic> json,
  ) {
    final causes = (json['causes'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(DiagnosisCause.fromJson)
        .take(5)
        .toList();
    final actions = (json['actions'] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .take(12)
        .toList();
    final materialNotes = (json['materialNotes'] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .take(5)
        .toList();
    final evidenceHints = (json['evidenceHints'] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .take(5)
        .toList();
    final severityName = json['severity']?.toString();
    final severity = Severity.values.firstWhere(
      (item) => item.name == severityName,
      orElse: () => Severity.medium,
    );

    return DiagnosisResult(
      title: json['title']?.toString().trim().isNotEmpty == true
          ? json['title'].toString()
          : '${request.issueType}AI 诊断结果',
      summary: json['summary']?.toString().trim().isNotEmpty == true
          ? json['summary'].toString()
          : 'AI 已基于描述、日志、材料和知识库生成诊断。',
      severity: severity,
      confidence: ((json['confidence'] as num?)?.round() ?? 70).clamp(0, 100),
      evidenceQuality: json['evidenceQuality']?.toString() ?? '证据可用',
      evidenceHints: evidenceHints,
      materialNotes: materialNotes,
      causes: causes.isEmpty
          ? const [
              DiagnosisCause(
                title: 'AI 未返回明确原因',
                reason: '建议补充图片、日志和已尝试的排查动作后重试。',
                score: 45,
              ),
            ]
          : causes,
      actions: actions.isEmpty ? const ['补充更多故障上下文后重新诊断。'] : actions,
      report: json['report']?.toString().trim().isNotEmpty == true
          ? json['report'].toString()
          : '问题类型：${request.issueType}\n机型：${request.printer}\n材料：${request.material}',
    );
  }
}

class AIDiagnosisException implements Exception {
  const AIDiagnosisException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LocalRuleDiagnosisService implements DiagnosisService {
  const LocalRuleDiagnosisService({this.knowledge = PrintKnowledge.empty});

  final PrintKnowledge knowledge;

  @override
  Future<DiagnosisResult> analyze(DiagnosisRequest request) async {
    final source =
        '${request.issueType.toLowerCase()} ${request.description.toLowerCase()} ${request.log.toLowerCase()}';
    final causes = <DiagnosisCause>[];
    final material = _findMaterial(request.material);

    void add(String title, String reason, int score) {
      causes.add(DiagnosisCause(title: title, reason: reason, score: score));
    }

    final matchedKnowledge = _matchKnowledgeIssues(source);
    for (final match in matchedKnowledge.take(3)) {
      add('知识库匹配：${match.problem}', match.solution, match.score);
    }

    if (_containsAny(source, [
      'timeout',
      'closed',
      'disconnect',
      '离线',
      '断连',
      'websocket',
      'retry',
    ])) {
      add('连接链路不稳定', '日志中出现连接关闭、超时或重试失败，优先排查网络、设备服务进程和 App 重连策略。', 88);
      add('任务状态恢复逻辑缺失', '断线后本地任务仍是 printing，但远端状态未知，说明状态同步需要补偿查询。', 76);
    }

    if (_containsAny(source, ['mismatch', 'unknown', '状态不同步', 'state'])) {
      add('本地与设备状态机不一致', '任务状态在本地和远端之间出现偏差，需要检查状态事件顺序、丢包和断线恢复后的全量刷新。', 84);
    }

    if (_containsAny(source, [
      'thermal',
      'temp',
      'temperature',
      '温度',
      'hotend',
      'bed',
    ])) {
      add('温控波动或传感器异常', '温度相关日志出现异常时，需要先确认热端、热床、热敏电阻和 PID 控制是否稳定。', 82);
    }

    if (_containsAny(source, [
      'under extrusion',
      'extrusion',
      'clog',
      '堵头',
      '挤出',
      'nozzle',
    ])) {
      add('挤出链路异常', '堵头、挤出不足或喷嘴状态异常会导致层间缺料，建议检查喷嘴、耗材、挤出轮和回抽参数。', 80);
    }

    if (_containsAny(source, [
      'warp',
      'adhesion',
      'first layer',
      '翘边',
      '首层',
      '不粘',
    ])) {
      add('首层附着不足', '翘边通常与平台调平、热床温度、首层速度、风扇和材料收缩有关。', 78);
    }

    if (causes.isEmpty) {
      add('信息不足，需要补充日志', '当前描述缺少明确错误信号，建议补充完整连接日志、温度曲线、失败时间点和机型固件版本。', 55);
      add('先按问题类型做基础排查', 'MVP 本地规则只能做初筛，后续接入 AI 后会结合更多上下文给出更细诊断。', 45);
    }

    causes.sort((a, b) => b.score.compareTo(a.score));
    final topCauses = causes.take(3).toList();
    final severity = topCauses.first.score >= 85
        ? Severity.high
        : topCauses.first.score >= 70
        ? Severity.medium
        : Severity.low;
    final evidenceHints = _buildEvidenceHints(request);
    final evidenceQuality = _evidenceQualityLabel(evidenceHints.length);
    final materialNotes = _buildMaterialNotes(material);
    final actions = _buildActions(topCauses, matchedKnowledge, material);
    final evidencePenalty = evidenceHints.length * 6;
    final confidence = (topCauses.first.score - evidencePenalty).clamp(40, 92);
    final report = _buildReport(
      request: request,
      causes: topCauses,
      actions: actions,
      evidenceHints: evidenceHints,
      materialNotes: materialNotes,
    );

    return DiagnosisResult(
      title: '${request.issueType}诊断结果',
      summary: '基于机型、材料、切片软件、故障描述和日志片段生成。当前为本地规则 MVP，适合快速初筛和生成售后沟通报告。',
      severity: severity,
      confidence: confidence,
      evidenceQuality: evidenceQuality,
      evidenceHints: evidenceHints,
      materialNotes: materialNotes,
      causes: topCauses,
      actions: actions,
      report: report,
    );
  }

  bool _containsAny(String source, List<String> keywords) {
    return keywords.any(source.contains);
  }

  MaterialProfile? _findMaterial(String materialName) {
    final normalized = materialName.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    for (final material in knowledge.materials) {
      final name = material.name.toLowerCase();
      if (normalized == name ||
          normalized.contains(name) ||
          name.contains(normalized)) {
        return material;
      }
    }
    return null;
  }

  List<_KnowledgeIssueMatch> _matchKnowledgeIssues(String source) {
    final matches = <_KnowledgeIssueMatch>[];
    for (final issue in knowledge.issues) {
      final score = _matchScore(source, '${issue.problem} ${issue.solution}');
      if (score >= 2) {
        matches.add(
          _KnowledgeIssueMatch(
            issue: issue,
            score: (60 + score * 8).clamp(60, 90),
          ),
        );
      }
    }
    matches.sort((a, b) => b.score.compareTo(a.score));
    return matches;
  }

  int _matchScore(String source, String text) {
    final tokens = _tokenize(text);
    var score = 0;
    for (final token in tokens) {
      if (source.contains(token)) {
        score++;
      }
    }
    return score;
  }

  Set<String> _tokenize(String text) {
    final normalized = text.toLowerCase().replaceAll(
      RegExp(r'[，。、/（）()→+\-_\s]+'),
      ' ',
    );
    final words = normalized
        .split(' ')
        .where((word) => word.trim().length >= 2)
        .toSet();
    final cnChunks = RegExp(
      r'[\u4e00-\u9fa5]{2,}',
    ).allMatches(text).expand((match) => _ngrams(match.group(0) ?? '')).toSet();
    return {...words, ...cnChunks};
  }

  Iterable<String> _ngrams(String text) sync* {
    if (text.length <= 4) {
      yield text;
      return;
    }
    for (var i = 0; i <= text.length - 2; i++) {
      yield text.substring(i, i + 2);
    }
    for (var i = 0; i <= text.length - 3; i++) {
      yield text.substring(i, i + 3);
    }
  }

  List<String> _buildEvidenceHints(DiagnosisRequest request) {
    final hints = <String>[];
    final description = request.description.trim();
    final log = request.log.trim();
    final slicer = request.slicer.trim();

    if (description.length < 20) {
      hints.add('故障描述偏短，建议补充失败比例、是否稳定复现、失败前最后一个可见现象。');
    }
    if (log.length < 30) {
      hints.add('日志或错误码不足，建议粘贴失败前后 30-60 秒的日志片段。');
    }
    if (!_containsAny(description.toLowerCase(), [
      '已尝试',
      '复现',
      '每次',
      '偶发',
      '重新',
      '一次',
    ])) {
      hints.add('缺少复现信息，建议说明问题是必现、偶发，还是换模型/换材料后才出现。');
    }
    if (slicer.isEmpty || slicer.contains('/')) {
      hints.add('切片软件信息不够精确，建议写明具体软件和版本，例如 OrcaSlicer 2.x。');
    }
    return hints;
  }

  String _evidenceQualityLabel(int hintCount) {
    if (hintCount == 0) {
      return '证据充分';
    }
    if (hintCount <= 2) {
      return '证据可用';
    }
    return '需要补充';
  }

  List<String> _buildMaterialNotes(MaterialProfile? material) {
    if (material == null) {
      return const ['未匹配到材料档案，参数建议会偏保守。'];
    }

    return [
      '${material.name} 基础窗口：喷嘴 ${material.nozzleTemp}，热床 ${material.bedTemp}，风扇 ${material.fan}。',
      '常见风险：${material.commonIssues.join('、')}。',
      material.tips,
    ];
  }

  List<String> _buildActions(
    List<DiagnosisCause> causes,
    List<_KnowledgeIssueMatch> matchedKnowledge,
    MaterialProfile? material,
  ) {
    final actions = <String>[
      '保留原始日志和失败时间点，不要只截图最后一个错误。',
      '复现一次问题，并记录机型、固件版本、切片软件、材料和环境温度。',
    ];

    if (material != null) {
      actions.add(
        '${material.name} 建议参数：喷嘴 ${material.nozzleTemp}，热床 ${material.bedTemp}，风扇 ${material.fan}。',
      );
      actions.add('${material.name} 材料提示：${material.tips}');
    }

    for (final match in matchedKnowledge.take(2)) {
      actions.add('知识库建议：${match.solution}');
    }

    if (causes.any(
      (cause) => cause.title.contains('连接') || cause.title.contains('状态机'),
    )) {
      actions.addAll([
        '检查设备与 App 的网络链路，确认同一局域网、弱网、休眠和后台切换场景。',
        '断线重连后主动拉取设备全量状态，避免只依赖本地缓存状态继续显示 printing。',
      ]);
    }

    if (causes.any((cause) => cause.title.contains('温控'))) {
      actions.addAll([
        '观察热端和热床温度曲线，确认是否有剧烈波动或异常掉温。',
        '检查热敏电阻、加热棒、风扇和 PID 参数，必要时重新做 PID tuning。',
      ]);
    }

    if (causes.any((cause) => cause.title.contains('挤出'))) {
      actions.addAll([
        '清理喷嘴并检查耗材是否受潮、打结或被挤出齿轮磨损。',
        '降低速度或提高喷嘴温度做 A/B 测试，观察挤出是否恢复稳定。',
      ]);
    }

    if (causes.any((cause) => cause.title.contains('首层'))) {
      actions.addAll([
        '重新调平平台并校准 Z offset，首层速度先降到保守值。',
        '根据材料调整热床温度，必要时清洁平台或增加附着辅助。',
      ]);
    }

    actions.add('如果问题仍然复现，把诊断报告发给售后或研发同事，继续做日志级定位。');
    return actions;
  }

  String _buildReport({
    required DiagnosisRequest request,
    required List<DiagnosisCause> causes,
    required List<String> actions,
    required List<String> evidenceHints,
    required List<String> materialNotes,
  }) {
    final causeLines = causes
        .map((cause) => '- ${cause.title} (${cause.score}%): ${cause.reason}')
        .join('\n');
    final actionLines = actions
        .asMap()
        .entries
        .map((entry) => '${entry.key + 1}. ${entry.value}')
        .join('\n');
    final evidenceLines = evidenceHints.isEmpty
        ? '输入信息较完整，可直接按建议排查。'
        : evidenceHints.map((hint) => '- $hint').join('\n');
    final materialLines = materialNotes.map((note) => '- $note').join('\n');

    return '''
问题类型：${request.issueType}
机型：${request.printer}
材料：${request.material}
切片软件：${request.slicer}

故障描述：
${request.description.isEmpty ? '未填写' : request.description}

可能原因：
$causeLines

材料/参数上下文：
$materialLines

需要补充的信息：
$evidenceLines

建议排查：
$actionLines
''';
  }
}

class _KnowledgeIssueMatch {
  const _KnowledgeIssueMatch({required this.issue, required this.score});

  final PrintIssueFix issue;
  final int score;

  String get problem => issue.problem;
  String get solution => issue.solution;
}
