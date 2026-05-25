import 'package:flutter/material.dart';

class DiagnosisWorkspace extends StatelessWidget {
  const DiagnosisWorkspace({
    super.key,
    required this.form,
    required this.result,
  });

  final Widget form;
  final Widget result;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;
        if (!isWide) {
          return Column(children: [form, const SizedBox(height: 16), result]);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 11, child: form),
            const SizedBox(width: 16),
            Expanded(flex: 13, child: result),
          ],
        );
      },
    );
  }
}
