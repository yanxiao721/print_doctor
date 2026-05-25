import 'package:flutter/material.dart';

enum AppModule {
  diagnosis('故障检测', Icons.troubleshoot_outlined),
  troubleshooting('排查向导', Icons.account_tree_outlined),
  parameters('参数推荐', Icons.speed_outlined),
  materials('耗材建议', Icons.category_outlined),
  slicerTips('切片技巧', Icons.tune_outlined),
  history('诊断历史', Icons.history_outlined),
  feedback('问题反馈', Icons.rate_review_outlined);

  const AppModule(this.label, this.icon);

  final String label;
  final IconData icon;
}
