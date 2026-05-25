import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/print_knowledge.dart';

class KnowledgeRepository {
  const KnowledgeRepository({
    this.assetPath = 'assets/knowledge/3d_print_info.json',
  });

  final String assetPath;

  Future<PrintKnowledge> load() async {
    final raw = await rootBundle.loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return PrintKnowledge.fromJson(json);
  }
}
