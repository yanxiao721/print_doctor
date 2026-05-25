import 'package:flutter/material.dart';

import '../../core/widgets/panel_widgets.dart';
import '../../models/diagnosis.dart';

class DiagnosisPanel extends StatelessWidget {
  const DiagnosisPanel({
    super.key,
    required this.result,
    this.error,
    this.isLoading = false,
    this.engineLabel = '诊断',
  });

  final DiagnosisResult? result;
  final String? error;
  final bool isLoading;
  final String engineLabel;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Surface(child: LoadingState(engineLabel: engineLabel));
    }

    if (error != null && error!.isNotEmpty) {
      return Surface(child: ErrorState(message: error!));
    }

    if (result == null) {
      return const Surface(child: EmptyState());
    }

    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: result!.title, subtitle: result!.summary),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              StatusPill(
                label: result!.severity.label,
                icon: result!.severity.icon,
              ),
              StatusPill(
                label: '置信度 ${result!.confidence}%',
                icon: Icons.analytics_outlined,
              ),
              StatusPill(
                label: result!.evidenceQuality,
                icon: Icons.fact_check_outlined,
              ),
              StatusPill(
                label: '建议 ${result!.actions.length} 步',
                icon: Icons.checklist_outlined,
              ),
            ],
          ),
          const SizedBox(height: 18),
          DiagnosisSignalStrip(result: result!),
          const SizedBox(height: 18),
          const Text('可能原因', style: PanelStyles.heading),
          const SizedBox(height: 10),
          ...result!.causes.map((cause) => CauseTile(cause: cause)),
          const SizedBox(height: 18),
          const Text('排查步骤', style: PanelStyles.heading),
          const SizedBox(height: 10),
          ...result!.actions.asMap().entries.map(
            (entry) => StepTile(index: entry.key + 1, text: entry.value),
          ),
          const SizedBox(height: 18),
          const Text('诊断报告草稿', style: PanelStyles.heading),
          const SizedBox(height: 10),
          ReportBox(text: result!.report),
        ],
      ),
    );
  }
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, required this.engineLabel});

  final String engineLabel;

  @override
  Widget build(BuildContext context) {
    final isAi = engineLabel.contains('AI');
    return SizedBox(
      height: 420,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 58,
                height: 58,
                child: CircularProgressIndicator(strokeWidth: 4),
              ),
              const SizedBox(height: 20),
              Text(
                isAi ? 'AI 正在分析打印问题' : '正在匹配本地规则',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF172033),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isAi
                    ? '正在整理故障描述、日志、材料上下文和图片信息。复杂日志或图片会慢一点。'
                    : '正在根据知识库和关键词生成排查建议。',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF667085),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusPill(
                    label: engineLabel,
                    icon: isAi
                        ? Icons.auto_awesome_outlined
                        : Icons.offline_bolt_outlined,
                  ),
                  StatusPill(
                    label: isAi ? '联网请求中' : '离线计算中',
                    icon: Icons.timer_outlined,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DiagnosisSignalStrip extends StatelessWidget {
  const DiagnosisSignalStrip({super.key, required this.result});

  final DiagnosisResult result;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;
        final children = [
          Expanded(
            child: SignalCard(
              title: '输入质量',
              icon: Icons.fact_check_outlined,
              lines: result.evidenceHints.isEmpty
                  ? const ['信息较完整，可以直接进入排查。']
                  : result.evidenceHints,
            ),
          ),
          const SizedBox(width: 12, height: 12),
          Expanded(
            child: SignalCard(
              title: '材料上下文',
              icon: Icons.category_outlined,
              lines: result.materialNotes,
            ),
          ),
        ];

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children
              .map((child) => child is Expanded ? child.child : child)
              .toList(),
        );
      },
    );
  }
}

class SignalCard extends StatelessWidget {
  const SignalCard({
    super.key,
    required this.title,
    required this.icon,
    required this.lines,
  });

  final String title;
  final IconData icon;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF0F766E)),
              const SizedBox(width: 8),
              Text(title, style: PanelStyles.heading),
            ],
          ),
          const SizedBox(height: 10),
          ...lines
              .take(4)
              .map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '·',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.2,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          line,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: Color(0xFF344054),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 34,
                color: Color(0xFFB42318),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '诊断失败',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF172033),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 420,
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF667085), height: 1.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 520,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFE7F4F1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.troubleshoot_outlined,
                size: 38,
                color: Color(0xFF0F766E),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '等待诊断',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF172033),
              ),
            ),
            const SizedBox(height: 8),
            const SizedBox(
              width: 360,
              child: Text(
                '输入故障描述和日志后，右侧会生成原因排序、排查步骤和可复制的报告草稿。',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF667085), height: 1.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CauseTile extends StatelessWidget {
  const CauseTile({super.key, required this.cause});

  final DiagnosisCause cause;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              '${cause.score}%',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F766E),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cause.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF172033),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  cause.reason,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF5B667A),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StepTile extends StatelessWidget {
  const StepTile({super.key, required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF172033),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$index',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF344054),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReportBox extends StatelessWidget {
  const ReportBox({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF101828),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText(
        text,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: Color(0xFFE4E7EC),
          height: 1.55,
        ),
      ),
    );
  }
}
