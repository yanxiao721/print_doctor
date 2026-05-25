import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'features/diagnosis/diagnosis_form.dart';
import 'features/diagnosis/diagnosis_panel.dart';
import 'features/diagnosis/diagnosis_workspace.dart';
import 'features/feedback/feedback_panel.dart';
import 'features/history/diagnosis_history_panel.dart';
import 'features/materials/materials_panel.dart';
import 'features/parameters/parameter_recommender_panel.dart';
import 'features/slicer_tips/slicer_tips_panel.dart';
import 'features/troubleshooting/troubleshooting_panel.dart';
import 'models/diagnosis.dart';
import 'models/print_knowledge.dart';
import 'services/diagnosis_service.dart';
import 'services/diagnosis_history_repository.dart';
import 'services/knowledge_repository.dart';
import 'shell/app_header.dart';
import 'shell/app_module.dart';
import 'shell/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const PrintDoctorApp());
}

class PrintDoctorApp extends StatelessWidget {
  const PrintDoctorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Print Doctor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F8FA),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD7DEE5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD7DEE5)),
          ),
        ),
      ),
      home: const DiagnosisPage(),
    );
  }
}

class DiagnosisPage extends StatefulWidget {
  const DiagnosisPage({super.key});

  @override
  State<DiagnosisPage> createState() => _DiagnosisPageState();
}

class _DiagnosisPageState extends State<DiagnosisPage> {
  final _knowledgeRepository = const KnowledgeRepository();
  final _historyRepository = const DiagnosisHistoryRepository();
  final _imagePicker = ImagePicker();
  final _printerController = TextEditingController();
  final _materialController = TextEditingController();
  final _slicerController = TextEditingController(
    text: 'Bambu Studio / Cura / OrcaSlicer',
  );
  final _descriptionController = TextEditingController();
  final _logController = TextEditingController();

  AppModule _selectedModule = AppModule.diagnosis;
  DiagnosisEngine _engine = DiagnosisEngine.local;
  String _issueType = '';
  String _printer = '';
  String _material = '';
  String? _selectedImageName;
  String? _selectedImageMimeType;
  String? _selectedImageBase64;
  DiagnosisResult? _result;
  List<DiagnosisHistoryEntry> _history = [];
  PrintKnowledge _knowledge = PrintKnowledge.empty;
  bool _isKnowledgeLoading = true;
  bool _isDiagnosing = false;
  String? _diagnosisError;

  @override
  void initState() {
    super.initState();
    _loadKnowledge();
    _loadHistory();
  }

