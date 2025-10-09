import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fleet_management/app.dart';

void main() {
  testWidgets('Fleet Management App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: FleetManagementApp(),
      ),
    );

    // Verify that our app loads with the expected text.
    expect(find.text('Architecture successfully implemented!'), findsOneWidget);
    
    // Verify navigation elements are present
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Vehicles'), findsOneWidget);
    expect(find.text('Drivers'), findsOneWidget);
    expect(find.text('Trips'), findsOneWidget);
    expect(find.text('Excel Import'), findsOneWidget);
  });
}