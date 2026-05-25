import 'package:flutter/material.dart';

import '../models/print_knowledge.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key, required this.knowledge, required this.isLoading});

  final PrintKnowledge knowledge;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 480;
        return Container(
          padding: EdgeInsets.fromLTRB(isNarrow ? 14 : 24, isNarrow ? 10 : 18, isNarrow ? 14 : 24, isNarrow ? 10 : 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE3E8EF))),
          ),
          child: Row(
            children: [
              Container(
                width: isNarrow ? 36 : 42,
                height: isNarrow ? 36 : 42,
                decoration: BoxDecoration(color: const Color(0xFF0F766E), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.precision_manufacturing_outlined, color: Colors.white, size: isNarrow ? 20 : 24),
              ),
              SizedBox(width: isNarrow ? 10 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Print Doctor',
                      style: TextStyle(fontSize: isNarrow ? 18 : 22, fontWeight: FontWeight.w800, color: const Color(0xFF172033)),
                    ),
                    if (!isNarrow) ...[const SizedBox(height: 2), const Text('3D 打印故障诊断助手 MVP', style: TextStyle(fontSize: 13, color: Color(0xFF5B667A)))],
                  ],
                ),
              ),
              SupportAuthorButton(subtitle: isLoading ? '知识库加载中' : '${knowledge.issues.length} fixes · ${knowledge.materials.length} materials', compact: isNarrow),
            ],
          ),
        );
      },
    );
  }
}

class SupportAuthorButton extends StatelessWidget {
  const SupportAuthorButton({super.key, required this.subtitle, this.compact = false});

  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // MVP 阶段不做登录和付费墙，右上角用轻量打赏入口验证用户支持意愿。
    return Tooltip(
      message: '支持作者继续维护知识库',
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => showDialog<void>(context: context, builder: (context) => const RewardDialog()),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12, vertical: compact ? 8 : 9),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6F5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFC9E7E1)),
          ),
          child: compact
              ? const Icon(Icons.volunteer_activism_outlined, size: 18, color: Color(0xFF0F766E))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.volunteer_activism_outlined, size: 18, color: Color(0xFF0F766E)),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '支持作者',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F514A)),
                        ),
                        Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF5B667A))),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class RewardDialog extends StatelessWidget {
  const RewardDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: const Color(0xFFEFF6F5), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.volunteer_activism_outlined, color: Color(0xFF0F766E)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '支持作者',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF172033)),
                        ),
                        SizedBox(height: 2),
                        Text('请作者喝杯咖啡，继续补案例和参数库。', style: TextStyle(fontSize: 13, color: Color(0xFF667085))),
                      ],
                    ),
                  ),
                  IconButton(tooltip: '关闭', onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  // 收款码作为本地 asset 打包，线上不依赖第三方图片服务。
                  'assets/images/wechat_reward.jpg',
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 14),
              const Text('如果这个工具帮你少废了一卷料，可以随手支持一下。感谢每一次真实使用和反馈。', style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF344054))),
            ],
          ),
        ),
      ),
    );
  }
}
