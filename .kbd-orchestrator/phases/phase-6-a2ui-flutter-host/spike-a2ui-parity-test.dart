// Probe: does genui render the SAME A2UI document the web and MCP hosts render?
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:a2ui_core/a2ui_core.dart' as core;

/// v1.0 -> v0.9, mirroring toV09Messages() in the MCP-UI guest and
/// toSdkMessages() in the AG-UI web host. Two differences:
///   1. catalogId must name the renderer's own catalog
///   2. v1.0 carries components/dataModel INSIDE createSurface; v0.9 splits them
List<Map<String, Object?>> toV09(List<dynamic> messages, String catalogId) {
  final out = <Map<String, Object?>>[];
  for (final m in messages) {
    final msg = m as Map<String, dynamic>;
    final cs = msg['createSurface'] as Map<String, dynamic>?;
    if (cs == null) { out.add(msg); continue; }
    final sid = cs['surfaceId'] as String;
    out.add({'version': 'v0.9', 'createSurface': {'surfaceId': sid, 'catalogId': catalogId}});
    final comps = cs['components'];
    if (comps is List && comps.isNotEmpty) {
      out.add({'version': 'v0.9', 'updateComponents': {'surfaceId': sid, 'components': comps}});
    }
    if (cs['dataModel'] != null) {
      out.add({'version': 'v0.9',
        'updateDataModel': {'surfaceId': sid, 'path': '/', 'value': cs['dataModel']}});
    }
  }
  return out;
}

void main() {
  testWidgets('renders the shared A2UI document', (tester) async {
    final raw = File('assets/source.a2ui.json').readAsStringSync();
    final doc = jsonDecode(raw);
    final catalog = BasicCatalogItems.asCatalog();

    final controller = SurfaceController(catalogs: [catalog]);
    for (final m in toV09([doc], basicCatalogId)) {
      controller.handleMessage(core.A2uiMessage.fromJson(m));
    }

    final surfaceId = (jsonDecode(raw) as Map<String, dynamic>)['createSurface']['surfaceId'] as String;
    final ctx = controller.contextFor(surfaceId);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Surface(surfaceContext: ctx))));
    await tester.pumpAndSettle();

    // PARITY: assert the SAME observable facts the web/MCP browser gate asserts.
    // The web host renders: heading text, body text, and TWO buttons
    // labelled "Enable" / "Not now".
    expect(find.text('Enable notifications'), findsOneWidget,
        reason: 'heading from the shared A2UI document');
    expect(find.textContaining('Get alerts'), findsOneWidget,
        reason: 'body text from the shared A2UI document');
    final buttons = find.byWidgetPredicate((w) => w is ButtonStyleButton);
    expect(buttons, findsNWidgets(2), reason: 'two Button components');
    expect(find.text('Enable'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);
    debugPrint('PARITY OK: heading + body + 2 buttons, same as the web host');
  });
}
