import 'package:flutter_test/flutter_test.dart';
import 'package:unemployment_predictor/main.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const UnemploymentPredictorApp());
    expect(find.text('Unemployment Predictor'), findsOneWidget);
    expect(find.text('Predict'), findsOneWidget);
  });
}
