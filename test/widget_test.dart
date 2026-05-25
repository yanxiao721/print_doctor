import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:print_doctor/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    Hive.init('${Directory.systemTemp.path}/print_doctor_test_hive');
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk('diagnosis_history');
  });

  testWidgets('Print Doctor renders diagnosis form', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    await tester.pumpWidget(const PrintDoctorApp());
    await tester.pumpAndSettle();

    expect(find.text('Print Doctor'), findsOneWidget);
    expect(find.text('故障信息'), findsOneWidget);
    expect(find.text('开始诊断'), findsOneWidget);
  });
}
