import 'package:flutter/material.dart';

import '../../core/widgets/panel_widgets.dart';
import '../../models/print_knowledge.dart';

class ParameterRecommenderPanel extends StatefulWidget {
  const ParameterRecommenderPanel({
    super.key,
    required this.materials,
    required this.recommendations,
  });

  final List<MaterialProfile> materials;
  final List<ParameterRecommendation> recommendations;

  @override
  State<ParameterRecommenderPanel> createState() =>
      _ParameterRecommenderPanelState();
}

class _ParameterRecommenderPanelState extends State<ParameterRecommenderPanel> {
  int _materialIndex = 0;
  int _goalIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.materials.isEmpty || widget.recommendations.isEmpty) {
      return const Surface(
        child: SectionTitle(
          title: '参数推荐',
          subtitle:
              '暂无材料或目标数据。可以继续往 knowledge JSON 里补充 materials 和 parameter_recommendations。',
        ),
      );
    }

    final material =
        widget.materials[_materialIndex.clamp(0, widget.materials.length - 1)];
    final recommendation =
        widget.recommendations[_goalIndex.clamp(
          0,
          widget.recommendations.length - 1,
        )];

    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: '参数推荐',
            subtitle: '选择耗材和目标，生成一组保守但可执行的切片调整建议。',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 240,
                child: DropdownButtonFormField<int>(
                  initialValue: _materialIndex,
                  decoration: const InputDecoration(labelText: '耗材'),
                  items: widget.materials
                      .asMap()
                      .entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _materialIndex = value);
                    }
                  },
                ),
              ),
              SizedBox(
                width: 260,
                child: DropdownButtonFormField<int>(
                  initialValue: _goalIndex,
                  decoration: const InputDecoration(labelText: '目标'),
                  items: widget.recommendations
                      .asMap()
                      .entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value.goal),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _goalIndex = value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              StatusPill(
                label: '喷嘴 ${material.nozzleTemp}',
                icon: Icons.thermostat_outlined,
              ),
              StatusPill(
                label: '热床 ${material.bedTemp}',
                icon: Icons.grid_on_outlined,
              ),
              StatusPill(label: '风扇 ${material.fan}', icon: Icons.air_outlined),
            ],
          ),
          const SizedBox(height: 18),
          const Text('推荐设置', style: PanelStyles.heading),
          const SizedBox(height: 10),
          ...recommendation.settings.map(
            (item) => RecommendationLine(icon: Icons.tune_outlined, text: item),
          ),
          const SizedBox(height: 14),
          const Text('注意事项', style: PanelStyles.heading),
          const SizedBox(height: 10),
          RecommendationLine(icon: Icons.info_outline, text: material.tips),
          ...recommendation.tradeoffs.map(
            (item) => RecommendationLine(
              icon: Icons.warning_amber_outlined,
              text: item,
            ),
          ),
        ],
      ),
    );
  }
}

class RecommendationLine extends StatelessWidget {
  const RecommendationLine({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0F766E)),
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
