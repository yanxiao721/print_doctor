import 'package:flutter/material.dart';

import '../../core/widgets/panel_widgets.dart';

class DiagnosisForm extends StatelessWidget {
  const DiagnosisForm({
    super.key,
    required this.issueType,
    required this.issueOptions,
    required this.printer,
    required this.printerOptions,
    required this.material,
    required this.materialOptions,
    required this.slicerController,
    required this.descriptionController,
    required this.logController,
    required this.engine,
    required this.selectedImageName,
    required this.onEngineChanged,
    required this.onIssueChanged,
    required this.onPrinterChanged,
    required this.onMaterialChanged,
    required this.onPickImage,
    required this.onClearImage,
    required this.onDiagnose,
    required this.onLoadSample,
    required this.isDiagnosing,
  });

  final String issueType;
  final List<String> issueOptions;
  final String printer;
  final List<String> printerOptions;
  final String material;
  final List<String> materialOptions;
  final TextEditingController slicerController;
  final TextEditingController descriptionController;
  final TextEditingController logController;
  final String engine;
  final String? selectedImageName;
  final ValueChanged<String> onEngineChanged;
  final ValueChanged<String> onIssueChanged;
  final ValueChanged<String> onPrinterChanged;
  final ValueChanged<String> onMaterialChanged;
  final VoidCallback onPickImage;
  final VoidCallback onClearImage;
  final VoidCallback onDiagnose;
  final VoidCallback onLoadSample;
  final bool isDiagnosing;

  @override
  Widget build(BuildContext context) {
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: '故障信息', subtitle: '先把现象、机型、日志和图片喂进去，可选择本地规则或 AI 分析。'),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 500;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: isMobile ? double.infinity : 280,
                    child: SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: 'local', icon: Icon(Icons.offline_bolt_outlined), label: Text('本地规则')),
                        ButtonSegment(value: 'ai', icon: Icon(Icons.auto_awesome_outlined), label: Text('AI 分析')),
                      ],
                      selected: {engine},
                      onSelectionChanged: (selection) => onEngineChanged(selection.first),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: issueOptions.contains(issueType) ? issueType : null,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: '问题类型'),
                    items: issueOptions
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        onIssueChanged(value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: isMobile ? constraints.maxWidth : 250,
                        child: DropdownButtonFormField<String>(
                          initialValue: printerOptions.contains(printer) ? printer : null,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: '机型/品牌'),
                          items: printerOptions
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item, overflow: TextOverflow.ellipsis),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              onPrinterChanged(value);
                            }
                          },
                        ),
                      ),
                      SizedBox(
                        width: isMobile ? constraints.maxWidth : 160,
                        child: DropdownButtonFormField<String>(
                          initialValue: materialOptions.contains(material) ? material : null,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: '材料'),
                          items: materialOptions
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item, overflow: TextOverflow.ellipsis),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              onMaterialChanged(value);
                            }
                          },
                        ),
                      ),
                      SizedBox(
                        width: isMobile ? constraints.maxWidth : 250,
                        child: TextField(
                          controller: slicerController,
                          decoration: const InputDecoration(labelText: '切片软件'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descriptionController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(labelText: '故障描述', hintText: '例如：打印到一半断连，喷头温度波动，模型翘边，任务状态不同步...'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: logController,
            minLines: 9,
            maxLines: 13,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            decoration: const InputDecoration(labelText: '日志 / G-code 片段 / 错误信息', hintText: '粘贴连接日志、错误码、温度记录或关键 G-code 片段。', alignLabelWithHint: true),
          ),
          const SizedBox(height: 12),
          ImagePickerRow(selectedImageName: selectedImageName, onPickImage: onPickImage, onClearImage: onClearImage),
          const SizedBox(height: 18),
          Row(
            children: [
              FilledButton.icon(
                onPressed: isDiagnosing ? null : onDiagnose,
                icon: Icon(isDiagnosing ? Icons.hourglass_top_outlined : Icons.medical_information_outlined),
                label: Text(isDiagnosing ? '诊断中' : '开始诊断'),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(onPressed: onLoadSample, icon: const Icon(Icons.science_outlined), label: const Text('载入样例')),
            ],
          ),
        ],
      ),
    );
  }
}

class ImagePickerRow extends StatelessWidget {
  const ImagePickerRow({super.key, required this.selectedImageName, required this.onPickImage, required this.onClearImage});

  final String? selectedImageName;
  final VoidCallback onPickImage;
  final VoidCallback onClearImage;

  @override
  Widget build(BuildContext context) {
    final hasImage = selectedImageName != null && selectedImageName!.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.image_outlined, color: Color(0xFF0F766E)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasImage ? selectedImageName! : '可选：上传缺陷照片，AI 模式会把图片一起送入诊断。',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Color(0xFF344054)),
            ),
          ),
          const SizedBox(width: 10),
          if (hasImage) IconButton(tooltip: '移除图片', onPressed: onClearImage, icon: const Icon(Icons.close)),
          OutlinedButton.icon(onPressed: onPickImage, icon: const Icon(Icons.upload_file_outlined), label: Text(hasImage ? '更换' : '选择图片')),
        ],
      ),
    );
  }
}
