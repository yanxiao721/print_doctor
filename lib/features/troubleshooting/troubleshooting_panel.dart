import 'package:flutter/material.dart';

import '../../core/widgets/panel_widgets.dart';
import '../../models/print_knowledge.dart';

class TroubleshootingPanel extends StatefulWidget {
  const TroubleshootingPanel({super.key, required this.flows});

  final List<TroubleshootingFlow> flows;

  @override
  State<TroubleshootingPanel> createState() => _TroubleshootingPanelState();
}

class _TroubleshootingPanelState extends State<TroubleshootingPanel> {
  int _selectedFlowIndex = 0;
  final Map<int, int> _selectedOptions = {};

  @override
  Widget build(BuildContext context) {
    if (widget.flows.isEmpty) {
      return const Surface(
        child: SectionTitle(
          title: '排查向导',
          subtitle: '暂无排查流程。可以继续往 knowledge JSON 里补充 troubleshooting_flows。',
        ),
      );
    }

    final flow =
        widget.flows[_selectedFlowIndex.clamp(0, widget.flows.length - 1)];
    final suggestions = <String>[];
    for (final entry in _selectedOptions.entries) {
      if (entry.key < flow.steps.length &&
          entry.value < flow.steps[entry.key].options.length) {
        suggestions.add(flow.steps[entry.key].options[entry.value].suggestion);
      }
    }

    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: '排查向导',
            subtitle: '不依赖 AI，用规则树一步步缩小问题范围，适合新手和售后场景。',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _selectedFlowIndex,
            decoration: const InputDecoration(labelText: '排查主题'),
            items: widget.flows
                .asMap()
                .entries
                .map(
                  (entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value.title),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedFlowIndex = value;
                _selectedOptions.clear();
              });
            },
          ),
          const SizedBox(height: 10),
          Text(
            flow.description,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF5B667A),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ...flow.steps.asMap().entries.map((entry) {
            final stepIndex = entry.key;
            final step = entry.value;
            return TroubleshootingStepCard(
              index: stepIndex + 1,
              step: step,
              selectedOption: _selectedOptions[stepIndex],
              onSelected: (optionIndex) =>
                  setState(() => _selectedOptions[stepIndex] = optionIndex),
            );
          }),
          const SizedBox(height: 16),
          const Text('当前建议', style: PanelStyles.heading),
          const SizedBox(height: 10),
          if (suggestions.isEmpty)
            const Text(
              '选择上面的选项后，这里会生成排查建议。',
              style: TextStyle(color: Color(0xFF667085)),
            )
          else
            ...suggestions.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: Color(0xFF0F766E),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          fontSize: 14,
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

class TroubleshootingStepCard extends StatelessWidget {
  const TroubleshootingStepCard({
    super.key,
    required this.index,
    required this.step,
    required this.selectedOption,
    required this.onSelected,
  });

  final int index;
  final TroubleshootingStep step;
  final int? selectedOption;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$index. ${step.question}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF172033),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: step.options.asMap().entries.map((entry) {
              final optionIndex = entry.key;
              final option = entry.value;
              return ChoiceChip(
                selected: selectedOption == optionIndex,
                label: Text(option.label),
                onSelected: (_) => onSelected(optionIndex),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
