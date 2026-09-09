import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finance_app/main.dart';

void main() {
  testWidgets('Shows a warning when Supabase is not configured', (
    WidgetTester tester,
  ) async {
    dotenv.loadFromString(envString: 'SUPABASE_URL=\nSUPABASE_ANON_KEY=\n');

    await tester.pumpWidget(const FinanceApp());
    await tester.pump();

    expect(find.text('Kinscope'), findsWidgets);
    expect(find.textContaining('not configured'), findsOneWidget);
  });
}
