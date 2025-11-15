import 'package:excel_test/data.dart';
import 'package:excel_test/data_cell.dart';

class AuditData {
  late String time;
  late String from;
  late String to;

  AuditData(String str) {
    var arr = str.split(';;');
    time = arr[0];
    from = arr[1];
    to = arr[2];
  }

  mDataCell getFromData() {
    try {
      var arr = from.split(';');
      String table = arr[0];
      int row = int.parse(arr[1]);
      int cell = int.parse(arr[2]);
      String value = arr[3];
      return mDataCell(row: row, cell: cell, data: value, sheet: table);
    } catch (err) {
      print(err);
    }
    return mDataCell(row: -1, cell: -1, data: 'null');
  }

  String getSheet() {
    try {
      var arr = from.split(';');
      String table = arr[0];
      return table;
    } catch (err) {
      print(err);
    }
    return table ?? '';
  }

  mDataCell getToData() {
    try {
      var arr = to.split(';');
      String table = arr[0];
      int row = int.parse(arr[1]);
      int cell = int.parse(arr[2]);
      String value = arr[3];
      return mDataCell(row: row, cell: cell, data: value, sheet: table);
    } catch (err) {
      print(err);
    }
    return mDataCell(row: -1, cell: -1, data: 'null');
  }

  DateTime getTime() {
    try {
      var t = int.parse(time);
      return DateTime.fromMicrosecondsSinceEpoch(t);
    } catch (err) {
      print(err);
    }
    return DateTime.fromMicrosecondsSinceEpoch(1);
  }

  @override
  String toString() {
    return '$time;;$from;;$to';
  }
}
