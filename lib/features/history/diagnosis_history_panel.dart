import 'package:flutter/material.dart';

import '../../core/widgets/panel_widgets.dart';
import '../../models/diagnosis.dart';

class DiagnosisHistoryPanel extends StatelessWidget {
  const DiagnosisHistoryPanel({
    super.key,
    required this.entries,
    required this.onRestore,
    required this.onClear,
  });

  final List<DiagnosisHistoryEntry> entries;
  final ValueChanged<DiagnosisHistoryEntry> onRestore;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionTitle(
                  title: '诊断历史',
                  subtitle: '本地保存最近诊断，方便同一台机器反复对比。',
                ),
              ),
              OutlinedButton.icon(
                onPressed: entries.isEmpty ? null : onClear,
                icon: const Icon(Icons.delete_outline),
                label: const Text('清空'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            const Text(
              '暂无历史。完成一次诊断后会自动保存到本机浏览器。',
              style: TextStyle(color: Color(0xFF667085)),
            )
          else
            ...entries.map(
              (entry) => HistoryEntryTile(
                entry: entry,
                onRestore: () => onRestore(entry),
              ),
            ),
        ],
      ),
    );
  }
}

class HistoryEntryTile extends StatelessWidget {
  const HistoryEntryTile({
    super.key,
    required this.entry,
    required this.onRestore,
  });

  final DiagnosisHistoryEntry entry;
  final VoidCallback onRestore;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  entry.result.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF172033),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              StatusPill(label: entry.engine, icon: Icons.history_outlined),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatDate(entry.createdAt)} · ${entry.request.printer} · ${entry.request.material} · ${entry.result.confidence}%',
            style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
          ),
          const SizedBox(height: 8),
          Text(
            entry.result.summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Color(0xFF344054),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRestore,
              icon: const Icon(Icons.restore_outlined),
              label: const Text('载入'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    String two(int input) => input.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} ${two(value.hour)}:${two(value.minute)}';
  }
}
