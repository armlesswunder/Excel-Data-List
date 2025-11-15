// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:excel_test/data.dart';
import 'package:excel_test/model/string_extension.dart';
import 'package:excel_test/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Timeframe test', () {
    currentTime = getCurrentDate();
    for (String str in [
      "6/1-2/1",
      "6/1-12/15",
      "9/1-6/1",
      "1/1-6/1",
      "1/1-2/1&4/1-5/1&8/1-9/1",
      "2/1-4/1&5/1-6/1&10/1-11/1",
    ]) {
      var arr1 = str.split('&');
      bool inTimeframe = arr1.any((element) {
        var arr2 = element.split('-');
        var d1 = arr2[0].getDate;
        print(d1);
        var d2 = arr2[1].getDate;
        print(d2);
        print(currentTime);

        print('${isInTimeframe(d1, d2)}\n\n');
        return isInTimeframe(d1, d2);
      });

      print('$arr1 $inTimeframe\n\n');
    }
  });
}
