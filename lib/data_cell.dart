import 'dart:io';

import 'package:excel/excel.dart';
import 'package:excel_test/favorite_button.dart';
import 'package:excel_test/model/string_extension.dart';
import 'package:excel_test/prefs.dart';
import 'package:excel_test/utils.dart';
import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/material.dart';

import 'data.dart';
import 'main.dart';
import 'model/audit_data.dart';

class mDataCell {
  int row;
  int cell;
  bool info = false;
  String? sheet;
  dynamic data;
  mDataCell(
      {required this.row,
      required this.cell,
      this.data,
      this.info = false,
      this.sheet});

  bool isMoveDownData() {
    var s = excel?.tables[sheet ?? table]?.rows[0][cell];

    String header = '${s!.value}';
    return header.contains('_md');
  }

  bool isCbData() {
    var s = excel?.tables[sheet ?? table]?.rows[0][cell];

    String header = '${s!.value}';
    return header.contains('_cb');
  }

  bool isFavData() {
    var s = excel?.tables[sheet ?? table]?.rows[0][cell];

    String header = '${s!.value}';
    return header.contains('_fav');
  }

  bool isGroupData() {
    var s = excel?.tables[sheet ?? table]?.rows[0][cell];

    String header = '${s!.value}';
    return header.contains('_group');
  }

  bool isPointerData() {
    var s = excel?.tables[sheet ?? table]?.rows[0][cell];

    String header = '${s!.value}';
    return header.startsWith('*');
  }

  int getFlex() {
    try {
      var s = excel?.tables[sheet ?? table]?.rows[0][cell];

      int maxColumns = getMaxColumns();

      if (maxColumns == cell) {
        return 7;
      }

      String header = '${s!.value}';
      if (header.contains('width=')) {
        var arr = header.split('_');
        var w = arr.firstWhere((element) => element.contains('width='));
        var f = w.split('=')[1];
        return int.parse(f);
      }
      return 10;
    } catch (e) {
      return 10;
    }
  }

