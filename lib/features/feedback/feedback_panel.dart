import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets/panel_widgets.dart';
import '../../models/print_knowledge.dart';

class FeedbackPanel extends StatefulWidget {
  const FeedbackPanel({super.key, required this.knowledge});

  final PrintKnowledge knowledge;

  @override
  State<FeedbackPanel> createState() => _FeedbackPanelState();
}

class _FeedbackPanelState extends State<FeedbackPanel> {
  final _problemController = TextEditingController();
  final _logController = TextEditingController();
  final _contactController = TextEditingController();

  String _brand = '';
  String _material = '';
  String _issue = '';
  String _report = '';

  @override
  void initState() {
    super.initState();
    _brand = widget.knowledge.brands.isNotEmpty
        ? widget.knowledge.brands.first
        : '';
    _material = widget.knowledge.materials.isNotEmpty
        ? widget.knowledge.materials.first.name
        : '';
    _issue = widget.knowledge.issues.isNotEmpty
        ? widget.knowledge.issues.first.problem
        : '';
  }

  @override
  void didUpdateWidget(covariant FeedbackPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.knowledge != widget.knowledge) {
      _brand = widget.knowledge.brands.isNotEmpty
          ? widget.knowledge.brands.first
          : _brand;
      _material = widget.knowledge.materials.isNotEmpty
          ? widget.knowledge.materials.first.name
          : _material;
      _issue = widget.knowledge.issues.isNotEmpty
          ? widget.knowledge.issues.first.problem
          : _issue;
    }
  }

  @override
  void dispose() {
    _problemController.dispose();
    _logController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _generateReport() {
    setState(() {
      _report = _buildReportText();
    });
  }

  Future<void> _copyReport() async {
    if (_report.isEmpty) {
      _generateReport();
    }
    final report = _report.isEmpty ? _buildReportText() : _report;
    await Clipboard.setData(ClipboardData(text: report));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('反馈报告已复制')));
  }

  Future<void> _openMail() async {
    final report = _report.isEmpty ? _buildReportText() : _report;
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@example.com',
      queryParameters: {'subject': 'Print Doctor 问题反馈：$_issue', 'body': report},
    );
    await launchUrl(uri);
  }

  String _buildReportText() {
    return '''
问题反馈

机型/品牌：$_brand
材料：$_material
问题类型：$_issue

现象描述：
${_problemController.text.trim().isEmpty ? '未填写' : _problemController.text.trim()}

日志/错误码/补充信息：
${_logController.text.trim().isEmpty ? '未填写' : _logController.text.trim()}

联系方式：
${_contactController.text.trim().isEmpty ? '未填写' : _contactController.text.trim()}
''';
  }

  @override
  Widget build(BuildContext context) {
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: '问题反馈',
            subtitle: '收集真实打印问题，后续可沉淀为案例库、排查流程和知识库条目。',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 260,
                child: DropdownButtonFormField<String>(
                  initialValue: widget.knowledge.brands.contains(_brand)
                      ? _brand
                      : null,
                  decoration: const InputDecoration(labelText: '机型/品牌'),
                  items: widget.knowledge.brands
                      .map(
                        (brand) =>
                            DropdownMenuItem(value: brand, child: Text(brand)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _brand = value);
                    }
                  },
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  initialValue:
                      widget.knowledge.materials
                          .map((item) => item.name)
                          .contains(_material)
                      ? _material
                      : null,
                  decoration: const InputDecoration(labelText: '材料'),
                  items: widget.knowledge.materials
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.name,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _material = value);
                    }
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: DropdownButtonFormField<String>(
                  initialValue:
                      widget.knowledge.issues
                          .map((item) => item.problem)
                          .contains(_issue)
                      ? _issue
                      : null,
                  decoration: const InputDecoration(labelText: '问题类型'),
                  items: widget.knowledge.issues
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.problem,
                          child: Text(item.problem),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _issue = value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _problemController,
            minLines: 4,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: '现象描述',
              hintText: '例如：打印到 20% 后层移位，重新打印仍然复现；或者 PETG 拉丝严重，已降低温度但无改善。',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _logController,
            minLines: 5,
            maxLines: 8,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            decoration: const InputDecoration(
              labelText: '日志 / 错误码 / 参数截图文字',
              hintText: '粘贴错误码、关键日志、切片参数或已尝试过的解决方法。',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contactController,
            decoration: const InputDecoration(
              labelText: '联系方式/备注',
              hintText: '可填微信、邮箱或备注。MVP 阶段不会自动上传，只生成可复制报告。',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _generateReport,
            icon: const Icon(Icons.description_outlined),
            label: const Text('生成反馈报告'),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: _copyReport,
                icon: const Icon(Icons.copy_outlined),
                label: const Text('复制报告'),
              ),
              OutlinedButton.icon(
                onPressed: _openMail,
                icon: const Icon(Icons.mail_outline),
                label: const Text('邮件反馈'),
              ),
            ],
          ),
          if (_report.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text('可复制反馈报告', style: PanelStyles.heading),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF101828),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _report,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Color(0xFFE4E7EC),
                  height: 1.55,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
