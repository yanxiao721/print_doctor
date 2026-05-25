import 'package:flutter/material.dart';

import '../../core/widgets/panel_widgets.dart';
import '../../models/print_knowledge.dart';

class MaterialsPanel extends StatelessWidget {
  const MaterialsPanel({super.key, required this.materials});

  final List<MaterialProfile> materials;

  @override
  Widget build(BuildContext context) {
    if (materials.isEmpty) {
      return const SizedBox.shrink();
    }

    return Surface(child: MaterialsWorkbench(materials: materials));
  }
}

class MaterialsWorkbench extends StatefulWidget {
  const MaterialsWorkbench({super.key, required this.materials});

  final List<MaterialProfile> materials;

  @override
  State<MaterialsWorkbench> createState() => _MaterialsWorkbenchState();
}

class _MaterialsWorkbenchState extends State<MaterialsWorkbench> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final material =
        widget.materials[_selectedIndex.clamp(0, widget.materials.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: '耗材工作台',
          subtitle: '按材料查看参数窗口、风险画像和适用场景。后续可以扩展到品牌耗材和机型预设。',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.materials.asMap().entries.map((entry) {
            final selected = entry.key == _selectedIndex;
            return ChoiceChip(
              selected: selected,
              label: Text(entry.value.name),
              onSelected: (_) => setState(() => _selectedIndex = entry.key),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        MaterialProfileDetail(material: material),
      ],
    );
  }
}

class MaterialProfileDetail extends StatelessWidget {
  const MaterialProfileDetail({super.key, required this.material});

  final MaterialProfile material;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 880;
        final children = [
          Expanded(
            flex: isWide ? 9 : 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF172033),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  material.tips,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: Color(0xFF344054),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: material.traits
                      .map((trait) => _Tag(label: trait))
                      .toList(),
                ),
                const SizedBox(height: 18),
                const Text('常见风险', style: PanelStyles.heading),
                const SizedBox(height: 10),
                ...material.commonIssues.map(
                  (issue) => _InfoLine(
                    icon: Icons.warning_amber_outlined,
                    text: issue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16, height: 16),
          Expanded(
            flex: isWide ? 7 : 0,
            child: Column(
              children: [
                _MetricCard(
                  label: '喷嘴温度',
                  value: material.nozzleTemp,
                  icon: Icons.thermostat_outlined,
                ),
                const SizedBox(height: 10),
                _MetricCard(
                  label: '热床温度',
                  value: material.bedTemp,
                  icon: Icons.grid_on_outlined,
                ),
                const SizedBox(height: 10),
                _MetricCard(
                  label: '风扇建议',
                  value: material.fan,
                  icon: Icons.air_outlined,
                ),
              ],
            ),
          ),
        ];

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE3E8EF)),
          ),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children
                      .map((child) => child is Expanded ? child.child : child)
                      .toList(),
                ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0F766E)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF667085),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF172033),
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

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0F766E)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Color(0xFF344054)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF5B667A),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
