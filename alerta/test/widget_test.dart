import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alerta/main.dart';
import 'package:alerta/services/storage_service.dart';
import 'package:alerta/services/location_service.dart';
import 'package:alerta/services/emergency_service.dart';

void main() {
  testWidgets('Sentinel app smoke test', (WidgetTester tester) async {
    // Initialize required services
    final storageService = StorageService();
    final locationService = LocationService();
    final emergencyService = EmergencyService(
      locationService: locationService,
      storageService: storageService,
    );

    // Build our app and trigger a frame
    await tester.pumpWidget(PersonalSafetyApp(
      storageService: storageService,
      locationService: locationService,
      emergencyService: emergencyService,
    ));

    // Wait for the app to settle
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Verify that our app contains the expected elements
    expect(find.text('Sentinel'), findsAtLeastNWidgets(1));
    expect(find.byIcon(Icons.security), findsAtLeastNWidgets(1));
  });

  testWidgets('App title is correct', (WidgetTester tester) async {
    final storageService = StorageService();
    final locationService = LocationService();
    final emergencyService = EmergencyService(
      locationService: locationService,
      storageService: storageService,
    );

    await tester.pumpWidget(PersonalSafetyApp(
      storageService: storageService,
      locationService: locationService,
      emergencyService: emergencyService,
    ));

    await tester.pumpAndSettle();

    // Find MaterialApp and verify title
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.title, 'Sentinel - Personal Safety');
  });
}