import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_faces/main.dart';

void main() {
  testWidgets('Apps starts up', (tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());
    expect(find.text('Flutter Face Detector'), findsOneWidget);
  });
}
