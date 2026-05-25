import 'package:flutter/material.dart';

import '../../core/widgets/panel_widgets.dart';
import '../../models/print_knowledge.dart';

class SlicerTipsPanel extends StatelessWidget {
  const SlicerTipsPanel({super.key, required this.tips});

  final List<SlicerTip> tips;

  @override
  Widget build(BuildContext context) {
    if (tips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Surface(child: SlicerTipsWorkbench(tips: tips));
  }
}

class SlicerTipsWorkbench extends StatefulWidget {
  const SlicerTipsWorkbench({super.key, required this.tips});

  final List<SlicerTip> tips;

  @override
  State<SlicerTipsWorkbench> createState() => _SlicerTipsWorkbenchState();
}

class _SlicerTipsWorkbenchState extends State<SlicerTipsWorkbench> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final selected =
        widget.tips[_selectedIndex.clamp(0, widget.tips.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: '切片策略库',
          subtitle: '按目标场景选择设置策略，展示操作方向、适用对象和副作用提醒。',
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            if (!isWide) {
              return Column(
                children: [
                  SlicerTipSelector(
                    tips: widget.tips,
                    selectedIndex: _selectedIndex,
                    onSelected: (index) =>
                        setState(() => _selectedIndex = index),
                  ),
                  const SizedBox(height: 14),
                  SlicerTipDetail(tip: selected),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 360,
                  child: SlicerTipSelector(
                    tips: widget.tips,
                    selectedIndex: _selectedIndex,
                    onSelected: (index) =>
                        setState(() => _selectedIndex = index),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: SlicerTipDetail(tip: selected)),
              ],
            );
          },
        ),
      ],
    );
  }
}

class SlicerTipSelector extends StatelessWidget {
  const SlicerTipSelector({
    super.key,
    required this.tips,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<SlicerTip> tips;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: tips.asMap().entries.map((entry) {
        final selected = entry.key == selectedIndex;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onSelected(entry.key),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFEFF6F5)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected
                      ? const Color(0xFFC9E7E1)
                      : const Color(0xFFE3E8EF),
                ),
              ),
              child: Text(
                entry.value.skill,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected
                      ? const Color(0xFF0F514A)
                      : const Color(0xFF344054),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class SlicerTipDetail extends StatelessWidget {
  const SlicerTipDetail({super.key, required this.tip});

  final SlicerTip tip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.tune_outlined, size: 30, color: Color(0xFF0F766E)),
          const SizedBox(height: 12),
          Text(
            tip.skill,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF172033),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            tip.description,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF344054),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 18),
          const Text('使用建议', style: PanelStyles.heading),
          const SizedBox(height: 10),
          const _TipLine(text: '先复制当前切片配置，再调整该策略，方便回退。'),
          const _TipLine(text: '一次只改 1-2 个关键参数，避免无法判断效果来源。'),
          const _TipLine(text: '同一模型用小区域或低层高版本做 A/B 测试，别上来就打印完整件。'),
        ],
      ),
    );
  }
}

class _TipLine extends StatelessWidget {
  const _TipLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Color(0xFF344054),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
