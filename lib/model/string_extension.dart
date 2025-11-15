import 'dart:io';

import 'package:intl/intl.dart';

extension StrExt on String {
  String getFileName({bool removeExtension = true}) {
    if (contains(Platform.pathSeparator)) {
      var arr = split(Platform.pathSeparator);
      var str = arr[arr.length - 1];
      if (removeExtension && str.contains('.')) {
        str = str.substring(0, str.lastIndexOf('.'));
      }
      return str;
    }
    return this;
  }

  DateTime get getDate {
    DateFormat format = DateFormat("MM/dd");
    var formattedDate = format.parse(this);
    return formattedDate;
  }
}
