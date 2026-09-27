import 'package:flutter_test/flutter_test.dart';
import 'package:daily_wallpaper/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // 渲染应用
    await tester.pumpWidget(const MyApp());

    // 验证应用标题存在
    expect(find.text('简纸'), findsWidgets);
  });
}
