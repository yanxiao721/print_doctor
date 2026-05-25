import 'package:flutter/material.dart';

enum Severity {
  low('低风险', Icons.check_circle_outline),
  medium('中风险', Icons.warning_amber_outlined),
  high('高风险', Icons.error_outline);

  const Severity(this.label, this.icon);

  final String label;
  final IconData icon;
}

class DiagnosisRequest {
  const DiagnosisRequest({
    required this.issueType,
    required this.printer,
    required this.material,
    required this.slicer,
    required this.description,
    required this.log,
    this.imageName,
    this.imageMimeType,
    this.imageBase64,
  });

  factory DiagnosisRequest.fromJson(Map<String, dynamic> json) {
    return DiagnosisRequest(
      issueType: json['issueType']?.toString() ?? '',
      printer: json['printer']?.toString() ?? '',
      material: json['material']?.toString() ?? '',
      slicer: json['slicer']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      log: json['log']?.toString() ?? '',
      imageName: json['imageName']?.toString(),
      imageMimeType: json['imageMimeType']?.toString(),
      imageBase64: json['imageBase64']?.toString(),
    );
  }

  final String issueType;
  final String printer;
  final String material;
  final String slicer;
  final String description;
  final String log;
  final String? imageName;
  final String? imageMimeType;
  final String? imageBase64;

  bool get hasImage => imageBase64 != null && imageBase64!.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'issueType': issueType,
      'printer': printer,
      'material': material,
      'slicer': slicer,
      'description': description,
      'log': log,
      'imageName': imageName,
      'imageMimeType': imageMimeType,
      'imageBase64': imageBase64,
    };
  }
}

class DiagnosisResult {
  const DiagnosisResult({
    required this.title,
    required this.summary,
    required this.severity,
    required this.confidence,
    required this.evidenceQuality,
    required this.evidenceHints,
    required this.materialNotes,
    required this.causes,
    required this.actions,
    required this.report,
  });

  final String title;
  final String summary;
  final Severity severity;
  final int confidence;
  final String evidenceQuality;
  final List<String> evidenceHints;
  final List<String> materialNotes;
  final List<DiagnosisCause> causes;
  final List<String> actions;
  final String report;

  factory DiagnosisResult.fromJson(Map<String, dynamic> json) {
    return DiagnosisResult(
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      severity: Severity.values.firstWhere(
        (item) => item.name == json['severity'],
        orElse: () => Severity.low,
      ),
      confidence: (json['confidence'] as num?)?.round() ?? 50,
      evidenceQuality: json['evidenceQuality']?.toString() ?? '证据可用',
      evidenceHints: (json['evidenceHints'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      materialNotes: (json['materialNotes'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      causes: (json['causes'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(DiagnosisCause.fromJson)
          .toList(),
      actions: (json['actions'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      report: json['report']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'summary': summary,
      'severity': severity.name,
      'confidence': confidence,
      'evidenceQuality': evidenceQuality,
      'evidenceHints': evidenceHints,
      'materialNotes': materialNotes,
      'causes': causes.map((cause) => cause.toJson()).toList(),
      'actions': actions,
      'report': report,
    };
  }
}

class DiagnosisCause {
  const DiagnosisCause({
    required this.title,
    required this.reason,
    required this.score,
  });

  final String title;
  final String reason;
  final int score;

  factory DiagnosisCause.fromJson(Map<String, dynamic> json) {
    return DiagnosisCause(
      title: json['title']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      score: (json['score'] as num?)?.round() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'reason': reason, 'score': score};
  }
}

class DiagnosisHistoryEntry {
  const DiagnosisHistoryEntry({
    required this.id,
    required this.createdAt,
    required this.engine,
    required this.request,
    required this.result,
  });

  factory DiagnosisHistoryEntry.fromJson(Map<String, dynamic> json) {
    return DiagnosisHistoryEntry(
      id: json['id']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      engine: json['engine']?.toString() ?? '',
      request: DiagnosisRequest.fromJson(
        (json['request'] as Map<dynamic, dynamic>? ?? {})
            .cast<String, dynamic>(),
      ),
      result: DiagnosisResult.fromJson(
        (json['result'] as Map<dynamic, dynamic>? ?? {})
            .cast<String, dynamic>(),
      ),
    );
  }

  final String id;
  final DateTime createdAt;
  final String engine;
  final DiagnosisRequest request;
  final DiagnosisResult result;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'engine': engine,
      'request': request.toJson(),
      'result': result.toJson(),
    };
  }
}
