class PrintKnowledge {
  const PrintKnowledge({
    required this.brands,
    required this.issues,
    required this.slicerTips,
    required this.materials,
    required this.troubleshootingFlows,
    required this.parameterRecommendations,
  });

  factory PrintKnowledge.fromJson(Map<String, dynamic> json) {
    return PrintKnowledge(
      brands:
          (json['top_10_consumer_3d_printer_brands'] as List<dynamic>? ?? [])
              .map((item) => item.toString())
              .toList(),
      issues:
          (json['top_20_common_printing_issues_and_fixes'] as List<dynamic>? ??
                  [])
              .whereType<Map<String, dynamic>>()
              .map(PrintIssueFix.fromJson)
              .toList(),
      slicerTips: (json['top_10_slicer_skills'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(SlicerTip.fromJson)
          .toList(),
      materials: (json['materials'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(MaterialProfile.fromJson)
          .toList(),
      troubleshootingFlows:
          (json['troubleshooting_flows'] as List<dynamic>? ?? [])
              .whereType<Map<String, dynamic>>()
              .map(TroubleshootingFlow.fromJson)
              .toList(),
      parameterRecommendations:
          (json['parameter_recommendations'] as List<dynamic>? ?? [])
              .whereType<Map<String, dynamic>>()
              .map(ParameterRecommendation.fromJson)
              .toList(),
    );
  }

  static const empty = PrintKnowledge(
    brands: [],
    issues: [],
    slicerTips: [],
    materials: [],
    troubleshootingFlows: [],
    parameterRecommendations: [],
  );

  final List<String> brands;
  final List<PrintIssueFix> issues;
  final List<SlicerTip> slicerTips;
  final List<MaterialProfile> materials;
  final List<TroubleshootingFlow> troubleshootingFlows;
  final List<ParameterRecommendation> parameterRecommendations;
}

class PrintIssueFix {
  const PrintIssueFix({required this.problem, required this.solution});

  factory PrintIssueFix.fromJson(Map<String, dynamic> json) {
    return PrintIssueFix(
      problem: json['problem']?.toString() ?? '',
      solution: json['solution']?.toString() ?? '',
    );
  }

  final String problem;
  final String solution;
}

class SlicerTip {
  const SlicerTip({required this.skill, required this.description});

  factory SlicerTip.fromJson(Map<String, dynamic> json) {
    return SlicerTip(
      skill: json['skill']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }

  final String skill;
  final String description;
}

class MaterialProfile {
  const MaterialProfile({
    required this.name,
    required this.nozzleTemp,
    required this.bedTemp,
    required this.fan,
    required this.traits,
    required this.commonIssues,
    required this.tips,
  });

  factory MaterialProfile.fromJson(Map<String, dynamic> json) {
    return MaterialProfile(
      name: json['name']?.toString() ?? '',
      nozzleTemp: json['nozzle_temp']?.toString() ?? '',
      bedTemp: json['bed_temp']?.toString() ?? '',
      fan: json['fan']?.toString() ?? '',
      traits: (json['traits'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      commonIssues: (json['common_issues'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      tips: json['tips']?.toString() ?? '',
    );
  }

  final String name;
  final String nozzleTemp;
  final String bedTemp;
  final String fan;
  final List<String> traits;
  final List<String> commonIssues;
  final String tips;
}

class TroubleshootingFlow {
  const TroubleshootingFlow({
    required this.id,
    required this.title,
    required this.description,
    required this.steps,
  });

  factory TroubleshootingFlow.fromJson(Map<String, dynamic> json) {
    return TroubleshootingFlow(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      steps: (json['steps'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(TroubleshootingStep.fromJson)
          .toList(),
    );
  }

  final String id;
  final String title;
  final String description;
  final List<TroubleshootingStep> steps;
}

class TroubleshootingStep {
  const TroubleshootingStep({required this.question, required this.options});

  factory TroubleshootingStep.fromJson(Map<String, dynamic> json) {
    return TroubleshootingStep(
      question: json['question']?.toString() ?? '',
      options: (json['options'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(TroubleshootingOption.fromJson)
          .toList(),
    );
  }

  final String question;
  final List<TroubleshootingOption> options;
}

class TroubleshootingOption {
  const TroubleshootingOption({required this.label, required this.suggestion});

  factory TroubleshootingOption.fromJson(Map<String, dynamic> json) {
    return TroubleshootingOption(
      label: json['label']?.toString() ?? '',
      suggestion: json['suggestion']?.toString() ?? '',
    );
  }

  final String label;
  final String suggestion;
}

class ParameterRecommendation {
  const ParameterRecommendation({
    required this.goal,
    required this.settings,
    required this.tradeoffs,
  });

  factory ParameterRecommendation.fromJson(Map<String, dynamic> json) {
    return ParameterRecommendation(
      goal: json['goal']?.toString() ?? '',
      settings: (json['settings'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      tradeoffs: (json['tradeoffs'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
    );
  }

  final String goal;
  final List<String> settings;
  final List<String> tradeoffs;
}