  Future<void> _loadKnowledge() async {
    final knowledge = await _knowledgeRepository.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _knowledge = knowledge;
      _issueType = knowledge.issues.isNotEmpty
          ? knowledge.issues.first.problem
          : '';
      _printer = knowledge.brands.isNotEmpty ? knowledge.brands.first : '';
      _material = knowledge.materials.isNotEmpty
          ? knowledge.materials.first.name
          : '';
      _printerController.text = _printer;
      _materialController.text = _material;
      _isKnowledgeLoading = false;
    });
  }

  Future<void> _loadHistory() async {
    final history = await _historyRepository.loadAll();
    if (!mounted) {
      return;
    }
    setState(() {
      _history = history;
    });
  }

  @override
  void dispose() {
    _printerController.dispose();
    _materialController.dispose();
    _slicerController.dispose();
    _descriptionController.dispose();
    _logController.dispose();
    super.dispose();
  }

  Future<void> _diagnose() async {
    setState(() {
      _isDiagnosing = true;
      _diagnosisError = null;
    });

    final request = DiagnosisRequest(
      issueType: _issueType,
      printer: _printer,
      material: _material,
      slicer: _slicerController.text,
      description: _descriptionController.text,
      log: _logController.text,
      imageName: _selectedImageName,
      imageMimeType: _selectedImageMimeType,
      imageBase64: _selectedImageBase64,
    );
    final service = _engine == DiagnosisEngine.ai
        ? AIDiagnosisService(knowledge: _knowledge)
        : LocalRuleDiagnosisService(knowledge: _knowledge);

    try {
      final result = await service.analyze(request);
      final entry = DiagnosisHistoryEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        engine: _engine.label,
        request: request,
        result: result,
      );
      await _historyRepository.save(entry);

      if (!mounted) {
        return;
      }

      setState(() {
        _result = result;
        _history = [entry, ..._history].take(30).toList();
        _isDiagnosing = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _diagnosisError = error.toString();
        _isDiagnosing = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (image == null) {
      return;
    }
    final bytes = await image.readAsBytes();
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedImageName = image.name;
      _selectedImageMimeType = image.mimeType ?? 'image/jpeg';
      _selectedImageBase64 = base64Encode(bytes);
    });
  }

  void _clearImage() {
    setState(() {
      _selectedImageName = null;
      _selectedImageMimeType = null;
      _selectedImageBase64 = null;
    });
  }

  void _restoreHistory(DiagnosisHistoryEntry entry) {
    setState(() {
      _selectedModule = AppModule.diagnosis;
      _issueType = entry.request.issueType;
      _printer = entry.request.printer;
      _material = entry.request.material;
      _printerController.text = entry.request.printer;
      _materialController.text = entry.request.material;
      _slicerController.text = entry.request.slicer;
      _descriptionController.text = entry.request.description;
      _logController.text = entry.request.log;
      _selectedImageName = entry.request.imageName;
      _selectedImageMimeType = entry.request.imageMimeType;
      _selectedImageBase64 = entry.request.imageBase64;
      _result = entry.result;
      _diagnosisError = null;
    });
  }

  Future<void> _clearHistory() async {
    await _historyRepository.clear();
    if (!mounted) {
      return;
    }
    setState(() => _history = []);
  }

  void _loadSample() {
    setState(() {
      _issueType = _knowledge.issues
          .map((issue) => issue.problem)
          .firstWhere(
            (problem) => problem.contains('打印中断'),
            orElse: () => _issueType,
          );
      _printer = _knowledge.brands.isNotEmpty
          ? _knowledge.brands.first
          : '拓竹 Bambu Lab';
      _material = 'PLA';
      _printerController.text = _printer;
      _materialController.text = _material;
      _slicerController.text = 'OrcaSlicer';
      _descriptionController.text = '打印到 30% 左右突然断开，App 显示设备离线，重新连接后任务状态不同步。';
      _logController.text = '''
[18:42:11] connection timeout
[18:42:12] printer status: printing
[18:42:16] websocket closed unexpectedly
[18:42:20] retry connect failed
[18:42:31] task state mismatch: local=printing remote=unknown
''';
      _selectedImageName = null;
      _selectedImageMimeType = null;
      _selectedImageBase64 = null;
      _result = null;
      _diagnosisError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(knowledge: _knowledge, isLoading: _isKnowledgeLoading),
            Expanded(
              child: AppShell(
                selectedModule: _selectedModule,
                onModuleChanged: (module) =>
                    setState(() => _selectedModule = module),
                child: _buildModuleContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleContent() {
    return switch (_selectedModule) {
      AppModule.diagnosis => DiagnosisWorkspace(
        form: DiagnosisForm(
          issueType: _issueType,
          issueOptions: _knowledge.issues
              .map((issue) => issue.problem)
              .toList(),
          printer: _printer,
          printerOptions: _knowledge.brands,
          material: _material,
          materialOptions: _knowledge.materials
              .map((material) => material.name)
              .toList(),
          slicerController: _slicerController,
          descriptionController: _descriptionController,
          logController: _logController,
          engine: _engine.name,
          selectedImageName: _selectedImageName,
          onEngineChanged: (value) => setState(() {
            _engine = DiagnosisEngine.values.firstWhere(
              (engine) => engine.name == value,
              orElse: () => DiagnosisEngine.local,
            );
          }),
          onIssueChanged: (value) => setState(() => _issueType = value),
          onPrinterChanged: (value) => setState(() {
            _printer = value;
            _printerController.text = value;
          }),
          onMaterialChanged: (value) => setState(() {
            _material = value;
            _materialController.text = value;
          }),
          onPickImage: _pickImage,
          onClearImage: _clearImage,
          onDiagnose: _diagnose,
          onLoadSample: _loadSample,
          isDiagnosing: _isDiagnosing,
        ),
        result: DiagnosisPanel(
          result: _result,
          error: _diagnosisError,
          isLoading: _isDiagnosing,
          engineLabel: _engine.label,
        ),
      ),
      AppModule.troubleshooting => TroubleshootingPanel(
        flows: _knowledge.troubleshootingFlows,
      ),
      AppModule.parameters => ParameterRecommenderPanel(
        materials: _knowledge.materials,
        recommendations: _knowledge.parameterRecommendations,
      ),
      AppModule.materials => MaterialsPanel(materials: _knowledge.materials),
      AppModule.slicerTips => SlicerTipsPanel(tips: _knowledge.slicerTips),
      AppModule.history => DiagnosisHistoryPanel(
        entries: _history,
        onRestore: _restoreHistory,
        onClear: _clearHistory,
      ),
      AppModule.feedback => FeedbackPanel(knowledge: _knowledge),
    };
  }
}