  bool isTimeframe() {
    try {
      var s = excel?.tables[sheet ?? table]?.rows[0][cell];

      String header = '${s!.value}';
      if (header.contains('_timeframe')) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  bool isImage() {
    try {
      var s = excel?.tables[sheet ?? table]?.rows[0][cell];

      String header = '${s!.value}';
      if (header.contains('_img')) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  String getRowStr() {
    String header = '';

    try {
      excel?.tables[sheet ?? table]?.rows[row].forEach((element) {
        header += '${element?.value}, ';
      });
    } catch (e) {}
    return header.substring(0, header.lastIndexOf(', '));
  }

  String getHeader() {
    String header = '';

    try {
      var s = excel?.tables[sheet ?? table]?.rows[0][cell];

      header = '${s?.value}';
    } catch (e) {}
    return header;
  }

  String getHeaderDisplay() {
    String header = '';

    try {
      var s = excel?.tables[sheet ?? table]?.rows[0][cell];
      header = s?.value.toString() ?? '';
      if (header.contains('_')) {
        header = header.split('_').first;
      }
    } catch (e) {}
    return header;
  }

  void setHeader(String newHeader) {
    String header = '';

    try {
      var t = excel!.tables[sheet ?? table];
      var r = t?.row(0);
      var c = r?[cell];
      r?[cell]?.value = TextCellValue(newHeader);
      //saveExcel();
    } catch (e) {
      print(e);
    }
  }

  Widget build() {
    String header = '';

    try {
      var s = excel?.tables[sheet ?? table]?.rows[0][cell];

      header = '${s?.value}';
      if (header == 'null') {
        return Visibility(visible: false, child: Container());
      }
    } catch (e) {
      return Container();
    }

    if (info) {
      return buildContainer(
          SizedBox(
              width: infoWidth + 12,
              child: IconButton(
                  onPressed: () {
                    showInfoDialog(mcontext, row);
                  },
                  icon: const Icon(
                    Icons.info_outline,
                    color: Colors.white70,
                  ))),
          mh: cellWidthMargin,
          ph: cellWidthMargin);
    }

    if (row != 0 && isMoveDownData()) {
      return Padding(
          padding:
              EdgeInsets.symmetric(horizontal: cellWidthMargin, vertical: 8),
          child: IconButton(
            icon: const Icon(Icons.move_down),
            onPressed: () {
              var headerRow = excel!.sheets[table]?.rows[0];
              var dataRows = List.of(excel!.sheets[table]!.rows
                  .sublist(1, excel!.sheets[table]!.rows.length));
              dataRows.insert(0, headerRow!);
              dataRows.add(dataRows.removeAt(row));

              int i = 0;
              List<List<String>> l = dataRows
                  .map((e) => e.map((e) => e!.value.toString()).toList())
                  .toList();
              for (var row in l) {
                for (int j = 0; j < excel!.sheets[table]!.rows[i].length; j++) {
                  var t = excel!.tables[table];
                  var r = t?.row(i);
                  r?[j]?.value = TextCellValue(row[j] == 'null' ? '' : row[j]);
                }
                i += 1;
              }

              saveExcel();
              initData();
              mainState(() {});
            },
          ));
    }

    if (row != 0 && isCbData()) {
      return Padding(
          padding:
              EdgeInsets.symmetric(horizontal: cellWidthMargin, vertical: 8),
          child: StatefulBuilder(builder: (BuildContext context, state) {
            var t = excel?.tables[sheet ?? table];
            var r = t?.row(row);
            var displayVal = r?[cell]?.value.toString();
            return buildContainer(
                Checkbox(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                  side: MaterialStateBorderSide.resolveWith(
                    (states) =>
                        const BorderSide(width: 2.0, color: Colors.white70),
                  ),
                  onChanged: (value) {
                    var t = excel?.tables[sheet ?? table];
                    var r = t?.row(row);
                    var c = r?[cell];
                    r?[cell]?.value = TextCellValue(value! ? '1' : '0');
                    var prev = '${sheet ?? table};$row;$cell;${!value!}';
                    var change = '${sheet ?? table};$row;$cell;$value';
                    var time = DateTime.now().microsecondsSinceEpoch;
                    auditData.insert(0, AuditData('$time;;$prev;;$change'));
                    print(change);

                    if (Platform.isAndroid) {
                      unsavedChanges.add(change);
                      prefs.setStringList(fileContentsKey, unsavedChanges);
                    }
                    setAuditData();
                    unsaved = true;
                    try {
                      //saveExcel();
                      state(() {});
                      saveBtnState(() {});
                    } catch (e) {}
                  },
                  value: displayVal == '1',
                ),
                mh: cellWidthMargin);
          }));
    }

    if (row != 0 && isFavData()) {
      return Padding(
          padding:
              EdgeInsets.symmetric(horizontal: cellWidthMargin, vertical: 8),
          child: StatefulBuilder(builder: (BuildContext context, state) {
            var tab = sheet ?? table;
            return buildContainer(
                FavoriteButton(row: row, cell: cell, sheet: tab ?? ""),
                mh: cellWidthMargin);
          }));
    }
    if (data == 'null') {
      return Padding(
          padding:
              EdgeInsets.symmetric(horizontal: cellWidthMargin, vertical: 8),
          child: GestureDetector(
              onLongPress: () async {
                var res = await showUpdateDialog(mcontext, (value) {
                  var arr = value.split(';;');
                  var t = excel!.tables[sheet ?? table];
                  var r = t?.row(row);
                  r?[cell]?.value = TextCellValue(arr[0]);

                  var t1 = excel!.tables[table];
                  var r1 = t1?.row(0);
                  r1?[cell]?.value = TextCellValue(arr[1]);
                  //saveExcel();
                  mainState(() {});
                }, cell, row, content: data.toString());
              },
              child: buildContainer(const Text(' - '), mh: cellWidthMargin)));
    }
    if (header.contains('_img') || header.toLowerCase().contains('image')) {
      try {
        var arr = [data.value.toString(), ''];
        var name = '';
        if (data.value.toString().contains(';')) {
          arr = data.value.toString().split(';');
        }
        var imgUrl = arr[0];
        name = arr[1];
        imgUrl = '$assetDir$imgUrl';
        if (Platform.isAndroid) {
          imgUrl = imgUrl.replaceAll('\\', Platform.pathSeparator);
          print(imgUrl);
        }
        File imgFile = File(imgUrl);
        if (!imgFile.existsSync()) {
          try {
            String foundPath = Directory(assetDir)
                .listSync(recursive: true)
                .map((e) => e.path)
                .firstWhere((element) => element
                    .getFileName()
                    .toLowerCase()
                    .contains(
                        data.value.toString().getFileName().toLowerCase()));
            print(foundPath);
            imgFile = File(foundPath);
            name = data.value.toString();
          } catch (e) {
            imgUrl = arr[0];
          }
        }
        if (imgFile.existsSync()) {
          return Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                  onLongPress: () async {
                    var res = await showUpdateDialog(mcontext, (value) {
                      var arr = value.split(';;');
                      var t = excel!.tables[sheet ?? table];
                      var r = t?.row(row);
                      r?[cell]?.value = TextCellValue(arr[0]);

                      var t1 = excel!.tables[table];
                      var r1 = t1?.row(0);
                      r1?[cell]?.value = TextCellValue(arr[1]);
                      //saveExcel();
                      mainState(() {});
                    }, cell, row, content: data.toString());
                  },
                  child: Column(children: [
                    Image.file(imgFile, width: imgSize, height: imgSize),
                    Text(name)
                  ])));
        } else {
          return Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                  onLongPress: () async {
                    var res = await showUpdateDialog(mcontext, (value) {
                      var arr = value.split(';;');
                      var t = excel!.tables[sheet ?? table];
                      var r = t?.row(row);
                      r?[cell]?.value = TextCellValue(arr[0]);

                      var t1 = excel!.tables[table];
                      var r1 = t1?.row(0);
                      r1?[cell]?.value = TextCellValue(arr[1]);
                      //saveExcel();
                      mainState(() {});
                    }, cell, row, content: data.toString());
                  },
                  child: Column(children: [
                    FastCachedImage(
                      key: Key(data.toString()),
                      url: imgUrl,
                      width: imgSize,
                      height: imgSize,
                      loadingBuilder: (context, progress) {
                        return SizedBox(
                            width: imgSize / 2,
                            height: imgSize / 2,
                            child: const CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stack) {
                        return Container(
                            color: Colors.grey.withAlpha(100),
                            child: Text(
                                '${assetDir + data.value.toString()} not found.'));
                      },
                    ),
                    //Image.network(imgUrl, width: imgSize, height: imgSize),
                    Text(name)
                  ])));
        }
      } catch (e) {
        return Container(
            color: Colors.grey.withAlpha(100),
            child: Text('${assetDir + data.value.toString()} not found.'));
      }
    }
    return GestureDetector(
        onLongPress: () async {
          var res = await showUpdateDialog(mcontext, (value) {
            var arr = value.split(';;');
            var t = excel!.tables[sheet ?? table];
            var r = t?.row(row);
            r?[cell]?.value = TextCellValue(arr[0]);

            var t1 = excel!.tables[table];
            var r1 = t1?.row(0);
            r1?[cell]?.value = TextCellValue(arr[1]);
            //saveExcel();
            mainState(() {});
          }, cell, row, content: data.toString());
        },
        child: buildContainer(
            Text(
              '$data',
              maxLines: maxLines == 99999999999999 ? null : maxLines,
              overflow: TextOverflow.ellipsis,
            ),
            mh: cellWidthMargin));
  }

  Widget buildHeader() {
    if (data == null) {
      return Container();
    }

    var value = '$data';
    bool pointerData = false;
    String sheetPtr = table!;
    Data? header;

    if (data.value.toString().startsWith('*')) {
      pointerData = true;
      var args = data.value.toString().replaceFirst('*', '');
      var arr = args.split(';');
      sheetPtr = arr[0];
      String colPtr = arr[1];
      var rows = excel?.tables[sheetPtr]?.rows ?? [];
      header = rows[0]
          .firstWhere((element) => element!.value.toString().contains(colPtr));
      value = '${header!.value}';
    }

    if (value.contains('_')) {
      value = value.split('_')[0];
    }
    if (info) {
      return buildContainer(
          SizedBox(
              width: infoWidth,
              child: const Text('Info',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
          mh: cellWidthMargin);
    }
    return GestureDetector(
        onLongPress: () async {
          var res = await showUpdateDialog(mcontext, (value) {
            var t = excel!.tables[sheet ?? table];
            var r = t?.row(row);
            r?[cell]?.value = TextCellValue(value);
            //saveExcel();
            mainState(() {});
          }, cell, row, content: data.toString());
        },
        onTap: () {
          if (sortColumnIndex == cell) {
            sortColumnMode += 1;
            if (sortColumnMode > 1) {
              sortColumnMode = 0;
            }
            sortColumnIndex = cell;
          } else {
            sortColumnMode = 0;
            sortColumnIndex = cell;
          }
          mainState(() {});
        },
        child: buildContainer(
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            mh: cellWidthMargin));
  }

  String getValue() {
    var value = '$data';
    if ('$data' == 'null') {
      return 'zzzzzzzzzzzzzzzzz';
    }

    return value;
  }
}
